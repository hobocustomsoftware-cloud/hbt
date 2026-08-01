import uuid

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.core.validators import RegexValidator
from django.db import models

from .managers import UserManager

phone_validator = RegexValidator(
    regex=r"^\+?[0-9]{7,15}$",
    message="Enter a valid international or Myanmar phone number.",
)


class User(AbstractBaseUser, PermissionsMixin):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        DISABLED = "disabled", "Disabled"

    class Language(models.TextChoices):
        MYANMAR = "my", "Myanmar"
        ENGLISH = "en", "English"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(
        max_length=16,
        unique=True,
        validators=[phone_validator],
    )
    email = models.EmailField(blank=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.PENDING,
    )
    preferred_language = models.CharField(
        max_length=2,
        choices=Language.choices,
        default=Language.MYANMAR,
    )
    phone_verified_at = models.DateTimeField(null=True, blank=True)
    email_verified_at = models.DateTimeField(null=True, blank=True)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = []

    class Meta:
        db_table = "identity_user"
        indexes = [
            models.Index(fields=["status"], name="identity_user_status_idx"),
        ]

    def __str__(self) -> str:
        return self.phone_number


class PlatformAccessGrant(models.Model):
    class Role(models.TextChoices):
        SUPER_ADMIN = "super_admin", "Platform Super Admin"
        SUPPORT = "support", "Platform Support"
        SECURITY = "security", "Platform Security"
        AUDITOR = "auditor", "Platform Auditor"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="platform_access_grants",
    )
    role = models.CharField(max_length=32, choices=Role.choices)
    is_active = models.BooleanField(default=True)
    valid_from = models.DateTimeField(null=True, blank=True)
    valid_until = models.DateTimeField(null=True, blank=True)
    granted_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="platform_grants_issued",
    )
    reason = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    revoked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "identity_platform_access_grant"
        indexes = [
            models.Index(
                fields=["user", "role", "is_active"],
                name="platform_grant_active_idx",
            ),
        ]

    def clean(self):
        from django.core.exceptions import ValidationError

        if self.user_id == self.granted_by_id:
            raise ValidationError(
                {"granted_by": "Platform access cannot be self-granted."}
            )
        if (
            self.valid_from
            and self.valid_until
            and self.valid_until <= self.valid_from
        ):
            raise ValidationError(
                {"valid_until": "Expiry must be later than the start time."}
            )


class DataSubjectRequest(models.Model):
    class Type(models.TextChoices):
        ACCESS = "access", "Access"
        CORRECTION = "correction", "Correction"
        EXPORT = "export", "Export"
        DELETION = "deletion", "Deletion"
        RESTRICTION = "restriction", "Restriction"

    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Submitted"
        VERIFIED = "verified", "Identity verified"
        IN_PROGRESS = "in_progress", "In progress"
        FULFILLED = "fulfilled", "Fulfilled"
        REJECTED = "rejected", "Rejected"
        CANCELLED = "cancelled", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.PROTECT, related_name="privacy_requests"
    )
    request_type = models.CharField(max_length=16, choices=Type.choices)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.SUBMITTED
    )
    details = models.TextField(blank=True)
    jurisdiction = models.CharField(max_length=8, default="MM")
    due_at = models.DateTimeField()
    verification_method = models.CharField(max_length=80, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    retention_hold = models.BooleanField(default=False)
    retention_reason = models.TextField(blank=True)
    response_summary = models.TextField(blank=True)
    evidence_reference = models.CharField(max_length=255, blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="privacy_requests_reviewed",
    )
    resolved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "identity_data_subject_request"
        constraints = [
            models.UniqueConstraint(
                fields=["user", "request_type"],
                condition=models.Q(
                    status__in=["submitted", "verified", "in_progress"]
                ),
                name="unique_active_privacy_request_type_per_user",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(retention_hold=False, retention_reason="")
                    | models.Q(retention_hold=True)
                ),
                name="privacy_retention_reason_only_with_hold",
            ),
        ]
        indexes = [
            models.Index(
                fields=["status", "due_at"],
                name="privacy_status_due_idx",
            )
        ]
