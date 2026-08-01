import hashlib
import hmac
import json
from datetime import timedelta

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils import timezone
from django.utils.dateparse import parse_datetime

from apps.audit.services import record_audit_event
from apps.core.file_security import scan_upload
from apps.bookings.services import confirm_booking
from apps.notifications.models import Notification, PendingWorkItem
from apps.notifications.services import (
    enqueue_event_after_commit,
    recipients_with_permission,
)
from apps.ticketing.services import issue_ticket
from apps.core.field_crypto import decrypt_secret, encrypt_secret

from .models import (
    PaymentEvidence,
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


def resolve_receiving_account_versions(
    *,
    organization,
    branch=None,
    terminal_operation=None,
    counter=None,
    at=None,
):
    """Return only the highest-priority active payment destination scope."""
    now = at or timezone.now()
    base = PaymentReceivingAccountVersion.objects.filter(
        account__organization=organization,
        account__status=PaymentReceivingAccount.Status.ACTIVE,
        effective_from__lte=now,
    ).filter(
        models.Q(effective_until__isnull=True)
        | models.Q(effective_until__gt=now)
    ).select_related("account")
    scopes = []
    if counter is not None:
        if counter.terminal_operation.organization_id != organization.id:
            raise ValidationError("Counter belongs to another organization.")
        scopes.append(models.Q(account__counter=counter))
    if terminal_operation is not None:
        if terminal_operation.organization_id != organization.id:
            raise ValidationError(
                "Terminal operation belongs to another organization."
            )
        scopes.append(
            models.Q(
                account__counter__isnull=True,
                account__terminal_operation=terminal_operation,
            )
        )
    if branch is not None:
        if branch.organization_id != organization.id:
            raise ValidationError("Branch belongs to another organization.")
        scopes.append(
            models.Q(
                account__counter__isnull=True,
                account__terminal_operation__isnull=True,
                account__branch=branch,
            )
        )
    scopes.append(
        models.Q(
            account__counter__isnull=True,
            account__terminal_operation__isnull=True,
            account__branch__isnull=True,
        )
    )
    for scope in scopes:
        candidates = base.filter(scope).order_by(
            "account__account_code", "-version"
        )
        if candidates.exists():
            return candidates
    return base.none()

ALLOWED_UPLOAD_TYPES = {
    "image/jpeg": (b"\xff\xd8\xff",),
    "image/png": (b"\x89PNG\r\n\x1a\n",),
    "image/webp": (b"RIFF",),
    "application/pdf": (b"%PDF-",),
}


def store_private_upload(*, organization, actor, file, purpose):
    scan_upload(file)
    if file.size > settings.PAYMENT_UPLOAD_MAX_BYTES:
        raise ValidationError("File exceeds the 10 MB limit.")
    signatures = ALLOWED_UPLOAD_TYPES.get(file.content_type)
    header = file.read(12)
    file.seek(0)
    valid_signature = signatures and any(
        header.startswith(item) for item in signatures
    )
    if file.content_type == "image/webp":
        valid_signature = valid_signature and header[8:12] == b"WEBP"
    if not valid_signature:
        raise ValidationError("Only valid JPEG, PNG, WebP, or PDF files are accepted.")
    digest = hashlib.sha256()
    for chunk in file.chunks():
        digest.update(chunk)
    file.seek(0)
    upload = PrivatePaymentUpload(
        organization=organization,
        purpose=purpose,
        file=file,
        original_filename=file.name[:255],
        content_type=file.content_type,
        size_bytes=file.size,
        sha256=digest.hexdigest(),
        uploaded_by=actor,
    )
    upload.full_clean()
    upload.save()
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action="payment.private_upload.created",
        resource_type="private_payment_upload",
        resource_id=upload.id,
        after={
            "purpose": purpose,
            "content_type": upload.content_type,
            "size_bytes": upload.size_bytes,
            "sha256": upload.sha256,
        },
    )
    return upload


