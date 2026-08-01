from datetime import datetime, timedelta

from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.fleet.models import LayoutPosition, Vehicle, VehicleLayoutAssignment
from apps.notifications.models import Notification
from apps.notifications.services import enqueue_event_after_commit
from apps.workforce.models import ConductorProfile, DriverProfile

from .models import (
    Schedule,
    Trip,
    TripAssignmentEvent,
    TripOperationalEvent,
)


def _aware(service_date, value, day_offset=0):
    naive = datetime.combine(service_date + timedelta(days=day_offset), value)
    return timezone.make_aware(naive, timezone.get_current_timezone())


def generate_trip(*, schedule, service_date, trip_number):
    if not schedule.operates_on(service_date):
        raise ValidationError("Schedule is not operational on this service date.")
    route = schedule.route
    return Trip.objects.create(
        organization=schedule.organization,
        schedule=schedule,
        route=route,
        trip_number=trip_number,
        service_date=service_date,
        planned_departure_at=_aware(
            service_date, schedule.planned_departure_time
        ),
        planned_arrival_at=_aware(
            service_date,
            schedule.planned_arrival_time,
            schedule.arrival_day_offset,
        ),
        schedule_snapshot={
            "id": str(schedule.id),
            "code": schedule.code,
            "name": schedule.name,
            "version": schedule.version,
            "operating_days": schedule.operating_days,
        },
        route_snapshot={
            "id": str(route.id),
            "code": route.code,
            "name": route.name,
            "stops": [
                {
                    "id": str(stop.id),
                    "code": stop.code,
                    "name": stop.name,
                    "sequence": stop.sequence,
                }
                for stop in route.stops.order_by("sequence")
            ],
        },
    )


def _ensure_assignable(trip):
    if trip.immutable:
        raise ValidationError("Completed, closed, or archived trips are immutable.")
    if trip.status not in (Trip.Status.PLANNED, Trip.Status.READY):
        raise ValidationError("Resources can only be assigned before boarding.")


def _conflicts(trip, field, resource):
    return (
        Trip.objects.filter(
            organization=trip.organization,
            planned_departure_at__lt=trip.planned_arrival_at,
            planned_arrival_at__gt=trip.planned_departure_at,
        )
        .exclude(pk=trip.pk)
        .exclude(status__in=[Trip.Status.CANCELLED, Trip.Status.ARCHIVED])
        .filter(**{field: resource})
        .exists()
    )


def _record(trip, resource_type, previous_id, resource, actor, reason):
    TripAssignmentEvent.objects.create(
        trip=trip,
        resource_type=resource_type,
        previous_resource_id=previous_id,
        resource_id=resource.id,
        assigned_by=actor,
        reason=reason,
    )
    record_audit_event(
        actor=actor,
        tenant_id=trip.organization.tenant_id,
        organization_id=trip.organization_id,
        action=f"trip.{resource_type}_assigned",
        resource_type="trip",
        resource_id=trip.id,
        reason=reason,
        before={f"{resource_type}_id": previous_id},
        after={f"{resource_type}_id": resource.id},
    )


@transaction.atomic
def assign_vehicle(*, trip, vehicle, actor, reason=""):
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    _ensure_assignable(trip)
    if vehicle.organization_id != trip.organization_id:
        raise ValidationError("Vehicle must belong to the trip organization.")
    if vehicle.status not in (Vehicle.Status.AVAILABLE, Vehicle.Status.RESERVED):
        raise ValidationError("Vehicle is not operationally available.")
    if _conflicts(trip, "vehicle", vehicle):
        raise ValidationError("Vehicle is assigned to an overlapping trip.")
    layout_assignment = (
        VehicleLayoutAssignment.objects.filter(
            vehicle=vehicle,
            effective_from__lte=trip.planned_departure_at,
        )
        .filter(
            Q(effective_until__isnull=True)
            | Q(effective_until__gt=trip.planned_departure_at)
        )
        .select_related("layout")
        .order_by("-effective_from")
        .first()
    )
    if layout_assignment is None:
        raise ValidationError("Vehicle has no effective approved seat layout.")
    layout = layout_assignment.layout
    positions = [
        {
            "id": str(position.id),
            "identifier": position.identifier,
            "position_type": position.position_type,
            "deck": position.deck,
            "row": position.row,
            "column": position.column,
            "label": position.label,
            "bookable": position.bookable,
        }
        for position in layout.positions.order_by("deck", "row", "column")
    ]
    previous_id = trip.vehicle_id
    trip.vehicle = vehicle
    trip.seat_layout = layout
    trip.seat_layout_snapshot = {
        "id": str(layout.id),
        "code": layout.code,
        "name": layout.name,
        "version": layout.version,
        "positions": positions,
    }
    trip.save(
        update_fields=[
            "vehicle", "seat_layout", "seat_layout_snapshot", "updated_at"
        ]
    )
    _record(
        trip,
        TripAssignmentEvent.ResourceType.VEHICLE,
        previous_id,
        vehicle,
        actor,
        reason,
    )
    return trip


