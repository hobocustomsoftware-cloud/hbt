from datetime import datetime, timedelta

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel
from apps.fleet.models import SeatLayout, Vehicle
from apps.network.models import Route
from apps.tenancy.models import Organization
from apps.workforce.models import ConductorProfile, DriverProfile


class Schedule(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        REVIEW = "review", "In review"
        APPROVED = "approved", "Approved"
        OPERATIONAL = "operational", "Operational"
        SUSPENDED = "suspended", "Suspended"
        EXPIRED = "expired", "Expired"
        ARCHIVED = "archived", "Archived"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="schedules"
    )
    route = models.ForeignKey(
        Route, on_delete=models.PROTECT, related_name="schedules"
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=255)
    planned_departure_time = models.TimeField()
    planned_arrival_time = models.TimeField()
    arrival_day_offset = models.PositiveSmallIntegerField(default=0)
    operating_days = models.JSONField(default=list)
    effective_from = models.DateField()
    expires_on = models.DateField(null=True, blank=True)
    operates_on_public_holidays = models.BooleanField(default=True)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.DRAFT
    )
    version = models.PositiveIntegerField(default=1)

    class Meta:
        db_table = "scheduling_schedule"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code", "version"],
                name="unique_schedule_code_version",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status"], name="schedule_org_status_idx"
            ),
        ]

    def clean(self):
        if self.route_id and self.organization_id:
            if self.route.organization_id != self.organization_id:
                raise ValidationError(
                    {"route": "Route must belong to the organization."}
                )
        if self.expires_on and self.expires_on < self.effective_from:
            raise ValidationError(
                {"expires_on": "Expiration cannot precede the effective date."}
            )
        days = self.operating_days
        if not isinstance(days, list) or not days:
            raise ValidationError(
                {"operating_days": "Select at least one operating weekday (0-6)."}
            )
        if any(type(day) is not int or day < 0 or day > 6 for day in days):
            raise ValidationError(
                {"operating_days": "Weekdays must be integers from 0 to 6."}
            )
        if len(days) != len(set(days)):
            raise ValidationError(
                {"operating_days": "Operating weekdays cannot be duplicated."}
            )
        if (
            self.arrival_day_offset == 0
            and self.planned_arrival_time <= self.planned_departure_time
        ):
            raise ValidationError(
                {"planned_arrival_time": "Arrival must be after departure."}
            )

    def operates_on(self, service_date):
        return (
            self.status == self.Status.OPERATIONAL
            and self.effective_from <= service_date
            and (self.expires_on is None or service_date <= self.expires_on)
            and service_date.weekday() in self.operating_days
        )