@transaction.atomic
def create_payment(*, organization, actor, **data):
    evidence_upload = data.pop("evidence_upload", None)
    request_id = data.get("client_request_id")
    if request_id:
        existing = PaymentRecord.objects.filter(client_request_id=request_id).first()
        if existing:
            if existing.organization_id != organization.id:
                raise ValidationError("Client request ID is already in use.")
            return existing
    target = (
        data.get("booking")
        or data.get("cargo_shipment")
        or data.get("corporate_invoice")
    )
    if not target or target.organization_id != organization.id:
        raise ValidationError("Payment target belongs to another organization.")
    method = data["method"]
    account_version = data.get("receiving_account_version")
    if method in (PaymentRecord.Method.WALLET_QR, PaymentRecord.Method.BANK_TRANSFER):
        if not account_version:
            raise ValidationError("Electronic payment requires a receiving account.")
        if account_version.account.organization_id != organization.id:
            raise ValidationError("Receiving account belongs to another organization.")
        if account_version.account.status != PaymentReceivingAccount.Status.ACTIVE:
            raise ValidationError("Receiving account is not active.")
        if not evidence_upload:
            raise ValidationError("Electronic payment requires payment evidence.")
    if evidence_upload and evidence_upload.organization_id != organization.id:
        raise ValidationError("Evidence upload belongs to another organization.")
    if evidence_upload and evidence_upload.uploaded_by_id != actor.id:
        raise ValidationError("Evidence upload was created by another user.")
    if account_version:
        now = timezone.now()
        if account_version.effective_from > now or (
            account_version.effective_until
            and account_version.effective_until <= now
        ):
            raise ValidationError("Receiving account version is not effective.")
    data["status"] = (
        PaymentRecord.Status.RECORDED
        if method == PaymentRecord.Method.CASH
        else PaymentRecord.Status.SUBMITTED
    )
    payment = PaymentRecord(
        organization=organization, recorded_by=actor, **data
    )
    payment.full_clean()
    payment.save()
    if evidence_upload:
        evidence = PaymentEvidence(
            payment=payment,
            upload=evidence_upload,
            submitted_by=actor,
        )
        evidence.full_clean()
        evidence.save()
    _audit(payment, actor, "payment.recorded")
    from apps.offline.services import record_sync_change

    record_sync_change(
        organization=organization,
        resource_type="payment",
        resource_id=payment.id,
        operation="created",
        payload={
            "id": payment.id,
            "status": payment.status,
            "method": payment.method,
            "amount": payment.amount,
            "updated_at": payment.updated_at,
        },
    )
    if payment.booking_id and payment.booking.customer_account_id:
        enqueue_event_after_commit(
            event_type="payment.submitted",
            event_key=f"payment:{payment.id}:submitted:passenger",
            kind=Notification.Kind.PAYMENT,
            category=Notification.Category.INFORMATION,
            recipients=[payment.booking.customer_account_id],
            organization=organization,
            title="ငွေပေးချေမှု တင်ပြီးပါပြီ",
            body="ငွေပေးချေမှုကို စစ်ဆေးနေပါသည်။",
            data={"payment_id": str(payment.id), "status": payment.status},
            deep_link=f"hbt://payments/{payment.id}",
        )
    if payment.status == PaymentRecord.Status.SUBMITTED:
        verifier_ids = list(
            recipients_with_permission(organization, "payment.confirm")
        )
        enqueue_event_after_commit(
            event_type="payment.verification_required",
            event_key=f"payment:{payment.id}:verification-required",
            kind=Notification.Kind.PAYMENT,
            category=Notification.Category.PAYMENT_VERIFICATION,
            recipients=verifier_ids,
            organization=organization,
            title="ငွေပေးချေမှု စစ်ဆေးရန်ရှိသည်",
            body="ငွေပေးချေမှုအထောက်အထားအသစ်ကို စစ်ဆေးပေးပါ။",
            data={"payment_id": str(payment.id)},
            deep_link=f"hbt-business://payments/{payment.id}/verify",
            action_required=True,
            work_type="payment_verification",
        )
    return payment


