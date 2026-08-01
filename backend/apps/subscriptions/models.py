from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Tenant


class SubscriptionPlan(TimeStampedModel):
    code = models.SlugField(max_length=32, unique=True)
    name_my = models.CharField(max_length=120)
    name_en = models.CharField(max_length=120)
    description_my = models.TextField(blank=True)
    description_en = models.TextField(blank=True)
    display_order = models.PositiveSmallIntegerField(default=0)
    monthly_price = models.DecimalField(max_digits=14, decimal_places=2)
    annual_price = models.DecimalField(max_digits=14, decimal_places=2)
    tax_rate = models.DecimalField(max_digits=7, decimal_places=4, default=5)
    entitlements = models.JSONField(default=dict)
    limits = models.JSONField(default=dict)
    contact_sales = models.BooleanField(default=False)
    is_public = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "subscriptions_plan"
        ordering = ("display_order",)
        constraints = [
            models.CheckConstraint(
                condition=models.Q(monthly_price__gte=0),
                name="subscription_plan_monthly_nonnegative",
            ),
            models.CheckConstraint(
                condition=models.Q(annual_price__gte=0),
                name="subscription_plan_annual_nonnegative",
            ),
            models.CheckConstraint(
                condition=models.Q(tax_rate__gte=0),
                name="subscription_plan_tax_nonnegative",
            ),
        ]


class TenantSubscription(TimeStampedModel):
    class Status(models.TextChoices):
        TRIAL = "trial", "Trial"
        PENDING = "pending", "Pending activation"
        ACTIVE = "active", "Active"
        GRACE = "grace", "Grace period"
        SUSPENDED = "suspended", "Suspended"
        CANCELLED = "cancelled", "Cancelled"
        EXPIRED = "expired", "Expired"

    class BillingCycle(models.TextChoices):
        MONTHLY = "monthly", "Monthly"
        ANNUAL = "annual", "Annual"

    tenant = models.OneToOneField(
        Tenant, on_delete=models.PROTECT, related_name="subscription"
    )
    plan = models.ForeignKey(
        SubscriptionPlan, on_delete=models.PROTECT, related_name="subscriptions"
    )
    scheduled_plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.PROTECT,
        related_name="scheduled_subscriptions",
        null=True,
        blank=True,
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.TRIAL
    )
    billing_cycle = models.CharField(
        max_length=16,
        choices=BillingCycle.choices,
        default=BillingCycle.MONTHLY,
    )
    starts_at = models.DateTimeField()
    current_period_ends_at = models.DateTimeField()
    grace_ends_at = models.DateTimeField(null=True, blank=True)
    trial_ends_at = models.DateTimeField(null=True, blank=True)
    cancel_at_period_end = models.BooleanField(default=False)
    suspended_at = models.DateTimeField(null=True, blank=True)
    suspension_reason = models.TextField(blank=True)
    entitlement_overrides = models.JSONField(default=dict, blank=True)
    limit_overrides = models.JSONField(default=dict, blank=True)
    changed_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="subscriptions_changed",
    )

    class Meta:
        db_table = "subscriptions_tenant_subscription"
        indexes = [
            models.Index(
                fields=["status", "current_period_ends_at"],
                name="subscription_status_period_idx",
            )
        ]

    def clean(self):
        if self.current_period_ends_at <= self.starts_at:
            raise ValidationError(
                {"current_period_ends_at": "Period end must follow start."}
            )
        if self.grace_ends_at and self.grace_ends_at < self.current_period_ends_at:
            raise ValidationError(
                {"grace_ends_at": "Grace must not end before the billing period."}
            )

    @property
    def effective_entitlements(self):
        return {**self.plan.entitlements, **self.entitlement_overrides}

    @property
    def effective_limits(self):
        return {**self.plan.limits, **self.limit_overrides}


class SubscriptionInvoice(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        ISSUED = "issued", "Issued"
        PAYMENT_SUBMITTED = "payment_submitted", "Payment submitted"
        PAID = "paid", "Paid"
        VOID = "void", "Void"
        OVERDUE = "overdue", "Overdue"

    subscription = models.ForeignKey(
        TenantSubscription, on_delete=models.PROTECT, related_name="invoices"
    )
    invoice_number = models.CharField(max_length=64, unique=True)
    status = models.CharField(
        max_length=24, choices=Status.choices, default=Status.DRAFT
    )
    currency = models.CharField(max_length=3, default="MMK")
    subtotal = models.DecimalField(max_digits=14, decimal_places=2)
    tax_rate = models.DecimalField(max_digits=7, decimal_places=4)
    tax_amount = models.DecimalField(max_digits=14, decimal_places=2)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2)
    period_starts_at = models.DateTimeField()
    period_ends_at = models.DateTimeField()
    due_at = models.DateTimeField()
    issued_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    payment_reference = models.CharField(max_length=160, blank=True)
    payment_evidence_note = models.TextField(blank=True)
    created_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="subscription_invoices_created",
    )
    verified_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="subscription_invoices_verified",
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "subscriptions_invoice"
        indexes = [
            models.Index(
                fields=["subscription", "status", "due_at"],
                name="subscription_invoice_due_idx",
            )
        ]
