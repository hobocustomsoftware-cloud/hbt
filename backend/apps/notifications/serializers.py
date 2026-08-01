from rest_framework import serializers

from .models import DeliveryAttempt, Notification, PendingWorkItem


class DeliveryAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryAttempt
        fields = "__all__"
        read_only_fields = (
            "id", "notification", "attempt_number", "device_id", "provider",
            "status", "provider_reference", "failure_reason", "attempted_at",
        )


class NotificationSerializer(serializers.ModelSerializer):
    delivery_attempts = DeliveryAttemptSerializer(many=True, read_only=True)

    class Meta:
        model = Notification
        fields = (
            "id",
            "organization",
            "event_type",
            "kind",
            "category",
            "channel",
            "language",
            "title",
            "body",
            "data",
            "deep_link",
            "status",
            "available_at",
            "expires_at",
            "read_at",
            "delivery_attempts",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class PendingWorkItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PendingWorkItem
        fields = "__all__"
        read_only_fields = (
            "id", "organization", "assignee", "event_key", "work_type",
            "title", "deep_link", "priority", "status", "due_at",
            "completed_at", "created_at", "updated_at",
        )