@transaction.atomic
def decide_payment(*, payment, actor, approve, reason="", tickets=None):
    payment = PaymentRecord.objects.select_for_update().get(pk=payment.pk)
    if payment.status not in (
        PaymentRecord.Status.RECORDED, PaymentRecord.Status.SUBMITTED
    ):
        raise ValidationError("Payment is not awaiting confirmation.")
    if approve:
        if payment.recorded_by_id == actor.id:
            raise ValidationError("The payment recorder cannot verify the same payment.")
        if payment.cargo_shipment_id:
            confirmed_total = (
                PaymentRecord.objects.filter(
                    cargo_shipment=payment.cargo_shipment,
                    status=PaymentRecord.Status.CONFIRMED,
                )
                .exclude(pk=payment.pk)
                .aggregate(total=models.Sum("amount"))["total"]
                or 0
            )
            if confirmed_total + payment.amount > payment.cargo_shipment.total_charge:
                raise ValidationError(
                    "Confirmed cargo payments cannot exceed the shipment total."
                )
        if payment.corporate_invoice_id:
            invoice = payment.corporate_invoice
            allocated = (
                InvoicePaymentAllocation.objects.filter(invoice=invoice)
                .aggregate(total=models.Sum("amount"))["total"]
                or 0
            )
            if allocated + payment.amount > invoice.total_amount:
                raise ValidationError(
                    "Invoice payments cannot exceed the invoice total."
                )
        if payment.method != PaymentRecord.Method.CASH:
            try:
                evidence = payment.evidence
            except PaymentEvidence.DoesNotExist as exc:
                raise ValidationError("Electronic payment has no evidence.") from exc
            evidence.status = PaymentEvidence.Status.ACCEPTED
            evidence.verified_by = actor
            evidence.verified_at = timezone.now()
            evidence.verification_note = reason
            evidence.save()
        payment.status = PaymentRecord.Status.CONFIRMED
        payment.confirmed_by = actor
        payment.confirmed_at = timezone.now()
    else:
        if not reason.strip():
            raise ValidationError("A rejection reason is required.")
        payment.status = PaymentRecord.Status.REJECTED
        payment.rejection_reason = reason
        if hasattr(payment, "evidence"):
            payment.evidence.status = PaymentEvidence.Status.REJECTED
            payment.evidence.verified_by = actor
            payment.evidence.verified_at = timezone.now()
            payment.evidence.verification_note = reason
            payment.evidence.save()
    payment.save()
    if approve and payment.corporate_invoice_id:
        allocation = InvoicePaymentAllocation(
            invoice=payment.corporate_invoice,
            payment=payment,
            amount=payment.amount,
            allocated_by=actor,
        )
        allocation.full_clean()
        allocation.save()
        allocated_total = (
            InvoicePaymentAllocation.objects.filter(
                invoice=payment.corporate_invoice
            ).aggregate(total=models.Sum("amount"))["total"]
            or 0
        )
        if allocated_total == payment.corporate_invoice.total_amount:
            payment.corporate_invoice.status = (
                payment.corporate_invoice.Status.PAID
            )
            payment.corporate_invoice.save()
    _audit(
        payment, actor,
        "payment.confirmed" if approve else "payment.rejected",
        reason,
    )
    if approve and payment.booking_id:
        ticket_rows = tickets or []
        if not ticket_rows:
            raise ValidationError("Ticket details are required to complete a booking payment.")
        total = sum(row["total_amount"] for row in ticket_rows)
        if total != payment.amount:
            raise ValidationError("Payment amount must equal the ticket allocation total.")
        booking = confirm_booking(
            booking=payment.booking,
            actor=actor,
            authorization_reference=payment.payment_number,
        )
        for row in ticket_rows:
            issue_ticket(actor=actor, **row)
        _audit(payment, actor, "payment.allocated_and_tickets_issued")
    PendingWorkItem.objects.filter(
        organization=payment.organization,
        event_key=f"payment:{payment.id}:verification-required",
        work_type="payment_verification",
        status=PendingWorkItem.Status.PENDING,
    ).update(status=PendingWorkItem.Status.COMPLETED, completed_at=timezone.now())
    if payment.booking_id and payment.booking.customer_account_id:
        approved_title = (
            "ငွေပေးချေမှု အတည်ပြုပြီးပါပြီ"
            if approve
            else "ငွေပေးချေမှုကို အတည်မပြုနိုင်ပါ"
        )
        approved_body = (
            "လက်မှတ်ကို App ထဲတွင် ကြည့်နိုင်ပါပြီ။"
            if approve
            else "အသေးစိတ်ကို App ထဲတွင် ပြန်လည်စစ်ဆေးပါ။"
        )
        enqueue_event_after_commit(
            event_type=(
                "payment.confirmed" if approve else "payment.rejected"
            ),
            event_key=(
                f"payment:{payment.id}:"
                f"{'confirmed' if approve else 'rejected'}:passenger"
            ),
            kind=Notification.Kind.PAYMENT,
            category=Notification.Category.INFORMATION,
            recipients=[payment.booking.customer_account_id],
            organization=payment.organization,
            title=approved_title,
            body=approved_body,
            data={"payment_id": str(payment.id), "status": payment.status},
            deep_link=f"hbt://payments/{payment.id}",
        )
    from apps.offline.services import record_sync_change

    record_sync_change(
        organization=payment.organization,
        resource_type="payment",
        resource_id=payment.id,
        operation="updated",
        payload={
            "id": payment.id,
            "status": payment.status,
            "amount": payment.amount,
            "updated_at": payment.updated_at,
        },
    )
    return payment


