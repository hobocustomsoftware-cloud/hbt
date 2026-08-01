from datetime import timedelta

from django.db import transaction
from django.db.models import Max
from django.utils import timezone

from apps.offline.models import Device

from .models import DeliveryAttempt, Notification
from .push import configured_push_provider


MAX_PUSH_ATTEMPTS = 5


@transaction.atomic
def dispatch_one_push(notification, provider=None):
    notification = Notification.objects.select_for_update().get(pk=notification.pk)
    if (
        notification.channel != Notification.Channel.PUSH
        or notification.status
        not in (Notification.Status.QUEUED, Notification.Status.FAILED)
        or notification.available_at > timezone.now()
    ):
        return notification
    if notification.expires_at and notification.expires_at <= timezone.now():
        notification.status = Notification.Status.EXPIRED
        notification.save(update_fields=["status", "updated_at"])
        return notification
    provider = provider or configured_push_provider()
    devices = list(
        Device.objects.filter(
            user=notification.recipient,
            status=Device.Status.ACTIVE,
        ).exclude(encrypted_push_token="")  # nosec B106
    )
    if not devices:
        notification.status = Notification.Status.FAILED
        notification.available_at = timezone.now() + timedelta(hours=1)
        notification.save(
            update_fields=["status", "available_at", "updated_at"]
        )
        return notification
    previous = (
        notification.delivery_attempts.aggregate(number=Max("attempt_number"))[
            "number"
        ]
        or 0
    )
    attempt_number = previous + 1
    any_accepted = False
    transient_failure = False
    for device in devices:
        result = provider.send(
            token=device.get_push_token(),
            platform=device.platform,
            notification=notification,
        )
        DeliveryAttempt.objects.create(
            notification=notification,
            attempt_number=attempt_number,
            device_id=device.id,
            provider=provider.name,
            status="accepted" if result.accepted else "failed",
            provider_reference=result.provider_reference,
            failure_reason=result.failure_reason[:500],
        )
        any_accepted = any_accepted or result.accepted
        transient_failure = transient_failure or (
            not result.accepted and not result.permanent_failure
        )
        if result.permanent_failure:
            device.set_push_token("")
            device.save(update_fields=["encrypted_push_token", "updated_at"])
    if any_accepted:
        notification.status = Notification.Status.SENT
    elif transient_failure and attempt_number < MAX_PUSH_ATTEMPTS:
        notification.status = Notification.Status.FAILED
        notification.available_at = timezone.now() + timedelta(
            minutes=min(2 ** attempt_number, 60)
        )
    else:
        notification.status = Notification.Status.FAILED
    notification.save(update_fields=["status", "available_at", "updated_at"])
    return notification


def dispatch_push_batch(*, limit=100, provider=None):
    ids = list(
        Notification.objects.filter(
            channel=Notification.Channel.PUSH,
            status__in=(Notification.Status.QUEUED, Notification.Status.FAILED),
            available_at__lte=timezone.now(),
        )
        .order_by("available_at")
        .values_list("id", flat=True)[:limit]
    )
    return [
        dispatch_one_push(
            Notification.objects.get(pk=notification_id), provider=provider
        )
        for notification_id in ids
    ]
