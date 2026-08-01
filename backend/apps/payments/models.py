import uuid

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from apps.bookings.models import Booking
from apps.cargo.models import CargoShipment
from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization
from .storage import PrivatePaymentStorage

private_payment_storage = PrivatePaymentStorage()


def payment_upload_path(instance, filename):
    extension = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"
    return (
        f"payments/{instance.organization_id}/"
        f"{timezone.now():%Y/%m}/{uuid.uuid4().hex}.{extension}"
    )


class PaymentReceivingAccount(TimeStampedModel):
    class Type(models.TextChoices):
        MERCHANT = "merchant", "Merchant account"
        PERSONAL = "personal", "Approved personal wallet"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        ARCHIVED = "archived", "Archived"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="payment_accounts"
    )
    account_code = models.SlugField(max_length=50)
    account_type = models.CharField(max_length=16, choices=Type.choices)
    provider_name = models.CharField(max_length=100)
    account_name = models.CharField(max_length=150)
    account_identifier = models.CharField(max_length=100)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.DRAFT
    )
    branch = models.ForeignKey(
        "locations.Branch", on_delete=models.PROTECT, null=True, blank=True
    )
    terminal_operation = models.ForeignKey(
        "locations.CompanyTerminalOperation",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
    )
    counter = models.ForeignKey(
        "locations.SalesCounter", on_delete=models.PROTECT, null=True, blank=True
    )
    business_justification = models.TextField(blank=True)
    approved_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="approved_payment_accounts"
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="created_payment_accounts"
    )

    class Meta:
        db_table = "payments_receiving_account"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "account_code"],
                name="unique_payment_account_code_per_org",
            )
        ]

    def clean(self):
        if self.branch_id and self.branch.organization_id != self.organization_id:
            raise ValidationError("Branch belongs to another organization.")
        if (
            self.terminal_operation_id
            and self.terminal_operation.organization_id != self.organization_id
        ):
            raise ValidationError("Terminal operation belongs to another organization.")
        if self.counter_id and self.counter.organization_id != self.organization_id:
            raise ValidationError("Counter belongs to another organization.")
        if self.account_type == self.Type.PERSONAL and self.status == self.Status.ACTIVE:
            if not self.business_justification.strip() or not self.approved_by_id:
                raise ValidationError(
                    "An active personal wallet requires justification and approval."
                )


class PrivatePaymentUpload(TimeStampedModel):
    class Purpose(models.TextChoices):
        PAYMENT_EVIDENCE = "payment_evidence", "Payment evidence"
        ACCOUNT_QR = "account_qr", "Receiving account QR"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="payment_uploads"
    )
    purpose = models.CharField(max_length=24, choices=Purpose.choices)
    file = models.FileField(storage=private_payment_storage, upload_to=payment_upload_path)
    original_filename = models.CharField(max_length=255)
    content_type = models.CharField(max_length=100)
    size_bytes = models.PositiveIntegerField()
    sha256 = models.CharField(max_length=64)
    uploaded_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="private_payment_uploads"
    )

    class Meta:
        db_table = "payments_private_upload"


class PaymentReceivingAccountVersion(TimeStampedModel):
    account = models.ForeignKey(
        PaymentReceivingAccount, on_delete=models.PROTECT, related_name="versions"
    )
    version = models.PositiveIntegerField()
    display_label = models.CharField(max_length=150)
    qr_upload = models.ForeignKey(
        PrivatePaymentUpload, on_delete=models.PROTECT, null=True, blank=True
    )
    effective_from = models.DateTimeField(default=timezone.now)
    effective_until = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="created_payment_account_versions"
    )

    class Meta:
        db_table = "payments_receiving_account_version"
        constraints = [
            models.UniqueConstraint(
                fields=["account", "version"],
                name="unique_payment_account_version",
            )
        ]

    def clean(self):
        if self.qr_upload_id:
            if self.qr_upload.organization_id != self.account.organization_id:
                raise ValidationError("QR upload belongs to another organization.")
            if self.qr_upload.purpose != PrivatePaymentUpload.Purpose.ACCOUNT_QR:
                raise ValidationError("Upload is not an account QR.")