def _audit(payment, actor, action, reason=""):
    record_audit_event(
        actor=actor,
        tenant_id=payment.organization.tenant_id,
        organization_id=payment.organization_id,
        action=action,
        resource_type="payment_record",
        resource_id=payment.id,
        reason=reason,
        after={
            "status": payment.status,
            "amount": payment.amount,
            "method": payment.method,
        },
    )


def _confirmed_refundable_balance(payment, *, exclude_refund_id=None):
    confirmed = payment.amount if payment.status in (
        PaymentRecord.Status.CONFIRMED,
        PaymentRecord.Status.REFUNDED,
    ) else 0
    refunds = RefundRequest.objects.filter(
        payment=payment,
        status__in=(
            RefundRequest.Status.APPROVED,
            RefundRequest.Status.PAID,
            RefundRequest.Status.COMPLETED,
        ),
    )
    if exclude_refund_id:
        refunds = refunds.exclude(pk=exclude_refund_id)
    allocated = refunds.aggregate(total=models.Sum("approved_amount"))["total"] or 0
    return confirmed - allocated


@transaction.atomic
def request_refund(*, organization, payment, actor, **data):
    payment = PaymentRecord.objects.select_for_update().get(pk=payment.pk)
    request_id = data.get("client_request_id")
    if request_id:
        existing = RefundRequest.objects.filter(client_request_id=request_id).first()
        if existing:
            if existing.organization_id != organization.id:
                raise ValidationError("Client request ID is already in use.")
            return existing
    if payment.organization_id != organization.id:
        raise ValidationError("Payment belongs to another organization.")
    if payment.status not in (
        PaymentRecord.Status.CONFIRMED,
        PaymentRecord.Status.REFUNDED,
    ):
        raise ValidationError("Only a confirmed payment can be refunded.")
    amount = data["requested_amount"]
    if amount > _confirmed_refundable_balance(payment):
        raise ValidationError("Refund exceeds the confirmed refundable balance.")
    ticket = data.get("ticket")
    if ticket and ticket.status in (
        ticket.Status.BOARDED,
        ticket.Status.COMPLETED,
        ticket.Status.ARCHIVED,
    ):
        raise ValidationError("A boarded or completed ticket cannot be refunded.")
    try:
        policy = organization.refund_policy
    except RefundPolicy.DoesNotExist:
        policy = None
    snapshot = (
        {
            "policy_id": str(policy.id),
            "enabled": policy.enabled,
            "refund_window_hours": policy.refund_window_hours,
            "refund_percentage": str(policy.refund_percentage),
            "fixed_fee": str(policy.fixed_fee),
            "approval_threshold": str(policy.approval_threshold),
        }
        if policy
        else {"manual_review_required": True}
    )
    refund = RefundRequest(
        organization=organization,
        payment=payment,
        requested_by=actor,
        policy_snapshot=snapshot,
        **data,
    )
    refund.full_clean()
    refund.save()
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action="refund.requested",
        resource_type="refund_request",
        resource_id=refund.id,
        reason=refund.reason,
        after={
            "status": refund.status,
            "payment_id": payment.id,
            "requested_amount": refund.requested_amount,
        },
    )
    return refund


