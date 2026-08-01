"""Seat lock protocol services.

A seat lock is a short-lived hold on a seat for a trip, acquired before a
booking is created (counter selection or passenger self-service). It
prevents two operators/passengers from both selecting the same seat while
one of them is mid-booking.

Protocol (matches the Flutter `SeatLockController` contract):
- Acquire:  POST   /organizations/{org}/seat-lock/         {trip_id, seat_position, idempotency_key}
- Release:  DELETE /organizations/{org}/seat-lock/{id}/
- Extend:   POST   /organizations/{org}/seat-lock/{id}/extend/
- List:     GET    /organizations/{org}/seat-locks/?trip_id=...

TTL: 5 minutes by default. Expired locks are swept on every acquire and
via the `sweep_expired_seat_locks` management command.
"""

from datetime import timedelta

from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.audit.services import record_audit_event

from .models import SeatLock, SeatReservation

DEFAULT_TTL = timedelta(seconds=SeatLock.DEFAULT_TTL_SECONDS)


def sweep_expired_seat_locks(*, now=None):
    """Expire all HELD locks past their TTL. Returns the count expired."""
    now = now or timezone.now()
    expired = SeatLock.objects.filter(
        status=SeatLock.Status.HELD, expires_at__lte=now
    )
    count = expired.count()
    expired.update(status=SeatLock.Status.EXPIRED, released_at=now)
    return count


def _serialize_lock(lock):
    return {
        "id": lock.id,
        "trip_id": lock.trip_id,
        "seat_position": lock.seat_position_id,
        "seat_identifier": lock.seat_position.identifier,
        "held_by_user_id": lock.held_by_user_id,
        "held_by_device_id": lock.held_by_device_id or None,
        "held_at": lock.created_at.isoformat(),
        "expires_at": lock.expires_at.isoformat(),
        "status": lock.status,
    }


def active_locks_for_trip(*, organization, trip, actor=None):
    """Active HELD locks for a trip, newest first."""
    sweep_expired_seat_locks()
    qs = SeatLock.objects.filter(
        organization=organization,
        trip=trip,
        status=SeatLock.Status.HELD,
    ).select_related("seat_position")
    return list(qs.order_by("-created_at"))


def seat_payload(seat, occupied_ids, locks_by_seat):
    """Seat dict for availability responses, including active lock info.

    `seat` is a LayoutPosition, `occupied_ids` a set of seat UUID strings,
    `locks_by_seat` a dict mapping seat UUID string -> SeatLock.
    """
    lock = locks_by_seat.get(str(seat.id))
    return {
        "id": seat.id,
        "identifier": seat.identifier,
        "label": seat.label,
        "deck": seat.deck,
        "row": seat.row,
        "column": seat.column,
        "available": str(seat.id) not in occupied_ids,
        "active_lock": (
            {
                "id": lock.id,
                "trip_id": lock.trip_id,
                "seat_position": lock.seat_position.identifier,
                "seat_position_id": lock.seat_position_id,
                "held_by_user_id": lock.held_by_user_id,
                "held_by_device_id": lock.held_by_device_id or None,
                "held_at": lock.created_at.isoformat(),
                "expires_at": lock.expires_at.isoformat(),
                "status": lock.status,
            }
            if lock is not None
            else None
        ),
    }


def _seat_is_committed(*, trip, seat_position, pickup_sequence=None, dropoff_sequence=None):
    """Whether the seat is already reserved/confirmed for the trip segment."""
    qs = SeatReservation.objects.filter(
        trip=trip,
        seat_position=seat_position,
        status__in=[
            SeatReservation.Status.HELD,
            SeatReservation.Status.RESERVED,
            SeatReservation.Status.CONFIRMED,
        ],
    )
    if pickup_sequence is not None and dropoff_sequence is not None:
        qs = qs.filter(
            pickup_sequence__lt=dropoff_sequence,
            dropoff_sequence__gt=pickup_sequence,
        )
    return qs.exists()


