from django.core.exceptions import ValidationError
from django.test import TestCase

from apps.network.models import Route, RouteSegment, RouteStop
from apps.tenancy.models import Organization, Tenant


class NetworkModelTests(TestCase):
    def setUp(self):
        tenant = Tenant.objects.create(name="Network Tenant", slug="network")
        organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Network Express Company",
            display_name="Network Express",
        )
        self.route = Route.objects.create(
            organization=organization,
            code="ygn-mdy",
            name="Yangon to Mandalay",
        )
        self.origin = RouteStop.objects.create(
            route=self.route,
            code="ygn",
            name="Yangon",
            sequence=1,
            stop_type=RouteStop.Type.MAJOR,
        )
        self.destination = RouteStop.objects.create(
            route=self.route,
            code="mdy",
            name="Mandalay",
            sequence=2,
            stop_type=RouteStop.Type.MAJOR,
        )

    def test_segment_must_move_forward(self):
        segment = RouteSegment(
            route=self.route,
            from_stop=self.destination,
            to_stop=self.origin,
            sequence=1,
        )

        with self.assertRaises(ValidationError):
            segment.full_clean()
