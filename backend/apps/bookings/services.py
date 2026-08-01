from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.fleet.models import LayoutPosition
from apps.passengers.models import Passenger
from apps.scheduling.models import Trip

from .models import (
    Booking,
    BookingPassenger,
    CorporateBookingApproval,
    CorporateCustomerMember,
    CorporateInvoice,
    SeatLock,
    SeatReservation,
)
from .seat_lock_services import consume_locks_for_booking, sweep_expired_seat_locks


@transaction.atomic
def create_booking(
    *, organization, actor, passenger_seats, customer_account=None, **data
):
    from apps.subscriptions.services import require_entitlement

    subscription = getattr(organization.tenant, "subscription", None)
    if subscription is not None:
        require_entitlement(subscription, "public_booking")
    client_request_id = data.get("client_request_id")
    if client_request_id:
        existing = Booking.objects.filter(
            client_request_id=client_request_id
        ).first()
        if existing:
            if (
                existing.organization_id != organization.id
                or (
                    customer_account
                    and existing.customer_account_id != customer_account.id
                )
            ):
                raise ValidationError("Client request ID is already in use.")
            return existing
    trip = Trip.objects.select_for_update().get(pk=data.pop("trip").pk)
    if trip.organization_id != organization.id:
        raise ValidationError("Trip belongs to another organization.")
    if organization.status != organization.Status.ACTIVE:
        raise ValidationError("Transport company is not accepting bookings.")
    if trip.status not in (Trip.Status.PLANNED, Trip.Status.READY):
        raise ValidationError("This trip is no longer open for advance booking.")
    if not trip.seat_layout_id:
        raise ValidationError("Trip has no assigned vehicle seat layout.")
    if not passenger_seats:
        raise ValidationError("Booking requires at least one passenger.")
    passenger_ids = [item["passenger"].id for item in passenger_seats]
    seat_ids = [item["seat_position"].id for item in passenger_seats]
    if len(passenger_ids) != len(set(passenger_ids)):
        raise ValidationError("A passenger cannot appear twice in one booking.")
    if len(seat_ids) != len(set(seat_ids)):
        raise ValidationError("A seat cannot appear twice in one booking.")
    booking = Booking(
        organization=organization,
        trip=trip,
        created_by=actor,
        customer_account=customer_account,
        status=Booking.Status.RESERVED,
        **data,
    )
    booking.full_clean()
    booking.save()
    seats = LayoutPosition.objects.select_for_update().filter(
        id__in=seat_ids, layout_id=trip.seat_layout_id, bookable=True
    )
    if seats.count() != len(seat_ids):
        raise ValidationError("One or more seats are invalid for this trip.")
    if Passenger.objects.filter(
        id__in=passenger_ids, organization=organization
    ).count() != len(passenger_ids):
        raise ValidationError("One or more passengers are invalid.")
    pickup_sequence = booking.pickup_stop.sequence
    dropoff_sequence = booking.dropoff_stop.sequence
    # Seat lock enforcement: seats held by someone else cannot be booked.
    sweep_expired_seat_locks()
    locks_conflict = SeatLock.objects.filter(
        trip=trip,
        seat_position_id__in=seat_ids,
        status=SeatLock.Status.HELD,
    )
    if actor is not None:
        locks_conflict = locks_conflict.exclude(held_by_user_id=actor.id)
    if locks_conflict.exists():
        raise ValidationError(
            "One or more seats are held by another counter or passenger."
        )
    conflicting = SeatReservation.objects.filter(
        trip=trip,
        seat_position_id__in=seat_ids,
        status__in=[
            SeatReservation.Status.HELD,
            SeatReservation.Status.RESERVED,
            SeatReservation.Status.CONFIRMED,
        ],
        pickup_sequence__lt=dropoff_sequence,
        dropoff_sequence__gt=pickup_sequence,
    ).exists()
    if conflicting:
        raise ValidationError("One or more seats are already reserved for this segment.")
    try:
        for item in passenger_seats:
            booking_passenger = BookingPassenger.objects.create(
                booking=booking, passenger=item["passenger"]
            )
            SeatReservation.objects.create(
                booking_passenger=booking_passenger,
                trip=trip,
                seat_position=item["seat_position"],
                seat_identifier_snapshot=item["seat_position"].identifier,
                pickup_sequence=pickup_sequence,
                dropoff_sequence=dropoff_sequence,
                status=SeatReservation.Status.RESERVED,
            )
    except IntegrityError as exc:
        raise ValidationError("One or more seats are already reserved.") from exc
    # The seats are now reserved under this booking — consume our own locks.
    consume_locks_for_booking(booking=booking, actor=actor)
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action="booking.created",
        resource_type="booking",
        resource_id=booking.id,
        after={
            "booking_number": booking.booking_number,
            "trip_id": trip.id,
            "passenger_count": len(passenger_seats),
            "seats": [item["seat_position"].identifier for item in passenger_seats],
        },
    )
    return booking


