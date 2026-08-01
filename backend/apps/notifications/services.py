import logging

from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.tenancy.models import Membership

from .models import DeliveryAttempt, Notification, PendingWorkItem

logger = logging.getLogger(__name__)


def recipients_with_permission(organization, permission_code):
    return (
        Membership.objects.filter(
            organization=organization,
            status=Membership.Status.ACTIVE,
            role_assignments__role__permissions__code=permission_code,
        )
        .values_list("user_id", flat=True)
        .distinct()
    )


def create_event_notifications(
    *,
    event_type,
    event_key,
    kind,
    category,
    recipients,
    title,
    body,
    organization=None,
    data=None,
    deep_link="",
    action_required=False,
    work_type="",
):
    now = timezone.now()
    created = []
    for recipient in recipients:
        recipient_id = getattr(recipient, "id", recipient)
        for channel in (
            Notification.Channel.IN_APP,
            Notification.Channel.PUSH,
        ):
            try:
                notification, was_created = Notification.objects.get_or_create(
                    recipient_id=recipient_id,
                    event_key=event_key,
                    channel=channel,
                    defaults={
                        "organization": organization,
                        "event_type": event_type,
                        "kind": kind,
                        "category": category,
                        "language": "my",
                        "title": title,
                        "body": body,
                        "data": data or {},
                        "deep_link": deep_link,
                        "status": Notification.Status.QUEUED,
                        "available_at": now,
                    },
                )
                if was_created:
                    created.append(notification)
            except IntegrityError:
                continue
        if action_required and organization:
            PendingWorkItem.objects.get_or_create(
                assignee_id=recipient_id,
                event_key=event_key,
                work_type=work_type or event_type,
                defaults={
                    "organization": organization,
                    "title": title,
                    "deep_link": deep_link,
                    "priority": "high",
                },
            )
    return created


def enqueue_event_after_commit(**kwargs):
    def callback():
        try:
            notifications = create_event_notifications(**kwargs)
            for notification in notifications:
                record_audit_event(
                    actor=None,
                    tenant_id=(
                        notification.organization.tenant_id
                        if notification.organization_id
                        else None
                    ),
                    organization_id=notification.organization_id,
                    action="notification.queued",
                    resource_type="notification",
                    resource_id=notification.id,
                    after={
                        "event_type": notification.event_type,
                        "channel": notification.channel,
                        "status": notification.status,
                    },
                )
        except Exception:
            # Notification failures must never roll back a business transaction.
            logger.exception("Unable to enqueue business-event notification")

    transaction.on_commit(callback)


def mark_read(notification, actor):
    if notification.read_at is None:
        notification.read_at = timezone.now()
        notification.save(update_fields=["read_at", "updated_at"])
        record_audit_event(
            actor=actor,
            tenant_id=(
                notification.organization.tenant_id
                if notification.organization_id
                else None
            ),
            organization_id=notification.organization_id,
            action="notification.read",
            resource_type="notification",
            resource_id=notification.id,
        )
        if notification.organization_id:
            from apps.offline.services import record_sync_change

            record_sync_change(
                organization=notification.organization,
                resource_type="notification",
                resource_id=notification.id,
                operation="updated",
                payload={
                    "id": notification.id,
                    "read_at": notification.read_at,
                    "status": notification.status,
                },
            )
    return notification


def retry_notification(notification, actor):
    if notification.status not in (
        Notification.Status.FAILED,
        Notification.Status.EXPIRED,
    ):
        raise ValueError("Only failed or expired notifications may be retried.")
    attempt_number = notification.delivery_attempts.count() + 1
    DeliveryAttempt.objects.create(
        notification=notification,
        attempt_number=attempt_number,
        status="retry_queued",
    )
    notification.status = Notification.Status.QUEUED
    notification.available_at = timezone.now()
    notification.save(update_fields=["status", "available_at", "updated_at"])
    record_audit_event(
        actor=actor,
        tenant_id=(
            notification.organization.tenant_id
            if notification.organization_id
            else None
        ),
        organization_id=notification.organization_id,
        action="notification.retried",
        resource_type="notification",
        resource_id=notification.id,
    )
    return notification
