from datetime import timedelta
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Max, Q
from django.utils import timezone

from apps.audit.services import json_safe, record_audit_event
from apps.bookings.models import Booking
from apps.offline.services import record_sync_change

from .models import CouponRedemption, FareQuote, FareQuoteLine, FareRule, Promotion


def resolve_fare_rule(*, booking):
    now = timezone.now()
    trip = booking.trip
    rules = FareRule.objects.filter(
        organization=booking.organization,
        route=trip.route,
        pickup_stop=booking.pickup_stop,
        dropoff_stop=booking.dropoff_stop,
        active=True,
        effective_from__lte=now,
    ).filter(
        Q(effective_until__isnull=True) | Q(effective_until__gt=now),
        Q(schedule__isnull=True) | Q(schedule=trip.schedule),
        Q(vehicle_category="")
        | Q(vehicle_category=getattr(trip.vehicle, "category", "")),
        Q(booking_channel="") | Q(booking_channel=booking.channel),
    )
    candidates = list(rules)
    candidates.sort(
        key=lambda rule: (
            1 if rule.schedule_id else 0,
            1 if rule.vehicle_category else 0,
            1 if rule.booking_channel else 0,
            rule.priority,
            rule.effective_from,
        ),
        reverse=True,
    )
    if not candidates:
        raise ValidationError("No active fare rule matches this booking.")
    return candidates[0]


@transaction.atomic
def _eligible_promotions(booking, coupon_code=""):
    now = timezone.now()
    count = booking.passenger_items.count()
    queryset = Promotion.objects.filter(
        organization=booking.organization,
        active=True,
        starts_at__lte=now,
        ends_at__gt=now,
        minimum_passengers__lte=count,
    ).filter(
        Q(route__isnull=True) | Q(route=booking.trip.route),
        Q(schedule__isnull=True) | Q(schedule=booking.trip.schedule),
        Q(booking_channel="") | Q(booking_channel=booking.channel),
    )
    normalized = coupon_code.strip().upper()
    if normalized:
        queryset = queryset.filter(coupon_code__iexact=normalized)
    else:
        queryset = queryset.filter(coupon_code="")
    return queryset.order_by("-priority", "-discount_value", "created_at")


def _discount_for_promotion(promotion, base_fares):
    subtotal = sum(base_fares, Decimal("0"))
    if promotion.discount_type == Promotion.DiscountType.PERCENT:
        discount = subtotal * promotion.discount_value / Decimal("100")
    elif promotion.discount_type == Promotion.DiscountType.FIXED:
        discount = promotion.discount_value
    else:
        eligible_count = min(
            promotion.discounted_passenger_count, len(base_fares)
        )
        discount = sum(sorted(base_fares)[:eligible_count], Decimal("0"))
    if promotion.maximum_discount is not None:
        discount = min(discount, promotion.maximum_discount)
    return min(subtotal, discount).quantize(Decimal("0.01"))


@transaction.atomic
def create_fare_quote(*, booking, actor, lifetime_minutes=15, coupon_code=""):
    booking = Booking.objects.select_for_update().get(pk=booking.pk)
    booking = Booking.objects.select_related(
        "trip__vehicle", "trip__schedule", "pickup_stop", "dropoff_stop"
    ).get(pk=booking.pk)
    if booking.status != Booking.Status.RESERVED:
        raise ValidationError("Only a reserved booking may be quoted.")
    rule = resolve_fare_rule(booking=booking)
    existing_max = (
        FareQuote.objects.filter(booking=booking).aggregate(value=Max("version"))[
            "value"
        ]
        or 0
    )
    FareQuote.objects.filter(
        booking=booking, status=FareQuote.Status.QUOTED
    ).update(status=FareQuote.Status.SUPERSEDED)
    passengers = list(booking.passenger_items.select_related("passenger"))
    subtotal = rule.base_fare * len(passengers)
    promotion = _eligible_promotions(booking, coupon_code).first()
    discount_amount = (
        _discount_for_promotion(
            promotion, [rule.base_fare for _ in passengers]
        )
        if promotion
        else Decimal("0")
    )
    taxable_amount = subtotal - discount_amount
    tax_amount = (taxable_amount * rule.tax_rate / Decimal("100")).quantize(
        Decimal("0.01")
    )
    quote = FareQuote.objects.create(
        booking=booking,
        version=existing_max + 1,
        currency=rule.currency,
        subtotal=subtotal,
        discount_amount=discount_amount,
        tax_amount=tax_amount,
        total_amount=taxable_amount + tax_amount,
        expires_at=timezone.now() + timedelta(minutes=lifetime_minutes),
        created_by=actor,
        applied_promotion=promotion,
        coupon_code=coupon_code.strip().upper() if promotion else "",
        snapshot=json_safe(
            {
                "booking_id": booking.id,
                "trip_id": booking.trip_id,
                "route_id": booking.trip.route_id,
                "pickup_stop_id": booking.pickup_stop_id,
                "dropoff_stop_id": booking.dropoff_stop_id,
                "passenger_count": len(passengers),
                "fare_rule_id": rule.id,
                "fare_rule_code": rule.code,
                "promotion": (
                    {
                        "id": promotion.id,
                        "code": promotion.code,
                        "coupon_code": promotion.coupon_code,
                        "discount_type": promotion.discount_type,
                        "discount_value": promotion.discount_value,
                        "minimum_passengers": promotion.minimum_passengers,
                        "discounted_passenger_count": (
                            promotion.discounted_passenger_count
                        ),
                    }
                    if promotion
                    else None
                ),
            }
        ),
    )
    remaining_discount = discount_amount
    for index, passenger_item in enumerate(passengers):
        remaining_lines = len(passengers) - index
        line_discount = (
            (remaining_discount / remaining_lines).quantize(Decimal("0.01"))
            if remaining_lines
            else Decimal("0")
        )
        line_discount = min(rule.base_fare, line_discount)
        remaining_discount -= line_discount
        line_tax = (
            (rule.base_fare - line_discount)
            * rule.tax_rate
            / Decimal("100")
        ).quantize(Decimal("0.01"))
        FareQuoteLine.objects.create(
            quote=quote,
            booking_passenger=passenger_item,
            fare_rule=rule,
            base_fare=rule.base_fare,
            discount_amount=line_discount,
            tax_amount=line_tax,
            total_amount=rule.base_fare - line_discount + line_tax,
            rule_snapshot=json_safe(
                {
                    "id": rule.id,
                    "code": rule.code,
                    "base_fare": rule.base_fare,
                    "tax_rate": rule.tax_rate,
                    "effective_from": rule.effective_from,
                }
            ),
        )
    _audit(quote, actor, "fare.quote_created")
    record_sync_change(
        organization=booking.organization,
        resource_type="fare_quote",
        resource_id=quote.id,
        operation="created",
        payload={
            "id": quote.id,
            "booking_id": booking.id,
            "status": quote.status,
            "total_amount": quote.total_amount,
            "expires_at": quote.expires_at,
        },
    )
    return quote