@transaction.atomic
def confirm_booking(*, booking, actor, authorization_reference):
    booking = Booking.objects.select_for_update().get(pk=booking.pk)
    if booking.status != Booking.Status.RESERVED:
        raise ValidationError("Only reserved bookings can be confirmed.")
    if booking.expires_at and booking.expires_at <= timezone.now():
        raise ValidationError("Booking has expired.")
    if not authorization_reference.strip():
        raise ValidationError("Completed payment reference is required.")
    from apps.payments.models import PaymentRecord

    payment_exists = PaymentRecord.objects.filter(
        booking=booking,
        payment_number=authorization_reference,
        status=PaymentRecord.Status.CONFIRMED,
    ).exists()
    if not payment_exists:
        raise ValidationError("Booking confirmation requires a completed payment.")
    missing_identity = booking.passenger_items.filter(
        passenger__nrc_blind_index="",
        passenger__passport_number="",
    ).exists()
    if missing_identity:
        raise ValidationError(
            "Every traveler requires an NRC or passport before confirmation."
        )
    booking.status = Booking.Status.CONFIRMED
    booking.confirmed_at = timezone.now()
    booking.authorization_reference = authorization_reference
    booking.save(
        update_fields=[
            "status",
            "confirmed_at",
            "authorization_reference",
            "updated_at",
        ]
    )
    SeatReservation.objects.filter(
        booking_passenger__booking=booking,
        status=SeatReservation.Status.RESERVED,
    ).update(status=SeatReservation.Status.CONFIRMED)
    record_audit_event(
        actor=actor,
        tenant_id=booking.organization.tenant_id,
        organization_id=booking.organization_id,
        action="booking.confirmed",
        resource_type="booking",
        resource_id=booking.id,
        after={"status": booking.status},
        metadata={"authorization_reference": authorization_reference},
    )
    return booking


@transaction.atomic
def cancel_booking(*, booking, actor, reason):
    booking = Booking.objects.select_for_update().get(pk=booking.pk)
    if booking.status not in (Booking.Status.RESERVED, Booking.Status.CONFIRMED):
        raise ValidationError("Booking cannot be cancelled in its current status.")
    if booking.tickets.filter(
        status__in=[
            "issued",
            "validated",
            "boarded",
            "completed",
        ]
    ).exists():
        raise ValidationError(
            "Active tickets must be cancelled before the booking."
        )
    booking.status = Booking.Status.CANCELLED
    booking.save(update_fields=["status", "updated_at"])
    SeatReservation.objects.filter(
        booking_passenger__booking=booking,
        status__in=[
            SeatReservation.Status.HELD,
            SeatReservation.Status.RESERVED,
            SeatReservation.Status.CONFIRMED,
        ],
    ).update(status=SeatReservation.Status.RELEASED)
    record_audit_event(
        actor=actor,
        tenant_id=booking.organization.tenant_id,
        organization_id=booking.organization_id,
        action="booking.cancelled",
        resource_type="booking",
        resource_id=booking.id,
        reason=reason,
        after={"status": booking.status},
    )
    return booking