class Trip(TimeStampedModel):
    class Status(models.TextChoices):
        PLANNED = "planned", "Planned"
        READY = "ready", "Ready"
        BOARDING = "boarding", "Boarding"
        DEPARTED = "departed", "Departed"
        IN_PROGRESS = "in_progress", "In progress"
        DELAYED = "delayed", "Delayed"
        INTERRUPTED = "interrupted", "Interrupted"
        ARRIVED = "arrived", "Arrived"
        COMPLETED = "completed", "Completed"
        CLOSED = "closed", "Closed"
        CANCELLED = "cancelled", "Cancelled"
        ARCHIVED = "archived", "Archived"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="trips"
    )
    schedule = models.ForeignKey(
        Schedule,
        on_delete=models.PROTECT,
        related_name="trips",
        null=True,
        blank=True,
    )
    route = models.ForeignKey(
        Route, on_delete=models.PROTECT, related_name="trips"
    )
    trip_number = models.CharField(max_length=50)
    service_date = models.DateField()
    planned_departure_at = models.DateTimeField()
    planned_arrival_at = models.DateTimeField()
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.PLANNED
    )
    operational_notes = models.TextField(blank=True)
    boarding_started_at = models.DateTimeField(null=True, blank=True)
    departed_at = models.DateTimeField(null=True, blank=True)
    arrived_at = models.DateTimeField(null=True, blank=True)
    current_stop = models.ForeignKey(
        "network.RouteStop",
        on_delete=models.PROTECT,
        related_name="current_trips",
        null=True,
        blank=True,
    )
    schedule_snapshot = models.JSONField(default=dict, blank=True)
    route_snapshot = models.JSONField(default=dict, blank=True)
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.PROTECT,
        related_name="assigned_trips",
        null=True,
        blank=True,
    )
    driver = models.ForeignKey(
        DriverProfile,
        on_delete=models.PROTECT,
        related_name="assigned_trips",
        null=True,
        blank=True,
    )
    conductor = models.ForeignKey(
        ConductorProfile,
        on_delete=models.PROTECT,
        related_name="assigned_trips",
        null=True,
        blank=True,
    )
    seat_layout = models.ForeignKey(
        SeatLayout,
        on_delete=models.PROTECT,
        related_name="trip_snapshots",
        null=True,
        blank=True,
    )
    seat_layout_snapshot = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = "scheduling_trip"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "trip_number"],
                name="unique_trip_number_per_org",
            ),
            models.UniqueConstraint(
                fields=["schedule", "service_date"],
                condition=models.Q(schedule__isnull=False),
                name="unique_schedule_trip_per_service_date",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "service_date", "status"],
                name="trip_org_date_status_idx",
            ),
        ]

    @property
    def resources_complete(self):
        return bool(self.vehicle_id and self.driver_id)

    @property
    def immutable(self):
        return self.status in (
            self.Status.COMPLETED,
            self.Status.CLOSED,
            self.Status.ARCHIVED,
        )

    def clean(self):
        if self.route_id and self.route.organization_id != self.organization_id:
            raise ValidationError(
                {"route": "Route must belong to the organization."}
            )
        if self.schedule_id:
            if self.schedule.organization_id != self.organization_id:
                raise ValidationError(
                    {"schedule": "Schedule must belong to the organization."}
                )
            if self.schedule.route_id != self.route_id:
                raise ValidationError(
                    {"route": "Trip route must match its schedule route."}
                )
        if self.planned_arrival_at <= self.planned_departure_at:
            raise ValidationError(
                {"planned_arrival_at": "Arrival must be after departure."}
            )
        if self.planned_departure_at.date() != self.service_date:
            raise ValidationError(
                {"service_date": "Service date must match planned departure."}
            )
        if self.current_stop_id and self.current_stop.route_id != self.route_id:
            raise ValidationError(
                {"current_stop": "Current stop must belong to the trip route."}
            )


class TripAssignmentEvent(TimeStampedModel):
    class ResourceType(models.TextChoices):
        VEHICLE = "vehicle", "Vehicle"
        DRIVER = "driver", "Driver"
        CONDUCTOR = "conductor", "Conductor"

    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="assignment_events"
    )
    resource_type = models.CharField(max_length=12, choices=ResourceType.choices)
    previous_resource_id = models.UUIDField(null=True, blank=True)
    resource_id = models.UUIDField()
    assigned_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="trip_assignment_events",
    )
    reason = models.CharField(max_length=255, blank=True)

    class Meta:
        db_table = "scheduling_trip_assignment_event"
        ordering = ("created_at",)


class TripOperationalEvent(TimeStampedModel):
    class Type(models.TextChoices):
        READY = "ready", "Trip ready"
        BOARDING_STARTED = "boarding_started", "Boarding started"
        DEPARTED = "departed", "Departed"
        EN_ROUTE = "en_route", "En route"
        STOP_REACHED = "stop_reached", "Stop reached"
        ARRIVED = "arrived", "Arrived"

    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="operational_events"
    )
    event_type = models.CharField(max_length=20, choices=Type.choices)
    from_status = models.CharField(max_length=16, choices=Trip.Status.choices)
    to_status = models.CharField(max_length=16, choices=Trip.Status.choices)
    route_stop = models.ForeignKey(
        "network.RouteStop",
        on_delete=models.PROTECT,
        related_name="trip_operational_events",
        null=True,
        blank=True,
    )
    occurred_at = models.DateTimeField(default=timezone.now)
    recorded_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="trip_operational_events",
    )
    notes = models.TextField(blank=True)
    offline = models.BooleanField(default=False)
    client_event_id = models.UUIDField(null=True, blank=True, unique=True)
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )

    class Meta:
        db_table = "scheduling_trip_operational_event"
        ordering = ("occurred_at", "created_at")
        indexes = [
            models.Index(
                fields=["trip", "event_type", "occurred_at"],
                name="trip_event_type_time_idx",
            ),
        ]
