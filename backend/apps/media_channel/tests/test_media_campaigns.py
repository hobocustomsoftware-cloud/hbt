from datetime import timedelta

from django.core.exceptions import PermissionDenied
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.utils import timezone

from apps.identity.models import User
from apps.subscriptions.models import SubscriptionPlan, TenantSubscription
from apps.tenancy.models import Organization, Tenant

from ..models import MediaCampaign, MediaCreative
from ..services import submit_campaign


class MediaPlanEnforcementTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(name="Media Tenant", slug="media-tenant")
        self.organization = Organization.objects.create(
            tenant=self.tenant,
            legal_name="Media Express Limited",
            display_name="Media Express",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959777200001", password="safe-test-password"
        )

    def campaign(self):
        campaign = MediaCampaign.objects.create(
            organization=self.organization,
            kind=MediaCampaign.Kind.OPERATOR,
            title_my="ခရီးစဉ်အသစ်",
            starts_at=timezone.now(),
            ends_at=timezone.now() + timedelta(days=7),
            created_by=self.user,
        )
        upload = SimpleUploadedFile(
            "banner.png", b"valid-enough-test-data", content_type="image/png"
        )
        MediaCreative.objects.create(
            campaign=campaign,
            kind=MediaCreative.Kind.IMAGE,
            file=upload,
            original_filename=upload.name,
            content_type=upload.content_type,
            size_bytes=upload.size,
        )
        return campaign

    def test_starter_cannot_submit_media_but_growth_can(self):
        starter = SubscriptionPlan.objects.get(code="starter")
        subscription = TenantSubscription.objects.create(
            tenant=self.tenant,
            plan=starter,
            starts_at=timezone.now(),
            current_period_ends_at=timezone.now() + timedelta(days=30),
            changed_by=self.user,
        )
        with self.assertRaises(PermissionDenied):
            submit_campaign(self.campaign(), self.user)
        subscription.plan = SubscriptionPlan.objects.get(code="growth")
        subscription.save(update_fields=["plan", "updated_at"])
        second = self.campaign()
        self.assertEqual(
            submit_campaign(second, self.user).status,
            MediaCampaign.Status.SUBMITTED,
        )

