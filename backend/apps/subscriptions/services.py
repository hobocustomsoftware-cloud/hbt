from datetime import timedelta
from decimal import Decimal, ROUND_HALF_UP

from django.core.exceptions import PermissionDenied, ValidationError
from django.db import transaction
from django.utils import timezone

from apps.audit.services import record_audit_event

from .models import SubscriptionInvoice, SubscriptionPlan, TenantSubscription


SAFE_SUSPENSION_ENTITLEMENTS = {
    "existing_ticket_validation",
    "active_trip_operations",
    "cargo_handover",
    "reconciliation",
    "invoice_payment",
    "lawful_data_export",
}


def entitlement_enabled(subscription, code):
    if subscription is None:
        return False
    enabled = bool(subscription.effective_entitlements.get(code, False))
    if subscription.status in ("trial", "active", "grace"):
        return enabled
    return enabled and code in SAFE_SUSPENSION_ENTITLEMENTS


def require_entitlement(subscription, code):
    if not entitlement_enabled(subscription, code):
        raise PermissionDenied(
            f"The current subscription does not include entitlement: {code}"
        )


def effective_limit(subscription, code, default=0):
    if subscription is None:
        return default
    return subscription.effective_limits.get(code, default)


def enforce_usage_limit(*, subscription, code, current_count, increment=1):
    limit = effective_limit(subscription, code, None)
    if limit in (None, ""):
        return
    try:
        normalized_limit = int(limit)
    except (TypeError, ValueError) as exc:
        raise ValidationError(
            f"Subscription limit '{code}' is not a valid integer."
        ) from exc
    if normalized_limit < 0:
        raise ValidationError(
            f"Subscription limit '{code}' cannot be negative."
        )
    if current_count + increment > normalized_limit:
        raise PermissionDenied(
            f"The current subscription limit for '{code}' has been reached."
        )


def _audit(subscription, actor, action, before=None, reason=""):
    organization = subscription.tenant.organizations.order_by("created_at").first()
    record_audit_event(
        actor=actor,
        tenant_id=subscription.tenant_id,
        organization_id=organization.id if organization else None,
        action=action,
        resource_type="tenant_subscription",
        resource_id=subscription.id,
        reason=reason,
        before=before or {},
        after={
            "status": subscription.status,
            "plan": subscription.plan.code,
            "period_ends_at": subscription.current_period_ends_at,
        },
    )


@transaction.atomic
def issue_subscription_invoice(*, subscription, actor, invoice_number):
    subscription = TenantSubscription.objects.select_for_update().select_related(
        "plan", "tenant"
    ).get(pk=subscription.pk)
    if subscription.invoices.filter(
        status__in=(
            SubscriptionInvoice.Status.ISSUED,
            SubscriptionInvoice.Status.PAYMENT_SUBMITTED,
        )
    ).exists():
        raise ValidationError("An unpaid subscription invoice already exists.")
    subtotal = (
        subscription.plan.monthly_price
        if subscription.billing_cycle == TenantSubscription.BillingCycle.MONTHLY
        else subscription.plan.annual_price
    )
    tax_amount = (subtotal * subscription.plan.tax_rate / Decimal("100")).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    now = timezone.now()
    invoice = SubscriptionInvoice.objects.create(
        subscription=subscription,
        invoice_number=invoice_number,
        status=SubscriptionInvoice.Status.ISSUED,
        subtotal=subtotal,
        tax_rate=subscription.plan.tax_rate,
        tax_amount=tax_amount,
        total_amount=subtotal + tax_amount,
        period_starts_at=subscription.current_period_ends_at,
        period_ends_at=subscription.current_period_ends_at
        + (
            timedelta(days=30)
            if subscription.billing_cycle
            == TenantSubscription.BillingCycle.MONTHLY
            else timedelta(days=365)
        ),
        due_at=now + timedelta(days=7),
        issued_at=now,
        created_by=actor,
    )
    _audit(subscription, actor, "subscription.invoice_issued")
    return invoice


@transaction.atomic
def submit_subscription_payment(*, invoice, actor, reference, evidence_note=""):
    invoice = SubscriptionInvoice.objects.select_for_update().get(pk=invoice.pk)
    if invoice.status != SubscriptionInvoice.Status.ISSUED:
        raise ValidationError("Only an issued invoice can receive payment evidence.")
    if not reference.strip():
        raise ValidationError("Payment reference is required.")
    invoice.status = SubscriptionInvoice.Status.PAYMENT_SUBMITTED
    invoice.payment_reference = reference.strip()
    invoice.payment_evidence_note = evidence_note
    invoice.save()
    _audit(invoice.subscription, actor, "subscription.payment_submitted")
    return invoice


