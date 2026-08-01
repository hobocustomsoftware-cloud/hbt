from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization


class Notification(TimeStampedModel):
    class Kind(models.TextChoices):
        BOOKING = "booking", "Booking"
        TICKET = "ticket", "Ticket"
        PAYMENT = "payment", "Payment"
        CARGO = "cargo", "Cargo"
        TRIP = "trip", "Trip"
        SYSTEM = "system", "System"
        SECURITY = "security", "Security"

    class Category(models.TextChoices):
        INFORMATION = "information", "Information"
        ACTION_REQUIRED = "action_required", "Action required"
        PAYMENT_VERIFICATION = "payment_verification", "Payment verification"
        TRIP_OPERATION = "trip_operation", "Trip operation"
        URGENT_EXCEPTION = "urgent_exception", "Urgent exception"

    class Channel(models.TextChoices):
        IN_APP = "in_app", "In-app"
        PUSH = "push", "Push"

    class Status(models.TextChoices):
        CREATED = "created", "Created"
        QUEUED = "queued", "Queued"
        PROCESSING = "processing", "Processing"
        SENT = "sent", "Sent"
        DELIVERED = "delivered", "Delivered"
        FAILED = "failed", "Failed"
        EXPIRED = "expired", "Expired"
        CANCELLED = "cancelled", "Cancelled"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.CASCADE,
        related_name="notifications",
        null=True,
        blank=True,
    )
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    event_type = models.CharField(max_length=100)
    event_key = models.CharField(max_length=200)
    kind = models.CharField(max_length=24, choices=Kind.choices)
    category = models.CharField(max_length=32, choices=Category.choices)
    channel = models.CharField(max_length=16, choices=Channel.choices)
    language = models.CharField(max_length=10, default="my")
    title = models.CharField(max_length=160)
    body = models.CharField(max_length=500)
    data = models.JSONField(default=dict)
    deep_link = models.CharField(max_length=500, blank=True)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.CREATED
    )
    available_at = models.DateTimeField()
    expires_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "notification_notification"
        constraints = [
            models.UniqueConstraint(
                fields=["recipient", "event_key", "channel"],
                name="unique_notification_event_channel",
            )
        ]
        indexes = [
            models.Index(
                fields=["recipient", "channel", "read_at", "created_at"],
                name="notification_inbox_idx",
            ),
            models.Index(
                fields=["status", "available_at"],
                name="notification_queue_idx",
            ),
        ]


class DeliveryAttempt(models.Model):
    notification = models.ForeignKey(
        Notification, on_delete=models.CASCADE, related_name="delivery_attempts"
    )
    attempt_number = models.PositiveIntegerField()
    device_id = models.UUIDField(null=True, blank=True)
    provider = models.CharField(max_length=64, blank=True)
    status = models.CharField(max_length=24)
    provider_reference = models.CharField(max_length=200, blank=True)
    failure_reason = models.CharField(max_length=500, blank=True)
    attempted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notification_delivery_attempt"
        constraints = [
            models.UniqueConstraint(
                fields=["notification", "attempt_number", "device_id"],
                name="unique_notification_delivery_attempt",
            )
        ]


class PendingWorkItem(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    organization = models.ForeignKey(
        Organization, on_delete=models.CASCADE, related_name="pending_work_items"
    )
    assignee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="pending_work_items",
    )
    event_key = models.CharField(max_length=200)
    work_type = models.CharField(max_length=80)
    title = models.CharField(max_length=160)
    deep_link = models.CharField(max_length=500)
    priority = models.CharField(max_length=16, default="normal")
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.PENDING
    )
    due_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "notification_pending_work"
        constraints = [
            models.UniqueConstraint(
                fields=["assignee", "event_key", "work_type"],
                name="unique_pending_work_event",
            )
        ]
        indexes = [
            models.Index(
                fields=["assignee", "status", "created_at"],
                name="pending_work_assignee_idx",
            )
        ]
