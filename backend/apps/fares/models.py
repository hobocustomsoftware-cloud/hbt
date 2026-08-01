from django.core.exceptions import ValidationError
from django.db import models

from apps.bookings.models import Booking, BookingPassenger
from apps.core.models import TimeStampedModel
from apps.network.models import Route, RouteStop
from apps.scheduling.models import Schedule
from apps.tenancy.models import Organization


class FareRule(TimeStampedModel):
    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="fare_rules"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=160)
    route = models.ForeignKey(
        Route, on_delete=models.PROTECT, related_name="fare_rules"
    )
    pickup_stop = models.ForeignKey(
        RouteStop, on_delete=models.PROTECT, related_name="fare_rules_from"
    )
    dropoff_stop = models.ForeignKey(
        RouteStop, on_delete=models.PROTECT, related_name="fare_rules_to"
    )
    schedule = models.ForeignKey(
        Schedule,
        on_delete=models.PROTECT,
        related_name="fare_rules",
        null=True,
        blank=True,
    )
    vehicle_category = models.CharField(max_length=32, blank=True)
    booking_channel = models.CharField(max_length=16, blank=True)
    currency = models.CharField(max_length=3, default="MMK")
    base_fare = models.DecimalField(max_digits=12, decimal_places=2)
    tax_rate = models.DecimalField(max_digits=7, decimal_places=4, default=0)
    priority = models.PositiveSmallIntegerField(default=100)
    effective_from = models.DateTimeField()
    effective_until = models.DateTimeField(null=True, blank=True)
    active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, related_name="fare_rules_created"
    )

    class Meta:
        db_table = "fares_rule"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"], name="unique_fare_rule_code"
            ),
            models.CheckConstraint(
                condition=models.Q(base_fare__gte=0),
                name="fare_rule_nonnegative",
            ),
            models.CheckConstraint(
                condition=models.Q(tax_rate__gte=0),
                name="fare_rule_tax_nonnegative",
            ),
        ]

    def clean(self):
        if self.route.organization_id != self.organization_id:
            raise ValidationError("Route belongs to another organization.")
        if (
            self.pickup_stop.route_id != self.route_id
            or self.dropoff_stop.route_id != self.route_id
        ):
            raise ValidationError("Fare stops must belong to the fare route.")
        if self.dropoff_stop.sequence <= self.pickup_stop.sequence:
            raise ValidationError("Fare destination must follow origin.")
        if self.schedule_id and self.schedule.organization_id != self.organization_id:
            raise ValidationError("Schedule belongs to another organization.")
        if self.effective_until and self.effective_until <= self.effective_from:
            raise ValidationError("Fare expiry must follow its effective start.")


class Promotion(TimeStampedModel):
    class DiscountType(models.TextChoices):
        PERCENT = "percent", "Percentage"
        FIXED = "fixed", "Fixed amount"
        BUY_X_GET_Y = "buy_x_get_y", "Buy X get Y"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="promotions"
    )
    code = models.SlugField(max_length=64)
    name_my = models.CharField(max_length=160)
    name_en = models.CharField(max_length=160, blank=True)
    description_my = models.TextField(blank=True)
    description_en = models.TextField(blank=True)
    coupon_code = models.CharField(max_length=64, blank=True)
    discount_type = models.CharField(
        max_length=16, choices=DiscountType.choices
    )
    discount_value = models.DecimalField(max_digits=14, decimal_places=2)
    maximum_discount = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    minimum_passengers = models.PositiveSmallIntegerField(default=1)
    discounted_passenger_count = models.PositiveSmallIntegerField(default=0)
    route = models.ForeignKey(
        Route,
        on_delete=models.PROTECT,
        related_name="promotions",
        null=True,
        blank=True,
    )
    schedule = models.ForeignKey(
        Schedule,
        on_delete=models.PROTECT,
        related_name="promotions",
        null=True,
        blank=True,
    )
    booking_channel = models.CharField(max_length=16, blank=True)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    total_usage_limit = models.PositiveIntegerField(null=True, blank=True)
    per_account_limit = models.PositiveIntegerField(default=1)
    priority = models.PositiveSmallIntegerField(default=100)
    stackable = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="promotions_created",
    )

    class Meta:
        db_table = "fares_promotion"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_promotion_code_per_org",
            ),
            models.UniqueConstraint(
                fields=["organization", "coupon_code"],
                condition=~models.Q(coupon_code=""),
                name="unique_coupon_code_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(discount_value__gte=0),
                name="promotion_discount_nonnegative",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "active", "starts_at", "ends_at"],
                name="promotion_active_window_idx",
            )
        ]

    def clean(self):
        if self.ends_at <= self.starts_at:
            raise ValidationError({"ends_at": "End must follow start."})
        if self.route_id and self.route.organization_id != self.organization_id:
            raise ValidationError("Promotion route belongs to another organization.")
        if (
            self.schedule_id
            and self.schedule.organization_id != self.organization_id
        ):
            raise ValidationError(
                "Promotion schedule belongs to another organization."
            )
        if (
            self.discount_type == self.DiscountType.PERCENT
            and self.discount_value > 100
        ):
            raise ValidationError("Percentage discount cannot exceed 100.")
        if (
            self.discount_type == self.DiscountType.BUY_X_GET_Y
            and self.discounted_passenger_count < 1
        ):
            raise ValidationError(
                "Buy-X-get-Y requires a discounted passenger count."
            )