@transaction.atomic
def verify_subscription_payment(*, invoice, actor, approve, reason=""):
    invoice = SubscriptionInvoice.objects.select_for_update().select_related(
        "subscription__plan", "subscription__tenant"
    ).get(pk=invoice.pk)
    if invoice.status != SubscriptionInvoice.Status.PAYMENT_SUBMITTED:
        raise ValidationError("Subscription payment is not awaiting verification.")
    if invoice.created_by_id == actor.id:
        raise ValidationError("Invoice creator cannot verify its payment.")
    if not approve:
        invoice.status = SubscriptionInvoice.Status.ISSUED
        invoice.payment_evidence_note = (
            f"{invoice.payment_evidence_note}\nRejected: {reason}".strip()
        )
        invoice.save()
        _audit(invoice.subscription, actor, "subscription.payment_rejected", reason=reason)
        return invoice
    now = timezone.now()
    invoice.status = SubscriptionInvoice.Status.PAID
    invoice.paid_at = now
    invoice.verified_by = actor
    invoice.save()
    subscription = invoice.subscription
    before = {"status": subscription.status, "plan": subscription.plan.code}
    if subscription.scheduled_plan_id:
        subscription.plan = subscription.scheduled_plan
        subscription.scheduled_plan = None
    subscription.status = TenantSubscription.Status.ACTIVE
    subscription.starts_at = min(subscription.starts_at, invoice.period_starts_at)
    subscription.current_period_ends_at = invoice.period_ends_at
    subscription.grace_ends_at = invoice.period_ends_at + timedelta(days=7)
    subscription.suspended_at = None
    subscription.suspension_reason = ""
    subscription.save()
    _audit(subscription, actor, "subscription.payment_confirmed", before=before)
    return invoice


@transaction.atomic
def change_subscription_plan(*, subscription, plan, actor, immediate=False):
    subscription = TenantSubscription.objects.select_for_update().select_related(
        "plan", "tenant"
    ).get(pk=subscription.pk)
    if not plan.is_active:
        raise ValidationError("Subscription plan is not active.")
    before = {"plan": subscription.plan.code}
    if immediate:
        subscription.plan = plan
        subscription.scheduled_plan = None
    else:
        subscription.scheduled_plan = plan
    subscription.save()
    _audit(subscription, actor, "subscription.plan_changed", before=before)
    return subscription


@transaction.atomic
def suspend_subscription(*, subscription, actor, reason):
    subscription = TenantSubscription.objects.select_for_update().select_related(
        "plan", "tenant"
    ).get(pk=subscription.pk)
    if not reason.strip():
        raise ValidationError("Suspension reason is required.")
    subscription.status = TenantSubscription.Status.SUSPENDED
    subscription.suspended_at = timezone.now()
    subscription.suspension_reason = reason
    subscription.save()
    _audit(subscription, actor, "subscription.suspended", reason=reason)
    return subscription


def process_subscription_deadlines(now=None):
    now = now or timezone.now()
    changed = 0
    for subscription in TenantSubscription.objects.select_related(
        "plan", "tenant"
    ).filter(
        status__in=(
            TenantSubscription.Status.TRIAL,
            TenantSubscription.Status.ACTIVE,
            TenantSubscription.Status.GRACE,
        )
    ):
        new_status = subscription.status
        if subscription.status == TenantSubscription.Status.TRIAL:
            if subscription.trial_ends_at and subscription.trial_ends_at <= now:
                new_status = TenantSubscription.Status.GRACE
        elif subscription.current_period_ends_at <= now:
            if subscription.grace_ends_at and subscription.grace_ends_at > now:
                new_status = TenantSubscription.Status.GRACE
            else:
                new_status = TenantSubscription.Status.SUSPENDED
        if new_status != subscription.status:
            subscription.status = new_status
            if new_status == TenantSubscription.Status.SUSPENDED:
                subscription.suspended_at = now
                subscription.suspension_reason = "Billing grace period expired."
            subscription.save()
            _audit(subscription, None, f"subscription.deadline_{new_status}")
            changed += 1
    SubscriptionInvoice.objects.filter(
        status=SubscriptionInvoice.Status.ISSUED, due_at__lt=now
    ).update(status=SubscriptionInvoice.Status.OVERDUE)
    return changed