@transaction.atomic
def decide_refund(*, refund, actor, approve, approved_amount=None, reason=""):
    refund = RefundRequest.objects.select_for_update(of=("self",)).select_related(
        "payment", "ticket"
    ).get(pk=refund.pk)
    if refund.status != RefundRequest.Status.REQUESTED:
        raise ValidationError("Refund is not awaiting a decision.")
    if refund.requested_by_id == actor.id:
        raise ValidationError("The refund requester cannot approve the same refund.")
    if approve:
        amount = approved_amount or refund.requested_amount
        if amount > refund.requested_amount:
            raise ValidationError("Approved amount cannot exceed requested amount.")
        if amount > _confirmed_refundable_balance(
            refund.payment, exclude_refund_id=refund.id
        ):
            raise ValidationError("Refund exceeds the confirmed refundable balance.")
        refund.status = RefundRequest.Status.APPROVED
        refund.approved_amount = amount
    else:
        if not reason.strip():
            raise ValidationError("A rejection reason is required.")
        refund.status = RefundRequest.Status.REJECTED
    refund.decided_by = actor
    refund.decided_at = timezone.now()
    refund.decision_reason = reason
    refund.full_clean()
    refund.save()
    record_audit_event(
        actor=actor,
        tenant_id=refund.organization.tenant_id,
        organization_id=refund.organization_id,
        action="refund.approved" if approve else "refund.rejected",
        resource_type="refund_request",
        resource_id=refund.id,
        reason=reason,
        after={
            "status": refund.status,
            "approved_amount": refund.approved_amount,
        },
    )
    return refund


@transaction.atomic
def mark_refund_paid(*, refund, actor, payout_reference):
    refund = RefundRequest.objects.select_for_update(of=("self",)).select_related(
        "payment", "ticket"
    ).get(pk=refund.pk)
    if refund.status != RefundRequest.Status.APPROVED:
        raise ValidationError("Only an approved refund can be marked paid.")
    if not payout_reference.strip():
        raise ValidationError("Payout reference is required.")
    refund.status = RefundRequest.Status.PAID
    refund.paid_by = actor
    refund.paid_at = timezone.now()
    refund.payout_reference = payout_reference.strip()
    refund.full_clean()
    refund.save()
    record_audit_event(
        actor=actor,
        tenant_id=refund.organization.tenant_id,
        organization_id=refund.organization_id,
        action="refund.paid",
        resource_type="refund_request",
        resource_id=refund.id,
        after={
            "status": refund.status,
            "approved_amount": refund.approved_amount,
            "payout_reference": refund.payout_reference,
        },
    )
    return refund


