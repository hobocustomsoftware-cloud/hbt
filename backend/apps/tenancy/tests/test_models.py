from django.core.exceptions import ValidationError
from django.test import TestCase

from apps.identity.models import User
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)


class TenancyModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959222222222",
            password="safe-test-password",
        )
        self.tenant = Tenant.objects.create(name="HBT Express", slug="hbt")
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="HBT Express Company Limited",
            display_name="HBT Express",
        )
        self.membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
        )

    def test_membership_exposes_organization_tenant(self):
        self.assertEqual(self.membership.tenant_id, self.tenant.id)

    def test_role_from_another_tenant_is_rejected(self):
        other_tenant = Tenant.objects.create(name="Other Express", slug="other")
        other_role = Role.objects.create(
            tenant=other_tenant,
            code="manager",
            name="Manager",
        )
        assignment = MembershipRole(
            membership=self.membership,
            role=other_role,
            scope_type=MembershipRole.ScopeType.COMPANY,
        )

        with self.assertRaises(ValidationError):
            assignment.full_clean()

    def test_branch_scope_requires_scope_id(self):
        role = Role.objects.create(
            tenant=self.tenant,
            code="terminal-manager",
            name="Terminal Manager",
        )
        assignment = MembershipRole(
            membership=self.membership,
            role=role,
            scope_type=MembershipRole.ScopeType.BRANCH,
        )

        with self.assertRaises(ValidationError):
            assignment.full_clean()
