from django.db import models

from apps.core.models import TimeStampedModel
from apps.network.models import RouteStop
from apps.passengers.models import Passenger
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization
from apps.ticketing.models import Ticket


class BoardingRecord(TimeStampedModel):
    class Status(models.TextChoices):
        VALIDATED = "validated", "Validated"
        BOARDED = "boarded", "Boarded"
        REJECTED = "rejected", "Rejected"
        CANCELLED = "cancelled", "Cancelled"
        COMPLETED = "completed", "Completed"
        NO_SHOW = "no_show", "No show"

    class Type(models.TextChoices):
        TERMINAL = "terminal", "Terminal"
        ROADSIDE = "roadside", "Roadside"
        STAFF = "staff", "Staff"
        EMERGENCY = "emergency", "Emergency"

    class Method(models.TextChoices):
        QR = "qr", "QR scan"
        BARCODE = "barcode", "Barcode"
        MANUAL_TICKET = "manual_ticket", "Manual ticket number"
        PASSENGER_SEARCH = "passenger_search", "Passenger search"
        OFFLINE = "offline", "Offline validation"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="boarding_records"
    )
    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="boarding_records"
    )
    ticket = models.OneToOneField(
        Ticket, on_delete=models.PROTECT, related_name="boarding_record"
    )
    passenger = models.ForeignKey(
        Passenger, on_delete=models.PROTECT, related_name="boarding_records"
    )
    boarding_type = models.CharField(max_length=12, choices=Type.choices)
    method = models.CharField(max_length=20, choices=Method.choices)
    status = models.CharField(max_length=12, choices=Status.choices)
    boarding_stop = models.ForeignKey(
        RouteStop,
        on_delete=models.PROTECT,
        related_name="boarding_records",
        null=True,
        blank=True,
    )
    validated_at = models.DateTimeField()
    boarded_at = models.DateTimeField(null=True, blank=True)
    validated_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="validated_boardings",
    )
    boarded_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="recorded_boardings",
        null=True,
        blank=True,
    )
    identity_confirmed = models.BooleanField(default=False)
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
        db_table = "boarding_record"
        constraints = [
            models.UniqueConstraint(
                fields=["trip", "passenger"],
                condition=models.Q(status__in=["validated", "boarded", "completed"]),
                name="unique_active_boarding_per_trip_passenger",
            ),
        ]
        indexes = [
            models.Index(
                fields=["trip", "status"], name="boarding_trip_status_idx"
            ),
        ]

