from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Membership, Organization
from apps.core.field_crypto import decrypt_push_token, encrypt_push_token


class Device(TimeStampedModel):
    class Platform(models.TextChoices):
        ANDROID = "android", "Android"
        IOS = "ios", "iOS"
        WEB = "web", "Web"

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        REVOKED = "revoked", "Revoked"
        REPLACED = "replaced", "Replaced"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="offline_devices",
    )
    installation_id = models.UUIDField(unique=True)
    platform = models.CharField(max_length=16, choices=Platform.choices)
    app_id = models.CharField(max_length=64)
    app_version = models.CharField(max_length=32)
    device_name = models.CharField(max_length=120, blank=True)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.ACTIVE
    )
    encrypted_push_token = models.TextField(blank=True)
    last_seen_at = models.DateTimeField(null=True, blank=True)
    revoked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "offline_device"
        indexes = [
            models.Index(fields=["user", "status"], name="offline_device_user_idx"),
        ]

    def set_push_token(self, value):
        self.encrypted_push_token = encrypt_push_token(value.strip()) if value else ""

    def get_push_token(self):
        return decrypt_push_token(self.encrypted_push_token)


class AuthorizationSnapshot(TimeStampedModel):
    device = models.ForeignKey(
        Device, on_delete=models.CASCADE, related_name="authorization_snapshots"
    )
    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="offline_authorization_snapshots",
    )
    membership = models.ForeignKey(
        Membership, on_delete=models.PROTECT, related_name="+"
    )
    permissions = models.JSONField(default=list)
    scopes = models.JSONField(default=list)
    issued_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "offline_authorization_snapshot"
        indexes = [
            models.Index(
                fields=["device", "organization", "expires_at"],
                name="offline_auth_expiry_idx",
            ),
        ]


class SyncChange(models.Model):
    sequence = models.BigAutoField(primary_key=True)
    organization = models.ForeignKey(
        Organization, on_delete=models.CASCADE, related_name="sync_changes"
    )
    resource_type = models.CharField(max_length=80)
    resource_id = models.UUIDField()
    operation = models.CharField(max_length=16)
    version = models.PositiveBigIntegerField(default=1)
    payload = models.JSONField(default=dict)
    occurred_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "offline_sync_change"
        indexes = [
            models.Index(
                fields=["organization", "sequence"],
                name="offline_change_cursor_idx",
            )
        ]


class SyncOperation(TimeStampedModel):
    class Status(models.TextChoices):
        RECEIVED = "received", "Received"
        APPLIED = "applied", "Applied"
        REJECTED = "rejected", "Rejected"
        CONFLICT = "conflict", "Conflict"

    device = models.ForeignKey(
        Device, on_delete=models.PROTECT, related_name="sync_operations"
    )
    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="sync_operations"
    )
    client_operation_id = models.UUIDField()
    operation_type = models.CharField(max_length=100)
    payload_hash = models.CharField(max_length=64)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.RECEIVED
    )
    request_payload = models.JSONField(default=dict)
    response_payload = models.JSONField(default=dict)
    error_code = models.CharField(max_length=80, blank=True)

    class Meta:
        db_table = "offline_sync_operation"
        constraints = [
            models.UniqueConstraint(
                fields=["device", "client_operation_id"],
                name="unique_offline_device_operation",
            )
        ]
        indexes = [
            models.Index(
                fields=["organization", "created_at"],
                name="offline_operation_org_idx",
            )
        ]
