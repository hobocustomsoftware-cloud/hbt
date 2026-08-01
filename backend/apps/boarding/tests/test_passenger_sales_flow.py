from datetime import timedelta
from decimal import Decimal
import hashlib
import hmac
import json
import uuid
from unittest.mock import patch

from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from apps.boarding.models import BoardingRecord
from apps.boarding.services import board_passenger, validate_boarding
from apps.bookings.models import (
    Booking,
    CorporateBookingApproval,
    CorporateCustomer,
    CorporateInvoice,
    SeatReservation,
)
from apps.bookings.services import confirm_booking, create_booking, expire_booking
from apps.fleet.models import LayoutPosition, SeatLayout
from apps.fares.models import FareQuote
from apps.identity.models import User
from apps.locations.models import OperationalStatus, PhysicalTerminal
from apps.network.models import Route, RouteStop
from apps.offline.models import Device, SyncOperation
from apps.offline.services import apply_sync_operation
from apps.passengers.models import Passenger
from apps.payments.models import (
    PaymentConnector,
    PaymentIntent,
    PaymentRecord,
    PaymentWebhookEvent,
    RefundRequest,
)
from apps.payments.services import (
    complete_refund,
    create_payment,
    decide_payment,
    decide_refund,
    mark_refund_paid,
    request_refund,
    initiate_provider_payment,
    reconcile_payment_intent,
    process_provider_webhook,
    save_payment_connector,
    test_payment_connector as verify_payment_connector,
)
from apps.payments.services import PAYMENT_ADAPTERS
from apps.scheduling.models import Trip
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)
from apps.ticketing.models import Ticket
from apps.ticketing.services import issue_ticket, reissue_ticket