class PaymentRecord(TimeStampedModel):
    class Method(models.TextChoices):
        CASH = "cash", "Cash"
        WALLET_QR = "wallet_qr", "Wallet QR"
        BANK_TRANSFER = "bank_transfer", "Bank transfer"
        CORPORATE_CREDIT = "corporate_credit", "Corporate credit"

    class Status(models.TextChoices):
        RECORDED = "recorded", "Recorded"
        SUBMITTED = "submitted", "Awaiting verification"
        CONFIRMED = "confirmed", "Confirmed"
        REJECTED = "rejected", "Rejected"
        CANCELLED = "cancelled", "Cancelled"
        REFUNDED = "refunded", "Refunded"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="payment_records"
    )
    payment_number = models.CharField(max_length=64)
    booking = models.ForeignKey(
        Booking, on_delete=models.PROTECT, null=True, blank=True,
        related_name="payment_records"
    )
    cargo_shipment = models.ForeignKey(
        CargoShipment, on_delete=models.PROTECT, null=True, blank=True,
        related_name="payment_records"
    )
    corporate_invoice = models.ForeignKey(
        "bookings.CorporateInvoice",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="payment_records",
    )
    method = models.CharField(max_length=20, choices=Method.choices)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.RECORDED
    )
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    currency = models.CharField(max_length=3, default="MMK")
    provider_name = models.CharField(max_length=100, blank=True)
    transaction_reference = models.CharField(max_length=255, blank=True)
    payer_reference = models.CharField(max_length=255, blank=True)
    receiving_account_version = models.ForeignKey(
        PaymentReceivingAccountVersion,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="payments",
    )
    paid_at = models.DateTimeField(null=True, blank=True)
    recorded_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="recorded_payments"
    )
    confirmed_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="confirmed_payments"
    )
    confirmed_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.TextField(blank=True)
    client_request_id = models.UUIDField(null=True, blank=True, unique=True)

    class Meta:
        db_table = "payments_payment_record"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "payment_number"],
                name="unique_payment_number_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(amount__gt=0),
                name="payment_amount_positive",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(
                        booking__isnull=False,
                        cargo_shipment__isnull=True,
                        corporate_invoice__isnull=True,
                    )
                    | models.Q(
                        booking__isnull=True,
                        cargo_shipment__isnull=False,
                        corporate_invoice__isnull=True,
                    )
                    | models.Q(
                        booking__isnull=True,
                        cargo_shipment__isnull=True,
                        corporate_invoice__isnull=False,
                    )
                ),
                name="payment_exactly_one_business_target",
            ),
            models.UniqueConstraint(
                fields=["organization", "provider_name", "transaction_reference"],
                condition=~models.Q(transaction_reference=""),
                name="unique_provider_payment_reference_per_org",
            ),
        ]

    @property
    def immutable(self):
        return self.status in (
            self.Status.CONFIRMED, self.Status.REFUNDED
        )


class PaymentEvidence(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending verification"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"

    payment = models.OneToOneField(
        PaymentRecord, on_delete=models.PROTECT, related_name="evidence"
    )
    upload = models.OneToOneField(
        PrivatePaymentUpload, on_delete=models.PROTECT, related_name="evidence"
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.PENDING
    )
    submitted_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="submitted_payment_evidence"
    )
    verified_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="verified_payment_evidence"
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    verification_note = models.TextField(blank=True)

    class Meta:
        db_table = "payments_payment_evidence"

    def clean(self):
        if self.upload.organization_id != self.payment.organization_id:
            raise ValidationError("Evidence belongs to another organization.")
        if self.upload.purpose != PrivatePaymentUpload.Purpose.PAYMENT_EVIDENCE:
            raise ValidationError("Upload is not payment evidence.")


class RefundPolicy(TimeStampedModel):
    organization = models.OneToOneField(
        Organization, on_delete=models.PROTECT, related_name="refund_policy"
    )
    enabled = models.BooleanField(default=True)
    refund_window_hours = models.PositiveIntegerField(default=24)
    refund_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=100
    )
    fixed_fee = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    approval_threshold = models.DecimalField(
        max_digits=14, decimal_places=2, default=0
    )
    configured_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="configured_refund_policies",
    )

    class Meta:
        db_table = "payments_refund_policy"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(refund_percentage__gte=0)
                & models.Q(refund_percentage__lte=100),
                name="refund_percentage_between_zero_and_hundred",
            ),
            models.CheckConstraint(
                condition=models.Q(fixed_fee__gte=0)
                & models.Q(approval_threshold__gte=0),
                name="refund_policy_amounts_nonnegative",
            ),
        ]


class RefundRequest(TimeStampedModel):
    class Status(models.TextChoices):
        REQUESTED = "requested", "Requested"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        PAID = "paid", "Paid"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="refund_requests"
    )
    payment = models.ForeignKey(
        PaymentRecord, on_delete=models.PROTECT, related_name="refund_requests"
    )
    ticket = models.ForeignKey(
        "ticketing.Ticket",
        on_delete=models.PROTECT,
        related_name="refund_requests",
        null=True,
        blank=True,
    )
    refund_number = models.CharField(max_length=64)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.REQUESTED
    )
    requested_amount = models.DecimalField(max_digits=14, decimal_places=2)
    approved_amount = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    currency = models.CharField(max_length=3, default="MMK")
    reason = models.TextField()
    policy_snapshot = models.JSONField(default=dict)
    requested_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="refunds_requested",
    )
    decided_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="refunds_decided",
        null=True,
        blank=True,
    )
    decided_at = models.DateTimeField(null=True, blank=True)
    decision_reason = models.TextField(blank=True)
    paid_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="refunds_paid",
        null=True,
        blank=True,
    )
    paid_at = models.DateTimeField(null=True, blank=True)
    payout_reference = models.CharField(max_length=255, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    client_request_id = models.UUIDField(null=True, blank=True, unique=True)

    class Meta:
        db_table = "payments_refund_request"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "refund_number"],
                name="unique_refund_number_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(requested_amount__gt=0),
                name="refund_requested_amount_positive",
            ),
            models.CheckConstraint(
                condition=models.Q(approved_amount__isnull=True)
                | models.Q(approved_amount__gt=0),
                name="refund_approved_amount_positive_or_null",
            ),
            models.UniqueConstraint(
                fields=["organization", "payout_reference"],
                condition=~models.Q(payout_reference=""),
                name="unique_refund_payout_reference_per_org",
            ),
        ]

    def clean(self):
        if self.payment_id and self.payment.organization_id != self.organization_id:
            raise ValidationError("Payment belongs to another organization.")
        if self.ticket_id:
            if self.ticket.organization_id != self.organization_id:
                raise ValidationError("Ticket belongs to another organization.")
            if self.payment.booking_id != self.ticket.booking_id:
                raise ValidationError("Ticket does not belong to the payment booking.")


