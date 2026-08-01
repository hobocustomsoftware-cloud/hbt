from datetime import timedelta
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from apps.bookings.models import (
    Booking,
    BookingPassenger,
    CorporateCustomer,
    CorporateCustomerMember,
    CorporateInvoice,
)
from apps.bookings.services import (
    decide_corporate_booking,
    issue_corporate_invoice,
    submit_corporate_booking,
    void_corporate_invoice,
)
from apps.identity.models import User
from apps.network.models import Route, RouteStop
from apps.passengers.models import Passenger
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization, Tenant

from ..models import CouponRedemption, FareQuote, FareRule, Promotion
from ..services import create_fare_quote, lock_fare_quote, override_quote_line


class FareQuoteTests(TestCase):
    def setUp(self):
        tenant = Tenant.objects.create(name="Fare Tenant", slug="fare-tenant")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Fare Express Limited",
            display_name="Fare Express",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959700000001", password="Strong-pass-123"
        )
        self.approver = User.objects.create_user(
            phone_number="+959700000002", password="Strong-pass-456"
        )
        route = Route.objects.create(
            organization=self.organization,
            code="fare-route",
            name="Fare Route",
            status=Route.Status.ACTIVE,
        )
        self.pickup = RouteStop.objects.create(
            route=route,
            code="start",
            name="Start",
            sequence=1,
            stop_type=RouteStop.Type.PICKUP,
            status=RouteStop.Status.ACTIVE,
        )
        self.dropoff = RouteStop.objects.create(
            route=route,
            code="end",
            name="End",
            sequence=2,
            stop_type=RouteStop.Type.DROPOFF,
            status=RouteStop.Status.ACTIVE,
        )
        departure = timezone.now() + timedelta(days=1)
        trip = Trip.objects.create(
            organization=self.organization,
            route=route,
            trip_number="FARE-TRIP",
            service_date=departure.date(),
            planned_departure_at=departure,
            planned_arrival_at=departure + timedelta(hours=4),
        )
        self.booking = Booking.objects.create(
            organization=self.organization,
            trip=trip,
            booking_number="FARE-BOOKING",
            booking_type=Booking.Type.CORPORATE,
            channel=Booking.Channel.COUNTER,
            status=Booking.Status.RESERVED,
            contact_name="Company Buyer",
            contact_phone="+959711111111",
            pickup_stop=self.pickup,
            dropoff_stop=self.dropoff,
            created_by=self.user,
            customer_account=self.user,
        )
        for index in range(2):
            passenger = Passenger.objects.create(
                organization=self.organization,
                passenger_code=f"P-{index}",
                full_name=f"Passenger {index}",
                phone_number=f"+95972222222{index}",
            )
            BookingPassenger.objects.create(
                booking=self.booking, passenger=passenger
            )
        self.rule = FareRule.objects.create(
            organization=self.organization,
            code="standard",
            name="Standard Fare",
            route=route,
            pickup_stop=self.pickup,
            dropoff_stop=self.dropoff,
            base_fare=Decimal("10000"),
            tax_rate=Decimal("5"),
            effective_from=timezone.now() - timedelta(days=1),
            created_by=self.user,
        )

    def test_server_quote_snapshots_each_passenger_and_tax(self):
        quote = create_fare_quote(booking=self.booking, actor=self.user)
        self.assertEqual(quote.lines.count(), 2)
        self.assertEqual(quote.subtotal, Decimal("20000"))
        self.assertEqual(quote.tax_amount, Decimal("1000"))
        self.assertEqual(quote.total_amount, Decimal("21000"))
        self.assertEqual(quote.snapshot["fare_rule_code"], "standard")

    def test_group_coupon_is_server_calculated_and_redeemed_on_lock(self):
        promotion = Promotion.objects.create(
            organization=self.organization,
            code="group-five",
            name_my="အဖွဲ့လိုက်လျှော့ဈေး",
            coupon_code="GROUP5",
            discount_type=Promotion.DiscountType.PERCENT,
            discount_value=Decimal("10"),
            minimum_passengers=2,
            starts_at=timezone.now() - timedelta(hours=1),
            ends_at=timezone.now() + timedelta(days=1),
            created_by=self.user,
        )
        quote = create_fare_quote(
            booking=self.booking, actor=self.user, coupon_code="group5"
        )
        self.assertEqual(quote.applied_promotion, promotion)
        self.assertEqual(quote.discount_amount, Decimal("2000"))
        self.assertEqual(quote.tax_amount, Decimal("900"))
        self.assertEqual(quote.total_amount, Decimal("18900"))
        self.assertFalse(CouponRedemption.objects.filter(quote=quote).exists())
        lock_fare_quote(quote=quote, actor=self.user)
        self.assertTrue(CouponRedemption.objects.filter(quote=quote).exists())

    def test_override_requires_reason_and_locked_quote_is_immutable(self):
        quote = create_fare_quote(booking=self.booking, actor=self.user)
        line = quote.lines.first()
        with self.assertRaises(ValidationError):
            override_quote_line(
                line=line,
                actor=self.user,
                base_fare=Decimal("9000"),
                reason="",
            )
        override_quote_line(
            line=line,
            actor=self.user,
            base_fare=Decimal("9000"),
            reason="Approved company rate",
        )
        quote.refresh_from_db()
        self.assertEqual(quote.total_amount, Decimal("19950"))
        quote = lock_fare_quote(quote=quote, actor=self.user)
        self.assertEqual(quote.status, FareQuote.Status.LOCKED)
        with self.assertRaises(ValidationError):
            override_quote_line(
                line=line,
                actor=self.user,
                base_fare=Decimal("8000"),
                reason="Too late",
            )

    def test_company_approver_and_invoice_use_locked_quote(self):
        quote = lock_fare_quote(
            quote=create_fare_quote(booking=self.booking, actor=self.user),
            actor=self.user,
        )
        customer = CorporateCustomer.objects.create(
            organization=self.organization,
            code="acme",
            legal_name="ACME Company Limited",
            display_name="ACME",
        )
        CorporateCustomerMember.objects.create(
            corporate_customer=customer,
            user=self.user,
            status=CorporateCustomerMember.Status.ACTIVE,
            can_request=True,
            can_approve=True,
        )
        CorporateCustomerMember.objects.create(
            corporate_customer=customer,
            user=self.approver,
            status=CorporateCustomerMember.Status.ACTIVE,
            can_request=False,
            can_approve=True,
        )
        approval = submit_corporate_booking(
            booking=self.booking,
            corporate_customer=customer,
            fare_quote=quote,
            actor=self.user,
        )
        with self.assertRaises(ValidationError):
            decide_corporate_booking(
                approval=approval, actor=self.user, approve=True
            )
        approval = decide_corporate_booking(
            approval=approval, actor=self.approver, approve=True
        )
        invoice = issue_corporate_invoice(
            approval=approval,
            actor=self.approver,
            invoice_number="ACME-2026-000001",
        )
        self.assertEqual(invoice.total_amount, quote.total_amount)
        invoice = void_corporate_invoice(
            invoice=invoice,
            actor=self.approver,
            reason="Billing address correction",
        )
        self.assertEqual(invoice.status, CorporateInvoice.Status.VOID)
