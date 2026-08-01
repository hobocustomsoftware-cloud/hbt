from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.locations.models import Branch
from apps.tenancy.models import Organization


class SeatLayout(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        REVIEW = "review", "In review"
        APPROVED = "approved", "Approved"
        ACTIVE = "active", "Active"
        RETIRED = "retired", "Retired"
        ARCHIVED = "archived", "Archived"

    class Type(models.TextChoices):
        STANDARD_2_2 = "standard_2_2", "2+2 Standard"
        VIP_2_1 = "vip_2_1", "2+1 VIP"
        SLEEPER = "sleeper", "Sleeper"
        MINI_BUS = "mini_bus", "Mini Bus"
        CUSTOM = "custom", "Custom"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="seat_layouts",
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=150)
    layout_type = models.CharField(max_length=20, choices=Type.choices)
    version = models.PositiveIntegerField(default=1)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    deck_count = models.PositiveSmallIntegerField(default=1)
    row_count = models.PositiveSmallIntegerField()
    column_count = models.PositiveSmallIntegerField()

    class Meta:
        db_table = "fleet_seat_layout"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code", "version"],
                name="unique_layout_code_version",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"],
                name="layout_org_status_idx",
            ),
        ]

    def __str__(self):
        return f"{self.name} v{self.version}"


class LayoutPosition(TimeStampedModel):
    class Type(models.TextChoices):
        STANDARD = "standard", "Standard seat"
        VIP = "vip", "VIP seat"
        SLEEPER = "sleeper", "Sleeper bed"
        RESERVED = "reserved", "Reserved seat"
        CREW = "crew", "Crew seat"
        ACCESSIBLE = "accessible", "Accessible seat"
        AISLE = "aisle", "Aisle"
        EMPTY = "empty", "Empty space"
        STAIRS = "stairs", "Stairs"
        RESTROOM = "restroom", "Restroom"
        DRIVER = "driver", "Driver area"

    layout = models.ForeignKey(
        SeatLayout,
        on_delete=models.CASCADE,
        related_name="positions",
    )
    identifier = models.CharField(max_length=20)
    position_type = models.CharField(max_length=16, choices=Type.choices)
    deck = models.PositiveSmallIntegerField(default=1)
    row = models.PositiveSmallIntegerField()
    column = models.PositiveSmallIntegerField()
    label = models.CharField(max_length=30, blank=True)
    bookable = models.BooleanField(default=True)
    window = models.BooleanField(default=False)
    aisle = models.BooleanField(default=False)

    class Meta:
        db_table = "fleet_layout_position"
        constraints = [
            models.UniqueConstraint(
                fields=["layout", "identifier"],
                name="unique_position_identifier",
            ),
            models.UniqueConstraint(
                fields=["layout", "deck", "row", "column"],
                name="unique_layout_coordinate",
            ),
        ]
        ordering = ("deck", "row", "column")

    def clean(self):
        non_bookable = {
            self.Type.AISLE,
            self.Type.EMPTY,
            self.Type.STAIRS,
            self.Type.RESTROOM,
            self.Type.DRIVER,
        }
        if self.position_type in non_bookable and self.bookable:
            raise ValidationError(
                {"bookable": "This position type cannot be booked."}
            )
        if self.deck > self.layout.deck_count:
            raise ValidationError({"deck": "Deck exceeds layout dimensions."})
        if self.row > self.layout.row_count:
            raise ValidationError({"row": "Row exceeds layout dimensions."})
        if self.column > self.layout.column_count:
            raise ValidationError(
                {"column": "Column exceeds layout dimensions."}
            )

    def __str__(self):
        return self.label or self.identifier


class Vehicle(TimeStampedModel):
    class Category(models.TextChoices):
        EXPRESS_BUS = "express_bus", "Express Bus"
        MINI_BUS = "mini_bus", "Mini Bus"
        CARGO_TRUCK = "cargo_truck", "Cargo Truck"
        SHUTTLE = "shuttle", "Shuttle"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        AVAILABLE = "available", "Available"
        RESERVED = "reserved", "Reserved"
        IN_SERVICE = "in_service", "In service"
        MAINTENANCE = "maintenance", "Under maintenance"
        OUT_OF_SERVICE = "out_of_service", "Out of service"
        RETIRED = "retired", "Retired"
        ARCHIVED = "archived", "Archived"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="vehicles",
    )
    branch = models.ForeignKey(
        Branch,
        on_delete=models.PROTECT,
        related_name="vehicles",
    )
    code = models.SlugField(max_length=50)
    registration_number = models.CharField(max_length=50)
    fleet_number = models.CharField(max_length=50, blank=True)
    category = models.CharField(max_length=20, choices=Category.choices)
    brand = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    manufacturing_year = models.PositiveSmallIntegerField(null=True, blank=True)
    color = models.CharField(max_length=50, blank=True)
    fuel_type = models.CharField(max_length=50, blank=True)
    passenger_capacity = models.PositiveSmallIntegerField(default=0)
    cargo_supported = models.BooleanField(default=True)
    cargo_weight_capacity_kg = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        null=True,
        blank=True,
    )
    air_conditioned = models.BooleanField(default=False)
    wifi_available = models.BooleanField(default=False)
    gps_available = models.BooleanField(default=False)
    accessible = models.BooleanField(default=False)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
    )

    class Meta:
        db_table = "fleet_vehicle"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_vehicle_code_per_org",
            ),
            models.UniqueConstraint(
                fields=["organization", "registration_number"],
                name="unique_registration_per_org",
            ),
            models.UniqueConstraint(
                fields=["organization", "fleet_number"],
                condition=~models.Q(fleet_number=""),
                name="unique_fleet_number_per_org",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"],
                name="vehicle_org_status_idx",
            ),
        ]

    def clean(self):
        if self.branch_id and self.organization_id:
            if self.branch.organization_id != self.organization_id:
                raise ValidationError(
                    {"branch": "Branch must belong to the organization."}
                )

    def __str__(self):
        return self.registration_number


class VehicleLayoutAssignment(TimeStampedModel):
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.PROTECT,
        related_name="layout_assignments",
    )
    layout = models.ForeignKey(
        SeatLayout,
        on_delete=models.PROTECT,
        related_name="vehicle_assignments",
    )
    effective_from = models.DateTimeField()
    effective_until = models.DateTimeField(null=True, blank=True)
    assigned_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="vehicle_layout_assignments",
    )

    class Meta:
        db_table = "fleet_vehicle_layout_assignment"
        indexes = [
            models.Index(
                fields=["vehicle", "effective_from", "effective_until"],
                name="vehicle_layout_period_idx",
            ),
        ]

    def clean(self):
        if self.vehicle.organization_id != self.layout.organization_id:
            raise ValidationError("Vehicle and layout must share an organization.")
        if self.layout.status not in (
            SeatLayout.Status.APPROVED,
            SeatLayout.Status.ACTIVE,
        ):
            raise ValidationError("Only approved layouts may be assigned.")
        if (
            self.effective_until
            and self.effective_until <= self.effective_from
        ):
            raise ValidationError(
                {"effective_until": "End must be later than start."}
            )
        bookable_count = self.layout.positions.filter(bookable=True).count()
        if bookable_count != self.vehicle.passenger_capacity:
            raise ValidationError(
                "Layout bookable-seat count must equal vehicle passenger capacity."
            )
