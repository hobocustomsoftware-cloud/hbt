import uuid

from django.core.exceptions import ValidationError
from django.db import models

from apps.bookings.models import Booking, BookingPassenger
from apps.core.models import TimeStampedModel
from apps.fleet.models import LayoutPosition
from apps.passengers.models import Passenger
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization


class Ticket(TimeStampedModel):
    class Status(models.TextChoices):
        ISSUED = "issued", "Issued"
        VALIDATED = "validated", "Validated"
        BOARDED = "boarded", "Boarded"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"
        REISSUED = "reissued", "Reissued"
        ARCHIVED = "archived", "Archived"

    class Type(models.TextChoices):
        STANDARD = "standard", "Standard"
        VIP = "vip", "VIP"
        STAFF = "staff", "Staff"
        COMPLIMENTARY = "complimentary", "Complimentary"
        CHILD = "child", "Child"
        CORPORATE = "corporate", "Corporate"
        MANUAL = "manual", "Manual"
        ELECTRONIC = "electronic", "Electronic"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="tickets"
    )
    booking = models.ForeignKey(
        Booking, on_delete=models.PROTECT, related_name="tickets"
    )
    booking_passenger = models.ForeignKey(
        BookingPassenger, on_delete=models.PROTECT, related_name="tickets"
    )
    passenger = models.ForeignKey(
        Passenger, on_delete=models.PROTECT, related_name="tickets"
    )
    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="tickets"
    )
    seat_position = models.ForeignKey(
        LayoutPosition, on_delete=models.PROTECT, related_name="tickets"
    )
    ticket_number = models.CharField(max_length=64)
    ticket_type = models.CharField(
        max_length=16, choices=Type.choices, default=Type.ELECTRONIC
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.ISSUED
    )
    validation_code = models.UUIDField(
        default=uuid.uuid4, unique=True, editable=False
    )
    fare_amount = models.DecimalField(max_digits=12, decimal_places=2)
    discount_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    service_charge = models.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="MMK")
    issuing_channel = models.CharField(max_length=16)
    issued_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, related_name="issued_tickets"
    )
    issued_at = models.DateTimeField(auto_now_add=True)
    replacement_of = models.ForeignKey(
        "self",
        on_delete=models.PROTECT,
        related_name="replacements",
        null=True,
        blank=True,
    )
    revoked_at = models.DateTimeField(null=True, blank=True)
    revoked_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="revoked_tickets",
        null=True,
        blank=True,
    )
    revocation_reason = models.TextField(blank=True)

    class Meta:
        db_table = "ticketing_ticket"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "ticket_number"],
                name="unique_ticket_number_per_org",
            ),
            models.UniqueConstraint(
                fields=["booking_passenger"],
                condition=models.Q(
                    status__in=["issued", "validated", "boarded", "completed"]
                ),
                name="unique_active_ticket_per_booking_passenger",
            ),
            models.CheckConstraint(
                condition=models.Q(fare_amount__gte=0)
                & models.Q(discount_amount__gte=0)
                & models.Q(tax_amount__gte=0)
                & models.Q(service_charge__gte=0)
                & models.Q(total_amount__gte=0),
                name="ticket_fare_values_nonnegative",
            ),
        ]

    @property
    def immutable(self):
        return self.status in (
            self.Status.BOARDED,
            self.Status.COMPLETED,
            self.Status.ARCHIVED,
        )

    def clean(self):
        if self.booking.organization_id != self.organization_id:
            raise ValidationError("Booking belongs to another organization.")
        if self.booking_passenger.booking_id != self.booking_id:
            raise ValidationError("Passenger item does not belong to booking.")
        if self.passenger_id != self.booking_passenger.passenger_id:
            raise ValidationError("Ticket passenger does not match booking passenger.")
        if self.trip_id != self.booking.trip_id:
            raise ValidationError("Ticket trip does not match booking.")
        expected = (
            self.fare_amount
            - self.discount_amount
            + self.tax_amount
            + self.service_charge
        )
        if self.total_amount != expected:
            raise ValidationError({"total_amount": "Fare total does not reconcile."})
        if self.replacement_of_id:
            if self.replacement_of.organization_id != self.organization_id:
                raise ValidationError("Replacement ticket belongs to another organization.")
            if self.replacement_of.booking_passenger_id != self.booking_passenger_id:
                raise ValidationError("Replacement ticket must be for the same passenger.")
