from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.bookings.models import Booking, BookingPassenger, SeatReservation
from apps.notifications.models import Notification
from apps.notifications.services import enqueue_event_after_commit

from .models import Ticket


@transaction.atomic
def issue_ticket(*, booking_passenger, actor, **data):
    item = BookingPassenger.objects.select_for_update().get(
        pk=booking_passenger.pk
    )
    booking = item.booking
    if booking.status != Booking.Status.CONFIRMED:
        raise ValidationError("Ticket issuance requires a confirmed booking.")
    if not booking.authorization_reference:
        raise ValidationError("Booking has no completed payment authorization.")
    from apps.payments.models import PaymentRecord

    if not PaymentRecord.objects.filter(
        booking=booking,
        payment_number=booking.authorization_reference,
        status=PaymentRecord.Status.CONFIRMED,
    ).exists():
        raise ValidationError("Ticket issuance requires a completed payment.")
    reservation = item.seat_reservation
    if reservation.status != SeatReservation.Status.CONFIRMED:
        raise ValidationError("Passenger seat is not confirmed.")
    ticket = Ticket(
        organization=booking.organization,
        booking=booking,
        booking_passenger=item,
        passenger=item.passenger,
        trip=booking.trip,
        seat_position=reservation.seat_position,
        issued_by=actor,
        **data,
    )
    ticket.full_clean()
    try:
        ticket.save()
    except IntegrityError as exc:
        raise ValidationError("An active ticket already exists.") from exc
    record_audit_event(
        actor=actor,
        tenant_id=booking.organization.tenant_id,
        organization_id=booking.organization_id,
        action="ticket.issued",
        resource_type="ticket",
        resource_id=ticket.id,
        after={
            "ticket_number": ticket.ticket_number,
            "booking_id": booking.id,
            "passenger_id": item.passenger_id,
            "trip_id": booking.trip_id,
            "seat": reservation.seat_identifier_snapshot,
            "total_amount": ticket.total_amount,
            "currency": ticket.currency,
        },
    )
    if booking.customer_account_id:
        enqueue_event_after_commit(
            event_type="ticket.issued",
            event_key=f"ticket:{ticket.id}:issued",
            kind=Notification.Kind.TICKET,
            category=Notification.Category.INFORMATION,
            recipients=[booking.customer_account_id],
            organization=booking.organization,
            title="လက်မှတ်ထုတ်ပေးပြီးပါပြီ",
            body="သင့် E-ticket ကို App ထဲတွင်ကြည့်နိုင်ပါပြီ။",
            data={"ticket_id": str(ticket.id)},
            deep_link=f"hbt://tickets/{ticket.id}",
        )
    from apps.offline.services import record_sync_change

    record_sync_change(
        organization=booking.organization,
        resource_type="ticket",
        resource_id=ticket.id,
        operation="created",
        payload={
            "id": ticket.id,
            "ticket_number": ticket.ticket_number,
            "status": ticket.status,
            "trip_id": ticket.trip_id,
            "validation_code": ticket.validation_code,
            "updated_at": ticket.updated_at,
        },
    )
    return ticket


@transaction.atomic
def reissue_ticket(*, ticket, actor, ticket_number, reason):
    original = Ticket.objects.select_for_update().get(pk=ticket.pk)
    if original.status not in (Ticket.Status.ISSUED, Ticket.Status.VALIDATED):
        raise ValidationError("Only an active unboarded ticket can be reissued.")
    if not reason.strip():
        raise ValidationError("A reissue reason is required.")
    original.status = Ticket.Status.REISSUED
    original.revoked_at = timezone.now()
    original.revoked_by = actor
    original.revocation_reason = reason
    original.save()
    replacement = Ticket(
        organization=original.organization,
        booking=original.booking,
        booking_passenger=original.booking_passenger,
        passenger=original.passenger,
        trip=original.trip,
        seat_position=original.seat_position,
        ticket_number=ticket_number,
        ticket_type=original.ticket_type,
        fare_amount=original.fare_amount,
        discount_amount=original.discount_amount,
        tax_amount=original.tax_amount,
        service_charge=original.service_charge,
        total_amount=original.total_amount,
        currency=original.currency,
        issuing_channel=original.issuing_channel,
        issued_by=actor,
        replacement_of=original,
    )
    replacement.full_clean()
    try:
        replacement.save()
    except IntegrityError as exc:
        raise ValidationError("Ticket number already exists.") from exc
    record_audit_event(
        actor=actor,
        tenant_id=original.organization.tenant_id,
        organization_id=original.organization_id,
        action="ticket.reissued",
        resource_type="ticket",
        resource_id=replacement.id,
        reason=reason,
        before={"ticket_id": original.id, "status": Ticket.Status.ISSUED},
        after={
            "ticket_id": replacement.id,
            "ticket_number": replacement.ticket_number,
            "replacement_of": original.id,
        },
    )
    return replacement
