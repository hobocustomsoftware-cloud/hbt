from datetime import timedelta

from django.core.exceptions import PermissionDenied
from django.test import TestCase
from django.utils import timezone

from apps.identity.models import User
from apps.locations.models import Branch, CompanyTerminalOperation, SalesCounter
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Permission,
    Role,
    Tenant,
)
from apps.tenancy.services import (
    effective_permission_codes,
    has_resource_scope,
    require_permission,
    require_scoped_permission,
)


class AuthorizationWindowTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959777777777",
            password="safe-test-password",
        )
        self.tenant = Tenant.objects.create(
            name="Auth Window",
            slug="auth-window",
            status=Tenant.Status.ACTIVE,
        )
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Auth Window Co",
            display_name="Auth Window",
            status=Organization.Status.ACTIVE,
        )
        self.membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        self.permission = Permission.objects.create(
            code="test.window.permission",
            name="Window test permission",
        )
        self.role = Role.objects.create(
            tenant=self.tenant,
            code="window-role",
            name="Window Role",
        )
        self.role.permissions.add(self.permission)

    def _assign(self, **kwargs):
        return MembershipRole.objects.create(
            membership=self.membership,
            role=self.role,
            scope_type=MembershipRole.ScopeType.COMPANY,
            **kwargs,
        )

    def test_future_role_assignment_is_not_effective(self):
        self._assign(valid_from=timezone.now() + timedelta(minutes=5))
        self.assertNotIn(
            self.permission.code,
            effective_permission_codes(self.membership),
        )

    def test_expired_role_assignment_is_not_effective(self):
        self._assign(valid_until=timezone.now() - timedelta(minutes=5))
        self.assertNotIn(
            self.permission.code,
            effective_permission_codes(self.membership),
        )

    def test_current_role_assignment_is_effective(self):
        self._assign(
            valid_from=timezone.now() - timedelta(minutes=5),
            valid_until=timezone.now() + timedelta(minutes=5),
        )
        self.assertIn(
            self.permission.code,
            effective_permission_codes(self.membership),
        )
        require_permission(self.membership, self.permission.code)

    def test_expired_role_assignment_is_denied(self):
        self._assign(valid_until=timezone.now() - timedelta(seconds=1))
        with self.assertRaises(PermissionDenied):
            require_permission(self.membership, self.permission.code)

    def test_branch_scope_covers_only_assigned_branch(self):
        branch = Branch.objects.create(
            organization=self.organization,
            code="main",
            name="Main Branch",
        )
        other_branch = Branch.objects.create(
            organization=self.organization,
            code="other",
            name="Other Branch",
        )
        MembershipRole.objects.create(
            membership=self.membership,
            role=self.role,
            scope_type=MembershipRole.ScopeType.BRANCH,
            scope_id=branch.pk,
        )

        self.assertTrue(has_resource_scope(self.membership, branch))
        self.assertFalse(has_resource_scope(self.membership, other_branch))

    def test_counter_scope_covers_counter_and_its_parent_operation(self):
        branch = Branch.objects.create(
            organization=self.organization,
            code="main",
            name="Main Branch",
        )
        operation = CompanyTerminalOperation.objects.create(
            organization=self.organization,
            branch=branch,
            terminal_id=None,
            code="main-terminal",
            display_name="Main Terminal",
        )
        counter = SalesCounter.objects.create(
            terminal_operation=operation,
            code="counter-1",
            name="Counter 1",
        )
        other_counter = SalesCounter.objects.create(
            terminal_operation=operation,
            code="counter-2",
            name="Counter 2",
        )
        MembershipRole.objects.create(
            membership=self.membership,
            role=self.role,
            scope_type=MembershipRole.ScopeType.COUNTER,
            scope_id=counter.pk,
        )

        self.assertTrue(has_resource_scope(self.membership, counter))
        self.assertFalse(has_resource_scope(self.membership, other_counter))

    def test_cross_organization_resource_is_denied_even_with_company_scope(self):
        other_tenant = Tenant.objects.create(
            name="Other Tenant",
            slug="other-tenant",
            status=Tenant.Status.ACTIVE,
        )
        other_org = Organization.objects.create(
            tenant=other_tenant,
            legal_name="Other Co",
            display_name="Other Co",
            status=Organization.Status.ACTIVE,
        )
        other_branch = Branch.objects.create(
            organization=other_org,
            code="other",
            name="Other Branch",
        )
        self._assign()

        self.assertFalse(has_resource_scope(self.membership, other_branch))
        with self.assertRaises(PermissionDenied):
            require_scoped_permission(
                self.membership,
                self.permission.code,
                other_branch,
            )
