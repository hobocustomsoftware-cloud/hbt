from datetime import timedelta

from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from apps.identity.models import User
from apps.tenancy.models import Tenant, TenantSupportAccess


class TenantSupportAccessTests(TestCase):
    def test_support_access_cannot_be_self_approved(self):
        user = User.objects.create_user(
            phone_number="+959777777777",
            password="safe-test-password",
        )
        tenant = Tenant.objects.create(name="Support Test", slug="support-test")
        now = timezone.now()
        access = TenantSupportAccess(
            tenant=tenant,
            requester=user,
            approved_by=user,
            level=TenantSupportAccess.Level.READ_ONLY,
            reason="Investigate support case",
            starts_at=now,
            expires_at=now + timedelta(hours=1),
        )

        with self.assertRaises(ValidationError):
            access.full_clean()
