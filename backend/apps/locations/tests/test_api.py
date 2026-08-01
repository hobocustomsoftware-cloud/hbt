from datetime import timedelta

from django.utils import timezone
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.audit.models import AuditEvent
from apps.identity.models import User
from apps.locations.models import (
    Branch,
    CompanyTerminalOperation,
    OperationalStatus,
    PhysicalTerminal,
    SalesCounter,
)
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)
from apps.subscriptions.models import SubscriptionPlan, TenantSubscription


class LocationApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959101010101",
            password="safe-test-password",
        )
        self.tenant = Tenant.objects.create(
            name="Location Tenant",
            slug="location-api",
            status=Tenant.Status.ACTIVE,
        )
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Location Express Company",
            display_name="Location Express",
            status=Organization.Status.ACTIVE,
        )
        membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        owner_role = Role.objects.get(tenant=None, code="company-owner")
        MembershipRole.objects.create(
            membership=membership,
            role=owner_role,
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.terminal = PhysicalTerminal.objects.create(
            code="yangon-aung-mingalar",
            name="Aung Mingalar Highway Bus Terminal",
            name_myanmar="အောင်မင်္ဂလာ အဝေးပြေးဝင်း",
            status=OperationalStatus.ACTIVE,
            region="Yangon",
            city="Yangon",
        )
        self.client.force_authenticate(self.user)

    def test_owner_can_create_branch_operation_and_counter(self):
        branch_response = self.client.post(
            reverse(
                "locations:branch-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                },
            ),
            {"code": "ygn", "name": "Yangon Branch"},
            format="json",
        )
        self.assertEqual(branch_response.status_code, status.HTTP_201_CREATED)

        operation_response = self.client.post(
            reverse(
                "locations:terminal-operation-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                },
            ),
            {
                "branch": branch_response.data["id"],
                "terminal": str(self.terminal.id),
                "code": "ygn-main",
                "display_name": "Yangon Main Counter Operation",
            },
            format="json",
        )
        self.assertEqual(
            operation_response.status_code,
            status.HTTP_201_CREATED,
        )

        counter_response = self.client.post(
            reverse(
                "locations:counter-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                    "operation_id": operation_response.data["id"],
                },
            ),
            {"code": "c01", "name": "Counter 1"},
            format="json",
        )
        self.assertEqual(counter_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Branch.objects.count(), 1)
        self.assertEqual(CompanyTerminalOperation.objects.count(), 1)
        self.assertEqual(SalesCounter.objects.count(), 1)
        self.assertEqual(
            AuditEvent.objects.filter(
                action__startswith="locations."
            ).count(),
            3,
        )

    def test_another_tenant_cannot_access_branch(self):
        other_tenant = Tenant.objects.create(
            name="Other Tenant",
            slug="other-location-api",
        )
        other_org = Organization.objects.create(
            tenant=other_tenant,
            legal_name="Other Location Company",
            display_name="Other",
        )
        branch = Branch.objects.create(
            organization=other_org,
            code="other",
            name="Other Branch",
        )

        response = self.client.get(
            reverse(
                "locations:branch-detail",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                    "branch_id": branch.id,
                },
            )
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_counter_creation_enforces_subscription_limit(self):
        self.organization.tenant.subscription = TenantSubscription.objects.create(
            tenant=self.organization.tenant,
            plan=SubscriptionPlan.objects.get(code="starter"),
            status=TenantSubscription.Status.ACTIVE,
            billing_cycle=TenantSubscription.BillingCycle.MONTHLY,
            starts_at=timezone.now() - timedelta(days=1),
            current_period_ends_at=timezone.now() + timedelta(days=29),
            grace_ends_at=timezone.now() + timedelta(days=36),
            changed_by=self.user,
        )
        branch = Branch.objects.create(
            organization=self.organization, code="ygn", name="Yangon Branch"
        )
        operation = CompanyTerminalOperation.objects.create(
            organization=self.organization,
            branch=branch,
            terminal=self.terminal,
            code="ygn-main",
            display_name="Yangon Main",
        )
        SalesCounter.objects.create(
            terminal_operation=operation, code="c01", name="Counter 1"
        )

        response = self.client.post(
            reverse(
                "locations:counter-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                    "operation_id": operation.id,
                },
            ),
            {"code": "c02", "name": "Counter 2"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
