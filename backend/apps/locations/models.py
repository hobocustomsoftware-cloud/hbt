from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization


class OperationalStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    ACTIVE = "active", "Active"
    SUSPENDED = "suspended", "Suspended"
    CLOSED = "closed", "Closed"
    ARCHIVED = "archived", "Archived"


class AddressFieldsMixin(models.Model):
    country_code = models.CharField(max_length=2, default="MM")
    region = models.CharField(max_length=100, blank=True)
    township = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    address_line = models.TextField(blank=True)
    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
    )

    class Meta:
        abstract = True


class BranchQuerySet(models.QuerySet):
    def for_organization(self, organization):
        return self.filter(organization=organization)


class Branch(TimeStampedModel, AddressFieldsMixin):
    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="branches",
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=255)
    status = models.CharField(
        max_length=16,
        choices=OperationalStatus.choices,
        default=OperationalStatus.DRAFT,
    )
    contact_phone = models.CharField(max_length=32, blank=True)
    contact_email = models.EmailField(blank=True)
    operating_hours = models.JSONField(default=dict, blank=True)

    objects = BranchQuerySet.as_manager()

    class Meta:
        db_table = "locations_branch"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_branch_code_per_org",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"],
                name="branch_org_status_idx",
            ),
        ]

    def __str__(self):
        return self.name


class PhysicalTerminal(TimeStampedModel, AddressFieldsMixin):
    code = models.SlugField(max_length=50, unique=True)
    name = models.CharField(max_length=255)
    name_myanmar = models.CharField(max_length=255, blank=True)
    status = models.CharField(
        max_length=16,
        choices=OperationalStatus.choices,
        default=OperationalStatus.DRAFT,
    )
    contact_phone = models.CharField(max_length=32, blank=True)

    class Meta:
        db_table = "locations_physical_terminal"
        indexes = [
            models.Index(
                fields=["status", "region", "city"],
                name="terminal_status_location_idx",
            ),
        ]

    def __str__(self):
        return self.name


class CompanyTerminalOperation(TimeStampedModel):
    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="terminal_operations",
    )
    branch = models.ForeignKey(
        Branch,
        on_delete=models.PROTECT,
        related_name="terminal_operations",
    )
    terminal = models.ForeignKey(
        PhysicalTerminal,
        on_delete=models.PROTECT,
        related_name="company_operations",
    )
    code = models.SlugField(max_length=50)
    display_name = models.CharField(max_length=255)
    status = models.CharField(
        max_length=16,
        choices=OperationalStatus.choices,
        default=OperationalStatus.DRAFT,
    )
    operating_hours = models.JSONField(default=dict, blank=True)
    local_contact_phone = models.CharField(max_length=32, blank=True)

    class Meta:
        db_table = "locations_terminal_operation"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_terminal_operation_code",
            ),
            models.UniqueConstraint(
                fields=["organization", "terminal"],
                name="unique_org_physical_terminal",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"],
                name="terminal_op_org_status_idx",
            ),
        ]

    def clean(self):
        if self.branch_id and self.organization_id:
            if self.branch.organization_id != self.organization_id:
                raise ValidationError(
                    {"branch": "Branch must belong to the same organization."}
                )

    def __str__(self):
        return self.display_name


class SalesCounter(TimeStampedModel):
    terminal_operation = models.ForeignKey(
        CompanyTerminalOperation,
        on_delete=models.PROTECT,
        related_name="sales_counters",
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=150)
    status = models.CharField(
        max_length=16,
        choices=OperationalStatus.choices,
        default=OperationalStatus.DRAFT,
    )
    contact_phone = models.CharField(max_length=32, blank=True)
    operating_hours = models.JSONField(default=dict, blank=True)
    supports_printing = models.BooleanField(default=True)

    class Meta:
        db_table = "locations_sales_counter"
        constraints = [
            models.UniqueConstraint(
                fields=["terminal_operation", "code"],
                name="unique_counter_code_per_operation",
            ),
        ]
        indexes = [
            models.Index(
                fields=["terminal_operation", "status"],
                name="counter_operation_status_idx",
            ),
        ]

    @property
    def organization_id(self):
        return self.terminal_operation.organization_id

    def __str__(self):
        return self.name