class InvoicePaymentAllocation(TimeStampedModel):
    invoice = models.ForeignKey(
        "bookings.CorporateInvoice",
        on_delete=models.PROTECT,
        related_name="payment_allocations",
    )
    payment = models.ForeignKey(
        PaymentRecord, on_delete=models.PROTECT, related_name="invoice_allocations"
    )
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    allocated_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="invoice_payment_allocations",
    )

    class Meta:
        db_table = "payments_invoice_allocation"
        constraints = [
            models.UniqueConstraint(
                fields=["invoice", "payment"],
                name="unique_invoice_payment_allocation",
            ),
            models.CheckConstraint(
                condition=models.Q(amount__gt=0),
                name="invoice_allocation_amount_positive",
            ),
        ]

    def clean(self):
        if self.invoice.organization_id != self.payment.organization_id:
            raise ValidationError("Invoice and payment belong to different organizations.")
        if self.payment.corporate_invoice_id != self.invoice_id:
            raise ValidationError("Payment target does not match the invoice.")


class PaymentConnector(TimeStampedModel):
    class Environment(models.TextChoices):
        SANDBOX = "sandbox", "Sandbox"
        PRODUCTION = "production", "Production"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        ACTIVE = "active", "Active"
        DISABLED = "disabled", "Disabled"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="payment_connectors"
    )
    code = models.SlugField(max_length=50)
    adapter = models.CharField(max_length=100)
    environment = models.CharField(max_length=16, choices=Environment.choices)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.DRAFT
    )
    merchant_id = models.CharField(max_length=255)
    encrypted_credentials = models.TextField()
    webhook_secret_encrypted = models.TextField()
    credential_version = models.PositiveIntegerField(default=1)
    last_tested_at = models.DateTimeField(null=True, blank=True)
    last_test_succeeded = models.BooleanField(default=False)
    created_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="created_payment_connectors",
    )

    class Meta:
        db_table = "payments_connector"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code", "environment"],
                name="unique_payment_connector_environment",
            )
        ]


class PaymentIntent(TimeStampedModel):
    class Status(models.TextChoices):
        CREATED = "created", "Created"
        PENDING = "pending", "Pending"
        SUCCEEDED = "succeeded", "Succeeded"
        FAILED = "failed", "Failed"
        CANCELLED = "cancelled", "Cancelled"
        REQUIRES_RECONCILIATION = "requires_reconciliation", "Requires reconciliation"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="payment_intents"
    )
    connector = models.ForeignKey(
        PaymentConnector, on_delete=models.PROTECT, related_name="payment_intents"
    )
    payment = models.OneToOneField(
        PaymentRecord, on_delete=models.PROTECT, related_name="provider_intent"
    )
    idempotency_key = models.UUIDField(unique=True)
    status = models.CharField(
        max_length=32, choices=Status.choices, default=Status.CREATED
    )
    provider_reference = models.CharField(max_length=255, blank=True)
    checkout_payload = models.JSONField(default=dict)
    last_error_code = models.CharField(max_length=100, blank=True)
    reconciliation_attempts = models.PositiveIntegerField(default=0)
    last_reconciled_at = models.DateTimeField(null=True, blank=True)
    next_reconcile_at = models.DateTimeField(null=True, blank=True)
    reconciliation_error = models.CharField(max_length=500, blank=True)

    class Meta:
        db_table = "payments_intent"
        indexes = [
            models.Index(
                fields=["status", "next_reconcile_at"],
                name="payment_intent_reconcile_idx",
            )
        ]


class PaymentWebhookEvent(TimeStampedModel):
    class Status(models.TextChoices):
        RECEIVED = "received", "Received"
        PROCESSED = "processed", "Processed"
        DUPLICATE = "duplicate", "Duplicate"
        QUARANTINED = "quarantined", "Quarantined"

    connector = models.ForeignKey(
        PaymentConnector, on_delete=models.PROTECT, related_name="webhook_events"
    )
    event_id = models.CharField(max_length=255)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.RECEIVED
    )
    payload_sha256 = models.CharField(max_length=64)
    payload = models.JSONField(default=dict)
    reason = models.TextField(blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "payments_webhook_event"
        constraints = [
            models.UniqueConstraint(
                fields=["connector", "event_id"],
                name="unique_connector_webhook_event",
            )
        ]
