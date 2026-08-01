from django.core.exceptions import ValidationError
from django.test import TestCase

from apps.identity.models import PlatformAccessGrant, User


class PlatformAccessGrantTests(TestCase):
    def test_platform_access_cannot_be_self_granted(self):
        user = User.objects.create_user(
            phone_number="+959555555555",
            password="safe-test-password",
        )
        grant = PlatformAccessGrant(
            user=user,
            granted_by=user,
            role=PlatformAccessGrant.Role.SUPER_ADMIN,
            reason="Invalid self grant",
        )

        with self.assertRaises(ValidationError):
            grant.full_clean()
