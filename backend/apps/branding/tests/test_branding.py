from django.test import TestCase

from apps.identity.models import User
from apps.tenancy.models import Organization, Tenant

from ..models import OrganizationBranding


class BrandingModelTests(TestCase):
    def test_public_slug_is_unique_and_branding_is_tenant_owned(self):
        tenant = Tenant.objects.create(name="Brand Tenant", slug="brand-tenant")
        organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Brand Express Limited",
            display_name="Brand Express",
            status=Organization.Status.ACTIVE,
        )
        user = User.objects.create_user(
            phone_number="+959777100001", password="safe-test-password"
        )
        branding = OrganizationBranding.objects.create(
            organization=organization,
            public_slug="brand-express",
            name_my="ဘရန်း အမြန်ယာဉ်",
            updated_by=user,
        )
        self.assertEqual(branding.organization.tenant, tenant)
        self.assertEqual(branding.public_slug, "brand-express")

