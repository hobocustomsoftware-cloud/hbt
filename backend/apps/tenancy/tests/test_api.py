from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.audit.models import AuditEvent
from apps.identity.models import User
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)


class RoleApiTests(APITestCase):
    def setUp(self):
        self.owner = User.objects.create_user(
            phone_number="+959666666666",
            password="safe-test-password",
        )
        self.tenant = Tenant.objects.create(
            name="HBT Express",
            slug="hbt-api",
            status=Tenant.Status.ACTIVE,
        )
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="HBT Express Company Limited",
            display_name="HBT Express",
            status=Organization.Status.ACTIVE,
        )
        self.membership = Membership.objects.create(
            organization=self.organization,
            user=self.owner,
            status=Membership.Status.ACTIVE,
        )
        owner_role = Role.objects.get(
            tenant=None,
            code="company-owner",
        )
        MembershipRole.objects.create(
            membership=self.membership,
            role=owner_role,
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.client.force_authenticate(self.owner)

    def test_owner_can_create_delegated_custom_role(self):
        response = self.client.post(
            reverse(
                "tenancy:role-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                },
            ),
            {
                "code": "membership-reviewer",
                "name": "Membership Reviewer",
                "permission_codes": [
                    "organization.view",
                    "access.membership.view",
                ],
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        role = Role.objects.get(
            tenant=self.tenant,
            code="membership-reviewer",
        )
        self.assertFalse(role.is_system)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="authorization.role_created",
                resource_id=str(role.id),
            ).exists()
        )

    def test_user_can_read_their_organization_context(self):
        response = self.client.get(
            reverse(
                "tenancy:my-organization-context",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                },
            )
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.data["organization"]["id"],
            str(self.organization.id),
        )
        self.assertIn("organization.view", response.data["permissions"])

    def test_user_cannot_view_another_tenant_organization(self):
        other_tenant = Tenant.objects.create(
            name="Other",
            slug="other-api",
            status=Tenant.Status.ACTIVE,
        )
        other_org = Organization.objects.create(
            tenant=other_tenant,
            legal_name="Other Company",
            display_name="Other",
            status=Organization.Status.ACTIVE,
        )

        response = self.client.get(
            reverse(
                "tenancy:organization-detail",
                kwargs={
                    "version": "v1",
                    "organization_id": other_org.id,
                },
            )
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
