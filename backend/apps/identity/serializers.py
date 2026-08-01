import hashlib

from django.contrib.auth import authenticate
from django.conf import settings
from django.db import IntegrityError, transaction
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from apps.audit.services import record_audit_event

from .models import DataSubjectRequest, User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id",
            "phone_number",
            "email",
            "first_name",
            "last_name",
            "status",
            "preferred_language",
            "phone_verified_at",
            "email_verified_at",
            "date_joined",
        )
        read_only_fields = (
            "id",
            "phone_number",
            "status",
            "phone_verified_at",
            "email_verified_at",
            "date_joined",
        )

    def update(self, instance, validated_data):
        previous_email = instance.email
        instance = super().update(instance, validated_data)
        if instance.email != previous_email:
            instance.email_verified_at = None
            instance.save(update_fields=["email_verified_at"])
        return instance


class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
        style={"input_type": "password"},
    )

    class Meta:
        model = User
        fields = (
            "id",
            "phone_number",
            "password",
            "email",
            "first_name",
            "last_name",
            "preferred_language",
        )
        read_only_fields = ("id",)

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(
            password=password,
            status=User.Status.ACTIVE,
            **validated_data,
        )
        record_audit_event(
            actor=user,
            action="identity.registered",
            resource_type="user",
            resource_id=user.id,
            after={"status": user.status},
        )
        return user


class HBTTokenObtainPairSerializer(TokenObtainPairSerializer):
    def record_failure(self, phone_number, reason):
        digest = hashlib.sha256(
            f"{settings.SECRET_KEY}:{phone_number}".encode()
        ).hexdigest()
        record_audit_event(
            action="authentication.login_failed",
            resource_type="session",
            metadata={
                "identifier_digest": digest,
                "reason": reason,
            },
        )

    def validate(self, attrs):
        phone_number = attrs.get(self.username_field, "")
        user = authenticate(
            request=self.context.get("request"),
            phone_number=phone_number,
            password=attrs.get("password"),
        )
        if user and user.status != User.Status.ACTIVE:
            self.record_failure(phone_number, "account_inactive")
            raise serializers.ValidationError(
                {"detail": "This account is not active."},
                code="account_inactive",
            )

        try:
            data = super().validate(attrs)
        except AuthenticationFailed:
            self.record_failure(phone_number, "invalid_credentials")
            raise
        record_audit_event(
            actor=self.user,
            action="authentication.login_succeeded",
            resource_type="session",
            metadata={"method": "phone_password"},
        )
        return data


class DataSubjectRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = DataSubjectRequest
        fields = "__all__"
        read_only_fields = (
            "user", "status", "jurisdiction", "due_at",
            "verification_method", "verified_at", "retention_hold",
            "retention_reason", "response_summary", "evidence_reference",
            "reviewed_by", "resolved_at", "created_at", "updated_at",
        )

    def validate_request_type(self, value):
        request = self.context.get("request")
        if request and DataSubjectRequest.objects.filter(
            user=request.user,
            request_type=value,
            status__in=(
                DataSubjectRequest.Status.SUBMITTED,
                DataSubjectRequest.Status.VERIFIED,
                DataSubjectRequest.Status.IN_PROGRESS,
            ),
        ).exists():
            raise serializers.ValidationError(
                "An active request of this type already exists."
            )
        return value

    def create(self, validated_data):
        try:
            with transaction.atomic():
                return DataSubjectRequest.objects.create(**validated_data)
        except IntegrityError as exc:
            raise serializers.ValidationError(
                "An active request of this type already exists."
            ) from exc


class PrivacyRequestActionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(
        choices=("verify", "start", "fulfill", "reject")
    )
    reason = serializers.CharField(required=False, allow_blank=True)
    verification_method = serializers.CharField(
        required=False, allow_blank=True, max_length=80
    )
    retention_hold = serializers.BooleanField(required=False, default=False)
    evidence_reference = serializers.CharField(
        required=False, allow_blank=True, max_length=255
    )

    def validate(self, attrs):
        action = attrs["action"]
        if action == "verify" and not attrs.get("verification_method", "").strip():
            raise serializers.ValidationError(
                {"verification_method": "Verification method is required."}
            )
        if action in ("fulfill", "reject") and not attrs.get("reason", "").strip():
            raise serializers.ValidationError(
                {"reason": "Resolution reason/summary is required."}
            )
        if attrs.get("retention_hold") and not attrs.get("reason", "").strip():
            raise serializers.ValidationError(
                {"reason": "Retention hold requires a reason."}
            )
        if (
            action == "fulfill"
            and self.context["privacy_request"].request_type
            == DataSubjectRequest.Type.DELETION
            and not attrs.get("evidence_reference", "").strip()
        ):
            raise serializers.ValidationError(
                {
                    "evidence_reference":
                    "Deletion fulfillment requires erasure/anonymization evidence."
                }
            )
        return attrs


class UserDataExportSerializer(serializers.Serializer):
    generated_at = serializers.DateTimeField()
    user = UserSerializer()
    memberships = serializers.JSONField()
    bookings = serializers.JSONField()
    tickets = serializers.JSONField()
    notifications = serializers.JSONField()
    limits = serializers.JSONField()