@transaction.atomic
def expire_booking(*, booking):
    """Expire an unpaid reservation and release its seats idempotently."""
    booking = Booking.objects.select_for_update().select_related(
        "organization"
    ).get(pk=booking.pk)
    if booking.status != Booking.Status.RESERVED:
        return False
    if not booking.expires_at or booking.expires_at > timezone.now():
        return False

    from apps.payments.models import PaymentRecord

    if PaymentRecord.objects.filter(
        booking=booking,
        status=PaymentRecord.Status.CONFIRMED,
    ).exists():
        return False

    booking.status = Booking.Status.EXPIRED
    booking.save(update_fields=["status", "updated_at"])
    SeatReservation.objects.filter(
        booking_passenger__booking=booking,
        status__in=[
            SeatReservation.Status.HELD,
            SeatReservation.Status.RESERVED,
        ],
    ).update(status=SeatReservation.Status.EXPIRED)
    CorporateBookingApproval.objects.filter(
        booking=booking,
        status=CorporateBookingApproval.Status.SUBMITTED,
    ).update(status=CorporateBookingApproval.Status.CANCELLED)
    record_audit_event(
        tenant_id=booking.organization.tenant_id,
        organization_id=booking.organization_id,
        action="booking.expired",
        resource_type="booking",
        resource_id=booking.id,
        before={"status": Booking.Status.RESERVED},
        after={"status": Booking.Status.EXPIRED},
        metadata={"expires_at": booking.expires_at},
    )
    if booking.customer_account_id:
        from apps.notifications.models import Notification
        from apps.notifications.services import enqueue_event_after_commit

        enqueue_event_after_commit(
            event_type="booking.expired",
            event_key=f"booking:{booking.id}:expired",
            kind=Notification.Kind.BOOKING,
            category=Notification.Category.ACTION_REQUIRED,
            recipients=[booking.customer_account_id],
            organization=booking.organization,
            title="Booking သက်တမ်းကုန်သွားပါပြီ",
            body="အချိန်မီငွေပေးချေမှုမပြီးသဖြင့် ထိုင်ခုံကို ပြန်လွှတ်လိုက်ပါပြီ။",
            data={"booking_id": str(booking.id)},
            deep_link=f"/bookings/{booking.id}",
        )
    return True


@transaction.atomic
def submit_corporate_booking(
    *, booking, corporate_customer, fare_quote, actor
):
    booking = Booking.objects.select_for_update().get(pk=booking.pk)
    membership = CorporateCustomerMember.objects.filter(
        corporate_customer=corporate_customer,
        user=actor,
        status=CorporateCustomerMember.Status.ACTIVE,
        can_request=True,
    ).first()
    if membership is None:
        raise ValidationError("User is not an authorized company requester.")
    if booking.customer_account_id != actor.id:
        raise ValidationError("Corporate booking belongs to another requester.")
    if booking.booking_type != Booking.Type.CORPORATE:
        raise ValidationError("Booking is not a corporate booking.")
    if fare_quote.booking_id != booking.id or fare_quote.status != "locked":
        raise ValidationError("Corporate booking requires its locked fare quote.")
    approval = CorporateBookingApproval(
        booking=booking,
        corporate_customer=corporate_customer,
        fare_quote=fare_quote,
        requested_by=actor,
        submitted_at=timezone.now(),
    )
    approval.full_clean()
    approval.save()
    record_audit_event(
        actor=actor,
        tenant_id=booking.organization.tenant_id,
        organization_id=booking.organization_id,
        action="corporate_booking.submitted",
        resource_type="corporate_booking_approval",
        resource_id=approval.id,
        after={
            "booking_id": booking.id,
            "corporate_customer_id": corporate_customer.id,
            "fare_quote_id": fare_quote.id,
            "total_amount": fare_quote.total_amount,
        },
    )
    return approval


