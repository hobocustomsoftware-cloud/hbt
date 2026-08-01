from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase


class HealthViewTests(APITestCase):
    def test_health_endpoint_is_public(self):
        response = self.client.get(
            reverse("core:health", kwargs={"version": "v1"})
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "ok")
        self.assertEqual(response.data["api_version"], "v1")
