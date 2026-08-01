from django.test import TestCase

from apps.identity.models import User


class UserModelTests(TestCase):
    def test_user_uses_normalized_phone_as_identity(self):
        user = User.objects.create_user(
            phone_number="+95 9-123-456-789",
            password="safe-test-password",
        )

        self.assertEqual(user.phone_number, "+959123456789")
        self.assertTrue(user.check_password("safe-test-password"))
        self.assertEqual(User.USERNAME_FIELD, "phone_number")

    def test_user_defaults_to_myanmar_language(self):
        user = User.objects.create_user(
            phone_number="+959111111111",
            password="safe-test-password",
        )

        self.assertEqual(user.preferred_language, User.Language.MYANMAR)
