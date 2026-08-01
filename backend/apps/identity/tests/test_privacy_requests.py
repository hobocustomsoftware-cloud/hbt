from rest_framework.test import APITestCase

from apps.identity.models import DataSubjectRequest, PlatformAccessGrant, User


class PrivacyRequestApiTests(APITestCase):
    def setUp(self):
        self.requester = User.objects.create_user(
            phone_number="+959700000001", password="Strong-pass-123"
        )
        self.reviewer = User.objects.create_user(
            phone_number="+959700000002", password="Strong-pass-456"
        )
        self.grantor = User.objects.create_superuser(
            phone_number="+959700000003", password="Strong-pass-789"
        )
        PlatformAccessGrant.objects.create(
            user=self.reviewer,
            role=PlatformAccessGrant.Role.SECURITY,
            granted_by=self.grantor,
            reason="Privacy operations assignment",
        )

    def submit(self, request_type="deletion"):
        self.client.force_authenticate(self.requester)
        return self.client.post(
            "/api/v1/auth/me/privacy-requests/",
            {
                "request_type": request_type,
                "details": "Please process my request.",
            },
            format="json",
        )

    def test_requester_can_submit_and_cannot_duplicate_active_type(self):
        response = self.submit()
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["status"], DataSubjectRequest.Status.SUBMITTED)
        self.assertGreater(
            DataSubjectRequest.objects.get(pk=response.data["id"]).due_at,
            DataSubjectRequest.objects.get(pk=response.data["id"]).created_at,
        )
        repeated = self.submit()
        self.assertEqual(repeated.status_code, 400)

    def test_ordinary_user_cannot_review_requests(self):
        item_id = self.submit("access").data["id"]
        self.client.force_authenticate(self.requester)
        response = self.client.post(
            f"/api/v1/auth/platform/privacy-requests/{item_id}/action/",
            {"action": "verify", "verification_method": "verified-phone"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_privacy_reviewer_lifecycle_requires_deletion_evidence(self):
        item_id = self.submit().data["id"]
        self.client.force_authenticate(self.reviewer)
        verify = self.client.post(
            f"/api/v1/auth/platform/privacy-requests/{item_id}/action/",
            {"action": "verify", "verification_method": "verified-phone"},
            format="json",
        )
        self.assertEqual(verify.status_code, 200)
        start = self.client.post(
            f"/api/v1/auth/platform/privacy-requests/{item_id}/action/",
            {"action": "start"},
            format="json",
        )
        self.assertEqual(start.status_code, 200)
        missing_evidence = self.client.post(
            f"/api/v1/auth/platform/privacy-requests/{item_id}/action/",
            {"action": "fulfill", "reason": "Anonymized eligible data."},
            format="json",
        )
        self.assertEqual(missing_evidence.status_code, 400)
        fulfilled = self.client.post(
            f"/api/v1/auth/platform/privacy-requests/{item_id}/action/",
            {
                "action": "fulfill",
                "reason": "Anonymized eligible data; finance records retained.",
                "retention_hold": True,
                "evidence_reference": "PRIVACY-EVIDENCE-001",
            },
            format="json",
        )
        self.assertEqual(fulfilled.status_code, 200)
        self.assertEqual(
            fulfilled.data["status"], DataSubjectRequest.Status.FULFILLED
        )
        self.assertTrue(fulfilled.data["retention_hold"])

    def test_requester_cannot_review_own_request_even_with_platform_grant(self):
        item_id = self.submit("correction").data["id"]
        PlatformAccessGrant.objects.create(
            user=self.requester,
            role=PlatformAccessGrant.Role.SECURITY,
            granted_by=self.grantor,
            reason="Temporary privacy assignment",
        )
        self.client.force_authenticate(self.requester)
        response = self.client.post(
            f"/api/v1/auth/platform/privacy-requests/{item_id}/action/",
            {"action": "verify", "verification_method": "verified-phone"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_self_data_export_excludes_credentials(self):
        self.client.force_authenticate(self.requester)
        response = self.client.get("/api/v1/auth/me/data-export/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["user"]["id"], str(self.requester.id))
        self.assertNotIn("password", response.data["user"])
        self.assertIn("bookings", response.data)
        self.assertIn("notifications", response.data)
