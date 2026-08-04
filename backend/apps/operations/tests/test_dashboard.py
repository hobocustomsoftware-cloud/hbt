"""Owner dashboard endpoint tests.

Verifies the dashboard snapshot is built entirely from real model data:
money (ticket + cargo revenue), trip ops, cargo ops, bookings, cash &
pending refunds, fleet/people, revenue trend, rankings, and pulse.
No seeded/fake data is involved — every assertion maps to created rows.
"""

import uuid
from datetime import timedelta
from decimal import Decimal

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.bookings.models import Booking, BookingPassenger
from apps.cargo.models import CargoContact, CargoShipment
from apps.fleet.models import LayoutPosition, SeatLayout, Vehicle
from apps.identity.models import User
from apps.locations.models import Branch, CompanyTerminalOperation, PhysicalTerminal
from apps.network.models import Route, RouteStop
from apps.passengers.models import Passenger
from apps.payments.models import PaymentRecord, RefundRequest
from apps.scheduling.models import Schedule, Trip
from apps.tenancy.models import Membership, MembershipRole, Organization, Role, Tenant
from apps.ticketing.models import Ticket
from apps.workforce.models import StaffProfile


def _make_tenant_org():
    slug = f"dash-tenant-{uuid.uuid4().hex[:8]}"
    tenant = Tenant.objects.create(name="Dash Tenant", slug=slug)
    organization = Organization.objects.create(
        tenant=tenant,
        legal_name="Dash Express",
        display_name="Dash Express",
        status=Organization.Status.ACTIVE,
    )
    return tenant, organization


def _make_owner(tenant, organization):
    user = User.objects.create_user(
        phone_number="+959777700999", password="Strong-pass-123"
    )
    membership = Membership.objects.create(
        organization=organization,
        user=user,
        status=Membership.Status.ACTIVE,
    )
    MembershipRole.objects.create(
        membership=membership,
        role=Role.objects.get(tenant=None, code="company-owner"),
        scope_type=MembershipRole.ScopeType.COMPANY,
    )
    return user, membership


