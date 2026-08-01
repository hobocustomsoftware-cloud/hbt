from django.db import models

from apps.core.models import TimeStampedModel
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization


class PrintDocument(TimeStampedModel):
    class Type(models.TextChoices):
        TICKET = "ticket", "Ticket"
        PAYMENT_SLIP = "payment_slip", "Payment slip"
        CARGO_RECEIPT = "cargo_receipt", "Cargo receipt"
        CARGO_LABEL = "cargo_label", "Cargo label"
        TRIP_MANIFEST = "trip_manifest", "Trip manifest"
        SETTLEMENT = "settlement", "Settlement"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="print_documents"
    )
    document_type = models.CharField(max_length=20, choices=Type.choices)
    resource_type = models.CharField(max_length=50)
    resource_id = models.UUIDField()
    payload = models.JSONField()
    template_version = models.PositiveIntegerField(default=1)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT
    )
    client_request_id = models.UUIDField(null=True, blank=True, unique=True)
    print_count = models.PositiveIntegerField(default=0)
    last_printed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "operations_print_document"


class PrinterProfile(TimeStampedModel):
    class ConnectionType(models.TextChoices):
        BLUETOOTH = "bluetooth", "Bluetooth"
        NETWORK = "network", "Network"
        USB = "usb", "USB"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="printer_profiles"
    )
    name = models.CharField(max_length=120)
    connection_type = models.CharField(
        max_length=16, choices=ConnectionType.choices
    )
    paper_width_mm = models.PositiveSmallIntegerField(default=80)
    model_name = models.CharField(max_length=120, blank=True)
    character_encoding = models.CharField(max_length=32, default="utf-8")
    capabilities = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "operations_printer_profile"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "name"],
                name="unique_printer_profile_name_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(paper_width_mm__in=[58, 80]),
                name="printer_paper_width_supported",
            ),
        ]


class PrintTemplate(TimeStampedModel):
    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="print_templates"
    )
    document_type = models.CharField(
        max_length=20, choices=PrintDocument.Type.choices
    )
    name = models.CharField(max_length=120)
    version = models.PositiveIntegerField(default=1)
    paper_width_mm = models.PositiveSmallIntegerField(default=80)
    definition = models.JSONField(default=dict)
    active = models.BooleanField(default=True)
    created_by = models.ForeignKey("identity.User", on_delete=models.PROTECT)

    class Meta:
        db_table = "operations_print_template"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "document_type", "version"],
                name="unique_print_template_version_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(paper_width_mm__in=[58, 80]),
                name="template_paper_width_supported",
            ),
        ]


class PrintAttempt(TimeStampedModel):
    class Status(models.TextChoices):
        PRINTED = "printed", "Printed"
        FAILED = "failed", "Failed"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="print_attempts"
    )
    document = models.ForeignKey(
        PrintDocument, on_delete=models.PROTECT, related_name="attempts"
    )
    printer_profile = models.ForeignKey(
        PrinterProfile, on_delete=models.PROTECT, null=True, blank=True
    )
    device_installation_id = models.UUIDField(null=True, blank=True)
    client_attempt_id = models.UUIDField(unique=True)
    status = models.CharField(max_length=12, choices=Status.choices)
    offline = models.BooleanField(default=False)
    failure_reason = models.CharField(max_length=500, blank=True)
    printed_by = models.ForeignKey("identity.User", on_delete=models.PROTECT)
    occurred_at = models.DateTimeField()

    class Meta:
        db_table = "operations_print_attempt"
        constraints = [
            models.CheckConstraint(
                condition=(
                    models.Q(status="printed", failure_reason="")
                    | models.Q(status="failed")
                ),
                name="print_failure_reason_only_on_failure",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "occurred_at"],
                name="print_attempt_org_time_idx",
            )
        ]


class TripClosing(TimeStampedModel):
    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="trip_closings"
    )
    trip = models.OneToOneField(
        Trip, on_delete=models.PROTECT, related_name="closing"
    )
    passenger_count = models.PositiveIntegerField()
    boarded_count = models.PositiveIntegerField()
    cargo_count = models.PositiveIntegerField()
    cargo_handed_over_count = models.PositiveIntegerField()
    unresolved_exception_count = models.PositiveIntegerField()
    summary_snapshot = models.JSONField()
    closed_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT
    )
    closed_at = models.DateTimeField()
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "operations_trip_closing"


class CashSettlement(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending verification"
        VERIFIED = "verified", "Verified"
        APPROVED = "approved", "Approved"
        CLOSED = "closed", "Closed"
        REJECTED = "rejected", "Rejected"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="cash_settlements"
    )
    trip = models.OneToOneField(
        Trip, on_delete=models.PROTECT, related_name="cash_settlement"
    )
    settlement_number = models.CharField(max_length=64)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING
    )
    expected_amount = models.DecimalField(max_digits=14, decimal_places=2)
    actual_amount = models.DecimalField(max_digits=14, decimal_places=2)
    difference_amount = models.DecimalField(max_digits=14, decimal_places=2)
    difference_reason = models.TextField(blank=True)
    submitted_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="submitted_settlements"
    )
    verified_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="verified_settlements"
    )
    approved_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="approved_settlements"
    )
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "operations_cash_settlement"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "settlement_number"],
                name="unique_settlement_number_per_org",
            ),
        ]


class OfflineOperationReceipt(TimeStampedModel):
    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="offline_receipts"
    )
    user = models.ForeignKey("identity.User", on_delete=models.PROTECT)
    client_operation_id = models.UUIDField(unique=True)
    operation_type = models.CharField(max_length=100)
    resource_type = models.CharField(max_length=50)
    resource_id = models.UUIDField(null=True, blank=True)
    request_hash = models.CharField(max_length=64)
    result_snapshot = models.JSONField(default=dict)
    occurred_at = models.DateTimeField()
    synchronized_at = models.DateTimeField()

    class Meta:
        db_table = "operations_offline_receipt"
