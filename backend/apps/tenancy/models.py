from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel


class TenantQuerySet(models.QuerySet):
    def active(self):
        return self.filter(status=Tenant.Status.ACTIVE)


class Tenant(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        DISABLED = "disabled", "Disabled"
        ARCHIVED = "archived", "Archived"

    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=100, unique=True)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.PENDING,
    )
    primary_language = models.CharField(max_length=10, default="my")
    timezone = models.CharField(max_length=64, default="Asia/Yangon")
    currency = models.CharField(max_length=3, default="MMK")

    objects = TenantQuerySet.as_manager()

    class Meta:
        db_table = "tenancy_tenant"
        indexes = [
            models.Index(fields=["status"], name="tenant_status_idx"),
        ]

    def __str__(self) -> str:
        return self.name


class OrganizationQuerySet(models.QuerySet):
    def for_tenant(self, tenant):
        return self.filter(tenant=tenant)


class Organization(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        CLOSED = "closed", "Closed"
        ARCHIVED = "archived", "Archived"

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        related_name="organizations",
    )
    legal_name = models.CharField(max_length=255)
    display_name = models.CharField(max_length=255)
    registration_number = models.CharField(max_length=100, blank=True)
    tax_identifier = models.CharField(max_length=100, blank=True)
    contact_phone = models.CharField(max_length=32, blank=True)
    contact_email = models.EmailField(blank=True)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.PENDING,
    )

    objects = OrganizationQuerySet.as_manager()

    class Meta:
        db_table = "tenancy_organization"
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "legal_name"],
                name="unique_legal_name_per_tenant",
            ),
            models.UniqueConstraint(
                fields=["tenant", "registration_number"],
                condition=~models.Q(registration_number=""),
                name="unique_registration_per_tenant",
            ),
        ]
        indexes = [
            models.Index(
                fields=["tenant", "status"],
                name="org_tenant_status_idx",
            ),
        ]

    def __str__(self) -> str:
        return self.display_name


class Membership(TimeStampedModel):
    class Status(models.TextChoices):
        INVITED = "invited", "Invited"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        REVOKED = "revoked", "Revoked"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="memberships",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="organization_memberships",
    )
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.INVITED,
    )
    invited_at = models.DateTimeField(null=True, blank=True)
    joined_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "tenancy_membership"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "user"],
                name="unique_org_user_membership",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"],
                name="membership_org_status_idx",
            ),
            models.Index(
                fields=["user", "status"],
                name="membership_user_status_idx",
            ),
        ]

    @property
    def tenant_id(self):
        return self.organization.tenant_id


class Permission(TimeStampedModel):
    code = models.CharField(max_length=150, unique=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)

    class Meta:
        db_table = "tenancy_permission"
        ordering = ("code",)

    def __str__(self) -> str:
        return self.code


class Role(TimeStampedModel):
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        related_name="roles",
        null=True,
        blank=True,
        help_text="Null identifies a platform-provided role template.",
    )
    code = models.SlugField(max_length=100)
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    is_system = models.BooleanField(default=False)
    permissions = models.ManyToManyField(
        Permission,
        related_name="roles",
        blank=True,
    )

    class Meta:
        db_table = "tenancy_role"
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "code"],
                name="unique_role_code_per_tenant",
                condition=models.Q(tenant__isnull=False),
            ),
            models.UniqueConstraint(
                fields=["code"],
                name="unique_platform_role_code",
                condition=models.Q(tenant__isnull=True),
            ),
        ]

    def __str__(self) -> str:
        return self.name


class MembershipRole(TimeStampedModel):
    class ScopeType(models.TextChoices):
        COMPANY = "company", "Company-wide"
        BRANCH = "branch", "Branch"
        TERMINAL = "terminal", "Terminal"
        COUNTER = "counter", "Counter"
        ASSIGNED_TRIP = "assigned_trip", "Assigned trip"
        SELF = "self", "Self only"

    membership = models.ForeignKey(
        Membership,
        on_delete=models.CASCADE,
        related_name="role_assignments",
    )
    role = models.ForeignKey(
        Role,
        on_delete=models.PROTECT,
        related_name="membership_assignments",
    )
    scope_type = models.CharField(max_length=32, choices=ScopeType.choices)
    scope_id = models.UUIDField(null=True, blank=True)
    valid_from = models.DateTimeField(null=True, blank=True)
    valid_until = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "tenancy_membership_role"
        constraints = [
            models.UniqueConstraint(
                fields=["membership", "role", "scope_type", "scope_id"],
                name="unique_membership_role_scope",
                condition=models.Q(scope_id__isnull=False),
            ),
            models.UniqueConstraint(
                fields=["membership", "role", "scope_type"],
                name="unique_membership_role_null_scope",
                condition=models.Q(scope_id__isnull=True),
            ),
        ]
        indexes = [
            models.Index(
                fields=["membership", "scope_type", "scope_id"],
                name="member_role_scope_idx",
            ),
        ]

    def clean(self):
        if self.role.tenant_id not in (
            None,
            self.membership.organization.tenant_id,
        ):
            raise ValidationError(
                {"role": "Role and membership must belong to the same tenant."}
            )
        if self.scope_type in (self.ScopeType.COMPANY, self.ScopeType.SELF):
            if self.scope_id is not None:
                raise ValidationError(
                    {"scope_id": "This scope type must not have a scope ID."}
                )
        elif self.scope_id is None:
            raise ValidationError(
                {"scope_id": "This scope type requires a scope ID."}
            )


class TenantSupportAccess(TimeStampedModel):
    class Level(models.TextChoices):
        READ_ONLY = "read_only", "Read only"
        LIMITED_WRITE = "limited_write", "Limited write"

    class Status(models.TextChoices):
        REQUESTED = "requested", "Requested"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        REVOKED = "revoked", "Revoked"
        EXPIRED = "expired", "Expired"

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        related_name="support_access_grants",
    )
    requester = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="support_access_requests",
    )
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="support_access_approvals",
        null=True,
        blank=True,
    )
    level = models.CharField(max_length=20, choices=Level.choices)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.REQUESTED,
    )
    reason = models.TextField()
    permissions = models.ManyToManyField(
        Permission,
        related_name="support_access_grants",
        blank=True,
    )
    starts_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    approved_at = models.DateTimeField(null=True, blank=True)
    revoked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "tenancy_support_access"
        indexes = [
            models.Index(
                fields=["tenant", "status", "expires_at"],
                name="support_tenant_status_idx",
            ),
            models.Index(
                fields=["requester", "status"],
                name="support_requester_idx",
            ),
        ]

    def clean(self):
        if self.expires_at <= self.starts_at:
            raise ValidationError(
                {"expires_at": "Expiry must be later than the start time."}
            )
        if self.approved_by_id and self.approved_by_id == self.requester_id:
            raise ValidationError(
                {"approved_by": "Support access cannot be self-approved."}
            )
