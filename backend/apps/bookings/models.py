from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel
from apps.fleet.models import LayoutPosition
from apps.network.models import RouteStop
from apps.passengers.models import Passenger
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization


class Booking(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        RESERVED = "reserved", "Reserved"
        CONFIRMED = "confirmed", "Confirmed"
        CANCELLED = "cancelled", "Cancelled"
        EXPIRED = "expired", "Expired"
        COMPLETED = "completed", "Completed"
        ARCHIVED = "archived", "Archived"

    class Type(models.TextChoices):
        INDIVIDUAL = "individual", "Individual"
        GROUP = "group", "Group"
        FAMILY = "family", "Family"
        CORPORATE = "corporate", "Corporate"
        AGENT = "agent", "Agent"

    class Channel(models.TextChoices):
        COUNTER = "counter", "Counter"
        AGENT = "agent", "Agent"
        MOBILE = "mobile", "Mobile app"
        WEBSITE = "website", "Website"
        CALL_CENTER = "call_center", "Call center"
        API = "api", "API integration"
        ROADSIDE = "roadside", "Roadside"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="bookings"
    )
    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="bookings"
    )
    booking_number = models.CharField(max_length=50)
    booking_type = models.CharField(max_length=16, choices=Type.choices)
    channel = models.CharField(max_length=16, choices=Channel.choices)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.DRAFT
    )
    contact_name = models.CharField(max_length=255)
    contact_phone = models.CharField(max_length=32)
    pickup_stop = models.ForeignKey(
        RouteStop, on_delete=models.PROTECT, related_name="pickup_bookings"
    )
    dropoff_stop = models.ForeignKey(
        RouteStop, on_delete=models.PROTECT, related_name="dropoff_bookings"
    )
    expires_at = models.DateTimeField(null=True, blank=True)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    authorization_reference = models.CharField(max_length=255, blank=True)
    notes = models.TextField(blank=True)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, related_name="created_bookings"
    )
    customer_account = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="customer_bookings",
        null=True,
        blank=True,
    )
    client_request_id = models.UUIDField(null=True, blank=True, unique=True)

    class Meta:
        db_table = "bookings_booking"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "booking_number"],
                name="unique_booking_number_per_org",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status", "created_at"],
                name="booking_org_status_date_idx",
            ),
        ]

    @property
    def immutable(self):
        return self.status in (
            self.Status.COMPLETED, self.Status.ARCHIVED
        )

    def clean(self):
        if self.trip_id and self.trip.organization_id != self.organization_id:
            raise ValidationError({"trip": "Trip belongs to another organization."})
        if self.pickup_stop_id and self.pickup_stop.route_id != self.trip.route_id:
            raise ValidationError({"pickup_stop": "Pickup is not on the trip route."})
        if self.dropoff_stop_id and self.dropoff_stop.route_id != self.trip.route_id:
            raise ValidationError({"dropoff_stop": "Drop-off is not on the trip route."})
        if (
            self.pickup_stop_id
            and self.dropoff_stop_id
            and self.dropoff_stop.sequence <= self.pickup_stop.sequence
        ):
            raise ValidationError("Drop-off must follow pickup on the route.")


class BookingPassenger(TimeStampedModel):
    booking = models.ForeignKey(
        Booking, on_delete=models.PROTECT, related_name="passenger_items"
    )
    passenger = models.ForeignKey(
        Passenger, on_delete=models.PROTECT, related_name="booking_items"
    )

    class Meta:
        db_table = "bookings_booking_passenger"
        constraints = [
            models.UniqueConstraint(
                fields=["booking", "passenger"],
                name="unique_passenger_per_booking",
            ),
        ]

    def clean(self):
        if self.passenger.organization_id != self.booking.organization_id:
            raise ValidationError("Passenger belongs to another organization.")


class SeatReservation(TimeStampedModel):
    class Status(models.TextChoices):
        HELD = "held", "Held"
        RESERVED = "reserved", "Reserved"
        CONFIRMED = "confirmed", "Confirmed"
        RELEASED = "released", "Released"
        EXPIRED = "expired", "Expired"
        COMPLETED = "completed", "Completed"

    booking_passenger = models.OneToOneField(
        BookingPassenger,
        on_delete=models.PROTECT,
        related_name="seat_reservation",
    )
    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="seat_reservations"
    )
    seat_position = models.ForeignKey(
        LayoutPosition,
        on_delete=models.PROTECT,
        related_name="trip_reservations",
    )
    seat_identifier_snapshot = models.CharField(max_length=20)
    pickup_sequence = models.PositiveIntegerField(default=1)
    dropoff_sequence = models.PositiveIntegerField(default=2)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.HELD
    )

    class Meta:
        db_table = "bookings_seat_reservation"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(dropoff_sequence__gt=models.F("pickup_sequence")),
                name="seat_reservation_segment_forward",
            ),
        ]

    def clean(self):
        booking = self.booking_passenger.booking
        if self.trip_id != booking.trip_id:
            raise ValidationError("Seat trip must match booking trip.")
        if self.trip.seat_layout_id != self.seat_position.layout_id:
            raise ValidationError("Seat is not part of the trip layout snapshot.")
        if not self.seat_position.bookable:
            raise ValidationError("Seat is not bookable.")


