from django.test import TestCase

from apps.identity.models import User
from apps.locations.models import Branch, CompanyTerminalOperation, PhysicalTerminal
from apps.tenancy.models import Membership, MembershipRole, Organization, Permission, Role, Tenant
from apps.tenancy.services import scoped_queryset


class SecurityScopeRegressionTests(TestCase):
    """Regression coverage for tenant anchoring and fail-closed queryset scope."""

    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959788888881", password="safe-test-password"
        )
        self.tenant = Tenant.objects.create(
            name="Scope Regression", slug="scope-regression", status=Tenant.Status.ACTIVE
        )
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Scope Regression Co",
            display_name="Scope Regression Co",
            status=Organization.Status.ACTIVE,
        )
        self.membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        self.permission = Permission.objects.create(
            code="security.scope.view", name="Security scope view"
        )
        self.role = Role.objects.create(
            tenant=self.tenant, code="security-scope-role", name="Security Scope Role"
        )
        self.role.permissions.add(self.permission)
        MembershipRole.objects.create(
            membership=self.membership,
            role=self.role,
            scope_type=MembershipRole.ScopeType.COMPANY,
        )

    def test_company_scoped_physical_terminal_queryset_is_tenant_anchored(self):
        own_branch = Branch.objects.create(
            organization=self.organization, code="own-branch", name="Own Branch"
        )
        own_terminal = PhysicalTerminal.objects.create(
            code="own-terminal", name="Own Terminal"
        )
        CompanyTerminalOperation.objects.create(
            organization=self.organization,
            branch=own_branch,
            terminal=own_terminal,
            code="own-operation",
            display_name="Own Operation",
        )

        other_tenant = Tenant.objects.create(
            name="Other Scope Tenant",
            slug="other-scope-tenant",
            status=Tenant.Status.ACTIVE,
        )
        other_org = Organization.objects.create(
            tenant=other_tenant,
            legal_name="Other Scope Co",
            display_name="Other Scope Co",
            status=Organization.Status.ACTIVE,
        )
        other_branch = Branch.objects.create(
            organization=other_org, code="other-branch", name="Other Branch"
        )
        other_terminal = PhysicalTerminal.objects.create(
            code="other-terminal", name="Other Terminal"
        )
        CompanyTerminalOperation.objects.create(
            organization=other_org,
            branch=other_branch,
            terminal=other_terminal,
            code="other-operation",
            display_name="Other Operation",
        )

        queryset = scoped_queryset(
            self.membership, PhysicalTerminal.objects.all(), self.permission.code
        )

        self.assertEqual(
            set(queryset.values_list("pk", flat=True)), {own_terminal.pk}
        )
        self.assertNotIn(other_terminal.pk, queryset.values_list("pk", flat=True))

    def test_unsupported_queryset_is_fail_closed(self):
        queryset = scoped_queryset(
            self.membership, Tenant.objects.all(), self.permission.code
        )
        self.assertEqual(queryset.count(), 0)
