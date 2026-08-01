from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from apps.bookings.models import BookingPassenger

from .models import (
    PaymentReceivingAccount,
    PaymentReceivingAccountVersion,
    PaymentRecord,
    PrivatePaymentUpload,
    RefundPolicy,
    RefundRequest,
    InvoicePaymentAllocation,
    PaymentConnector,
    PaymentIntent,
    PaymentWebhookEvent,
)
from .services import (
    complete_refund,
    create_payment,
    decide_payment,
    decide_refund,
    mark_refund_paid,
    request_refund,
    store_private_upload,
    initiate_provider_payment,
    save_payment_connector,
    test_payment_connector,
    rotate_payment_connector,
    disable_payment_connector,
)


class PrivatePaymentUploadSerializer(serializers.ModelSerializer):
    file = serializers.FileField(write_only=True)

    class Meta:
        model = PrivatePaymentUpload
        fields = (
            "id", "purpose", "file", "original_filename", "content_type",
            "size_bytes", "sha256", "created_at",
        )
        read_only_fields = (
            "id", "original_filename", "content_type", "size_bytes", "sha256",
            "created_at",
        )

    def create(self, data):
        try:
            return store_private_upload(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                file=data["file"],
                purpose=data["purpose"],
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class PaymentReceivingAccountVersionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentReceivingAccountVersion
        fields = (
            "id", "version", "display_label", "qr_upload", "effective_from",
            "effective_until", "created_at",
        )
        read_only_fields = ("id", "created_at")


class PaymentReceivingAccountSerializer(serializers.ModelSerializer):
    versions = PaymentReceivingAccountVersionSerializer(many=True, read_only=True)
    account_identifier_masked = serializers.SerializerMethodField()

    class Meta:
        model = PaymentReceivingAccount
        fields = (
            "id", "account_code", "account_type", "provider_name",
            "account_name", "account_identifier", "account_identifier_masked",
            "status", "branch", "terminal_operation", "counter",
            "business_justification", "approved_by", "approved_at",
            "versions", "created_at", "updated_at",
        )
        read_only_fields = ("id", "approved_by", "approved_at", "created_at", "updated_at")
        extra_kwargs = {"account_identifier": {"write_only": True}}

    @extend_schema_field(serializers.CharField)
    def get_account_identifier_masked(self, obj):
        value = obj.account_identifier
        return f"{'*' * max(len(value) - 4, 0)}{value[-4:]}"

    def create(self, data):
        account = PaymentReceivingAccount(
            organization=self.context["organization"],
            created_by=self.context["request"].user,
            **data,
        )
        account.full_clean()
        account.save()
        return account

    def update(self, instance, data):
        if instance.status == PaymentReceivingAccount.Status.ARCHIVED:
            raise serializers.ValidationError("Archived accounts are immutable.")
        for field, value in data.items():
            setattr(instance, field, value)
        instance.full_clean()
        instance.save()
        return instance


class PaymentRecordSerializer(serializers.ModelSerializer):
    evidence_status = serializers.CharField(source="evidence.status", read_only=True)
    evidence_upload = serializers.PrimaryKeyRelatedField(
        queryset=PrivatePaymentUpload.objects.filter(
            purpose=PrivatePaymentUpload.Purpose.PAYMENT_EVIDENCE
        ),
        write_only=True,
        required=False,
    )
    class Meta:
        model = PaymentRecord
        fields = "__all__"
        read_only_fields = (
            "organization", "status", "recorded_by", "confirmed_by",
            "confirmed_at", "rejection_reason", "created_at", "updated_at",
        )

    def create(self, data):
        try:
            return create_payment(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            if hasattr(exc, "message_dict"):
                raise serializers.ValidationError(exc.message_dict) from exc
            raise serializers.ValidationError(exc.messages) from exc


class PaymentDecisionSerializer(serializers.Serializer):
    class TicketAllocationSerializer(serializers.Serializer):
        booking_passenger = serializers.PrimaryKeyRelatedField(
            queryset=BookingPassenger.objects.all()
        )
        ticket_number = serializers.CharField(max_length=64)
        ticket_type = serializers.CharField(max_length=16)
        fare_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
        discount_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
        tax_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
        service_charge = serializers.DecimalField(max_digits=12, decimal_places=2)
        total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
        currency = serializers.CharField(max_length=3, default="MMK")
        issuing_channel = serializers.CharField(max_length=16)

    approve = serializers.BooleanField()
    reason = serializers.CharField(required=False, allow_blank=True)
    tickets = TicketAllocationSerializer(many=True, required=False)

    def create(self, data):
        try:
            return decide_payment(
                payment=self.context["payment"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class RefundPolicySerializer(serializers.ModelSerializer):
    class Meta:
        model = RefundPolicy
        fields = (
            "id", "enabled", "refund_window_hours", "refund_percentage",
            "fixed_fee", "approval_threshold", "configured_by",
            "created_at", "updated_at",
        )
        read_only_fields = (
            "id", "configured_by", "created_at", "updated_at",
        )

    def create(self, data):
        policy, _ = RefundPolicy.objects.update_or_create(
            organization=self.context["organization"],
            defaults={
                **data,
                "configured_by": self.context["request"].user,
            },
        )
        policy.full_clean()
        policy.save()
        return policy

    def update(self, instance, data):
        for field, value in data.items():
            setattr(instance, field, value)
        instance.configured_by = self.context["request"].user
        instance.full_clean()
        instance.save()
        return instance


class RefundRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = RefundRequest
        fields = "__all__"
        read_only_fields = (
            "organization", "status", "policy_snapshot", "requested_by",
            "approved_amount", "decided_by", "decided_at", "decision_reason",
            "paid_by", "paid_at", "payout_reference", "completed_at",
            "created_at", "updated_at",
        )

    def create(self, data):
        try:
            return request_refund(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class RefundDecisionSerializer(serializers.Serializer):
    approve = serializers.BooleanField()
    approved_amount = serializers.DecimalField(
        max_digits=14, decimal_places=2, required=False
    )
    reason = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        try:
            return decide_refund(
                refund=self.context["refund"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class RefundPaidSerializer(serializers.Serializer):
    payout_reference = serializers.CharField(max_length=255)

    def create(self, data):
        try:
            return mark_refund_paid(
                refund=self.context["refund"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class RefundCompleteSerializer(serializers.Serializer):
    def create(self, data):
        try:
            return complete_refund(
                refund=self.context["refund"],
                actor=self.context["request"].user,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class InvoicePaymentAllocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoicePaymentAllocation
        fields = (
            "id", "invoice", "payment", "amount", "allocated_by", "created_at",
        )
        read_only_fields = fields


class PaymentConnectorSerializer(serializers.ModelSerializer):
    credentials = serializers.JSONField(write_only=True, required=False)
    webhook_secret = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = PaymentConnector
        fields = (
            "id", "code", "adapter", "environment", "status", "merchant_id",
            "credentials", "webhook_secret", "credential_version",
            "last_tested_at", "last_test_succeeded", "created_by",
            "created_at", "updated_at",
        )
        read_only_fields = (
            "id", "last_tested_at", "last_test_succeeded", "created_by",
            "created_at", "updated_at",
        )

    def _save(self, instance, data):
        credentials = data.pop("credentials", None)
        webhook_secret = data.pop("webhook_secret", None)
        try:
            return save_payment_connector(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                instance=instance,
                credentials=credentials,
                webhook_secret=webhook_secret,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc

    def create(self, data):
        return self._save(None, data)

    def update(self, instance, data):
        return self._save(instance, data)


class PaymentIntentSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentIntent
        fields = (
            "id", "connector", "payment", "idempotency_key", "status",
            "provider_reference", "checkout_payload", "last_error_code",
            "created_at", "updated_at",
        )
        read_only_fields = (
            "id", "status", "provider_reference", "checkout_payload",
            "last_error_code", "created_at", "updated_at",
        )

    def create(self, data):
        connector = data.pop("connector")
        payment = data.pop("payment")
        try:
            return initiate_provider_payment(
                connector=connector,
                payment=payment,
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class PaymentWebhookEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentWebhookEvent
        fields = (
            "id", "event_id", "status", "payload_sha256", "reason",
            "processed_at", "created_at",
        )
        read_only_fields = fields


class PaymentConnectorRotationSerializer(serializers.Serializer):
    credentials = serializers.JSONField()
    webhook_secret = serializers.CharField()

    def create(self, data):
        try:
            return rotate_payment_connector(
                connector=self.context["connector"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class PaymentConnectorDisableSerializer(serializers.Serializer):
    reason = serializers.CharField()

    def create(self, data):
        try:
            return disable_payment_connector(
                connector=self.context["connector"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class PaymentOptionSerializer(serializers.Serializer):
    account_version_id = serializers.UUIDField()
    provider_name = serializers.CharField()
    account_name = serializers.CharField()
    account_identifier_masked = serializers.CharField()
    display_label = serializers.CharField()
    has_qr = serializers.BooleanField()