class SeatLock(TimeStampedModel):
    """A short-lived hold on a seat for a trip.

    Acquired before a booking is created (counter selection or passenger
    self-service). Enforces one active holder per seat per trip via a
    partial unique constraint on PostgreSQL; service-layer conflict
    checks enforce on all databases. Expired by TTL sweep.
    """

    class Status(models.TextChoices):
        HELD = "held", "Held"
        RELEASED = "released", "Released"
        EXPIRED = "expired", "Expired"
        CONSUMED = "consumed", "Consumed"

    # Default hold duration for a seat lock.
    DEFAULT_TTL_SECONDS = 300  # 5 minutes

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="seat_locks"
    )
    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, related_name="seat_locks"
    )
    seat_position = models.ForeignKey(
        LayoutPosition,
        on_delete=models.PROTECT,
        related_name="trip_seat_locks",
    )
    held_by_user = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="seat_locks",
        null=True,
        blank=True,
    )
    held_by_device_id = models.CharField(max_length=64, blank=True)
    idempotency_key = models.CharField(max_length=128, unique=True)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.HELD
    )
    expires_at = models.DateTimeField()
    released_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "bookings_seat_lock"
        constraints = [
            # One active lock per seat per trip (PostgreSQL partial index;
            # service-layer checks enforce on SQLite dev builds).
            models.UniqueConstraint(
                fields=["trip", "seat_position"],
                condition=models.Q(status="held"),
                name="uniq_active_seat_lock_per_trip_seat",
            ),
        ]
        indexes = [
            models.Index(
                fields=["status", "expires_at"],
                name="seat_lock_status_expiry_idx",
            ),
        ]

    @property
    def is_active(self):
        return (
            self.status == self.Status.HELD
            and self.expires_at > timezone.now()
        )

    def clean(self):
        if self.trip.organization_id != self.organization_id:
            raise ValidationError("Trip belongs to another organization.")
        if self.trip.seat_layout_id != self.seat_position.layout_id:
            raise ValidationError("Seat is not part of the trip layout.")
        if not self.seat_position.bookable:
            raise ValidationError("Seat is not bookable.")


class CorporateCustomer(TimeStampedModel):
    organization = models.ForeignKey(
        Organization,
        on_delete=models.PROTECT,
        related_name="corporate_customers",
    )
    code = models.SlugField(max_length=50)
    legal_name = models.CharField(max_length=255)
    display_name = models.CharField(max_length=255)
    billing_address = models.TextField(blank=True)
    tax_identifier = models.CharField(max_length=100, blank=True)
    payment_terms_days = models.PositiveSmallIntegerField(default=7)
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "bookings_corporate_customer"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_corporate_customer_code",
            )
        ]


class CorporateCustomerMember(TimeStampedModel):
    class Status(models.TextChoices):
        INVITED = "invited", "Invited"
        ACTIVE = "active", "Active"
        REVOKED = "revoked", "Revoked"

    corporate_customer = models.ForeignKey(
        CorporateCustomer, on_delete=models.CASCADE, related_name="members"
    )
    user = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="corporate_customer_memberships",
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.INVITED
    )
    can_request = models.BooleanField(default=True)
    can_approve = models.BooleanField(default=False)

    class Meta:
        db_table = "bookings_corporate_customer_member"
        constraints = [
            models.UniqueConstraint(
                fields=["corporate_customer", "user"],
                name="unique_corporate_customer_user",
            )
        ]


class CorporateBookingApproval(TimeStampedModel):
    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Submitted"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        CANCELLED = "cancelled", "Cancelled"

    booking = models.OneToOneField(
        Booking, on_delete=models.PROTECT, related_name="corporate_approval"
    )
    corporate_customer = models.ForeignKey(
        CorporateCustomer,
        on_delete=models.PROTECT,
        related_name="booking_approvals",
    )
    fare_quote = models.OneToOneField(
        "fares.FareQuote",
        on_delete=models.PROTECT,
        related_name="corporate_approval",
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.SUBMITTED
    )
    requested_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="corporate_bookings_requested",
    )
    submitted_at = models.DateTimeField()
    decided_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="corporate_bookings_decided",
        null=True,
        blank=True,
    )
    decided_at = models.DateTimeField(null=True, blank=True)
    decision_reason = models.TextField(blank=True)

    class Meta:
        db_table = "bookings_corporate_approval"

    def clean(self):
        if self.booking.organization_id != self.corporate_customer.organization_id:
            raise ValidationError("Corporate customer belongs to another operator.")
        if self.fare_quote.booking_id != self.booking_id:
            raise ValidationError("Fare quote belongs to another booking.")


class CorporateInvoice(TimeStampedModel):
    class Status(models.TextChoices):
        ISSUED = "issued", "Issued"
        PAID = "paid", "Paid"
        VOID = "void", "Void"
        OVERDUE = "overdue", "Overdue"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="corporate_invoices"
    )
    approval = models.ForeignKey(
        CorporateBookingApproval, on_delete=models.PROTECT, related_name="invoices"
    )
    replaces = models.ForeignKey(
        "self",
        on_delete=models.PROTECT,
        related_name="replacements",
        null=True,
        blank=True,
    )
    invoice_number = models.CharField(max_length=64)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.ISSUED
    )
    currency = models.CharField(max_length=3, default="MMK")
    subtotal = models.DecimalField(max_digits=14, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2)
    due_at = models.DateTimeField()
    issued_at = models.DateTimeField()
    issued_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, related_name="invoices_issued"
    )
    voided_at = models.DateTimeField(null=True, blank=True)
    voided_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="invoices_voided",
        null=True,
        blank=True,
    )
    void_reason = models.TextField(blank=True)
    snapshot = models.JSONField(default=dict)

    class Meta:
        db_table = "bookings_corporate_invoice"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "invoice_number"],
                name="unique_corporate_invoice_number",
            )
        ]
