from pathlib import Path

from rest_framework import serializers
from apps.core.file_security import scan_upload

from .models import OrganizationBranding

ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_LOGO_BYTES = 2 * 1024 * 1024
MAX_COVER_BYTES = 5 * 1024 * 1024


class OrganizationBrandingSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = OrganizationBranding
        fields = "__all__"
        read_only_fields = (
            "id", "organization", "is_verified", "updated_by",
            "created_at", "updated_at",
        )

    def validate_logo(self, upload):
        return self._validate_image(upload, MAX_LOGO_BYTES)

    def validate_cover_image(self, upload):
        return self._validate_image(upload, MAX_COVER_BYTES)

    @staticmethod
    def _validate_image(upload, max_bytes):
        scan_upload(upload)
        extension = Path(upload.name).suffix.lower()
        content_type = getattr(upload, "content_type", "")
        if (
            extension not in ALLOWED_IMAGE_EXTENSIONS
            or content_type not in ALLOWED_IMAGE_TYPES
        ):
            raise serializers.ValidationError(
                "Only JPEG, PNG and WebP images are accepted."
            )
        if upload.size > max_bytes:
            raise serializers.ValidationError("The image exceeds its size limit.")
        return upload

    def validate(self, data):
        instance = OrganizationBranding(
            organization=self.context["organization"],
            updated_by=self.context["request"].user,
            **{
                field: value
                for field, value in data.items()
                if field not in ("logo", "cover_image")
            },
        )
        if self.instance:
            instance.pk = self.instance.pk
            for field in self.Meta.model._meta.fields:
                if field.name not in data and hasattr(self.instance, field.name):
                    setattr(instance, field.name, getattr(self.instance, field.name))
        instance.clean()
        return data


class PublicOrganizationBrandingSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = OrganizationBranding
        fields = (
            "organization_id", "public_slug", "name_my", "name_en",
            "about_my", "about_en", "logo", "cover_image", "primary_color",
            "secondary_color", "public_phone", "public_email", "website_url",
            "social_links", "is_verified",
        )
