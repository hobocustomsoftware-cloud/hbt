from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from apps.identity.models import User
from apps.locations.models import Branch
from apps.tenancy.models import Membership, Organization, Tenant
from apps.workforce.models import DriverProfile, StaffProfile


class DriverEligibilityTests(TestCase):
    def setUp(self):
        user = User.objects.create_user(
            phone_number="+959131313131",
            password="safe-test-password",
        )
        tenant = Tenant.objects.create(name="Workforce", slug="workforce")
        organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Workforce Company",
            display_name="Workforce",
        )
        membership = Membership.objects.create(
            organization=organization,
            user=user,
            status=Membership.Status.ACTIVE,
        )
        branch = Branch.objects.create(
            organization=organization, code="ygn", name="Yangon"
        )
        self.staff = StaffProfile.objects.create(
            membership=membership,
            branch=branch,
            employee_code="D001",
            status=StaffProfile.Status.ACTIVE,
        )

    def test_expired_license_is_not_eligible(self):
        driver = DriverProfile.objects.create(
            staff=self.staff,
            driver_code="DRV001",
            license_number="LIC001",
            license_class="E",
            license_expiry=timezone.localdate() - timedelta(days=1),
            availability=DriverProfile.Availability.AVAILABLE,
            qualifications_verified_at=timezone.now(),
        )
        self.assertFalse(driver.operationally_eligible)

    def test_verified_available_driver_is_eligible(self):
        driver = DriverProfile.objects.create(
            staff=self.staff,
            driver_code="DRV002",
            license_number="LIC002",
            license_class="E",
            license_expiry=timezone.localdate() + timedelta(days=365),
            availability=DriverProfile.Availability.AVAILABLE,
            qualifications_verified_at=timezone.now(),
        )
        self.assertTrue(driver.operationally_eligible)