@transaction.atomic
def decide_corporate_booking(*, approval, actor, approve, reason=""):
    approval = CorporateBookingApproval.objects.select_for_update().get(
        pk=approval.pk
    )
    authorized = CorporateCustomerMember.objects.filter(
        corporate_customer=approval.corporate_customer,
        user=actor,
        status=CorporateCustomerMember.Status.ACTIVE,
        can_approve=True,
    ).exists()
    if not authorized:
        raise ValidationError("User is not an authorized company approver.")
    if approval.requested_by_id == actor.id:
        raise ValidationError("Requester cannot approve their own booking.")
    if approval.status != CorporateBookingApproval.Status.SUBMITTED:
        raise ValidationError("Corporate booking is not awaiting approval.")
    if not approve and not reason.strip():
        raise ValidationError("Rejection requires a reason.")
    approval.status = (
        CorporateBookingApproval.Status.APPROVED
        if approve
        else CorporateBookingApproval.Status.REJECTED
    )
    approval.decided_by = actor
    approval.decided_at = timezone.now()
    approval.decision_reason = reason
    approval.save()
    record_audit_event(
        actor=actor,
        tenant_id=approval.booking.organization.tenant_id,
        organization_id=approval.booking.organization_id,
        action=f"corporate_booking.{approval.status}",
        resource_type="corporate_booking_approval",
        resource_id=approval.id,
        reason=reason,
        after={"booking_id": approval.booking_id, "status": approval.status},
    )
    return approval


@transaction.atomic
def issue_corporate_invoice(
    *, approval, actor, invoice_number, replaces=None
):
    approval = CorporateBookingApproval.objects.select_for_update().select_related(
        "fare_quote", "corporate_customer", "booking__organization"
    ).get(pk=approval.pk)
    if approval.status != CorporateBookingApproval.Status.APPROVED:
        raise ValidationError("Invoice requires an approved corporate booking.")
    if approval.invoices.exclude(status=CorporateInvoice.Status.VOID).exists():
        raise ValidationError("An active invoice already exists.")
    if replaces and (
        replaces.approval_id != approval.id
        or replaces.status != CorporateInvoice.Status.VOID
    ):
        raise ValidationError("Replacement must reference a void invoice.")
    quote = approval.fare_quote
    now = timezone.now()
    invoice = CorporateInvoice.objects.create(
        organization=approval.booking.organization,
        approval=approval,
        replaces=replaces,
        invoice_number=invoice_number,
        currency=quote.currency,
        subtotal=quote.subtotal,
        discount_amount=quote.discount_amount,
        tax_amount=quote.tax_amount,
        total_amount=quote.total_amount,
        due_at=now + timedelta(
            days=approval.corporate_customer.payment_terms_days
        ),
        issued_at=now,
        issued_by=actor,
        snapshot={
            "booking_id": str(approval.booking_id),
            "fare_quote_id": str(quote.id),
            "fare_quote_version": quote.version,
            "corporate_customer_id": str(approval.corporate_customer_id),
            "corporate_customer_name": approval.corporate_customer.legal_name,
            "passenger_count": approval.booking.passenger_items.count(),
        },
    )
    record_audit_event(
        actor=actor,
        tenant_id=invoice.organization.tenant_id,
        organization_id=invoice.organization_id,
        action="invoice.issued",
        resource_type="corporate_invoice",
        resource_id=invoice.id,
        after={
            "invoice_number": invoice.invoice_number,
            "total_amount": invoice.total_amount,
        },
    )
    return invoice


@transaction.atomic
def void_corporate_invoice(*, invoice, actor, reason):
    invoice = CorporateInvoice.objects.select_for_update().get(pk=invoice.pk)
    if invoice.status != CorporateInvoice.Status.ISSUED:
        raise ValidationError("Only an issued invoice may be voided.")
    if not reason.strip():
        raise ValidationError("Invoice void requires a reason.")
    invoice.status = CorporateInvoice.Status.VOID
    invoice.voided_at = timezone.now()
    invoice.voided_by = actor
    invoice.void_reason = reason
    invoice.save()
    record_audit_event(
        actor=actor,
        tenant_id=invoice.organization.tenant_id,
        organization_id=invoice.organization_id,
        action="invoice.voided",
        resource_type="corporate_invoice",
        resource_id=invoice.id,
        reason=reason,
    )
    return invoice
from datetime import timedelta