@transaction.atomic
def assign_driver(*, trip, driver, actor, reason=""):
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    _ensure_assignable(trip)
    if driver.staff.organization_id != trip.organization_id:
        raise ValidationError("Driver must belong to the trip organization.")
    if not driver.operationally_eligible:
        raise ValidationError("Driver is not operationally eligible.")
    if (
        trip.vehicle_id
        and driver.authorized_vehicle_categories
        and trip.vehicle.category not in driver.authorized_vehicle_categories
    ):
        raise ValidationError("Driver is not authorized for this vehicle category.")
    if _conflicts(trip, "driver", driver):
        raise ValidationError("Driver is assigned to an overlapping trip.")
    previous_id = trip.driver_id
    trip.driver = driver
    trip.save(update_fields=["driver", "updated_at"])
    _record(
        trip,
        TripAssignmentEvent.ResourceType.DRIVER,
        previous_id,
        driver,
        actor,
        reason,
    )
    return trip


@transaction.atomic
def assign_conductor(*, trip, conductor, actor, reason=""):
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    _ensure_assignable(trip)
    if conductor.staff.organization_id != trip.organization_id:
        raise ValidationError("Conductor must belong to the trip organization.")
    if not conductor.operationally_eligible:
        raise ValidationError("Conductor is not operationally eligible.")
    if _conflicts(trip, "conductor", conductor):
        raise ValidationError("Conductor is assigned to an overlapping trip.")
    previous_id = trip.conductor_id
    trip.conductor = conductor
    trip.save(update_fields=["conductor", "updated_at"])
    _record(
        trip,
        TripAssignmentEvent.ResourceType.CONDUCTOR,
        previous_id,
        conductor,
        actor,
        reason,
    )
    return trip


TRANSITIONS = {
    TripOperationalEvent.Type.READY: (Trip.Status.PLANNED, Trip.Status.READY),
    TripOperationalEvent.Type.BOARDING_STARTED: (
        Trip.Status.READY,
        Trip.Status.BOARDING,
    ),
    TripOperationalEvent.Type.DEPARTED: (
        Trip.Status.BOARDING,
        Trip.Status.DEPARTED,
    ),
    TripOperationalEvent.Type.EN_ROUTE: (
        Trip.Status.DEPARTED,
        Trip.Status.IN_PROGRESS,
    ),
    TripOperationalEvent.Type.ARRIVED: (
        (Trip.Status.IN_PROGRESS, Trip.Status.DELAYED),
        Trip.Status.ARRIVED,
    ),
}


def _create_operational_event(
    *,
    trip,
    event_type,
    from_status,
    to_status,
    actor,
    occurred_at,
    notes,
    offline,
    client_event_id,
    route_stop=None,
    latitude=None,
    longitude=None,
):
    event = TripOperationalEvent.objects.create(
        trip=trip,
        event_type=event_type,
        from_status=from_status,
        to_status=to_status,
        route_stop=route_stop,
        occurred_at=occurred_at or timezone.now(),
        recorded_by=actor,
        notes=notes,
        offline=offline,
        client_event_id=client_event_id,
        latitude=latitude,
        longitude=longitude,
    )
    record_audit_event(
        actor=actor,
        tenant_id=trip.organization.tenant_id,
        organization_id=trip.organization_id,
        action=f"trip.{event_type}",
        resource_type="trip",
        resource_id=trip.id,
        reason=notes,
        before={"status": from_status},
        after={
            "status": to_status,
            "event_id": event.id,
            "occurred_at": event.occurred_at,
        },
        metadata={
            "offline": offline,
            "client_event_id": client_event_id,
            "route_stop_id": route_stop.id if route_stop else None,
        },
    )
    from apps.offline.services import record_sync_change

    record_sync_change(
        organization=trip.organization,
        resource_type="trip",
        resource_id=trip.id,
        operation="updated",
        payload={
            "id": trip.id,
            "trip_number": trip.trip_number,
            "status": to_status,
            "current_stop_id": trip.current_stop_id,
            "updated_at": trip.updated_at,
        },
    )
    passenger_ids = list(
        trip.bookings.filter(customer_account__isnull=False)
        .values_list("customer_account_id", flat=True)
        .distinct()
    )
    if passenger_ids and event_type in (
        TripOperationalEvent.Type.BOARDING_STARTED,
        TripOperationalEvent.Type.DEPARTED,
        TripOperationalEvent.Type.ARRIVED,
    ):
        labels = {
            TripOperationalEvent.Type.BOARDING_STARTED: (
                "ကားပေါ်တက်နိုင်ပါပြီ",
                "Boarding စတင်ပါပြီ။",
            ),
            TripOperationalEvent.Type.DEPARTED: (
                "ကားထွက်ခွာပါပြီ",
                "သင့်ခရီးစဉ် စတင်ထွက်ခွာပါပြီ။",
            ),
            TripOperationalEvent.Type.ARRIVED: (
                "ခရီးစဉ် ရောက်ရှိပါပြီ",
                "သင့်ခရီးစဉ် နောက်ဆုံးဂိတ်သို့ ရောက်ရှိပါပြီ။",
            ),
        }
        title, body = labels[event_type]
        enqueue_event_after_commit(
            event_type=f"trip.{event_type}",
            event_key=f"trip:{trip.id}:event:{event.id}",
            kind=Notification.Kind.TRIP,
            category=Notification.Category.TRIP_OPERATION,
            recipients=passenger_ids,
            organization=trip.organization,
            title=title,
            body=body,
            data={"trip_id": str(trip.id), "status": to_status},
            deep_link=f"hbt://trips/{trip.id}",
        )
    return event


