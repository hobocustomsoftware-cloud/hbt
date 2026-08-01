from datetime import timedelta

from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from apps.bookings.models import SeatLock
from apps.bookings.seat_lock_services import (
    acquire_seat_lock,
    extend_seat_lock,
    release_seat_lock,
    sweep_expired_seat_locks,
)
from apps.bookings.services import create_booking
from apps.fleet.models import LayoutPosition, SeatLayout
from apps.identity.models import User
from apps.locations.models import OperationalStatus, PhysicalTerminal
from apps.network.models import Route, RouteStop
from apps.passengers.models import Passenger
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization, Tenant


class SeatLockProtocolTests(TestCase):
    """Verifies the seat lock protocol: acquire, conflict, release, TTL."""

    def setUp(self):
        tenant = Tenant.objects.create(name="Lock Tenant", slug="lock-tenant")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Lock Company",
            display_name="Lock Company",
            status=Organization.Status.ACTIVE,
        )
        self.user_a = User.objects.create_user(
            phone_number="+959700000001", password="Strong-pass-123"
        )
        self.user_b = User.objects.create_user(
            phone_number="+959700000002", password="Strong-pass-123"
        )
        terminal = PhysicalTerminal.objects.create(
            code="lock-terminal",
            name="Lock Terminal",
            status=OperationalStatus.ACTIVE,
        )
        self.route = Route.objects.create(
            organization=self.organization,
            code="lock-route",
            name="Lock Route",
            status=Route.Status.ACTIVE,
        )
        self.origin = RouteStop.objects.create(
            route=self.route,
            terminal=terminal,
            code="lock-origin",
            name="Origin",
            sequence=1,
            stop_type=RouteStop.Type.TERMINAL,
            status=RouteStop.Status.ACTIVE,
        )
        self.destination = RouteStop.objects.create(
            route=self.route,
            code="lock-destination",
            name="Destination",
            sequence=2,
            stop_type=RouteStop.Type.MAJOR,
            status=RouteStop.Status.ACTIVE,
        )
        self.layout = SeatLayout.objects.create(
            organization=self.organization,
            code="lock-layout",
            name="Lock Layout",
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
            trip_number="LOCK-TRIP-1",
            service_date=departure.date(),
            planned_departure_at=departure,
            planned_arrival_at=departure + timedelta(hours=8),
            seat_layout=self.layout,
            seat_layout_snapshot={"id": str(self.layout.id), "version": 1},
        )
        self.passenger_a = Passenger.objects.create(
            organization=self.organization,
            passenger_code="L-P-1",
            full_name="Lock Passenger One",
        )
        self.passenger_a.set_nrc("12/ကမရ(နိုင်)123456")
        self.passenger_a.save()
        self.passenger_b = Passenger.objects.create(
            organization=self.organization,
            passenger_code="L-P-2",
            full_name="Lock Passenger Two",
        )
        self.passenger_b.set_nrc("12/ကမရ(နိုင်)123457")
        self.passenger_b.save()

    def test_acquire_then_conflict_for_second_user(self):
        lock, conflict = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
        )
        self.assertIsNotNone(lock)
        self.assertIsNone(conflict)
        self.assertEqual(lock.status, SeatLock.Status.HELD)

        # Second user cannot acquire the same seat.
        other, conflict = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_b,
        )
        self.assertIsNone(other)
        self.assertEqual(conflict, "seat_already_locked")

    def test_idempotent_acquire_returns_existing_lock(self):
        lock, _ = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
            idempotency_key="lock-1",
        )
        again, conflict = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
            idempotency_key="lock-1",
        )
        self.assertIsNone(conflict)
        self.assertEqual(again.id, lock.id)

    def test_release_frees_seat_for_another_user(self):
        lock, _ = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
        )
        release_seat_lock(lock=lock, actor=self.user_a)

        other, conflict = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_b,
        )
        self.assertIsNone(conflict)
        self.assertIsNotNone(other)

    def test_sweep_expires_stale_locks(self):
        lock, _ = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
            ttl=timedelta(minutes=5),
        )
        SeatLock.objects.filter(pk=lock.pk).update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )
        expired = sweep_expired_seat_locks()
        self.assertEqual(expired, 1)

        # Seat is acquirable again after the sweep.
        other, conflict = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_b,
        )
        self.assertIsNone(conflict)
        self.assertIsNotNone(other)

    def test_extend_bumps_expiry(self):
        lock, _ = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
        )
        original = lock.expires_at
        extended, conflict = extend_seat_lock(lock=lock, actor=self.user_a)
        self.assertIsNone(conflict)
        self.assertGreater(extended.expires_at, original)

    def _create_booking(self, user, passenger, seat, number, contact):
        return create_booking(
            organization=self.organization,
            actor=user,
            trip=self.trip,
            booking_number=number,
            booking_type="individual",
            channel="counter",
            contact_name=contact,
            contact_phone="+959700000001",
            pickup_stop=self.origin,
            dropoff_stop=self.destination,
            passenger_seats=[
                {
                    "passenger": passenger,
                    "seat_position": seat,
                }
            ],
        )

    def test_booking_rejects_seat_locked_by_another_user(self):
        acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_b,
        )
        with self.assertRaises(ValidationError):
            self._create_booking(
                self.user_a, self.passenger_a, self.seat_a, "LOCK-BOOK-1", "Lock Passenger One"
            )

    def test_booking_succeeds_with_own_lock_and_consumes_it(self):
        lock, conflict = acquire_seat_lock(
            organization=self.organization,
            trip=self.trip,
            seat_position=self.seat_a,
            actor=self.user_a,
        )
        self.assertIsNone(conflict)
        booking = self._create_booking(
            self.user_a, self.passenger_a, self.seat_a, "LOCK-BOOK-2", "Lock Passenger One"
        )
        self.assertIsNotNone(booking)
        lock.refresh_from_db()
        self.assertEqual(lock.status, SeatLock.Status.CONSUMED)

    def test_booking_still_rejects_without_lock_when_seat_taken(self):
        # Create a booking for seat A without any lock protocol.
        self._create_booking(
            self.user_a, self.passenger_a, self.seat_a, "LOCK-BOOK-3", "Lock Passenger One"
        )
        # Second booking for the same seat must fail (reservation conflict).
        with self.assertRaises(ValidationError):
            self._create_booking(
                self.user_b, self.passenger_b, self.seat_a, "LOCK-BOOK-4", "Lock Passenger Two"
            )