@transaction.atomic
def complete_refund(*, refund, actor):
    refund = RefundRequest.objects.select_for_update(of=("self",)).select_related(
        "payment", "ticket", "payment__booking"
    ).get(pk=refund.pk)
    if refund.status != RefundRequest.Status.PAID:
        raise ValidationError("Only a paid refund can be completed.")
    refund.status = RefundRequest.Status.COMPLETED
    refund.completed_at = timezone.now()
    refund.save()
    if refund.ticket_id:
        ticket = refund.ticket
        ticket.status = ticket.Status.CANCELLED
        ticket.revoked_at = timezone.now()
        ticket.revoked_by = actor
        ticket.revocation_reason = f"Refund {refund.refund_number}"
        ticket.save()
    remaining = _confirmed_refundable_balance(refund.payment)
    if remaining == 0:
        refund.payment.status = PaymentRecord.Status.REFUNDED
        refund.payment.save()
    record_audit_event(
        actor=actor,
        tenant_id=refund.organization.tenant_id,
        organization_id=refund.organization_id,
        action="refund.completed",
        resource_type="refund_request",
        resource_id=refund.id,
        after={"status": refund.status, "remaining_payment_balance": remaining},
    )
    return refund


class ManualSandboxAdapter:
    """Safe contract adapter used until an official provider adapter is installed."""

    def test_connection(self, connector, credentials):
        return bool(connector.merchant_id and credentials)

    def initiate(self, connector, payment, idempotency_key):
        return {
            "provider_reference": f"SBX-{str(idempotency_key)[:18]}",
            "status": PaymentIntent.Status.PENDING,
            "checkout_payload": {
                "mode": "sandbox",
                "payment_number": payment.payment_number,
                "amount": str(payment.amount),
                "currency": payment.currency,
            },
        }

    def query(self, connector, intent, credentials):
        return {
            "provider_reference": intent.provider_reference,
            "status": "pending",
            "amount": str(intent.payment.amount),
            "currency": intent.payment.currency,
            "merchant_id": connector.merchant_id,
        }


PAYMENT_ADAPTERS = {"manual_sandbox": ManualSandboxAdapter()}


def _adapter_for(connector):
    adapter = PAYMENT_ADAPTERS.get(connector.adapter)
    if not adapter:
        raise ValidationError("Payment connector adapter is not installed.")
    if (
        connector.environment == PaymentConnector.Environment.PRODUCTION
        and connector.adapter == "manual_sandbox"
    ):
        raise ValidationError("Sandbox adapter cannot be activated in production.")
    return adapter


@transaction.atomic
def save_payment_connector(
    *, organization, actor, credentials, webhook_secret, instance=None, **data
):
    connector = instance or PaymentConnector(
        organization=organization, created_by=actor
    )
    if connector.organization_id != organization.id:
        raise ValidationError("Connector belongs to another organization.")
    for field, value in data.items():
        setattr(connector, field, value)
    if credentials:
        connector.encrypted_credentials = encrypt_secret(
            json.dumps(credentials, sort_keys=True)
        )
    if webhook_secret:
        connector.webhook_secret_encrypted = encrypt_secret(webhook_secret)
    if not connector.encrypted_credentials or not connector.webhook_secret_encrypted:
        raise ValidationError("Credentials and webhook secret are required.")
    connector.full_clean()
    connector.save()
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action="payment.connector.saved",
        resource_type="payment_connector",
        resource_id=connector.id,
        after={
            "code": connector.code,
            "adapter": connector.adapter,
            "environment": connector.environment,
            "credential_version": connector.credential_version,
        },
    )
    return connector


@transaction.atomic
def test_payment_connector(*, connector, actor):
    connector = PaymentConnector.objects.select_for_update().get(pk=connector.pk)
    credentials = json.loads(decrypt_secret(connector.encrypted_credentials))
    succeeded = _adapter_for(connector).test_connection(connector, credentials)
    connector.last_tested_at = timezone.now()
    connector.last_test_succeeded = succeeded
    connector.save()
    record_audit_event(
        actor=actor,
        tenant_id=connector.organization.tenant_id,
        organization_id=connector.organization_id,
        action="payment.connector.tested",
        resource_type="payment_connector",
        resource_id=connector.id,
        after={"succeeded": succeeded},
    )
    return connector