@transaction.atomic
def transition_trip(
    *,
    trip,
    event_type,
    actor,
    occurred_at=None,
    notes="",
    offline=False,
    client_event_id=None,
    latitude=None,
    longitude=None,
):
    if client_event_id:
        existing = TripOperationalEvent.objects.filter(
            client_event_id=client_event_id
        ).select_related("trip").first()
        if existing:
            if existing.trip_id != trip.id or existing.event_type != event_type:
                raise ValidationError("Client event ID is already in use.")
            return existing.trip, existing
    trip = Trip.objects.select_for_update().get(pk=trip.pk)
    expected, target = TRANSITIONS[event_type]
    allowed_sources = expected if isinstance(expected, tuple) else (expected,)
    if trip.status not in allowed_sources:
        raise ValidationError(
            f"Cannot record {event_type} while trip is {trip.status}."
        )
    if event_type == TripOperationalEvent.Type.READY:
        if not trip.vehicle_id or not trip.driver_id:
            raise ValidationError("Ready requires an assigned vehicle and driver.")
        if trip.route.status != trip.route.Status.ACTIVE:
            raise ValidationError("Ready requires an active route.")
        trip.vehicle.status = Vehicle.Status.RESERVED
        trip.vehicle.save(update_fields=["status", "updated_at"])
        trip.driver.availability = DriverProfile.Availability.ASSIGNED
        trip.driver.save(update_fields=["availability", "updated_at"])
        if trip.conductor_id:
            trip.conductor.availability = ConductorProfile.Availability.ASSIGNED
            trip.conductor.save(update_fields=["availability", "updated_at"])
    elif event_type == TripOperationalEvent.Type.BOARDING_STARTED:
        trip.boarding_started_at = occurred_at or timezone.now()
    elif event_type == TripOperationalEvent.Type.DEPARTED:
        trip.departed_at = occurred_at or timezone.now()
        trip.vehicle.status = Vehicle.Status.IN_SERVICE
        trip.vehicle.save(update_fields=["status", "updated_at"])
        trip.driver.availability = DriverProfile.Availability.ON_DUTY
        trip.driver.save(update_fields=["availability", "updated_at"])
        if trip.conductor_id:
            trip.conductor.availability = ConductorProfile.Availability.ON_DUTY
            trip.conductor.save(update_fields=["availability", "updated_at"])
    elif event_type == TripOperationalEvent.Type.ARRIVED:
        trip.arrived_at = occurred_at or timezone.now()
        final_stop = trip.route.stops.order_by("-sequence").first()
        trip.current_stop = final_stop
    old_status = trip.status
    trip.status = target
    trip.save()
    event = _create_operational_event(
        trip=trip,
        event_type=event_type,
        from_status=old_status,
        to_status=target,
        actor=actor,
        occurred_at=occurred_at,
        notes=notes,
        offline=offline,
        client_event_id=client_event_id,
        latitude=latitude,
        longitude=longitude,
    )
    return trip, event


@transaction.atomic
def record_stop_reached(
    *,
    trip,
    route_stop,
    actor,
    occurred_at=None,
    notes="",
    offline=False,
    client_event_id=None,
    latitude=None,
    longitude=None,
):
    if client_event_id:
        existing = TripOperationalEvent.objects.filter(
            client_event_id=client_event_id
        ).select_related("trip").first()
        if existing:
            if (
                existing.trip_id != trip.id
                or existing.event_type != TripOperationalEvent.Type.STOP_REACHED
                or existing.route_stop_id != route_stop.id
            ):
                raise ValidationError("Client event ID is already in use.")
            return existing.trip, existing
    trip = Trip.objects.select_for_update().select_related("route").get(pk=trip.pk)
    if trip.status not in (Trip.Status.IN_PROGRESS, Trip.Status.DELAYED):
        raise ValidationError("Stops can only be reached by an active trip.")
    if route_stop.route_id != trip.route_id:
        raise ValidationError("Stop must belong to the trip route.")
    if trip.current_stop_id and route_stop.sequence <= trip.current_stop.sequence:
        raise ValidationError("Trip stops cannot move backward or be duplicated.")
    old_status = trip.status
    trip.current_stop = route_stop
    trip.save(update_fields=["current_stop", "updated_at"])
    event = _create_operational_event(
        trip=trip,
        event_type=TripOperationalEvent.Type.STOP_REACHED,
        from_status=old_status,
        to_status=old_status,
        actor=actor,
        occurred_at=occurred_at,
        notes=notes,
        offline=offline,
        client_event_id=client_event_id,
        route_stop=route_stop,
        latitude=latitude,
        longitude=longitude,
    )
    return trip, event
