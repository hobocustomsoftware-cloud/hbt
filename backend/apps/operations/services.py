from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Q, Sum
from django.utils import timezone

from apps.audit.services import json_safe, record_audit_event
from apps.boarding.models import BoardingRecord
from apps.cargo.models import CargoShipment
from apps.fleet.models import Vehicle
from apps.payments.models import PaymentRecord
from apps.scheduling.models import Trip
from apps.ticketing.models import Ticket
from apps.workforce.models import ConductorProfile, DriverProfile

from .models import CashSettlement, PrintAttempt, PrintDocument, TripClosing


@transaction.atomic
def close_trip(*, trip, actor, notes=""):
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    if trip.status != Trip.Status.ARRIVED:
        raise ValidationError("Only an arrived trip can be closed.")
    unresolved_cargo = trip.cargo_shipments.exclude(
        status__in=[
            CargoShipment.Status.ARRIVED,
            CargoShipment.Status.READY_FOR_PICKUP,
            CargoShipment.Status.HANDED_OVER,
        ]
    ).count()
    unresolved_boarding = trip.boarding_records.filter(
        status=BoardingRecord.Status.VALIDATED
    ).count()
    if unresolved_cargo or unresolved_boarding:
        raise ValidationError("Trip has unresolved boarding or cargo records.")
    passenger_count = trip.tickets.exclude(
        status=Ticket.Status.CANCELLED
    ).count()
    boarded_count = trip.boarding_records.filter(
        status=BoardingRecord.Status.BOARDED
    ).count()
    cargo_count = trip.cargo_shipments.count()
    handed = trip.cargo_shipments.filter(
        status=CargoShipment.Status.HANDED_OVER
    ).count()
    snapshot = {
        "trip_number": trip.trip_number,
        "planned_departure_at": trip.planned_departure_at,
        "departed_at": trip.departed_at,
        "arrived_at": trip.arrived_at,
        "passenger_count": passenger_count,
        "boarded_count": boarded_count,
        "cargo_count": cargo_count,
        "cargo_handed_over_count": handed,
        "operational_event_count": trip.operational_events.count(),
    }
    closing = TripClosing.objects.create(
        organization=trip.organization,
        trip=trip,
        passenger_count=passenger_count,
        boarded_count=boarded_count,
        cargo_count=cargo_count,
        cargo_handed_over_count=handed,
        unresolved_exception_count=0,
        summary_snapshot=json_safe(snapshot),
        closed_by=actor,
        closed_at=timezone.now(),
        notes=notes,
    )
    trip.status = Trip.Status.CLOSED
    trip.save(update_fields=["status", "updated_at"])
    if trip.vehicle_id:
        trip.vehicle.status = Vehicle.Status.AVAILABLE
        trip.vehicle.save(update_fields=["status", "updated_at"])
    if trip.driver_id:
        trip.driver.availability = DriverProfile.Availability.AVAILABLE
        trip.driver.save(update_fields=["availability", "updated_at"])
    if trip.conductor_id:
        trip.conductor.availability = ConductorProfile.Availability.AVAILABLE
        trip.conductor.save(update_fields=["availability", "updated_at"])
    _audit(trip, actor, "trip.closed", {"closing_id": closing.id})
    return closing


@transaction.atomic
def create_settlement(
    *, trip, actor, settlement_number, actual_amount,
    difference_reason="", notes=""
):
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    if trip.status != Trip.Status.CLOSED or not hasattr(trip, "closing"):
        raise ValidationError("Trip must be operationally closed first.")
    payments = PaymentRecord.objects.filter(
        organization=trip.organization,
        status=PaymentRecord.Status.CONFIRMED,
        method=PaymentRecord.Method.CASH,
    ).filter(
        Q(booking__trip=trip) | Q(cargo_shipment__assigned_trip=trip)
    )
    expected = payments.aggregate(total=Sum("amount"))["total"] or Decimal("0")
    difference = actual_amount - expected
    if difference and not difference_reason.strip():
        raise ValidationError("Cash difference requires a reason.")
    settlement = CashSettlement.objects.create(
        organization=trip.organization,
        trip=trip,
        settlement_number=settlement_number,
        expected_amount=expected,
        actual_amount=actual_amount,
        difference_amount=difference,
        difference_reason=difference_reason,
        submitted_by=actor,
        notes=notes,
    )
    _audit(trip, actor, "settlement.created", {
        "settlement_id": settlement.id,
        "expected": expected,
        "actual": actual_amount,
        "difference": difference,
    })
    return settlement


