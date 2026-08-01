import uuid
from pathlib import Path

from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization


def creative_upload_path(instance, filename):
    extension = Path(filename).suffix.lower()
    return f"media-channel/{instance.campaign_id}/{uuid.uuid4()}{extension}"


class AdvertiserAccount(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending review"
        VERIFIED = "verified", "Verified"
        REJECTED = "rejected", "Rejected"
        SUSPENDED = "suspended", "Suspended"

    owner = models.OneToOneField(
        "identity.User", on_delete=models.PROTECT, related_name="advertiser_account"
    )
    business_name = models.CharField(max_length=255)
    contact_phone = models.CharField(max_length=32)
    contact_email = models.EmailField(blank=True)
    registration_number = models.CharField(max_length=100, blank=True)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.PENDING
    )
    reviewed_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="advertisers_reviewed",
        null=True,
        blank=True,
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "media_advertiser_account"


class MediaCampaign(TimeStampedModel):
    class Kind(models.TextChoices):
        OPERATOR = "operator", "Operator media"
        SPONSORED = "sponsored", "Sponsored advertisement"
        PLATFORM = "platform", "HBT announcement"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        SUBMITTED = "submitted", "Submitted"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        ACTIVE = "active", "Active"
        PAUSED = "paused", "Paused"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    class PaymentStatus(models.TextChoices):
        NOT_REQUIRED = "not_required", "Not required"
        PENDING = "pending", "Pending"
        SUBMITTED = "submitted", "Submitted for verification"
        CONFIRMED = "confirmed", "Confirmed"
        REJECTED = "rejected", "Rejected"

    class Placement(models.TextChoices):
        MEDIA_FEED = "media_feed", "Media feed"
        HOME = "home", "Home"
        ROUTE_RESULTS = "route_results", "Route results"
        OPERATOR_PAGE = "operator_page", "Operator page"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="media_campaigns",
        null=True,
        blank=True,
    )
    advertiser = models.ForeignKey(
        AdvertiserAccount,
        on_delete=models.PROTECT,
        related_name="campaigns",
        null=True,
        blank=True,
    )
    kind = models.CharField(max_length=16, choices=Kind.choices)
    title_my = models.CharField(max_length=180)
    title_en = models.CharField(max_length=180, blank=True)
    body_my = models.TextField(blank=True)
    body_en = models.TextField(blank=True)
    placement = models.CharField(
        max_length=24, choices=Placement.choices, default=Placement.MEDIA_FEED
    )
    call_to_action_url = models.URLField(blank=True)
    targeting = models.JSONField(default=dict, blank=True)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    priority = models.PositiveSmallIntegerField(default=100)
    frequency_cap_per_day = models.PositiveSmallIntegerField(default=3)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.DRAFT
    )
    payment_status = models.CharField(
        max_length=24,
        choices=PaymentStatus.choices,
        default=PaymentStatus.NOT_REQUIRED,
    )
    payment_reference = models.CharField(max_length=160, blank=True)
    review_reason = models.TextField(blank=True)
    created_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="media_campaigns_created",
    )
    reviewed_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="media_campaigns_reviewed",
        null=True,
        blank=True,
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    impressions = models.PositiveBigIntegerField(default=0)
    clicks = models.PositiveBigIntegerField(default=0)

    class Meta:
        db_table = "media_campaign"
        indexes = [
            models.Index(
                fields=["status", "starts_at", "ends_at"],
                name="media_campaign_delivery_idx",
            ),
            models.Index(
                fields=["organization", "status"],
                name="media_campaign_org_idx",
            ),
        ]

    def clean(self):
        if self.ends_at <= self.starts_at:
            raise ValidationError({"ends_at": "End time must follow start time."})
        if bool(self.organization_id) == bool(self.advertiser_id):
            raise ValidationError(
                "A campaign must belong to one operator or one advertiser."
            )
        if self.kind == self.Kind.OPERATOR and not self.organization_id:
            raise ValidationError("Operator media requires an organization.")
        if self.kind == self.Kind.SPONSORED and (
            self.payment_status == self.PaymentStatus.NOT_REQUIRED
        ):
            raise ValidationError("Sponsored media requires payment tracking.")


class MediaCreative(TimeStampedModel):
    class Kind(models.TextChoices):
        IMAGE = "image", "Image"
        VIDEO = "video", "Video"

    campaign = models.ForeignKey(
        MediaCampaign, on_delete=models.CASCADE, related_name="creatives"
    )
    kind = models.CharField(max_length=8, choices=Kind.choices)
    file = models.FileField(upload_to=creative_upload_path)
    original_filename = models.CharField(max_length=255)
    content_type = models.CharField(max_length=120)
    size_bytes = models.PositiveBigIntegerField()
    duration_seconds = models.PositiveSmallIntegerField(null=True, blank=True)
    width = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    poster_image = models.FileField(
        upload_to=creative_upload_path, blank=True
    )
    processing_status = models.CharField(max_length=16, default="ready")

    class Meta:
        db_table = "media_creative"

