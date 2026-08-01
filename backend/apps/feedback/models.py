from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization


class Feedback(TimeStampedModel):
    class Category(models.TextChoices):
        FEATURE = "feature", "Feature request"
        USABILITY = "usability", "Usability"
        BUG = "bug", "Bug"
        SERVICE = "service", "Service"
        SECURITY = "security", "Private security report"
        OTHER = "other", "Other"

    class Status(models.TextChoices):
        NEW = "new", "New"
        REVIEWING = "reviewing", "Reviewing"
        PLANNED = "planned", "Planned"
        RESOLVED = "resolved", "Resolved"
        DECLINED = "declined", "Declined"
        DUPLICATE = "duplicate", "Duplicate"

    class Source(models.TextChoices):
        PASSENGER = "passenger", "HBT Passenger"
        BUSINESS = "business", "HBT Business"
        WEB = "web", "Website"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="feedback_items",
        null=True,
        blank=True,
    )
    submitted_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="feedback_submitted",
    )
    source = models.CharField(max_length=16, choices=Source.choices)
    category = models.CharField(max_length=16, choices=Category.choices)
    title = models.CharField(max_length=160)
    message = models.TextField()
    language = models.CharField(max_length=10, default="my")
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.NEW
    )
    priority = models.CharField(max_length=16, default="normal")
    app_version = models.CharField(max_length=32, blank=True)
    device_context = models.JSONField(default=dict, blank=True)
    owner_response = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="feedback_reviewed",
        null=True,
        blank=True,
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "feedback_item"
        indexes = [
            models.Index(
                fields=["organization", "status", "created_at"],
                name="feedback_org_status_idx",
            )
        ]