def create_print_document(
    *, organization, actor, document_type, resource_type, resource_id,
    client_request_id=None
):
    if client_request_id:
        existing = PrintDocument.objects.filter(
            client_request_id=client_request_id
        ).first()
        if existing:
            return existing
    if resource_type == "cargo_shipment":
        resource = CargoShipment.objects.select_related(
            "sender", "receiver", "origin_terminal", "destination_terminal"
        ).get(pk=resource_id, organization=organization)
        payload = {
            "reference": resource.shipment_number,
            "qr": f"HBT:CARGO:{resource.tracking_code}",
            "sender": resource.sender.name,
            "sender_phone": resource.sender.phone_number,
            "receiver": resource.receiver.name,
            "receiver_phone": resource.receiver.phone_number,
            "origin": resource.origin_terminal.display_name,
            "destination": resource.destination_terminal.display_name,
            "pieces": resource.piece_count,
            "weight_kg": resource.weight_kg,
            "total_charge": resource.total_charge,
            "currency": resource.currency,
        }
    elif resource_type == "ticket":
        resource = Ticket.objects.select_related(
            "passenger", "trip", "booking_passenger__seat_reservation"
        ).get(pk=resource_id, organization=organization)
        payload = {
            "reference": resource.ticket_number,
            "qr": f"HBT:TICKET:{resource.validation_code}",
            "passenger": resource.passenger.full_name,
            "trip": resource.trip.trip_number,
            "departure": resource.trip.planned_departure_at,
            "seat": resource.booking_passenger.seat_reservation.seat_identifier_snapshot,
        }
    else:
        raise ValidationError("Unsupported print resource type.")
    document = PrintDocument.objects.create(
        organization=organization,
        document_type=document_type,
        resource_type=resource_type,
        resource_id=resource.id,
        payload=json_safe(payload),
        created_by=actor,
        client_request_id=client_request_id,
    )
    return document


@transaction.atomic
def advance_settlement(*, settlement, actor, action, reason=""):
    settlement = CashSettlement.objects.select_for_update().get(pk=settlement.pk)
    transitions = {
        "verify": (CashSettlement.Status.PENDING, CashSettlement.Status.VERIFIED),
        "approve": (CashSettlement.Status.VERIFIED, CashSettlement.Status.APPROVED),
        "close": (CashSettlement.Status.APPROVED, CashSettlement.Status.CLOSED),
        "reject": (
            (CashSettlement.Status.PENDING, CashSettlement.Status.VERIFIED),
            CashSettlement.Status.REJECTED,
        ),
    }
    expected, target = transitions[action]
    sources = expected if isinstance(expected, tuple) else (expected,)
    if settlement.status not in sources:
        raise ValidationError("Invalid settlement state transition.")
    if action == "reject" and not reason.strip():
        raise ValidationError("Rejection requires a reason.")
    settlement.status = target
    if action == "verify":
        settlement.verified_by = actor
    elif action == "approve":
        settlement.approved_by = actor
    settlement.save()
    _audit(settlement.trip, actor, f"settlement.{target}", {
        "settlement_id": settlement.id, "status": target, "reason": reason
    })
    return settlement


@transaction.atomic
def acknowledge_print(
    *,
    document,
    actor,
    client_attempt_id,
    status,
    occurred_at,
    printer_profile=None,
    device_installation_id=None,
    offline=False,
    failure_reason="",
):
    document = PrintDocument.objects.select_for_update().get(pk=document.pk)
    existing = PrintAttempt.objects.filter(
        client_attempt_id=client_attempt_id
    ).first()
    if existing:
        if existing.document_id != document.id:
            raise ValidationError("Client print attempt ID is already in use.")
        replay_matches = (
            existing.status == status
            and existing.occurred_at == occurred_at
            and existing.printer_profile_id
            == getattr(printer_profile, "id", None)
            and existing.device_installation_id == device_installation_id
            and existing.offline == offline
            and existing.failure_reason == failure_reason
        )
        if not replay_matches:
            raise ValidationError(
                "Client print attempt replay payload does not match."
            )
        return existing
    attempt = PrintAttempt.objects.create(
        organization=document.organization,
        document=document,
        printer_profile=printer_profile,
        device_installation_id=device_installation_id,
        client_attempt_id=client_attempt_id,
        status=status,
        offline=offline,
        failure_reason=failure_reason,
        printed_by=actor,
        occurred_at=occurred_at,
    )
    if status == PrintAttempt.Status.PRINTED:
        document.print_count += 1
        document.last_printed_at = occurred_at
        document.save(
            update_fields=["print_count", "last_printed_at", "updated_at"]
        )
    record_audit_event(
        actor=actor,
        tenant_id=document.organization.tenant_id,
        organization_id=document.organization_id,
        action=f"print.{status}",
        resource_type=document.resource_type,
        resource_id=document.resource_id,
        after={
            "document_id": document.id,
            "print_count": document.print_count,
            "attempt_id": attempt.id,
            "offline": offline,
            "failure_reason": failure_reason,
        },
    )
    return attempt


def _audit(trip, actor, action, after):
    record_audit_event(
        actor=actor,
        tenant_id=trip.organization.tenant_id,
        organization_id=trip.organization_id,
        action=action,
        resource_type="trip",
        resource_id=trip.id,
        after=after,
    )
