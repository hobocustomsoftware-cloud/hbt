from datetime import timedelta

from django.core.exceptions import PermissionDenied
from django.test import TestCase
from django.utils import timezone

from apps.identity.models import User
from apps.tenancy.models import Membership, MembershipRole, Organization, Role, Tenant
from apps.tenancy.services import effective_permission_codes, require_permission
from apps.tenancy.models import Permission


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
