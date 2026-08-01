from datetime import timedelta

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.locations.models import Branch
from apps.subscriptions.models import SubscriptionPlan, TenantSubscription
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)
from apps.workforce.models import StaffProfile


class WorkforceApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959141414141",
            password="safe-test-password",
        )
        self.tenant = Tenant.objects.create(
            name="Workforce Tenant",
            slug="workforce-api",
            status=Tenant.Status.ACTIVE,
        )
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Workforce Express Company",
            display_name="Workforce Express",
            status=Organization.Status.ACTIVE,
        )
        membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.branch = Branch.objects.create(
            organization=self.organization,
            code="ygn",
            name="Yangon Branch",
        )
        self.client.force_authenticate(self.user)

    def test_staff_creation_enforces_subscription_limit(self):
        TenantSubscription.objects.create(
            tenant=self.organization.tenant,
            plan=SubscriptionPlan.objects.get(code="starter"),
            status=TenantSubscription.Status.ACTIVE,
            billing_cycle=TenantSubscription.BillingCycle.MONTHLY,
            starts_at=timezone.now() - timedelta(days=1),
            current_period_ends_at=timezone.now() + timedelta(days=29),
            grace_ends_at=timezone.now() + timedelta(days=36),
            changed_by=self.user,
        )
        for index in range(5):
            staff_user = User.objects.create_user(
                phone_number=f"+95930000010{index}",
                password="safe-test-password",
            )
            staff_membership = Membership.objects.create(
                organization=self.organization,
                user=staff_user,
                status=Membership.Status.ACTIVE,
            )
            StaffProfile.objects.create(
                membership=staff_membership,
                branch=self.branch,
                employee_code=f"E{index + 1:03d}",
                status=StaffProfile.Status.ACTIVE,
            )

        extra_user = User.objects.create_user(
            phone_number="+959399999999",
            password="safe-test-password",
        )
        extra_membership = Membership.objects.create(
            organization=self.organization,
            user=extra_user,
            status=Membership.Status.ACTIVE,
        )
        response = self.client.post(
            reverse(
                "workforce:staff-list-create",
                kwargs={
                    "version": "v1",
                    "organization_id": self.organization.id,
                },
            ),
            {
                "membership": str(extra_membership.id),
                "branch": str(self.branch.id),
                "employee_code": "E999",
                "status": StaffProfile.Status.ACTIVE,
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