@transaction.atomic
def rotate_payment_connector(
    *, connector, actor, credentials, webhook_secret
):
    connector = PaymentConnector.objects.select_for_update().get(pk=connector.pk)
    if not credentials or not webhook_secret:
        raise ValidationError(
            "A complete credential set and webhook secret are required."
        )
    connector.encrypted_credentials = encrypt_secret(
        json.dumps(credentials, sort_keys=True)
    )
    connector.webhook_secret_encrypted = encrypt_secret(webhook_secret)
    connector.credential_version += 1
    connector.status = PaymentConnector.Status.DRAFT
    connector.last_test_succeeded = False
    connector.last_tested_at = None
    connector.save()
    record_audit_event(
        actor=actor,
        tenant_id=connector.organization.tenant_id,
        organization_id=connector.organization_id,
        action="payment.connector.credentials_rotated",
        resource_type="payment_connector",
        resource_id=connector.id,
        after={"credential_version": connector.credential_version},
    )
    return connector


@transaction.atomic
def disable_payment_connector(*, connector, actor, reason):
    connector = PaymentConnector.objects.select_for_update().get(pk=connector.pk)
    if not reason.strip():
        raise ValidationError("A disable reason is required.")
    connector.status = PaymentConnector.Status.DISABLED
    connector.save()
    record_audit_event(
        actor=actor,
        tenant_id=connector.organization.tenant_id,
        organization_id=connector.organization_id,
        action="payment.connector.disabled",
        resource_type="payment_connector",
        resource_id=connector.id,
        reason=reason,
        after={"status": connector.status},
    )
    return connector


@transaction.atomic
def initiate_provider_payment(*, connector, payment, actor, idempotency_key):
    if connector.organization_id != payment.organization_id:
        raise ValidationError("Connector and payment belong to different organizations.")
    if connector.status != PaymentConnector.Status.ACTIVE:
        raise ValidationError("Payment connector is not active.")
    existing = PaymentIntent.objects.filter(idempotency_key=idempotency_key).first()
    if existing:
        if existing.payment_id != payment.id:
            raise ValidationError("Idempotency key is already in use.")
        return existing
    result = _adapter_for(connector).initiate(
        connector, payment, idempotency_key
    )
    intent = PaymentIntent.objects.create(
        organization=payment.organization,
        connector=connector,
        payment=payment,
        idempotency_key=idempotency_key,
        status=result["status"],
        provider_reference=result["provider_reference"],
        checkout_payload=result["checkout_payload"],
    )
    record_audit_event(
        actor=actor,
        tenant_id=payment.organization.tenant_id,
        organization_id=payment.organization_id,
        action="payment.provider_initiated",
        resource_type="payment_intent",
        resource_id=intent.id,
        after={"status": intent.status, "connector_id": connector.id},
    )
    return intent


@transaction.atomic
def process_provider_webhook(*, connector, raw_body, signature, payload):
    secret = decrypt_secret(connector.webhook_secret_encrypted)
    expected = hmac.new(
        secret.encode("utf-8"), raw_body, hashlib.sha256
    ).hexdigest()
    if not hmac.compare_digest(expected, signature):
        raise ValidationError("Invalid webhook signature.")
    event_id = str(payload.get("event_id", "")).strip()
    if not event_id:
        raise ValidationError("Webhook event_id is required.")
    occurred_at = parse_datetime(str(payload.get("occurred_at", "")))
    if not occurred_at:
        raise ValidationError("Webhook occurred_at timestamp is required.")
    if occurred_at.tzinfo is None:
        raise ValidationError("Webhook occurred_at must include a timezone.")
    if abs(timezone.now() - occurred_at) > timedelta(minutes=5):
        raise ValidationError("Webhook timestamp is outside the replay window.")
    digest = hashlib.sha256(raw_body).hexdigest()
    existing = PaymentWebhookEvent.objects.filter(
        connector=connector, event_id=event_id
    ).first()
    if existing:
        return existing
    event = PaymentWebhookEvent.objects.create(
        connector=connector,
        event_id=event_id,
        payload_sha256=digest,
        payload=payload,
    )
    reference = str(payload.get("provider_reference", ""))
    intent = PaymentIntent.objects.select_for_update().filter(
        connector=connector, provider_reference=reference
    ).select_related("payment").first()
    if not intent:
        event.status = PaymentWebhookEvent.Status.QUARANTINED
        event.reason = "Unknown provider reference"
        event.save()
        return event
    amount = str(payload.get("amount", ""))
    currency = str(payload.get("currency", ""))
    merchant_id = str(payload.get("merchant_id", ""))
    if (
        amount != str(intent.payment.amount)
        or currency != intent.payment.currency
        or merchant_id != connector.merchant_id
    ):
        event.status = PaymentWebhookEvent.Status.QUARANTINED
        event.reason = "Amount, currency, or merchant mismatch"
        event.save()
        return event
    provider_status = payload.get("status")
    if provider_status == "succeeded":
        intent.status = PaymentIntent.Status.SUCCEEDED
        intent.payment.status = PaymentRecord.Status.SUBMITTED
        intent.payment.transaction_reference = reference
        intent.payment.save()
    elif provider_status in ("failed", "cancelled"):
        intent.status = provider_status
    else:
        intent.status = PaymentIntent.Status.REQUIRES_RECONCILIATION
    intent.save()
    event.status = PaymentWebhookEvent.Status.PROCESSED
    event.processed_at = timezone.now()
    event.save()
    return event


