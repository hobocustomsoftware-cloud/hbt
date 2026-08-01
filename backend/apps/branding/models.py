import uuid
from pathlib import Path

from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization


def branding_upload_path(instance, filename):
    extension = Path(filename).suffix.lower()
    return f"branding/{instance.organization_id}/{uuid.uuid4()}{extension}"


class OrganizationBranding(TimeStampedModel):
    organization = models.OneToOneField(
        Organization, on_delete=models.PROTECT, related_name="branding"
    )
    public_slug = models.SlugField(max_length=120, unique=True)
    name_my = models.CharField(max_length=255)
    name_en = models.CharField(max_length=255, blank=True)
    about_my = models.TextField(blank=True)
    about_en = models.TextField(blank=True)
    logo = models.FileField(upload_to=branding_upload_path, blank=True)
    cover_image = models.FileField(upload_to=branding_upload_path, blank=True)
    primary_color = models.CharField(max_length=7, default="#1F6FEB")
    secondary_color = models.CharField(max_length=7, default="#FFFFFF")
    public_phone = models.CharField(max_length=32, blank=True)
    public_email = models.EmailField(blank=True)
    website_url = models.URLField(blank=True)
    social_links = models.JSONField(default=dict, blank=True)
    is_verified = models.BooleanField(default=False)
    is_published = models.BooleanField(default=True)
    updated_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="organization_branding_updates",
    )

    class Meta:
        db_table = "branding_organization"
        indexes = [
            models.Index(
                fields=["is_published", "is_verified"],
                name="branding_public_verified_idx",
            )
        ]

    def clean(self):
        for field_name in ("primary_color", "secondary_color"):
            value = getattr(self, field_name)
            if len(value) != 7 or not value.startswith("#"):
                raise ValidationError({field_name: "Use a six-digit hex color."})

