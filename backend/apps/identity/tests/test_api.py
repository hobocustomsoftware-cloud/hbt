from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.audit.models import AuditEvent
from apps.identity.models import User


class AuthenticationApiTests(APITestCase):
    def test_register_login_and_read_profile(self):
        register_response = self.client.post(
            reverse("identity:register", kwargs={"version": "v1"}),
            {
                "phone_number": "+959333333333",
                "password": "safe-test-password",
                "first_name": "Test",
            },
            format="json",
        )
        self.assertEqual(register_response.status_code, status.HTTP_201_CREATED)

        login_response = self.client.post(
            reverse("identity:login", kwargs={"version": "v1"}),
            {
                "phone_number": "+959333333333",
                "password": "safe-test-password",
            },
            format="json",
        )
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        self.assertIn("access", login_response.data)
        self.assertIn("refresh", login_response.data)

        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {login_response.data['access']}"
        )
        profile_response = self.client.get(
            reverse("identity:me", kwargs={"version": "v1"})
        )
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            profile_response.data["phone_number"],
            "+959333333333",
        )
        self.assertTrue(
            AuditEvent.objects.filter(
                action="authentication.login_succeeded"
            ).exists()
        )

    def test_non_active_account_cannot_login(self):
        User.objects.create_user(
            phone_number="+959444444444",
            password="safe-test-password",
            status=User.Status.SUSPENDED,
        )

        response = self.client.post(
            reverse("identity:login", kwargs={"version": "v1"}),
            {
                "phone_number": "+959444444444",
                "password": "safe-test-password",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="authentication.login_failed"
            ).exists()
        )

    def test_profile_update_cannot_change_login_phone(self):
        user = User.objects.create_user(
            phone_number="+959888888888",
            password="safe-test-password",
            status=User.Status.ACTIVE,
        )
        self.client.force_authenticate(user)

        response = self.client.patch(
            reverse("identity:me", kwargs={"version": "v1"}),
            {
                "phone_number": "+959999999999",
                "first_name": "Updated",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        self.assertEqual(user.phone_number, "+959888888888")
        self.assertEqual(user.first_name, "Updated")
