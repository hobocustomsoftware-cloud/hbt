from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from .models import (
    CashSettlement,
    PrintAttempt,
    PrintDocument,
    PrinterProfile,
    PrintTemplate,
    TripClosing,
)
from .services import (
    acknowledge_print,
    advance_settlement,
    close_trip,
    create_print_document,
    create_settlement,
)


class PrintDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrintDocument
        fields = "__all__"
        read_only_fields = (
            "organization", "payload", "template_version", "created_by",
            "print_count", "last_printed_at", "created_at", "updated_at",
        )

    def create(self, data):
        try:
            return create_print_document(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class PrinterProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrinterProfile
        fields = "__all__"
        read_only_fields = ("organization", "created_at", "updated_at")


class PrintTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrintTemplate
        fields = "__all__"
        read_only_fields = (
            "organization", "created_by", "created_at", "updated_at"
        )


class PrintAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrintAttempt
        fields = "__all__"
        read_only_fields = (
            "organization", "document", "printed_by", "created_at", "updated_at"
        )
        extra_kwargs = {"client_attempt_id": {"validators": []}}

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        organization = self.context.get("organization")
        if organization is not None:
            self.fields["printer_profile"].queryset = (
                PrinterProfile.objects.filter(organization=organization)
            )

    def validate(self, attrs):
        profile = attrs.get("printer_profile")
        if profile and profile.organization_id != self.context["organization"].id:
            raise serializers.ValidationError(
                {"printer_profile": "Printer profile belongs to another organization."}
            )
        if attrs["status"] == PrintAttempt.Status.FAILED and not attrs.get(
            "failure_reason", ""
        ).strip():
            raise serializers.ValidationError(
                {"failure_reason": "Failure reason is required."}
            )
        return attrs


class TripClosingSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripClosing
        fields = "__all__"


class TripCloseRequestSerializer(serializers.Serializer):
    notes = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        try:
            return close_trip(
                trip=self.context["trip"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class CashSettlementSerializer(serializers.ModelSerializer):
    class Meta:
        model = CashSettlement
        fields = "__all__"


class SettlementCreateSerializer(serializers.Serializer):
    settlement_number = serializers.CharField(max_length=64)
    actual_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    difference_reason = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        try:
            return create_settlement(
                trip=self.context["trip"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class SettlementActionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(
        choices=("verify", "approve", "close", "reject")
    )
    reason = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        try:
            return advance_settlement(
                settlement=self.context["settlement"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class OwnerTripSummarySerializer(serializers.Serializer):
    total = serializers.IntegerField()
    active = serializers.IntegerField()
    closed = serializers.IntegerField()


class OwnerCargoSummarySerializer(serializers.Serializer):
    accepted = serializers.IntegerField()
    in_transit = serializers.IntegerField()
    ready_for_pickup = serializers.IntegerField()
    exceptions = serializers.IntegerField()


class OwnerPaymentSummarySerializer(serializers.Serializer):
    method = serializers.CharField()
    amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    count = serializers.IntegerField()


class OwnerDashboardSerializer(serializers.Serializer):
    date = serializers.DateField()
    data_freshness = serializers.DateTimeField()
    trips = OwnerTripSummarySerializer()
    tickets = serializers.DictField(child=serializers.IntegerField())
    cargo = OwnerCargoSummarySerializer()
    confirmed_payments = OwnerPaymentSummarySerializer(many=True)


class SyncCargoItemSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    shipment_number = serializers.CharField()
    tracking_code = serializers.UUIDField()
    status = serializers.CharField()
    assigned_trip_id = serializers.UUIDField(allow_null=True)
    updated_at = serializers.DateTimeField()


class SyncTripItemSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    trip_number = serializers.CharField()
    status = serializers.CharField()
    service_date = serializers.DateField()
    updated_at = serializers.DateTimeField()


class SyncBootstrapSerializer(serializers.Serializer):
    server_time = serializers.DateTimeField()
    cargo_shipments = SyncCargoItemSerializer(many=True)
    trips = SyncTripItemSerializer(many=True)


class ReportExportQuerySerializer(serializers.Serializer):
    report = serializers.ChoiceField(
        choices=("owner_summary", "trips", "payments", "cargo")
    )
    date = serializers.DateField(required=False)
    date_from = serializers.DateField(required=False)
    date_to = serializers.DateField(required=False)

    def validate(self, attrs):
        date = attrs.get("date")
        start = attrs.get("date_from")
        end = attrs.get("date_to")
        if date:
            attrs["date_from"] = attrs["date_to"] = date
        elif not (start and end):
            raise serializers.ValidationError(
                "Provide date or both date_from and date_to."
            )
        if attrs["date_to"] < attrs["date_from"]:
            raise serializers.ValidationError("date_to must follow date_from.")
        if (attrs["date_to"] - attrs["date_from"]).days > 366:
            raise serializers.ValidationError(
                "Export date range cannot exceed 366 days."
            )
        return attrs


class MonitoringServiceOverviewSerializer(serializers.Serializer):
    generated_at = serializers.DateTimeField()
    active_devices_24h = serializers.IntegerField(min_value=0)
    pending_push_notifications = serializers.IntegerField(min_value=0)
    push_queue_oldest_seconds = serializers.IntegerField(min_value=0)
    pending_work_items = serializers.IntegerField(min_value=0)
    sync_backlog_count = serializers.IntegerField(min_value=0)
    sync_backlog_oldest_seconds = serializers.IntegerField(min_value=0)
    sync_conflicts_24h = serializers.IntegerField(min_value=0)
    payment_reconciliation_backlog = serializers.IntegerField(min_value=0)
    webhook_backlog_count = serializers.IntegerField(min_value=0)
    webhook_backlog_oldest_seconds = serializers.IntegerField(min_value=0)


class MonitoringBusinessReliabilitySerializer(serializers.Serializer):
    bookings_today = serializers.IntegerField(min_value=0)
    expired_bookings_today = serializers.IntegerField(min_value=0)
    active_trips = serializers.IntegerField(min_value=0)
    rejected_boardings_24h = serializers.IntegerField(min_value=0)
    cargo_exceptions_24h = serializers.IntegerField(min_value=0)
    refunds_in_progress = serializers.IntegerField(min_value=0)
    subscription_past_due = serializers.IntegerField(min_value=0)


class MonitoringInfrastructureSerializer(serializers.Serializer):
    database = serializers.CharField()
    disk_free_bytes = serializers.IntegerField(min_value=0)
    backup_age_seconds = serializers.IntegerField(
        min_value=0, allow_null=True
    )
    certificate_expires_in_days = serializers.IntegerField(
        min_value=0, allow_null=True
    )


class MonitoringDashboardSerializer(serializers.Serializer):
    service_overview = MonitoringServiceOverviewSerializer()
    business_reliability = MonitoringBusinessReliabilitySerializer()
    infrastructure = MonitoringInfrastructureSerializer()


class MonitoringAlertSerializer(serializers.Serializer):
    code = serializers.CharField()
    severity = serializers.ChoiceField(
        choices=("info", "warning", "critical")
    )
    status = serializers.ChoiceField(
        choices=("ok", "triggered", "unavailable")
    )
    threshold = serializers.CharField()
    value = serializers.CharField()
    message = serializers.CharField()


class MonitoringAlertListSerializer(serializers.Serializer):
    generated_at = serializers.DateTimeField()
    alerts = MonitoringAlertSerializer(many=True)
