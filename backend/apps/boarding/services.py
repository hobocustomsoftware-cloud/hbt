from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.scheduling.models import Trip
from apps.ticketing.models import Ticket

from .models import BoardingRecord


@transaction.atomic
def validate_boarding(
    *,
    organization,
    trip,
    validation_code,
    actor,
    boarding_type,
    method,
    boarding_stop=None,
    identity_confirmed=False,
    notes="",
    offline=False,
    client_event_id=None,
    latitude=None,
    longitude=None,
):
    if client_event_id:
        existing = BoardingRecord.objects.filter(
            client_event_id=client_event_id
        ).first()
        if existing:
            if existing.trip_id != trip.id:
                raise ValidationError("Client event ID is already in use.")
            return existing
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    allowed = (
        (Trip.Status.BOARDING,)
        if boarding_type != BoardingRecord.Type.ROADSIDE
        else (Trip.Status.DEPARTED, Trip.Status.IN_PROGRESS, Trip.Status.DELAYED)
    )
    if trip.status not in allowed:
        raise ValidationError("Trip is not open for this boarding type.")
    try:
        ticket = (
            Ticket.objects.select_for_update()
            .select_related("passenger", "booking")
            .get(
                organization=organization,
                trip=trip,
                validation_code=validation_code,
            )
        )
    except Ticket.DoesNotExist as exc:
        raise ValidationError("Ticket is invalid for this trip.") from exc
    if ticket.status != Ticket.Status.ISSUED:
        raise ValidationError("Ticket is not eligible for validation.")
    if boarding_stop and boarding_stop.route_id != trip.route_id:
        raise ValidationError("Boarding stop is not on the trip route.")
    if boarding_type == BoardingRecord.Type.ROADSIDE and boarding_stop is None:
        raise ValidationError("Roadside boarding requires a route stop.")
    record = BoardingRecord(
        organization=organization,
        trip=trip,
        ticket=ticket,
        passenger=ticket.passenger,
        boarding_type=boarding_type,
        method=method,
        status=BoardingRecord.Status.VALIDATED,
        boarding_stop=boarding_stop,
        validated_at=timezone.now(),
        validated_by=actor,
        identity_confirmed=identity_confirmed,
        notes=notes,
        offline=offline,
        client_event_id=client_event_id,
        latitude=latitude,
        longitude=longitude,
    )
    try:
        record.save()
    except IntegrityError as exc:
        raise ValidationError("Passenger or ticket was already validated.") from exc
    ticket.status = Ticket.Status.VALIDATED
    ticket.save(update_fields=["status", "updated_at"])
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action="boarding.validated",
        resource_type="boarding_record",
        resource_id=record.id,
        after={
            "trip_id": trip.id,
            "ticket_id": ticket.id,
            "passenger_id": ticket.passenger_id,
            "method": method,
            "offline": offline,
        },
    )
    return record


@transaction.atomic
def board_passenger(*, record, actor, notes=""):
    record = (
        BoardingRecord.objects.select_for_update()
        .select_related("ticket", "trip", "organization")
        .get(pk=record.pk)
    )
    if record.status != BoardingRecord.Status.VALIDATED:
        raise ValidationError("Only a validated passenger can be boarded.")
    if record.trip.status not in (
        Trip.Status.BOARDING,
        Trip.Status.DEPARTED,
        Trip.Status.IN_PROGRESS,
        Trip.Status.DELAYED,
    ):
        raise ValidationError("Trip is not open for boarding.")
    if record.ticket.status != Ticket.Status.VALIDATED:
        raise ValidationError("Ticket validation state is inconsistent.")
    record.status = BoardingRecord.Status.BOARDED
    record.boarded_at = timezone.now()
    record.boarded_by = actor
    if notes:
        record.notes = notes
    record.save(
        update_fields=[
            "status", "boarded_at", "boarded_by", "notes", "updated_at"
        ]
    )
    record.ticket.status = Ticket.Status.BOARDED
    record.ticket.save(update_fields=["status", "updated_at"])
    record_audit_event(
        actor=actor,
        tenant_id=record.organization.tenant_id,
        organization_id=record.organization_id,
        action="boarding.passenger_boarded",
        resource_type="boarding_record",
        resource_id=record.id,
        after={
            "trip_id": record.trip_id,
            "ticket_id": record.ticket_id,
            "passenger_id": record.passenger_id,
            "boarded_at": record.boarded_at,
        },
    )
    return record

