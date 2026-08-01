from pathlib import Path

from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field
from apps.core.file_security import scan_upload

from .models import AdvertiserAccount, MediaCampaign, MediaCreative
from .services import submit_campaign


class AdvertiserAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdvertiserAccount
        fields = "__all__"
        read_only_fields = (
            "id", "owner", "status", "reviewed_by", "reviewed_at",
            "created_at", "updated_at",
        )


class MediaCreativeSerializer(serializers.ModelSerializer):
    file = serializers.FileField(write_only=True)
    file_url = serializers.FileField(source="file", read_only=True)

    class Meta:
        model = MediaCreative
        fields = (
            "id", "kind", "file", "file_url", "original_filename",
            "content_type", "size_bytes", "duration_seconds", "width", "height",
            "poster_image", "processing_status", "created_at",
        )
        read_only_fields = (
            "id", "original_filename", "content_type", "size_bytes",
            "processing_status", "created_at",
        )

    def validate(self, data):
        upload = data["file"]
        scan_upload(upload)
        extension = Path(upload.name).suffix.lower()
        content_type = getattr(upload, "content_type", "")
        kind = data["kind"]
        if kind == MediaCreative.Kind.IMAGE:
            if extension not in {".jpg", ".jpeg", ".png", ".webp"} or (
                content_type not in {"image/jpeg", "image/png", "image/webp"}
            ):
                raise serializers.ValidationError("Unsupported image type.")
            if upload.size > 5 * 1024 * 1024:
                raise serializers.ValidationError("Image exceeds 5 MB.")
        else:
            if extension not in {".mp4", ".mov"} or content_type not in {
                "video/mp4", "video/quicktime"
            }:
                raise serializers.ValidationError("Unsupported video type.")
            if not data.get("duration_seconds"):
                raise serializers.ValidationError(
                    {"duration_seconds": "Video duration is required."}
                )
        return data

    def create(self, data):
        upload = data["file"]
        return MediaCreative.objects.create(
            campaign=self.context["campaign"],
            original_filename=upload.name,
            content_type=getattr(upload, "content_type", ""),
            size_bytes=upload.size,
            **data,
        )


class MediaCampaignSerializer(serializers.ModelSerializer):
    creatives = MediaCreativeSerializer(many=True, read_only=True)

    class Meta:
        model = MediaCampaign
        fields = "__all__"
        read_only_fields = (
            "id", "organization", "advertiser", "status", "review_reason",
            "created_by", "reviewed_by", "reviewed_at", "impressions", "clicks",
            "payment_status", "payment_reference", "created_at", "updated_at",
        )

    def validate(self, data):
        instance = MediaCampaign(
            organization=self.context.get("organization"),
            advertiser=self.context.get("advertiser"),
            created_by=self.context["request"].user,
            **data,
        )
        if self.instance:
            instance.pk = self.instance.pk
            for field in self.Meta.model._meta.fields:
                if field.name not in data and hasattr(self.instance, field.name):
                    setattr(instance, field.name, getattr(self.instance, field.name))
        instance.clean()
        return data

    def create(self, data):
        if data.get("kind") == MediaCampaign.Kind.SPONSORED:
            data["payment_status"] = MediaCampaign.PaymentStatus.PENDING
        return MediaCampaign.objects.create(
            organization=self.context.get("organization"),
            advertiser=self.context.get("advertiser"),
            created_by=self.context["request"].user,
            **data,
        )


class PublicMediaCampaignSerializer(serializers.ModelSerializer):
    creatives = MediaCreativeSerializer(many=True, read_only=True)
    operator_slug = serializers.CharField(
        source="organization.branding.public_slug", read_only=True
    )
    sponsored = serializers.SerializerMethodField()

    class Meta:
        model = MediaCampaign
        fields = (
            "id", "kind", "title_my", "title_en", "body_my", "body_en",
            "placement", "call_to_action_url", "starts_at", "ends_at",
            "operator_slug", "sponsored", "creatives",
        )

    @extend_schema_field(serializers.BooleanField)
    def get_sponsored(self, obj):
        return obj.kind == MediaCampaign.Kind.SPONSORED


class CampaignSubmitSerializer(serializers.Serializer):
    def create(self, data):
        return submit_campaign(
            self.context["campaign"], self.context["request"].user
        )


class CampaignReviewSerializer(serializers.Serializer):
    approve = serializers.BooleanField()
    reason = serializers.CharField(required=False, allow_blank=True)


class CampaignPaymentConfirmSerializer(serializers.Serializer):
    payment_reference = serializers.CharField(max_length=160)


class AdvertiserReviewSerializer(serializers.Serializer):
    approve = serializers.BooleanField()
