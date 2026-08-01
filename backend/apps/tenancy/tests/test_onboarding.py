"""Company onboarding endpoint tests (Owner first-run flow)."""

from rest_framework import status
from rest_framework.test import APITestCase

from apps.branding.models import OrganizationBranding
from apps.identity.models import User
from apps.tenancy.models import Membership, MembershipRole, Organization, Tenant


class CompanyOnboardingTests(APITestCase):
    def test_full_onboarding_creates_company_with_owner(self):
        payload = {
            "company_name": "Ayeyar Express",
            "legal_name": "Ayeyar Express Co., Ltd.",
            "public_slug": "ayeyar-express",
            "name_my": "ဧရာဝတီ အမြန်ခရီး",
            "primary_color": "#0B7A4B",
            "secondary_color": "#FFFFFF",
            "business_type": "bus_operator",
            "default_language": "my",
            "timezone": "Asia/Yangon",
            "currency": "MMK",
            "owner_phone": "+959770000001",
            "owner_password": "Strong-pass-123",
            "owner_first_name": "U",
            "owner_last_name": "Kaung",
        }
        response = self.client.post("/api/v1/onboarding/company/", payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        org = Organization.objects.get(display_name="Ayeyar Express")
        tenant = org.tenant
        self.assertEqual(tenant.primary_language, "my")
        self.assertEqual(tenant.timezone, "Asia/Yangon")
        self.assertEqual(tenant.currency, "MMK")

        branding = OrganizationBranding.objects.get(organization=org)
        self.assertEqual(branding.public_slug, "ayeyar-express")
        self.assertEqual(branding.name_my, "ဧရာဝတီ အမြန်ခရီး")
        self.assertEqual(branding.primary_color, "#0B7A4B")

        owner = User.objects.get(phone_number="+959770000001")
        self.assertTrue(owner.check_password("Strong-pass-123"))
        self.assertEqual(owner.preferred_language, "my")

        membership = Membership.objects.get(organization=org, user=owner)
        self.assertEqual(membership.status, Membership.Status.ACTIVE)
        self.assertTrue(
            MembershipRole.objects.filter(
                membership=membership, role__code="company-owner"
            ).exists()
        )

    def test_onboarding_rejects_existing_owner_phone(self):
        User.objects.create_user(
            phone_number="+959770000002", password="Strong-pass-123"
        )
        payload = {
            "company_name": "Second Co",
            "owner_phone": "+959770000002",
            "owner_password": "Strong-pass-123",
        }
        response = self.client.post("/api/v1/onboarding/company/", payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("owner_phone", response.data)

    def test_onboarding_creates_unique_slug_on_collision(self):
        payload = {
            "company_name": "Collision Co",
            "public_slug": "same-slug",
            "owner_phone": "+959770000003",
            "owner_password": "Strong-pass-123",
        }
        self.client.post("/api/v1/onboarding/company/", payload, format="json")
        payload2 = dict(payload, owner_phone="+959770000004")
        response = self.client.post("/api/v1/onboarding/company/", payload2, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertNotEqual(response.data["public_slug"], "same-slug")

    def test_onboarding_requires_phone_and_password(self):
        response = self.client.post(
            "/api/v1/onboarding/company/", {"company_name": "Minimal Co"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("owner_phone", response.data)
        self.assertIn("owner_password", response.data)
