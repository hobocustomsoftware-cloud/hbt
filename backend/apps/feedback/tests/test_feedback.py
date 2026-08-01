from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)

from ..models import Feedback


class FeedbackApiTests(APITestCase):
    def setUp(self):
        self.owner = User.objects.create_user(
            phone_number="+959800000001", password="Strong-pass-123"
        )
        tenant = Tenant.objects.create(name="Feedback", slug="feedback-tests")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Feedback Express",
            display_name="Feedback Express",
            status=Organization.Status.ACTIVE,
        )
        membership = Membership.objects.create(
            organization=self.organization,
            user=self.owner,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.client.force_authenticate(self.owner)

    def test_staff_submits_and_owner_triages_feedback(self):
        created = self.client.post(
            "/api/v1/me/feedback/",
            {
                "organization": str(self.organization.id),
                "source": "business",
                "category": "feature",
                "title": "Faster cargo entry",
                "message": "Remember recent receivers.",
                "language": "en",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        response = self.client.post(
            f"/api/v1/organizations/{self.organization.id}/feedback/"
            f"{created.data['id']}/triage/",
            {
                "status": "planned",
                "priority": "high",
                "owner_response": "Included in roadmap.",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], Feedback.Status.PLANNED)

