from datetime import timedelta
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.core import signing
from django.test import TestCase
from django.utils import timezone

from apps.cargo.models import (
    CargoCategory,
    CargoChargeLine,
    CargoContact,
    CargoPricingRule,
    CargoShipment,
)
from apps.cargo.services import (
    accept_shipment,
    assign_trip,
    mark_allocation_paid,
    transition_shipment,
)
from apps.cargo.serializers import CargoShipmentSerializer
from apps.fleet.models import Vehicle
from apps.identity.models import User
from apps.locations.models import (
    Branch,
    CompanyTerminalOperation,
    OperationalStatus,
    PhysicalTerminal,
)
from apps.network.models import Route, RouteStop
from apps.operations.services import (
    close_trip,
    create_print_document,
    create_settlement,
)
from apps.payments.models import PaymentRecord
from apps.payments.services import create_payment, decide_payment
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization, Tenant


class CargoLiteFlowTests(TestCase):
    def setUp(self):
        tenant = Tenant.objects.create(name="Cargo Tenant", slug="cargo-tenant")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Cargo Company Limited",
            display_name="Cargo Company",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959777777777", password="Strong-pass-123"
        )
        self.verifier = User.objects.create_user(
            phone_number="+959777777778", password="Strong-pass-123"
        )
        self.branch = Branch.objects.create(
            organization=self.organization,
            code="cargo-branch",
            name="Cargo Branch",
            status=OperationalStatus.ACTIVE,
        )
        origin_terminal = PhysicalTerminal.objects.create(
            code="cargo-origin", name="Cargo Origin",
            status=OperationalStatus.ACTIVE
        )
        destination_terminal = PhysicalTerminal.objects.create(
            code="cargo-destination", name="Cargo Destination",
            status=OperationalStatus.ACTIVE
        )
        self.origin_operation = CompanyTerminalOperation.objects.create(
            organization=self.organization,
            branch=self.branch,
            terminal=origin_terminal,
            code="origin-op",
            display_name="Origin Gate",
            status=OperationalStatus.ACTIVE,
        )
        self.destination_operation = CompanyTerminalOperation.objects.create(
            organization=self.organization,
            branch=self.branch,
            terminal=destination_terminal,
            code="destination-op",
            display_name="Destination Gate",
            status=OperationalStatus.ACTIVE,
        )
        route = Route.objects.create(
            organization=self.organization,
            code="cargo-route",
            name="Cargo Route",
            status=Route.Status.ACTIVE,
        )
        RouteStop.objects.create(
            route=route, terminal=origin_terminal, code="origin", name="Origin",
            sequence=1, stop_type=RouteStop.Type.TERMINAL,
            status=RouteStop.Status.ACTIVE, cargo_allowed=True
        )
        RouteStop.objects.create(
            route=route, terminal=destination_terminal, code="destination",
            name="Destination", sequence=2,
            stop_type=RouteStop.Type.TERMINAL,
            status=RouteStop.Status.ACTIVE, cargo_allowed=True
        )
        vehicle = Vehicle.objects.create(
            organization=self.organization,
            branch=self.branch,
            code="cargo-bus",
            registration_number="9N-CARGO",
            category=Vehicle.Category.EXPRESS_BUS,
            cargo_supported=True,
            status=Vehicle.Status.AVAILABLE,
        )
        departure = timezone.now() + timedelta(days=1)
        self.trip = Trip.objects.create(
            organization=self.organization,
            route=route,
            trip_number="CARGO-TRIP",
            service_date=departure.date(),
            planned_departure_at=departure,
            planned_arrival_at=departure + timedelta(hours=8),
            vehicle=vehicle,
        )
        self.sender = CargoContact.objects.create(
            organization=self.organization,
            contact_code="S-1",
            name="Regular Sender",
            phone_number="+959111111111",
        )
        self.sender.set_nrc("12/ကမရ(နိုင်)123456")
        self.sender.save()
        self.receiver = CargoContact.objects.create(
            organization=self.organization,
            contact_code="R-1",
            name="Receiver",
            phone_number="+959222222222",
        )
        self.category = CargoCategory.objects.create(
            organization=self.organization,
            code="parcel",
            name="Parcel",
            name_myanmar="ပါဆယ်",
        )
        self.tiered_rule = CargoPricingRule.objects.create(
            organization=self.organization,
            category=self.category,
            code="five-kg-base",
            name="5 kg base rate",
            base_weight_kg=Decimal("5"),
            base_price=Decimal("20000"),
            excess_rate_per_kg=Decimal("5000"),
            created_by=self.user,
        )

    def accept(self, **overrides):
        data = {
            "shipment_number": "CARGO-001",
            "sender": self.sender,
            "receiver": self.receiver,
            "origin_terminal": self.origin_operation,
            "destination_terminal": self.destination_operation,
            "item_category": "parcel",
            "piece_count": 2,
            "weight_kg": Decimal("10"),
            "weight_source": CargoShipment.WeightSource.MEASURED,
            "pricing_method": CargoShipment.PricingMethod.PER_KG,
            "rate_per_kg": Decimal("1000"),
            "additional_charge": Decimal("500"),
            "discount_amount": Decimal("500"),
            "total_charge": Decimal("10000"),
        }
        data.update(overrides)
        return accept_shipment(
            organization=self.organization, actor=self.user, **data
        )

    def test_per_kg_and_manual_pricing(self):
        kg = self.accept()
        self.assertEqual(kg.total_charge, Decimal("10000"))
        manual = self.accept(
            shipment_number="CARGO-002",
            pricing_method=CargoShipment.PricingMethod.MANUAL,
            rate_per_kg=None,
            manual_charge=Decimal("7500"),
            additional_charge=Decimal("500"),
            discount_amount=Decimal("0"),
            total_charge=Decimal("8000"),
        )
        self.assertEqual(manual.total_charge, Decimal("8000"))

    def test_end_to_end_custody_payment_print_close_and_settlement(self):
        shipment = self.accept()
        shipment = assign_trip(
            shipment=shipment, trip=self.trip, actor=self.user
        )
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.LOADED,
            actor=self.user,
        )
        self.trip.status = Trip.Status.IN_PROGRESS
        self.trip.save(update_fields=["status"])
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.IN_TRANSIT,
            actor=self.user,
        )
        payment = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="PAY-CARGO-1",
            cargo_shipment=shipment,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("10000"),
        )
        payment = decide_payment(
            payment=payment, actor=self.verifier, approve=True
        )
        document = create_print_document(
            organization=self.organization,
            actor=self.user,
            document_type="cargo_receipt",
            resource_type="cargo_shipment",
            resource_id=shipment.id,
        )
        self.assertEqual(document.payload["reference"], "CARGO-001")
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.ARRIVED,
            actor=self.user,
        )
        self.trip.status = Trip.Status.ARRIVED
        self.trip.save(update_fields=["status"])
        closing = close_trip(trip=self.trip, actor=self.user)
        settlement = create_settlement(
            trip=self.trip,
            actor=self.user,
            settlement_number="SET-1",
            actual_amount=Decimal("10000"),
        )
        self.assertEqual(closing.cargo_count, 1)
        self.assertEqual(settlement.difference_amount, Decimal("0"))
        self.assertGreaterEqual(shipment.custody_events.count(), 4)

    def test_invalid_per_kg_total_is_rejected(self):
        with self.assertRaises(ValidationError):
            self.accept(rate_per_kg=None)

    def test_multiple_items_and_charge_lines_are_calculated_by_server(self):
        shipment = accept_shipment(
            organization=self.organization,
            actor=self.user,
            shipment_number="CARGO-LINES-1",
            sender=self.sender,
            receiver=self.receiver,
            origin_terminal=self.origin_operation,
            destination_terminal=self.destination_operation,
            item_category="ignored-client-summary",
            piece_count=99,
            pricing_method=CargoShipment.PricingMethod.MANUAL,
            manual_charge=Decimal("1"),
            total_charge=Decimal("1"),
            items=[
                {
                    "category": self.category,
                    "quantity": 2,
                    "pricing_method": CargoShipment.PricingMethod.ITEMIZED,
                    "unit_price": Decimal("3000"),
                    "description": "Two parcels",
                },
                {
                    "category": self.category,
                    "quantity": 1,
                    "weight_kg": Decimal("5"),
                    "pricing_method": CargoShipment.PricingMethod.PER_KG,
                    "rate_per_kg": Decimal("1000"),
                },
            ],
            charge_lines=[
                {
                    "code": "handling",
                    "label": "Handling",
                    "kind": CargoChargeLine.Kind.CHARGE,
                    "amount": Decimal("500"),
                },
                {
                    "code": "regular-customer",
                    "label": "Regular customer discount",
                    "kind": CargoChargeLine.Kind.DISCOUNT,
                    "amount": Decimal("1000"),
                },
                {
                    "code": "destination-terminal-share",
                    "label": "Destination terminal share",
                    "kind": CargoChargeLine.Kind.ALLOCATION,
                    "amount": Decimal("750"),
                    "payout_recipient_name": "Cargo introducer",
                },
            ],
        )
        self.assertEqual(shipment.piece_count, 3)
        self.assertEqual(shipment.total_charge, Decimal("10500"))
        self.assertEqual(shipment.items.count(), 2)
        self.assertEqual(shipment.charge_lines.count(), 3)
        self.assertEqual(
            shipment.pricing_method, CargoShipment.PricingMethod.MIXED
        )

    def test_station_itemized_pricing_multiplies_quantity_and_keeps_allocations_internal(self):
        shipment = accept_shipment(
            organization=self.organization,
            actor=self.user,
            shipment_number="CARGO-STATION-1",
            sender=self.sender,
            receiver=self.receiver,
            origin_terminal=self.origin_operation,
            destination_terminal=self.destination_operation,
            item_category="parcel",
            piece_count=1,
            pricing_method=CargoShipment.PricingMethod.MANUAL,
            manual_charge=Decimal("0"),
            total_charge=Decimal("0"),
            items=[
                {
                    "category": self.category,
                    "quantity": 3,
                    "pricing_method": CargoShipment.PricingMethod.ITEMIZED,
                    "unit_price": Decimal("2000"),
                }
            ],
            charge_lines=[
                {
                    "code": "service",
                    "label": "Service charge",
                    "kind": CargoChargeLine.Kind.CHARGE,
                    "amount": Decimal("500"),
                },
                {
                    "code": "short-delivery",
                    "label": "Short delivery fee",
                    "kind": CargoChargeLine.Kind.CHARGE,
                    "amount": Decimal("300"),
                },
                {
                    "code": "terminal-share",
                    "label": "Destination terminal share",
                    "kind": CargoChargeLine.Kind.ALLOCATION,
                    "amount": Decimal("400"),
                    "payout_recipient_name": "Cargo introducer",
                },
            ],
        )
        self.assertEqual(shipment.total_charge, Decimal("6800"))
        self.assertEqual(
            shipment.pricing_method, CargoShipment.PricingMethod.ITEMIZED
        )

    def test_tiered_kg_pricing_preserves_decimal_excess(self):
        shipment = accept_shipment(
            organization=self.organization,
            actor=self.user,
            shipment_number="CARGO-TIERED-1",
            sender=self.sender,
            receiver=self.receiver,
            origin_terminal=self.origin_operation,
            destination_terminal=self.destination_operation,
            item_category="parcel",
            piece_count=1,
            pricing_method=CargoShipment.PricingMethod.MANUAL,
            manual_charge=Decimal("0"),
            total_charge=Decimal("0"),
            items=[
                {
                    "category": self.category,
                    "quantity": 1,
                    "weight_kg": Decimal("5.5"),
                    "pricing_method": CargoShipment.PricingMethod.TIERED_KG,
                    "pricing_rule": self.tiered_rule,
                }
            ],
        )
        item = shipment.items.get()
        self.assertEqual(shipment.total_charge, Decimal("22500"))
        self.assertEqual(item.base_amount, Decimal("22500"))
        self.assertEqual(
            item.pricing_rule_snapshot["excess_rate_per_kg"], "5000"
        )

    def test_border_fee_is_internal_payout_not_customer_deduction(self):
        shipment = self.accept()
        line = CargoChargeLine.objects.create(
            shipment=shipment,
            code="border-fee",
            label="ဘော်ဒါကြေး",
            kind=CargoChargeLine.Kind.ALLOCATION,
            amount=Decimal("1000"),
            payout_recipient_name="Introducer",
        )
        before = shipment.total_charge
        line = mark_allocation_paid(charge_line=line, actor=self.verifier)
        shipment.refresh_from_db()
        self.assertEqual(shipment.total_charge, before)
        self.assertTrue(line.payout_paid)
        self.assertEqual(line.payout_paid_by, self.verifier)

    def test_qr_contains_signed_reference_without_contact_data(self):
        shipment = self.accept()
        qr_payload = CargoShipmentSerializer(shipment).data["qr_payload"]
        self.assertTrue(qr_payload.startswith("HBT:CARGO:V1:"))
        self.assertNotIn(self.sender.phone_number, qr_payload)
        decoded = signing.loads(
            qr_payload.removeprefix("HBT:CARGO:V1:"),
            salt="hbt.cargo.tracking.v1",
        )
        self.assertEqual(decoded["tracking_code"], str(shipment.tracking_code))

    def test_cargo_payment_cannot_exceed_server_total(self):
        shipment = self.accept()
        payment = create_payment(
            organization=self.organization,
            actor=self.user,
            payment_number="PAY-CARGO-OVER",
            cargo_shipment=shipment,
            method=PaymentRecord.Method.CASH,
            amount=Decimal("10001"),
        )
        with self.assertRaisesMessage(ValidationError, "cannot exceed"):
            decide_payment(
                payment=payment,
                actor=self.verifier,
                approve=True,
            )

    def test_handover_requires_masked_receiver_verification(self):
        shipment = assign_trip(
            shipment=self.accept(), trip=self.trip, actor=self.user
        )
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.LOADED,
            actor=self.user,
        )
        self.trip.status = Trip.Status.IN_PROGRESS
        self.trip.save(update_fields=["status"])
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.IN_TRANSIT,
            actor=self.user,
        )
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.ARRIVED,
            actor=self.user,
        )
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.READY_FOR_PICKUP,
            actor=self.user,
        )
        with self.assertRaisesMessage(ValidationError, "verification method"):
            transition_shipment(
                shipment=shipment,
                to_status=CargoShipment.Status.HANDED_OVER,
                actor=self.user,
            )
        shipment = transition_shipment(
            shipment=shipment,
            to_status=CargoShipment.Status.HANDED_OVER,
            actor=self.user,
            evidence={
                "verification_method": "identity",
                "verification_reference_last4": "3456",
                "recipient_name": "Receiver",
            },
        )
        event = shipment.custody_events.last()
        self.assertEqual(event.verification_reference_masked, "***3456")
        self.assertEqual(shipment.status, CargoShipment.Status.HANDED_OVER)
        self.assertIsNotNone(shipment.actual_delivery_at)