class FareQuote(TimeStampedModel):
    class Status(models.TextChoices):
        QUOTED = "quoted", "Quoted"
        LOCKED = "locked", "Locked"
        EXPIRED = "expired", "Expired"
        SUPERSEDED = "superseded", "Superseded"

    booking = models.ForeignKey(
        Booking, on_delete=models.PROTECT, related_name="fare_quotes"
    )
    version = models.PositiveIntegerField()
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.QUOTED
    )
    currency = models.CharField(max_length=3, default="MMK")
    subtotal = models.DecimalField(max_digits=14, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2)
    expires_at = models.DateTimeField()
    locked_at = models.DateTimeField(null=True, blank=True)
    applied_promotion = models.ForeignKey(
        Promotion,
        on_delete=models.PROTECT,
        related_name="fare_quotes",
        null=True,
        blank=True,
    )
    coupon_code = models.CharField(max_length=64, blank=True)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, related_name="fare_quotes_created"
    )
    snapshot = models.JSONField(default=dict)

    class Meta:
        db_table = "fares_quote"
        constraints = [
            models.UniqueConstraint(
                fields=["booking", "version"], name="unique_booking_fare_version"
            ),
            models.UniqueConstraint(
                fields=["booking"],
                condition=models.Q(status="locked"),
                name="unique_locked_fare_quote",
            ),
        ]


class CouponRedemption(TimeStampedModel):
    promotion = models.ForeignKey(
        Promotion, on_delete=models.PROTECT, related_name="redemptions"
    )
    quote = models.OneToOneField(
        FareQuote, on_delete=models.PROTECT, related_name="coupon_redemption"
    )
    account = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="coupon_redemptions",
    )
    coupon_code = models.CharField(max_length=64)
    discount_amount = models.DecimalField(max_digits=14, decimal_places=2)

    class Meta:
        db_table = "fares_coupon_redemption"
        indexes = [
            models.Index(
                fields=["promotion", "account"],
                name="coupon_promotion_account_idx",
            )
        ]


class FareQuoteLine(TimeStampedModel):
    quote = models.ForeignKey(
        FareQuote, on_delete=models.PROTECT, related_name="lines"
    )
    booking_passenger = models.ForeignKey(
        BookingPassenger, on_delete=models.PROTECT, related_name="fare_quote_lines"
    )
    fare_rule = models.ForeignKey(
        FareRule, on_delete=models.PROTECT, related_name="quote_lines"
    )
    base_fare = models.DecimalField(max_digits=12, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    overridden = models.BooleanField(default=False)
    override_reason = models.TextField(blank=True)
    overridden_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="fare_lines_overridden",
        null=True,
        blank=True,
    )
    rule_snapshot = models.JSONField(default=dict)

    class Meta:
        db_table = "fares_quote_line"
        constraints = [
            models.UniqueConstraint(
                fields=["quote", "booking_passenger"],
                name="unique_quote_passenger_line",
            )
        ]
