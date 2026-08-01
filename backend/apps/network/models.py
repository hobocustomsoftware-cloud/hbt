from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.locations.models import PhysicalTerminal
from apps.tenancy.models import Organization


class Route(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        REVIEW = "review", "In review"
        APPROVED = "approved", "Approved"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        RETIRED = "retired", "Retired"
        ARCHIVED = "archived", "Archived"

    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="routes",
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=255)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    estimated_distance_km = models.DecimalField(
        max_digits=9,
        decimal_places=2,
        null=True,
        blank=True,
    )
    estimated_duration_minutes = models.PositiveIntegerField(
        null=True,
        blank=True,
    )
    operating_region = models.CharField(max_length=150, blank=True)

    class Meta:
        db_table = "network_route"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_route_code_per_org",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(estimated_distance_km__isnull=True)
                    | models.Q(estimated_distance_km__gt=0)
                ),
                name="route_distance_positive",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"],
                name="route_org_status_idx",
            ),
        ]

    def __str__(self):
        return self.name


class RouteStop(TimeStampedModel):
    class Type(models.TextChoices):
        TERMINAL = "terminal", "Terminal"
        MAJOR = "major", "Major stop"
        MINOR = "minor", "Minor stop"
        PICKUP = "pickup", "Pickup point"
        DROPOFF = "dropoff", "Drop-off point"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        APPROVED = "approved", "Approved"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        ARCHIVED = "archived", "Archived"

    route = models.ForeignKey(
        Route,
        on_delete=models.CASCADE,
        related_name="stops",
    )
    terminal = models.ForeignKey(
        PhysicalTerminal,
        on_delete=models.PROTECT,
        related_name="route_stops",
        null=True,
        blank=True,
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=255)
    sequence = models.PositiveIntegerField()
    stop_type = models.CharField(max_length=16, choices=Type.choices)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    boarding_allowed = models.BooleanField(default=True)
    dropoff_allowed = models.BooleanField(default=True)
    cargo_allowed = models.BooleanField(default=False)
    rest_stop = models.BooleanField(default=False)
    meal_stop = models.BooleanField(default=False)
    fuel_stop = models.BooleanField(default=False)
    driver_change_allowed = models.BooleanField(default=False)
    region = models.CharField(max_length=100, blank=True)
    township = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    address_line = models.TextField(blank=True)
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )

    class Meta:
        db_table = "network_route_stop"
        ordering = ("sequence",)
        constraints = [
            models.UniqueConstraint(
                fields=["route", "sequence"],
                name="unique_stop_sequence_per_route",
            ),
            models.UniqueConstraint(
                fields=["route", "code"],
                name="unique_stop_code_per_route",
            ),
            models.CheckConstraint(
                condition=models.Q(sequence__gt=0),
                name="route_stop_sequence_positive",
            ),
        ]

    def clean(self):
        if self.stop_type == self.Type.TERMINAL and not self.terminal_id:
            raise ValidationError(
                {"terminal": "A terminal stop requires a physical terminal."}
            )
        if self.terminal_id and self.stop_type != self.Type.TERMINAL:
            raise ValidationError(
                {"stop_type": "A physical terminal requires terminal type."}
            )

    def __str__(self):
        return f"{self.sequence}. {self.name}"


class RouteSegment(TimeStampedModel):
    route = models.ForeignKey(
        Route,
        on_delete=models.CASCADE,
        related_name="segments",
    )
    from_stop = models.ForeignKey(
        RouteStop,
        on_delete=models.CASCADE,
        related_name="outgoing_segments",
    )
    to_stop = models.ForeignKey(
        RouteStop,
        on_delete=models.CASCADE,
        related_name="incoming_segments",
    )
    sequence = models.PositiveIntegerField()
    distance_km = models.DecimalField(
        max_digits=9,
        decimal_places=2,
        null=True,
        blank=True,
    )
    estimated_duration_minutes = models.PositiveIntegerField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "network_route_segment"
        ordering = ("sequence",)
        constraints = [
            models.UniqueConstraint(
                fields=["route", "sequence"],
                name="unique_segment_sequence_per_route",
            ),
            models.UniqueConstraint(
                fields=["route", "from_stop", "to_stop"],
                name="unique_segment_path_per_route",
            ),
            models.CheckConstraint(
                condition=~models.Q(from_stop=models.F("to_stop")),
                name="segment_stops_different",
            ),
            models.CheckConstraint(
                condition=models.Q(sequence__gt=0),
                name="route_segment_sequence_positive",
            ),
        ]

    def clean(self):
        if (
            self.from_stop_id
            and self.from_stop.route_id != self.route_id
        ) or (
            self.to_stop_id
            and self.to_stop.route_id != self.route_id
        ):
            raise ValidationError(
                "Both segment stops must belong to the same route."
            )
        if (
            self.from_stop_id
            and self.to_stop_id
            and self.to_stop.sequence <= self.from_stop.sequence
        ):
            raise ValidationError(
                "A segment must move forward through the stop sequence."
            )

    def __str__(self):
        return f"{self.from_stop} → {self.to_stop}"
