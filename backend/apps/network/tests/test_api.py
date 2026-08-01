from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.audit.models import AuditEvent
from apps.identity.models import User
from apps.network.models import Route, RouteSegment, RouteStop
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)


class NetworkApiTests(APITestCase):
    def setUp(self):
        user = User.objects.create_user(
            phone_number="+959121212121",
            password="safe-test-password",
        )
        self.tenant = Tenant.objects.create(
            name="Route Tenant",
            slug="route-api",
            status=Tenant.Status.ACTIVE,
        )
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Route Express Company",
            display_name="Route Express",
            status=Organization.Status.ACTIVE,
        )
        membership = Membership.objects.create(
            organization=self.organization,
            user=user,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.client.force_authenticate(user)

    def test_owner_can_build_route_stops_and_segment(self):
        route_response = self.client.post(
            reverse(
                "network:route-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                },
            ),
            {"code": "ygn-mdy", "name": "Yangon to Mandalay"},
            format="json",
        )
        self.assertEqual(route_response.status_code, status.HTTP_201_CREATED)
        route_id = route_response.data["id"]

        stop_ids = []
        for sequence, code, name in (
            (1, "ygn", "Yangon"),
            (2, "mdy", "Mandalay"),
        ):
            response = self.client.post(
                reverse(
                    "network:route-stop-list-create",
                    kwargs={
                        "version": "v1",
                        "organization_id": self.organization.id,
                        "route_id": route_id,
                    },
                ),
                {
                    "code": code,
                    "name": name,
                    "sequence": sequence,
                    "stop_type": "major",
                },
                format="json",
            )
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
            stop_ids.append(response.data["id"])

        segment_response = self.client.post(
            reverse(
                "network:route-segment-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                    "route_id": route_id,
                },
            ),
            {
                "from_stop": stop_ids[0],
                "to_stop": stop_ids[1],
                "sequence": 1,
                "distance_km": "620.00",
            },
            format="json",
        )
        self.assertEqual(segment_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Route.objects.count(), 1)
        self.assertEqual(RouteStop.objects.count(), 2)
        self.assertEqual(RouteSegment.objects.count(), 1)
        self.assertEqual(
            AuditEvent.objects.filter(action__startswith="network.").count(),
            4,
        )