@transaction.atomic
def acquire_seat_lock(
    *,
    organization,
    trip,
    seat_position,
    actor=None,
    held_by_device_id="",
    idempotency_key=None,
    ttl=DEFAULT_TTL,
):
    """Acquire a hold on a seat.

    Returns a tuple (lock_or_None, conflict_code_or_None).
    Conflict codes: "seat_booked" (already reserved), "seat_already_locked"
    (held by someone else), or "seat_invalid".
    """
    sweep_expired_seat_locks()

    if (
        trip.organization_id != organization.id
        or seat_position.layout_id != trip.seat_layout_id
        or not seat_position.bookable
    ):
        return None, "seat_invalid"

    if _seat_is_committed(trip=trip, seat_position=seat_position):
        return None, "seat_booked"

    # Idempotency: same client retrying the same acquire returns the hold.
    if idempotency_key:
        existing = SeatLock.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            if existing.status == SeatLock.Status.HELD and existing.is_active:
                return existing, None
            if existing.status == SeatLock.Status.CONSUMED:
                # Booking already created for this hold — seat is taken.
                return None, "seat_booked"

    # Conflict: someone else actively holds this seat.
    conflicting = SeatLock.objects.filter(
        trip=trip,
        seat_position=seat_position,
        status=SeatLock.Status.HELD,
    ).select_for_update()
    if conflicting.exists():
        holder = conflicting.first()
        # Own lock (same user or same device) can be re-acquired.
        if actor is not None and holder.held_by_user_id == actor.id:
            return holder, None
        if (
            held_by_device_id
            and holder.held_by_device_id == held_by_device_id
        ):
            return holder, None
        return None, "seat_already_locked"

    lock = SeatLock(
        organization=organization,
        trip=trip,
        seat_position=seat_position,
        held_by_user=actor,
        held_by_device_id=held_by_device_id or "",
        idempotency_key=idempotency_key or _generate_idempotency_key(trip, seat_position, actor, held_by_device_id),
        status=SeatLock.Status.HELD,
        expires_at=timezone.now() + ttl,
    )
    try:
        lock.full_clean()
        lock.save()
    except IntegrityError:
        return None, "seat_already_locked"
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action="seat_lock.acquired",
        resource_type="seat_lock",
        resource_id=lock.id,
        after={
            "trip_id": trip.id,
            "seat": seat_position.identifier,
        },
    )
    return lock, None


def _generate_idempotency_key(trip, seat_position, actor, held_by_device_id):
    actor_part = actor.id if actor is not None else held_by_device_id or "anon"
    return f"lock_{trip.id}_{seat_position.id}_{actor_part}"


@transaction.atomic
def release_seat_lock(*, lock, actor=None):
    """Release a held lock (best-effort by design)."""
    if lock.status != SeatLock.Status.HELD:
        return lock
    lock.status = SeatLock.Status.RELEASED
    lock.released_at = timezone.now()
    lock.save(update_fields=["status", "released_at", "updated_at"])
    record_audit_event(
        actor=actor,
        tenant_id=lock.organization.tenant_id,
        organization_id=lock.organization_id,
        action="seat_lock.released",
        resource_type="seat_lock",
        resource_id=lock.id,
    )
    return lock


@transaction.atomic
def extend_seat_lock(*, lock, actor=None, ttl=DEFAULT_TTL):
    """Extend a held lock's TTL. Returns (lock, error_code_or_None)."""
    if lock.status != SeatLock.Status.HELD:
        return lock, "lock_expired"
    if lock.expires_at <= timezone.now():
        lock.status = SeatLock.Status.EXPIRED
        lock.released_at = timezone.now()
        lock.save(update_fields=["status", "released_at", "updated_at"])
        return lock, "lock_expired"
    lock.expires_at = timezone.now() + ttl
    lock.save(update_fields=["expires_at", "updated_at"])
    return lock, None


@transaction.atomic
def consume_locks_for_booking(*, booking, actor=None):
    """Mark locks consumed once a booking has been created for the seats.

    Called from create_booking after the reservation conflict check passes,
    inside the same transaction. Any active HELD lock on the booked seats
    held by this actor is consumed; locks held by *others* were already
    rejected by the conflict check.
    """
    seat_ids = list(
        booking.passenger_items.values_list(
            "seat_reservation__seat_position_id", flat=True
        )
    )
    qs = SeatLock.objects.filter(
        trip=booking.trip,
        seat_position_id__in=seat_ids,
        status=SeatLock.Status.HELD,
    )
    if actor is not None:
        qs = qs.filter(held_by_user=actor)
    consumed = list(qs)
    now = timezone.now()
    for lock in consumed:
        lock.status = SeatLock.Status.CONSUMED
        lock.released_at = now
        lock.save(update_fields=["status", "released_at", "updated_at"])
    return consumed
