from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel
from apps.locations.models import Branch
from apps.tenancy.models import Membership


class StaffProfile(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        INACTIVE = "inactive", "Inactive"
        RETIRED = "retired", "Retired"
        ARCHIVED = "archived", "Archived"

    membership = models.OneToOneField(
        Membership,
        on_delete=models.PROTECT,
        related_name="staff_profile",
    )
    branch = models.ForeignKey(
        Branch,
        on_delete=models.PROTECT,
        related_name="staff_profiles",
    )
    employee_code = models.CharField(max_length=50)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.PENDING,
    )
    emergency_contact_name = models.CharField(max_length=150, blank=True)
    emergency_contact_phone = models.CharField(max_length=32, blank=True)

    class Meta:
        db_table = "workforce_staff_profile"
        constraints = [
            models.UniqueConstraint(
                fields=["branch", "employee_code"],
                name="unique_employee_code_per_branch",
            ),
        ]

    def clean(self):
        if (
            self.branch_id
            and self.membership_id
            and self.branch.organization_id
            != self.membership.organization_id
        ):
            raise ValidationError(
                {"branch": "Branch and membership must share an organization."}
            )

    @property
    def organization_id(self):
        return self.membership.organization_id


class DriverProfile(TimeStampedModel):
    class Availability(models.TextChoices):
        AVAILABLE = "available", "Available"
        ASSIGNED = "assigned", "Assigned"
        ON_DUTY = "on_duty", "On duty"
        OFF_DUTY = "off_duty", "Off duty"
        LEAVE = "leave", "Leave"
        SUSPENDED = "suspended", "Suspended"
        RETIRED = "retired", "Retired"

    staff = models.OneToOneField(
        StaffProfile,
        on_delete=models.PROTECT,
        related_name="driver_profile",
    )
    driver_code = models.CharField(max_length=50)
    license_number = models.CharField(max_length=100)
    license_class = models.CharField(max_length=100)
    license_expiry = models.DateField()
    medical_clearance_expiry = models.DateField(null=True, blank=True)
    certifications = models.JSONField(default=list, blank=True)
    authorized_vehicle_categories = models.JSONField(default=list, blank=True)
    availability = models.CharField(
        max_length=16,
        choices=Availability.choices,
        default=Availability.OFF_DUTY,
    )
    qualifications_verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "workforce_driver_profile"
        constraints = [
            models.UniqueConstraint(
                fields=["staff", "driver_code"],
                name="unique_driver_code_per_staff",
            ),
            models.UniqueConstraint(
                fields=["license_number"],
                name="unique_driver_license_number",
            ),
        ]

    @property
    def operationally_eligible(self):
        today = timezone.localdate()
        return (
            self.staff.status == StaffProfile.Status.ACTIVE
            and self.availability == self.Availability.AVAILABLE
            and self.license_expiry >= today
            and (
                self.medical_clearance_expiry is None
                or self.medical_clearance_expiry >= today
            )
            and self.qualifications_verified_at is not None
        )


class ConductorProfile(TimeStampedModel):
    class Availability(models.TextChoices):
        AVAILABLE = "available", "Available"
        ASSIGNED = "assigned", "Assigned"
        ON_DUTY = "on_duty", "On duty"
        OFF_DUTY = "off_duty", "Off duty"
        LEAVE = "leave", "Leave"
        SUSPENDED = "suspended", "Suspended"
        RETIRED = "retired", "Retired"

    staff = models.OneToOneField(
        StaffProfile,
        on_delete=models.PROTECT,
        related_name="conductor_profile",
    )
    conductor_code = models.CharField(max_length=50)
    availability = models.CharField(
        max_length=16,
        choices=Availability.choices,
        default=Availability.OFF_DUTY,
    )
    qualifications = models.JSONField(default=list, blank=True)
    trained_for_ticketing = models.BooleanField(default=False)
    trained_for_cargo = models.BooleanField(default=False)
    trained_for_cash_handling = models.BooleanField(default=False)
    qualifications_verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "workforce_conductor_profile"
        constraints = [
            models.UniqueConstraint(
                fields=["staff", "conductor_code"],
                name="unique_conductor_code_per_staff",
            ),
        ]

    @property
    def operationally_eligible(self):
        return (
            self.staff.status == StaffProfile.Status.ACTIVE
            and self.availability == self.Availability.AVAILABLE
            and self.qualifications_verified_at is not None
        )