class PassengerSalesFlowTests(TestCase):
    def setUp(self):
        tenant = Tenant.objects.create(name="Sales Tenant", slug="sales")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Sales Company Limited",
            display_name="Sales Company",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959555555555", password="Strong-pass-123"
        )
        terminal = PhysicalTerminal.objects.create(
            code="sales-terminal",
            name="Sales Terminal",
            status=OperationalStatus.ACTIVE,
        )
        self.route = Route.objects.create(
            organization=self.organization,
            code="sales-route",
            name="Sales Route",
            status=Route.Status.ACTIVE,
        )
        self.origin = RouteStop.objects.create(
            route=self.route,
            terminal=terminal,
            code="origin",
            name="Origin",
            sequence=1,
            stop_type=RouteStop.Type.TERMINAL,
            status=RouteStop.Status.ACTIVE,
        )
        self.destination = RouteStop.objects.create(
            route=self.route,
            code="destination",
            name="Destination",
            sequence=2,
            stop_type=RouteStop.Type.MAJOR,
            status=RouteStop.Status.ACTIVE,
        )
        self.layout = SeatLayout.objects.create(
            organization=self.organization,
            code="sales-layout",
            name="Sales Layout",
            layout_type=SeatLayout.Type.CUSTOM,
            status=SeatLayout.Status.APPROVED,
            row_count=1,
            column_count=2,
        )
        self.seat_a = LayoutPosition.objects.create(
            layout=self.layout,
            identifier="1A",
            position_type=LayoutPosition.Type.STANDARD,
            row=1,
            column=1,
        )
        self.seat_b = LayoutPosition.objects.create(
            layout=self.layout,
            identifier="1B",
            position_type=LayoutPosition.Type.STANDARD,
            row=1,
            column=2,
        )
        departure = timezone.now() + timedelta(days=2)
        self.trip = Trip.objects.create(
            organization=self.organization,
            route=self.route,
            trip_number="SALE-TRIP-1",
            service_date=departure.date(),
            planned_departure_at=departure,
            planned_arrival_at=departure + timedelta(hours=8),
            seat_layout=self.layout,
            seat_layout_snapshot={"id": str(self.layout.id), "version": 1},
        )
        self.passenger_a = Passenger.objects.create(
            organization=self.organization,
            passenger_code="P-1",
            full_name="Passenger One",
        )
        self.passenger_a.set_nrc("12/ကမရ(နိုင်)123456")
        self.passenger_a.save()
        self.passenger_b = Passenger.objects.create(
            organization=self.organization,
            passenger_code="P-2",
            full_name="Passenger Two",
        )
        self.passenger_b.set_nrc("12/ကမရ(နိုင်)123457")
        self.passenger_b.save()

    def make_booking(self):
        return create_booking(
            organization=self.organization,
            actor=self.user,
            trip=self.trip,
            booking_number="BOOK-1",
            booking_type=Booking.Type.GROUP,
            channel=Booking.Channel.MOBILE,
            contact_name="Buyer",
            contact_phone="+959111111111",
            pickup_stop=self.origin,
            dropoff_stop=self.destination,
            passenger_seats=[
                {"passenger": self.passenger_a, "seat_position": self.seat_a},
                {"passenger": self.passenger_b, "seat_position": self.seat_b},
            ],
        )

    def issue_for_item(self, item, number):
        return issue_ticket(
            booking_passenger=item,
            actor=self.user,
            ticket_number=number,
            ticket_type=Ticket.Type.ELECTRONIC,
            fare_amount=Decimal("20000"),
            discount_amount=Decimal("1000"),
            tax_amount=Decimal("0"),
            service_charge=Decimal("500"),
            total_amount=Decimal("19500"),
            currency="MMK",
            issuing_channel="mobile",
        )

    def confirm_paid_booking(self, booking):
        PaymentRecord.objects.create(
            organization=self.organization,
            payment_number="MANUAL-CASH-001",
            booking=booking,
            method=PaymentRecord.Method.CASH,
            status=PaymentRecord.Status.CONFIRMED,
            amount=Decimal("39000"),
            recorded_by=self.user,
            confirmed_by=self.user,
            confirmed_at=timezone.now(),
        )
        return confirm_booking(
            booking=booking,
            actor=self.user,
            authorization_reference="MANUAL-CASH-001",
        )

    def test_expiry_releases_seats_and_is_idempotent(self):
        booking = self.make_booking()
        booking.customer_account = self.user
        booking.expires_at = timezone.now() - timedelta(minutes=1)
        booking.save(update_fields=["customer_account", "expires_at", "updated_at"])

        with self.captureOnCommitCallbacks(execute=True):
            self.assertTrue(expire_booking(booking=booking))
        booking.refresh_from_db()
        self.assertEqual(booking.status, Booking.Status.EXPIRED)
        self.assertFalse(
            SeatReservation.objects.filter(
                booking_passenger__booking=booking,
                status=SeatReservation.Status.RESERVED,
            ).exists()
        )
        self.assertFalse(expire_booking(booking=booking))

    def test_expiry_does_not_override_confirmed_payment(self):
        booking = self.make_booking()
        booking.expires_at = timezone.now() - timedelta(minutes=1)
        booking.save(update_fields=["expires_at", "updated_at"])
        PaymentRecord.objects.create(
            organization=self.organization,
            payment_number="CONFIRMED-BEFORE-EXPIRY",
            booking=booking,
            method=PaymentRecord.Method.CASH,
            status=PaymentRecord.Status.CONFIRMED,
            amount=Decimal("39000"),
            recorded_by=self.user,
            confirmed_by=self.user,
            confirmed_at=timezone.now(),
        )

        self.assertFalse(expire_booking(booking=booking))
        booking.refresh_from_db()
        self.assertEqual(booking.status, Booking.Status.RESERVED)

    def test_group_booking_reserves_one_unique_seat_per_passenger(self):
        booking = self.make_booking()
        self.assertEqual(booking.passenger_items.count(), 2)
        self.assertEqual(self.trip.seat_reservations.count(), 2)

    def test_booking_retry_returns_same_booking(self):
        request_id = uuid.uuid4()
        kwargs = {
            "organization": self.organization,
            "actor": self.user,
            "trip": self.trip,
            "booking_number": "BOOK-RETRY",
            "booking_type": Booking.Type.INDIVIDUAL,
            "channel": Booking.Channel.MOBILE,
            "contact_name": "Buyer",
            "contact_phone": "+959111111111",
            "pickup_stop": self.origin,
            "dropoff_stop": self.destination,
            "client_request_id": request_id,
            "passenger_seats": [
                {"passenger": self.passenger_a, "seat_position": self.seat_a}
            ],
        }
        first = create_booking(**kwargs)
        repeated = create_booking(**kwargs)
        self.assertEqual(first.id, repeated.id)
        self.assertEqual(Booking.objects.filter(client_request_id=request_id).count(), 1)

    def test_seat_cannot_be_double_booked(self):
        self.make_booking()
        with self.assertRaises(ValidationError):
            create_booking(
                organization=self.organization,
                actor=self.user,
                trip=self.trip,
                booking_number="BOOK-2",
                booking_type=Booking.Type.INDIVIDUAL,
                channel=Booking.Channel.COUNTER,
                contact_name="Other",
                contact_phone="+959222222222",
                pickup_stop=self.origin,
                dropoff_stop=self.destination,
                passenger_seats=[
                    {
                        "passenger": Passenger.objects.create(
                            organization=self.organization,
                            passenger_code="P-3",
                            full_name="Passenger Three",
                        ),
                        "seat_position": self.seat_a,
                    }
                ],
            )

    def test_confirmation_and_individual_etickets(self):
        booking = self.make_booking()
        self.confirm_paid_booking(booking)
        items = list(booking.passenger_items.order_by("created_at"))
        first = self.issue_for_item(items[0], "TICKET-1")
        second = self.issue_for_item(items[1], "TICKET-2")
        self.assertNotEqual(first.validation_code, second.validation_code)
        self.assertEqual(first.total_amount, Decimal("19500"))

    def test_ticket_requires_confirmed_booking(self):
        booking = self.make_booking()
        with self.assertRaisesMessage(ValidationError, "confirmed booking"):
            self.issue_for_item(booking.passenger_items.first(), "TICKET-1")

    def test_ticket_validation_and_boarding_prevent_duplicates(self):
        booking = self.make_booking()
        self.confirm_paid_booking(booking)
        ticket = self.issue_for_item(
            booking.passenger_items.first(), "TICKET-1"
        )
        self.trip.status = Trip.Status.BOARDING
        self.trip.save(update_fields=["status"])
        record = validate_boarding(
            organization=self.organization,
            trip=self.trip,
            validation_code=ticket.validation_code,
            actor=self.user,
            boarding_type=BoardingRecord.Type.TERMINAL,
            method=BoardingRecord.Method.QR,
            boarding_stop=self.origin,
            identity_confirmed=True,
        )
        boarded = board_passenger(record=record, actor=self.user)
        self.assertEqual(boarded.status, BoardingRecord.Status.BOARDED)
        ticket.refresh_from_db()
        self.assertEqual(ticket.status, Ticket.Status.BOARDED)
        with self.assertRaises(ValidationError):
            validate_boarding(
                organization=self.organization,
                trip=self.trip,
                validation_code=ticket.validation_code,
                actor=self.user,
                boarding_type=BoardingRecord.Type.TERMINAL,
                method=BoardingRecord.Method.QR,
            )

    def test_completed_payment_atomically_confirms_booking_and_issues_tickets(self):
        booking = self.make_booking()
        verifier = User.objects.create_user(
            phone_number="+959555555556", password="Strong-pass-123"
        )
        payment = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="CASH-INTEGRATED-1",
            booking=booking,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("39000"),
        )
        ticket_rows = []
        for index, item in enumerate(booking.passenger_items.order_by("created_at"), 1):
            ticket_rows.append(
                {
                    "booking_passenger": item,
                    "ticket_number": f"PAID-TICKET-{index}",
                    "ticket_type": Ticket.Type.ELECTRONIC,
                    "fare_amount": Decimal("20000"),
                    "discount_amount": Decimal("1000"),
                    "tax_amount": Decimal("0"),
                    "service_charge": Decimal("500"),
                    "total_amount": Decimal("19500"),
                    "currency": "MMK",
                    "issuing_channel": "counter",
                }
            )
        decide_payment(
            payment=payment,
            actor=verifier,
            approve=True,
            tickets=ticket_rows,
        )
        booking.refresh_from_db()
        payment.refresh_from_db()
        self.assertEqual(payment.status, PaymentRecord.Status.CONFIRMED)
        self.assertEqual(booking.status, Booking.Status.CONFIRMED)
        self.assertEqual(booking.tickets.count(), 2)

    def test_payment_recorder_cannot_verify_own_payment(self):
        booking = self.make_booking()
        payment = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="CASH-SELF-VERIFY",
            booking=booking,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("39000"),
        )
        with self.assertRaisesMessage(ValidationError, "cannot verify"):
            decide_payment(
                payment=payment,
                actor=self.user,
                approve=True,
                tickets=[],
            )

    def test_refund_enforces_separation_ceiling_and_revokes_ticket(self):
        booking = self.make_booking()
        self.confirm_paid_booking(booking)
        ticket = self.issue_for_item(
            booking.passenger_items.first(), "REFUND-TICKET-1"
        )
        payment = booking.payment_records.get()
        refund = request_refund(
            organization=self.organization,
            payment=payment,
            ticket=ticket,
            actor=self.user,
            refund_number="REF-1",
            requested_amount=Decimal("19500"),
            currency="MMK",
            reason="Passenger cancelled before departure",
        )
        with self.assertRaisesMessage(ValidationError, "cannot approve"):
            decide_refund(refund=refund, actor=self.user, approve=True)
        approver = User.objects.create_user(
            phone_number="+959555555557", password="Strong-pass-123"
        )
        refund = decide_refund(
            refund=refund,
            actor=approver,
            approve=True,
            approved_amount=Decimal("19500"),
        )
        refund = mark_refund_paid(
            refund=refund,
            actor=approver,
            payout_reference="PAYOUT-REF-1",
        )
        refund = complete_refund(refund=refund, actor=approver)
        ticket.refresh_from_db()
        self.assertEqual(refund.status, RefundRequest.Status.COMPLETED)
        self.assertEqual(ticket.status, Ticket.Status.CANCELLED)
        with self.assertRaisesMessage(ValidationError, "exceeds"):
            request_refund(
                organization=self.organization,
                payment=payment,
                actor=self.user,
                refund_number="REF-TOO-LARGE",
                requested_amount=Decimal("20000"),
                currency="MMK",
                reason="Invalid excessive refund",
            )

    def test_reissue_invalidates_original_qr_and_links_replacement(self):
        booking = self.make_booking()
        self.confirm_paid_booking(booking)
        original = self.issue_for_item(
            booking.passenger_items.first(), "REISSUE-OLD"
        )
        replacement = reissue_ticket(
            ticket=original,
            actor=self.user,
            ticket_number="REISSUE-NEW",
            reason="Damaged printed ticket",
        )
        original.refresh_from_db()
        self.assertEqual(original.status, Ticket.Status.REISSUED)
        self.assertEqual(replacement.replacement_of_id, original.id)
        self.assertNotEqual(replacement.validation_code, original.validation_code)

    def test_provider_connector_encrypts_secrets_and_quarantines_bad_webhook(self):
        booking = self.make_booking()
        payment = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="PROVIDER-PAYMENT-1",
            booking=booking,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("39000"),
        )
        connector = save_payment_connector(
            organization=self.organization,
            actor=self.user,
            credentials={"api_key": "sandbox-secret-key"},
            webhook_secret="signed-webhook-secret",
            code="sandbox-one",
            adapter="manual_sandbox",
            environment=PaymentConnector.Environment.SANDBOX,
            status=PaymentConnector.Status.ACTIVE,
            merchant_id="MERCHANT-1",
        )
        self.assertNotIn("sandbox-secret-key", connector.encrypted_credentials)
        connector = verify_payment_connector(
            connector=connector, actor=self.user
        )
        self.assertTrue(connector.last_test_succeeded)
        intent = initiate_provider_payment(
            connector=connector,
            payment=payment,
            actor=self.user,
            idempotency_key=uuid.uuid4(),
        )
        repeated = initiate_provider_payment(
            connector=connector,
            payment=payment,
            actor=self.user,
            idempotency_key=intent.idempotency_key,
        )
        self.assertEqual(intent.id, repeated.id)
        payload = {
            "event_id": "EVENT-1",
            "provider_reference": intent.provider_reference,
            "amount": "1.00",
            "currency": "MMK",
            "merchant_id": "MERCHANT-1",
            "status": "succeeded",
            "occurred_at": timezone.now().isoformat(),
        }
        raw = json.dumps(
            payload, sort_keys=True, separators=(",", ":")
        ).encode()
        signature = hmac.new(
            b"signed-webhook-secret", raw, hashlib.sha256
        ).hexdigest()
        event = process_provider_webhook(
            connector=connector,
            raw_body=raw,
            signature=signature,
            payload=payload,
        )
        self.assertEqual(
            event.status, PaymentWebhookEvent.Status.QUARANTINED
        )
        intent.refresh_from_db()
        self.assertEqual(intent.status, PaymentIntent.Status.PENDING)

    def test_provider_webhook_rejects_invalid_signature(self):
        connector = save_payment_connector(
            organization=self.organization,
            actor=self.user,
            credentials={"api_key": "sandbox-secret-key"},
            webhook_secret="signed-webhook-secret",
            code="sandbox-signature",
            adapter="manual_sandbox",
            environment=PaymentConnector.Environment.SANDBOX,
            status=PaymentConnector.Status.ACTIVE,
            merchant_id="MERCHANT-1",
        )
        with self.assertRaisesMessage(ValidationError, "signature"):
            process_provider_webhook(
                connector=connector,
                raw_body=b"{}",
                signature="invalid",
                payload={},
            )

    def test_provider_reconciliation_submits_matching_success_for_review(self):
        booking = self.make_booking()
        payment = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="RECONCILE-PAYMENT-1",
            booking=booking,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("39000"),
        )
        connector = save_payment_connector(
            organization=self.organization,
            actor=self.user,
            credentials={"api_key": "sandbox-secret-key"},
            webhook_secret="signed-webhook-secret",
            code="sandbox-reconcile",
            adapter="manual_sandbox",
            environment=PaymentConnector.Environment.SANDBOX,
            status=PaymentConnector.Status.ACTIVE,
            merchant_id="MERCHANT-1",
        )
        intent = initiate_provider_payment(
            connector=connector,
            payment=payment,
            actor=self.user,
            idempotency_key=uuid.uuid4(),
        )

        class SuccessfulAdapter:
            def query(self, connector, intent, credentials):
                return {
                    "provider_reference": intent.provider_reference,
                    "status": "succeeded",
                    "amount": str(intent.payment.amount),
                    "currency": intent.payment.currency,
                    "merchant_id": connector.merchant_id,
                }

        with patch.dict(
            PAYMENT_ADAPTERS, {"manual_sandbox": SuccessfulAdapter()}
        ):
            intent = reconcile_payment_intent(intent=intent)
        payment.refresh_from_db()
        self.assertEqual(intent.status, PaymentIntent.Status.SUCCEEDED)
        self.assertEqual(payment.status, PaymentRecord.Status.SUBMITTED)
        self.assertEqual(
            payment.transaction_reference, intent.provider_reference
        )
        self.assertIsNone(intent.next_reconcile_at)

    def test_invoice_partial_payments_allocate_and_mark_paid(self):
        booking = self.make_booking()
        customer = CorporateCustomer.objects.create(
            organization=self.organization,
            code="company-one",
            legal_name="Company One Limited",
            display_name="Company One",
        )
        quote = FareQuote.objects.create(
            booking=booking,
            version=1,
            status=FareQuote.Status.LOCKED,
            currency="MMK",
            subtotal=Decimal("39000"),
            discount_amount=Decimal("0"),
            tax_amount=Decimal("0"),
            total_amount=Decimal("39000"),
            expires_at=timezone.now() + timedelta(hours=1),
            locked_at=timezone.now(),
            created_by=self.user,
        )
        approval = CorporateBookingApproval.objects.create(
            booking=booking,
            corporate_customer=customer,
            fare_quote=quote,
            status=CorporateBookingApproval.Status.APPROVED,
            requested_by=self.user,
            submitted_at=timezone.now(),
            decided_by=self.user,
            decided_at=timezone.now(),
        )
        invoice = CorporateInvoice.objects.create(
            organization=self.organization,
            approval=approval,
            invoice_number="INV-PARTIAL-1",
            currency="MMK",
            subtotal=Decimal("39000"),
            total_amount=Decimal("39000"),
            due_at=timezone.now() + timedelta(days=7),
            issued_at=timezone.now(),
            issued_by=self.user,
        )
        approver = User.objects.create_user(
            phone_number="+959555555558", password="Strong-pass-123"
        )
        first = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="INV-PAY-1",
            corporate_invoice=invoice,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("20000"),
        )
        decide_payment(payment=first, actor=approver, approve=True)
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, CorporateInvoice.Status.ISSUED)
        second = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="INV-PAY-2",
            corporate_invoice=invoice,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("19000"),
        )
        decide_payment(payment=second, actor=approver, approve=True)
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, CorporateInvoice.Status.PAID)
        self.assertEqual(
            sum(a.amount for a in invoice.payment_allocations.all()),
            Decimal("39000"),
        )

    def test_offline_ticket_validation_is_idempotent_and_domain_guarded(self):
        membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
        )
        booking = self.make_booking()
        self.confirm_paid_booking(booking)
        ticket = self.issue_for_item(
            booking.passenger_items.first(), "OFFLINE-TICKET-1"
        )
        self.trip.status = Trip.Status.BOARDING
        self.trip.save(update_fields=["status"])
        operation_id = uuid.uuid4()
        payload = {
            "trip_id": str(self.trip.id),
            "validation_code": str(ticket.validation_code),
            "boarding_type": "terminal",
            "identity_confirmed": True,
        }
        first = apply_sync_operation(
            device=device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=operation_id,
            operation_type="ticket.validate",
            payload=payload,
        )
        repeated = apply_sync_operation(
            device=device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=operation_id,
            operation_type="ticket.validate",
            payload=payload,
        )
        self.assertEqual(first.status, SyncOperation.Status.APPLIED)
        self.assertEqual(first.id, repeated.id)
        self.assertEqual(
            BoardingRecord.objects.get(ticket=ticket).offline, True
        )

    def test_offline_idempotency_key_reuse_with_changed_payload_conflicts(self):
        device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
        )
        operation_id = uuid.uuid4()
        first = apply_sync_operation(
            device=device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=operation_id,
            operation_type="unsupported.example",
            payload={"value": 1},
        )
        self.assertEqual(first.status, SyncOperation.Status.REJECTED)
        with self.assertRaisesMessage(ValidationError, "different content"):
            apply_sync_operation(
                device=device,
                organization=self.organization,
                actor=self.user,
                client_operation_id=operation_id,
                operation_type="unsupported.example",
                payload={"value": 2},
            )

    def test_offline_walk_up_booking_and_cash_payment_use_server_rules(self):
        membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
        )
        payload = {
            "trip": str(self.trip.id),
            "booking_number": "OFFLINE-WALKUP-1",
            "booking_type": Booking.Type.INDIVIDUAL,
            "channel": Booking.Channel.ROADSIDE,
            "contact_name": "Offline Buyer",
            "contact_phone": "+959111111111",
            "pickup_stop": str(self.origin.id),
            "dropoff_stop": str(self.destination.id),
            "passenger_seats": [
                {
                    "passenger": str(self.passenger_a.id),
                    "seat_position": str(self.seat_a.id),
                }
            ],
        }
        booking_operation = apply_sync_operation(
            device=device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=uuid.uuid4(),
            operation_type="booking.walk_up",
            payload=payload,
        )
        self.assertEqual(booking_operation.status, SyncOperation.Status.APPLIED)
        booking = Booking.objects.get(
            pk=booking_operation.response_payload["booking_id"]
        )
        cash_operation = apply_sync_operation(
            device=device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=uuid.uuid4(),
            operation_type="payment.record_cash",
            payload={
                "booking_id": str(booking.id),
                "payment_number": "OFFLINE-CASH-1",
                "amount": "20000",
                "currency": "MMK",
            },
        )
        self.assertEqual(cash_operation.status, SyncOperation.Status.APPLIED)
        self.assertEqual(
            PaymentRecord.objects.get(
                pk=cash_operation.response_payload["payment_id"]
            ).status,
            PaymentRecord.Status.RECORDED,
        )
        conflict_payload = dict(payload)
        conflict_payload["booking_number"] = "OFFLINE-WALKUP-2"
        conflict = apply_sync_operation(
            device=device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=uuid.uuid4(),
            operation_type="booking.walk_up",
            payload=conflict_payload,
        )
        self.assertEqual(conflict.status, SyncOperation.Status.CONFLICT)