class OwnerDashboardEndpointTests(APITestCase):
    def setUp(self):
        self.tenant, self.organization = _make_tenant_org()
        self.user, self.membership = _make_owner(self.tenant, self.organization)
        self.client.force_authenticate(self.user)

        self.branch = Branch.objects.create(
            organization=self.organization,
            code="ygn",
            name="Yangon Central",
            status="active",
        )
        self.route = Route.objects.create(
            organization=self.organization,
            code="ygn-mdy",
            name="Yangon → Mandalay",
            status=Route.Status.ACTIVE,
        )
        self.pickup = RouteStop.objects.create(
            route=self.route,
            code="ygn-stop",
            name="Yangon Stop",
            sequence=1,
            stop_type=RouteStop.Type.PICKUP,
            status=RouteStop.Status.ACTIVE,
        )
        self.dropoff = RouteStop.objects.create(
            route=self.route,
            code="mdy-stop",
            name="Mandalay Stop",
            sequence=2,
            stop_type=RouteStop.Type.MAJOR,
            status=RouteStop.Status.ACTIVE,
        )
        self.vehicle = Vehicle.objects.create(
            organization=self.organization,
            branch=self.branch,
            code="bus-01",
            registration_number="YK 1234",
            category=Vehicle.Category.EXPRESS_BUS,
            status=Vehicle.Status.IN_SERVICE,
        )
        self.vehicle_maint = Vehicle.objects.create(
            organization=self.organization,
            branch=self.branch,
            code="bus-02",
            registration_number="YK 5678",
            category=Vehicle.Category.EXPRESS_BUS,
            status=Vehicle.Status.MAINTENANCE,
        )
        self.layout = SeatLayout.objects.create(
            organization=self.organization,
            code="dash-layout",
            name="Dashboard Layout",
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

        self.today = timezone.localdate()
        self.schedule = Schedule.objects.create(
            organization=self.organization,
            route=self.route,
            code="sched-1",
            name="Daily Express",
            planned_departure_time="06:00:00",
            planned_arrival_time="12:00:00",
            effective_from=self.today - timedelta(days=30),
            status=Schedule.Status.OPERATIONAL,
        )

    def _trip(self, status=Trip.Status.DEPARTED, service_date=None, vehicle=None):
        departure = timezone.now() - timedelta(hours=1)
        return Trip.objects.create(
            organization=self.organization,
            route=self.route,
            schedule=None,  # unique schedule+service_date constraint → one trip per schedule/day
            trip_number=f"TP-{uuid.uuid4().hex[:6].upper()}",
            service_date=service_date or self.today,
            planned_departure_at=departure,
            planned_arrival_at=departure + timedelta(hours=6),
            status=status,
            vehicle=vehicle or self.vehicle,
            seat_layout=self.layout,
            seat_layout_snapshot={"id": str(self.layout.id), "version": 1},
        )

    def _ticket(self, trip, amount=Decimal("10000.00"), status=Ticket.Status.ISSUED):
        passenger = Passenger.objects.create(
            organization=self.organization,
            passenger_code=f"P-{uuid.uuid4().hex[:6].upper()}",
            full_name="Test Passenger",
        )
        booking = Booking.objects.create(
            organization=self.organization,
            trip=trip,
            booking_number=f"BK-{uuid.uuid4().hex[:6].upper()}",
            booking_type=Booking.Type.INDIVIDUAL,
            channel=Booking.Channel.COUNTER,
            status=Booking.Status.CONFIRMED,
            contact_name="Buyer",
            contact_phone="+959111111111",
            pickup_stop=self.pickup,
            dropoff_stop=self.dropoff,
            created_by=self.user,
        )
        bp = BookingPassenger.objects.create(
            booking=booking, passenger=passenger
        )
        return Ticket.objects.create(
            organization=self.organization,
            booking=booking,
            booking_passenger=bp,
            passenger=passenger,
            trip=trip,
            seat_position=self.seat_a,
            ticket_number=f"TK-{uuid.uuid4().hex[:6].upper()}",
            total_amount=amount,
            fare_amount=amount,
            issuing_channel="counter",
            issued_by=self.user,
            status=status,
        )

    def _cargo(self, charge=Decimal("5000.00"), status=CargoShipment.Status.ACCEPTED):
        sender = CargoContact.objects.create(
            organization=self.organization,
            contact_code=f"SC-{uuid.uuid4().hex[:6]}",
            name="Sender",
            phone_number="+959700000001",
        )
        receiver = CargoContact.objects.create(
            organization=self.organization,
            contact_code=f"RC-{uuid.uuid4().hex[:6]}",
            name="Receiver",
            phone_number="+959700000002",
        )
        terminal = PhysicalTerminal.objects.create(
            code=f"term-{uuid.uuid4().hex[:6]}", name="Aung Mingalar"
        )
        op = CompanyTerminalOperation.objects.create(
            organization=self.organization,
            branch=self.branch,
            terminal=terminal,
            code=f"op-{uuid.uuid4().hex[:6]}",
        )
        return CargoShipment.objects.create(
            organization=self.organization,
            shipment_number=f"CG-{uuid.uuid4().hex[:6].upper()}",
            sender=sender,
            receiver=receiver,
            origin_terminal=op,
            destination_terminal=op,
            accepted_by=self.user,
            status=status,
            item_category="Box",
            piece_count=1,
            pricing_method=CargoShipment.PricingMethod.MANUAL,
            total_charge=charge,
        )

    def _payment(
        self,
        method=PaymentRecord.Method.CASH,
        amount=Decimal("20000.00"),
        booking=None,
        trip=None,
    ):
        if booking is None:
            trip = trip or self._trip()
            passenger = Passenger.objects.create(
                organization=self.organization,
                passenger_code=f"P-{uuid.uuid4().hex[:6].upper()}",
                full_name="Payer",
            )
            booking = Booking.objects.create(
                organization=self.organization,
                trip=trip,
                booking_number=f"BK-{uuid.uuid4().hex[:6].upper()}",
                booking_type=Booking.Type.INDIVIDUAL,
                channel=Booking.Channel.COUNTER,
                status=Booking.Status.CONFIRMED,
                contact_name="Payer",
                contact_phone="+959111111112",
                pickup_stop=self.pickup,
                dropoff_stop=self.dropoff,
                created_by=self.user,
            )
            BookingPassenger.objects.create(booking=booking, passenger=passenger)
        return PaymentRecord.objects.create(
            organization=self.organization,
            payment_number=f"PAY-{uuid.uuid4().hex[:6].upper()}",
            booking=booking,
            method=method,
            status=PaymentRecord.Status.CONFIRMED,
            amount=amount,
            recorded_by=self.user,
            confirmed_by=self.user,
            confirmed_at=timezone.now(),
        )

    def test_dashboard_returns_real_aggregates(self):
        trip = self._trip()
        self._ticket(trip, Decimal("12000.00"))
        self._ticket(trip, Decimal("8000.00"))
        self._cargo(Decimal("5000.00"))
        self._cargo(Decimal("3000.00"))
        self._payment(PaymentRecord.Method.CASH, Decimal("20000.00"), booking=None, trip=trip)

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/reports/owner-dashboard/"
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()

        # Money: ticket + cargo revenue, all from created rows.
        self.assertEqual(Decimal(data["money"]["ticket_revenue"]), Decimal("20000.00"))
        self.assertEqual(Decimal(data["money"]["cargo_revenue"]), Decimal("8000.00"))
        self.assertEqual(Decimal(data["money"]["total_revenue"]), Decimal("28000.00"))
        # Legacy summary keys stay intact.
        self.assertEqual(
            Decimal(data["confirmed_payments"][0]["amount"]), Decimal("20000.00")
        )

        # Trip ops.
        self.assertEqual(data["trip_ops"]["running"], 1)
        self.assertEqual(data["trip_ops"]["passengers"], 2)
        self.assertEqual(data["trip_ops"]["cargo_today"], 2)

        # Cargo ops.
        self.assertEqual(data["cargo_ops"]["accepted"], 2)

        # Bookings.
        self.assertEqual(data["bookings"]["total"], 3)

        # Cash & pending.
        self.assertEqual(
            Decimal(data["cash_pending"]["cash_in_counters"]), Decimal("20000.00")
        )

        # Fleet & people.
        self.assertEqual(data["fleet_people"]["vehicles_running"]["count"], 1)
        self.assertEqual(data["fleet_people"]["vehicles_running"]["total"], 2)
        self.assertEqual(data["fleet_people"]["vehicles_maintenance"], 1)

        # Rankings: vehicle + branch + route from ticket revenue.
        self.assertEqual(data["rankings"]["vehicles"][0]["name"], "YK 1234")
        self.assertEqual(
            Decimal(data["rankings"]["vehicles"][0]["revenue"]), Decimal("20000.00")
        )
        self.assertEqual(data["rankings"]["branches"][0]["name"], "Yangon Central")
        self.assertEqual(data["rankings"]["routes"][0]["name"], "Yangon → Mandalay")

        # Trend: total across all points matches revenue.
        trend_total = sum(Decimal(p["total"]) for p in data["revenue_trend"])
        self.assertEqual(trend_total, Decimal("28000.00"))
        self.assertEqual(data["revenue_trend"][-1]["label"], self.today.isoformat())

        # Pulse: no alerts with a clean dataset.
        self.assertEqual(data["pulse"]["alerts"], [])

    def test_dashboard_delayed_and_cancelled_produce_alerts(self):
        self._trip(status=Trip.Status.DELAYED)
        self._trip(status=Trip.Status.CANCELLED)

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/reports/owner-dashboard/"
        )
        data = response.json()
        severities = {a["severity"] for a in data["pulse"]["alerts"]}
        self.assertIn("warning", severities)  # delayed
        self.assertIn("danger", severities)  # cancelled
        self.assertEqual(data["trip_ops"]["delayed"], 1)
        self.assertEqual(data["trip_ops"]["cancelled"], 1)

    def test_dashboard_pending_refunds_and_approvals(self):
        payment = self._payment()
        RefundRequest.objects.create(
            organization=self.organization,
            payment=payment,
            refund_number="RF-0001",
            status=RefundRequest.Status.REQUESTED,
            requested_amount=Decimal("15000.00"),
            reason="Duplicate charge",
            requested_by=self.user,
        )

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/reports/owner-dashboard/"
        )
        data = response.json()
        self.assertEqual(data["cash_pending"]["pending_refunds"]["count"], 1)
        self.assertEqual(
            Decimal(data["cash_pending"]["pending_refunds"]["amount"]),
            Decimal("15000.00"),
        )
        self.assertEqual(data["cash_pending"]["pending_approvals"], 1)
        self.assertTrue(any("refund" in a["message"] for a in data["pulse"]["alerts"]))

    def test_dashboard_on_time_percent(self):
        on_time = self._trip()
        on_time.departed_at = on_time.planned_departure_at + timedelta(minutes=5)
        on_time.save()
        late = self._trip(status=Trip.Status.DEPARTED)
        late.departed_at = late.planned_departure_at + timedelta(minutes=45)
        late.save()

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/reports/owner-dashboard/"
        )
        data = response.json()
        self.assertEqual(data["trip_ops"]["on_time_percent"], 50.0)

    def test_dashboard_period_validation(self):
        url = f"/api/v1/organizations/{self.organization.id}/reports/owner-dashboard/"
        response = self.client.get(url, {"period": "decade"})
        self.assertEqual(response.status_code, 400)

        for period in ("day", "week", "month", "year"):
            response = self.client.get(url, {"period": period})
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()["period"], period)

    def test_dashboard_excludes_cancelled_ticket_revenue(self):
        trip = self._trip()
        self._ticket(trip, Decimal("12000.00"))
        self._ticket(trip, Decimal("8000.00"), status=Ticket.Status.CANCELLED)

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/reports/owner-dashboard/"
        )
        data = response.json()
        self.assertEqual(Decimal(data["money"]["ticket_revenue"]), Decimal("12000.00"))
        self.assertEqual(data["trip_ops"]["passengers"], 1)

    def test_dashboard_requires_owner_permission(self):
        tenant, org = _make_tenant_org()
        other = User.objects.create_user(
            phone_number="+959777700888", password="Strong-pass-123"
        )
        Membership.objects.create(
            organization=org,
            user=other,
            status=Membership.Status.ACTIVE,
        )
        self.client.force_authenticate(other)
        response = self.client.get(
            f"/api/v1/organizations/{org.id}/reports/owner-dashboard/"
        )
        self.assertEqual(response.status_code, 403)
