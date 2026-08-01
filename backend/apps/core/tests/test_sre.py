from unittest.mock import patch

from rest_framework.test import APITestCase


class ReliabilityProbeTests(APITestCase):
    def test_liveness_does_not_depend_on_database_query(self):
        response = self.client.get("/api/v1/health/live/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], "alive")

    def test_readiness_checks_database(self):
        response = self.client.get("/api/v1/health/ready/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["database"], "ok")

    def test_readiness_fails_closed_when_database_is_unavailable(self):
        with patch(
            "apps.core.views.connection.cursor",
            side_effect=RuntimeError("database unavailable"),
        ):
            response = self.client.get("/api/v1/health/ready/")
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.data["status"], "not_ready")