@transaction.atomic
def override_quote_line(*, line, actor, base_fare, reason):
    line = FareQuoteLine.objects.select_for_update().select_related(
        "quote__booking__organization"
    ).get(pk=line.pk)
    if line.quote.status != FareQuote.Status.QUOTED:
        raise ValidationError("Only an unlocked quote may be overridden.")
    if base_fare < 0 or not reason.strip():
        raise ValidationError("A non-negative fare and reason are required.")
    tax_rate = line.fare_rule.tax_rate
    line.base_fare = base_fare
    taxable_amount = max(Decimal("0"), base_fare - line.discount_amount)
    line.tax_amount = (taxable_amount * tax_rate / Decimal("100")).quantize(
        Decimal("0.01")
    )
    line.total_amount = base_fare + line.tax_amount - line.discount_amount
    line.overridden = True
    line.override_reason = reason
    line.overridden_by = actor
    line.save()
    _recalculate_quote(line.quote)
    _audit(line.quote, actor, "fare.quote_overridden", reason)
    return line


@transaction.atomic
def lock_fare_quote(*, quote, actor):
    quote = FareQuote.objects.select_for_update().get(pk=quote.pk)
    if quote.status == FareQuote.Status.LOCKED:
        return quote
    if quote.status != FareQuote.Status.QUOTED:
        raise ValidationError("Only a current quote may be locked.")
    if quote.expires_at <= timezone.now():
        quote.status = FareQuote.Status.EXPIRED
        quote.save(update_fields=["status", "updated_at"])
        raise ValidationError("Fare quote has expired.")
    if quote.applied_promotion_id:
        promotion = Promotion.objects.select_for_update().get(
            pk=quote.applied_promotion_id
        )
        if promotion.total_usage_limit is not None and (
            promotion.redemptions.count() >= promotion.total_usage_limit
        ):
            raise ValidationError("Promotion usage limit has been reached.")
        account = quote.booking.customer_account or actor
        if (
            promotion.redemptions.filter(account=account).count()
            >= promotion.per_account_limit
        ):
            raise ValidationError("Coupon account usage limit has been reached.")
        CouponRedemption.objects.get_or_create(
            quote=quote,
            defaults={
                "promotion": promotion,
                "account": account,
                "coupon_code": quote.coupon_code or promotion.code,
                "discount_amount": quote.discount_amount,
            },
        )
    FareQuote.objects.filter(
        booking=quote.booking, status=FareQuote.Status.LOCKED
    ).exclude(pk=quote.pk).update(status=FareQuote.Status.SUPERSEDED)
    quote.status = FareQuote.Status.LOCKED
    quote.locked_at = timezone.now()
    quote.save(update_fields=["status", "locked_at", "updated_at"])
    _audit(quote, actor, "fare.quote_locked")
    return quote


def _recalculate_quote(quote):
    lines = quote.lines.all()
    quote.subtotal = sum((line.base_fare for line in lines), Decimal("0"))
    quote.discount_amount = sum(
        (line.discount_amount for line in lines), Decimal("0")
    )
    quote.tax_amount = sum((line.tax_amount for line in lines), Decimal("0"))
    quote.total_amount = sum((line.total_amount for line in lines), Decimal("0"))
    quote.save(
        update_fields=[
            "subtotal",
            "discount_amount",
            "tax_amount",
            "total_amount",
            "updated_at",
        ]
    )


def _audit(quote, actor, action, reason=""):
    record_audit_event(
        actor=actor,
        tenant_id=quote.booking.organization.tenant_id,
        organization_id=quote.booking.organization_id,
        action=action,
        resource_type="fare_quote",
        resource_id=quote.id,
        reason=reason,
        after={
            "booking_id": quote.booking_id,
            "status": quote.status,
            "version": quote.version,
            "total_amount": quote.total_amount,
        },
    )