@transaction.atomic
def reconcile_payment_intent(*, intent):
    intent = PaymentIntent.objects.select_for_update().select_related(
        "connector__organization", "payment"
    ).get(pk=intent.pk)
    if intent.status not in (
        PaymentIntent.Status.PENDING,
        PaymentIntent.Status.REQUIRES_RECONCILIATION,
    ):
        return intent
    now = timezone.now()
    if intent.next_reconcile_at and intent.next_reconcile_at > now:
        return intent

    connector = intent.connector
    intent.reconciliation_attempts += 1
    intent.last_reconciled_at = now
    delay_minutes = min(2 ** min(intent.reconciliation_attempts, 6), 60)
    intent.next_reconcile_at = now + timedelta(minutes=delay_minutes)
    try:
        credentials = json.loads(decrypt_secret(connector.encrypted_credentials))
        result = _adapter_for(connector).query(connector, intent, credentials)
        if str(result.get("provider_reference", "")) != intent.provider_reference:
            raise ValidationError("Provider reconciliation reference mismatch.")
        if (
            str(result.get("amount", "")) != str(intent.payment.amount)
            or str(result.get("currency", "")) != intent.payment.currency
            or str(result.get("merchant_id", "")) != connector.merchant_id
        ):
            raise ValidationError(
                "Provider reconciliation amount, currency, or merchant mismatch."
            )
        provider_status = str(result.get("status", ""))
        if provider_status == "succeeded":
            intent.status = PaymentIntent.Status.SUCCEEDED
            intent.payment.status = PaymentRecord.Status.SUBMITTED
            intent.payment.transaction_reference = intent.provider_reference
            intent.payment.save(
                update_fields=[
                    "status", "transaction_reference", "updated_at"
                ]
            )
            intent.next_reconcile_at = None
        elif provider_status in ("failed", "cancelled"):
            intent.status = provider_status
            intent.next_reconcile_at = None
        elif provider_status == "pending":
            intent.status = PaymentIntent.Status.PENDING
        else:
            intent.status = PaymentIntent.Status.REQUIRES_RECONCILIATION
        intent.reconciliation_error = ""
    except Exception as exc:
        intent.status = PaymentIntent.Status.REQUIRES_RECONCILIATION
        intent.reconciliation_error = str(exc)[:500]
    intent.save()
    record_audit_event(
        tenant_id=intent.organization.tenant_id,
        organization_id=intent.organization_id,
        action="payment.intent_reconciled",
        resource_type="payment_intent",
        resource_id=intent.id,
        after={
            "status": intent.status,
            "attempt": intent.reconciliation_attempts,
            "next_reconcile_at": intent.next_reconcile_at,
            "has_error": bool(intent.reconciliation_error),
        },
    )
    return intent
