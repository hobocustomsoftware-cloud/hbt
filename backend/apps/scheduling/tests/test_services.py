from datetime import date, datetime, time, timedelta

from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from apps.fleet.models import (
    LayoutPosition,
    SeatLayout,
    Vehicle,
    VehicleLayoutAssignment,
)
from apps.identity.models import User
from apps.locations.models import Branch, OperationalStatus, PhysicalTerminal
from apps.network.models import Route, RouteStop
from apps.tenancy.models import Membership, Organization, Tenant
from apps.workforce.models import (
    ConductorProfile,
    DriverProfile,
    StaffProfile,
)

from ..models import Schedule, Trip, TripAssignmentEvent
from ..services import (
    assign_conductor,
    assign_driver,
    assign_vehicle,
    generate_trip,
    record_stop_reached,
    transition_trip,
)
from ..models import TripOperationalEvent


class SchedulingServiceTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(name="Tenant", slug="tenant")
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Company Limited",
            display_name="Company",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959111111111", password="Strong-pass-123"
        )
        self.membership = Membership.objects.create(
            user=self.user,
            organization=self.organization,
            status=Membership.Status.ACTIVE,
        )
        self.branch = Branch.objects.create(
            organization=self.organization,
            code="yangon",
            name="Yangon",
            status=OperationalStatus.ACTIVE,
        )
        self.terminal = PhysicalTerminal.objects.create(
            code="aung-mingalar",
            name="Aung Mingalar",
            status=OperationalStatus.ACTIVE,
            city="Yangon",
        )
        self.route = Route.objects.create(
            organization=self.organization,
            code="ygn-mdl",
            name="Yangon to Mandalay",
            status=Route.Status.ACTIVE,
        )
        self.origin_stop = RouteStop.objects.create(
            route=self.route,
            terminal=self.terminal,
            code="ygn",
            name="Yangon",
            sequence=1,
            stop_type=RouteStop.Type.TERMINAL,
            status=RouteStop.Status.ACTIVE,
        )
        self.destination_stop = RouteStop.objects.create(
            route=self.route,
            terminal=self.terminal,
            code="mdl",
            name="Mandalay",
            sequence=2,
            stop_type=RouteStop.Type.TERMINAL,
            status=RouteStop.Status.ACTIVE,
        )
        service_date = timezone.localdate() + timedelta(days=7)
        while service_date.weekday() != 0:
            service_date += timedelta(days=1)
        self.service_date = service_date
        self.schedule = Schedule.objects.create(
            organization=self.organization,
            route=self.route,
            code="morning",
            name="Morning Express",
            planned_departure_time=time(8),
            planned_arrival_time=time(18),
            operating_days=[0],
            effective_from=service_date,
            status=Schedule.Status.OPERATIONAL,
        )
        self.trip = generate_trip(
            schedule=self.schedule,
            service_date=service_date,
            trip_number="TRIP-001",
        )
        self.vehicle = Vehicle.objects.create(
            organization=self.organization,
            branch=self.branch,
            code="bus-1",
            registration_number="9N-1000",
            category=Vehicle.Category.EXPRESS_BUS,
            passenger_capacity=1,
            status=Vehicle.Status.AVAILABLE,
        )
        self.layout = SeatLayout.objects.create(
            organization=self.organization,
            code="one-seat",
            name="One Seat",
            layout_type=SeatLayout.Type.CUSTOM,
            status=SeatLayout.Status.APPROVED,
            row_count=1,
            column_count=1,
        )
        LayoutPosition.objects.create(
            layout=self.layout,
            identifier="1A",
            position_type=LayoutPosition.Type.STANDARD,
            row=1,
            column=1,
            bookable=True,
        )
        VehicleLayoutAssignment.objects.create(
            vehicle=self.vehicle,
            layout=self.layout,
            effective_from=self.trip.planned_departure_at - timedelta(days=1),
            assigned_by=self.user,
        )
        self.staff = StaffProfile.objects.create(
            membership=self.membership,
            branch=self.branch,
            employee_code="EMP-1",
            status=StaffProfile.Status.ACTIVE,
        )
        self.driver = DriverProfile.objects.create(
            staff=self.staff,
            driver_code="DRV-1",
            license_number="LIC-1",
            license_class="E",
            license_expiry=self.service_date + timedelta(days=365),
            availability=DriverProfile.Availability.AVAILABLE,
            qualifications_verified_at=timezone.now(),
        )

    def test_generated_trip_preserves_schedule_and_route_snapshot(self):
        self.assertEqual(self.trip.schedule_snapshot["version"], 1)
        self.assertEqual(self.trip.route_snapshot["code"], "ygn-mdl")
        self.assertEqual(self.trip.route_snapshot["stops"][0]["code"], "ygn")

    def test_assigns_vehicle_and_driver_with_auditable_history(self):
        assign_vehicle(trip=self.trip, vehicle=self.vehicle, actor=self.user)
        assign_driver(trip=self.trip, driver=self.driver, actor=self.user)
        self.trip.refresh_from_db()
        self.assertEqual(self.trip.vehicle, self.vehicle)
        self.assertEqual(self.trip.driver, self.driver)
        self.assertEqual(self.trip.seat_layout_snapshot["version"], 1)
        self.assertEqual(self.trip.assignment_events.count(), 2)

    def test_rejects_vehicle_overlap(self):
        assign_vehicle(trip=self.trip, vehicle=self.vehicle, actor=self.user)
        other = Trip.objects.create(
            organization=self.organization,
            route=self.route,
            trip_number="TRIP-002",
            service_date=self.service_date,
            planned_departure_at=self.trip.planned_departure_at
            + timedelta(hours=1),
            planned_arrival_at=self.trip.planned_arrival_at + timedelta(hours=1),
        )
        with self.assertRaisesMessage(
            ValidationError, "overlapping trip"
        ):
            assign_vehicle(trip=other, vehicle=self.vehicle, actor=self.user)

    def test_rejects_ineligible_driver(self):
        self.driver.license_expiry = timezone.localdate() - timedelta(days=1)
        self.driver.save(update_fields=["license_expiry"])
        with self.assertRaisesMessage(
            ValidationError, "not operationally eligible"
        ):
            assign_driver(trip=self.trip, driver=self.driver, actor=self.user)

    def test_conductor_is_optional_but_can_be_assigned(self):
        conductor_user = User.objects.create_user(
            phone_number="+959222222222", password="Strong-pass-123"
        )
        conductor_membership = Membership.objects.create(
            user=conductor_user,
            organization=self.organization,
            status=Membership.Status.ACTIVE,
        )
        staff = StaffProfile.objects.create(
            membership=conductor_membership,
            branch=self.branch,
            employee_code="EMP-2",
            status=StaffProfile.Status.ACTIVE,
        )
        conductor = ConductorProfile.objects.create(
            staff=staff,
            conductor_code="CON-1",
            availability=ConductorProfile.Availability.AVAILABLE,
            qualifications_verified_at=timezone.now(),
        )
        assign_conductor(
            trip=self.trip, conductor=conductor, actor=self.user
        )
        self.trip.refresh_from_db()
        self.assertEqual(self.trip.conductor, conductor)

    def prepare_trip(self):
        assign_vehicle(trip=self.trip, vehicle=self.vehicle, actor=self.user)
        assign_driver(trip=self.trip, driver=self.driver, actor=self.user)

    def test_ready_to_arrival_lifecycle_is_auditable(self):
        self.prepare_trip()
        for event_type in (
            TripOperationalEvent.Type.READY,
            TripOperationalEvent.Type.BOARDING_STARTED,
            TripOperationalEvent.Type.DEPARTED,
            TripOperationalEvent.Type.EN_ROUTE,
        ):
            self.trip, _ = transition_trip(
                trip=self.trip, event_type=event_type, actor=self.user
            )
        self.trip, _ = record_stop_reached(
            trip=self.trip,
            route_stop=self.origin_stop,
            actor=self.user,
        )
        self.trip, _ = record_stop_reached(
            trip=self.trip,
            route_stop=self.destination_stop,
            actor=self.user,
        )
        self.trip, _ = transition_trip(
            trip=self.trip,
            event_type=TripOperationalEvent.Type.ARRIVED,
            actor=self.user,
        )
        self.trip.refresh_from_db()
        self.assertEqual(self.trip.status, Trip.Status.ARRIVED)
        self.assertIsNotNone(self.trip.boarding_started_at)
        self.assertIsNotNone(self.trip.departed_at)
        self.assertIsNotNone(self.trip.arrived_at)
        self.assertEqual(self.trip.operational_events.count(), 7)

    def test_ready_requires_vehicle_and_driver(self):
        with self.assertRaisesMessage(
            ValidationError, "assigned vehicle and driver"
        ):
            transition_trip(
                trip=self.trip,
                event_type=TripOperationalEvent.Type.READY,
                actor=self.user,
            )

    def test_invalid_transition_is_rejected(self):
        self.prepare_trip()
        with self.assertRaisesMessage(ValidationError, "Cannot record departed"):
            transition_trip(
                trip=self.trip,
                event_type=TripOperationalEvent.Type.DEPARTED,
                actor=self.user,
            )

    def test_offline_client_event_is_idempotent(self):
        self.prepare_trip()
        event_id = "0f22fc16-20ec-4475-a8c9-665f7ec29a33"
        trip, first = transition_trip(
            trip=self.trip,
            event_type=TripOperationalEvent.Type.READY,
            actor=self.user,
            offline=True,
            client_event_id=event_id,
        )
        repeated_trip, repeated = transition_trip(
            trip=trip,
            event_type=TripOperationalEvent.Type.READY,
            actor=self.user,
            offline=True,
            client_event_id=event_id,
        )
        self.assertEqual(first.id, repeated.id)
        self.assertEqual(repeated_trip.id, trip.id)
