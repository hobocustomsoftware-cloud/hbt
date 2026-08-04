"""Owner dashboard aggregation service.

Builds the Owner Dashboard snapshot from the existing operational models
(trips, tickets, cargo, bookings, payments, refunds, vehicles, workforce,
audit, notifications). Every value in the snapshot is a real aggregate over
stored data for the requested period — nothing is seeded, faked, or derived
from tables that do not exist yet.

Sections that depend on models that are not part of the current schema
(e.g. Expenses, Shifts, Bank Balance) are intentionally absent. They are
documented as future enhancements in docs/implementation/dashboard.md and
can be appended to the snapshot without changing the response structure.
"""

from datetime import timedelta
from decimal import Decimal

from django.db.models import Count, F, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone

from apps.audit.models import AuditEvent
from apps.bookings.models import Booking
from apps.cargo.models import CargoShipment
from apps.fleet.models import Vehicle
from apps.notifications.models import Notification
from apps.payments.models import PaymentRecord, RefundRequest
from apps.scheduling.models import Trip
from apps.ticketing.models import Ticket
from apps.workforce.models import DriverProfile

PERIOD_DAYS = {
    "day": 1,
    "week": 7,
    "month": 30,
    "year": 365,
}

PERIOD_CHOICES = tuple(PERIOD_DAYS)

# A trip is "on time" when it departs within this grace window of its
# planned departure.
ON_TIME_GRACE_MINUTES = 15

# Trend windows: how far back the trend chart reaches for each period.
TREND_DAYS = {
    "day": 14,
    "week": 14,
    "month": 30,
    "year": 12,  # months
}


def _period_start(today, period):
    days = PERIOD_DAYS[period] - 1
    return today - timedelta(days=days)


def build_owner_dashboard(*, organization, period="day", now=None):
    """Return the owner dashboard snapshot for a period.

    Args:
        organization: tenancy.Organization instance.
        period: one of PERIOD_CHOICES ("day"|"week"|"month"|"year").
        now: optional datetime override (tests).
    """
    if period not in PERIOD_DAYS:
        raise ValueError(f"Unsupported dashboard period: {period}")

    now = now or timezone.now()
    today = timezone.localdate(now)
    start = _period_start(today, period)
    date_range = (start, today)

    money = _money_summary(organization, date_range)
    trips = _trip_summary(organization, date_range)
    cargo = _cargo_summary(organization, date_range)
    bookings = _booking_summary(organization, date_range)
    cash_pending = _cash_pending_summary(organization, date_range)
    fleet_people = _fleet_people_summary(organization, date_range)
    trend = _revenue_trend(organization, today, period)
    rankings = _rankings(organization, date_range)
    pulse = _pulse(organization, date_range, trips, cargo, cash_pending, bookings)

    return {
        "date": today,
        "period": period,
        "data_freshness": now,
        # Backward-compatible summary keys (consumed by earlier clients).
        "trips": {
            "total": trips["total"],
            "active": trips["running"],
            "closed": trips["completed"],
        },
        "tickets": {"count": trips["passengers"]},
        "cargo": {
            "accepted": cargo["accepted"],
            "in_transit": cargo["in_transit"],
            "ready_for_pickup": cargo["ready_for_pickup"],
            "exceptions": cargo["exceptions"],
        },
        "confirmed_payments": money["confirmed_payments"],
        # Dashboard zones (this snapshot is additive — new zones can be
        # appended without changing existing ones).
        "money": {
            "ticket_revenue": money["ticket_revenue"],
            "cargo_revenue": money["cargo_revenue"],
            "total_revenue": money["total_revenue"],
            "confirmed_payments": money["confirmed_payments"],
        },
        "trip_ops": trips,
        "cargo_ops": cargo,
        "bookings": bookings,
        "cash_pending": cash_pending,
        "fleet_people": fleet_people,
        "revenue_trend": trend,
        "rankings": rankings,
        "pulse": pulse,
    }


def _money_summary(organization, date_range):
    tickets = (
        Ticket.objects.filter(
            organization=organization,
            trip__service_date__range=date_range,
        )
        .exclude(status=Ticket.Status.CANCELLED)
        .aggregate(revenue=Sum("total_amount"))
    )
    cargo = (
        CargoShipment.objects.filter(
            organization=organization,
            created_at__date__range=date_range,
        )
        .exclude(status=CargoShipment.Status.CANCELLED)
        .aggregate(revenue=Sum("total_charge"))
    )
    ticket_revenue = tickets["revenue"] or Decimal("0")
    cargo_revenue = cargo["revenue"] or Decimal("0")

    payments = PaymentRecord.objects.filter(
        organization=organization,
        status=PaymentRecord.Status.CONFIRMED,
        confirmed_at__date__range=date_range,
    )
    payment_totals = list(
        payments.values("method").annotate(
            amount=Sum("amount"), count=Count("id")
        )
    )

    return {
        "ticket_revenue": ticket_revenue,
        "cargo_revenue": cargo_revenue,
        "total_revenue": ticket_revenue + cargo_revenue,
        "confirmed_payments": payment_totals,
    }


def _trip_summary(organization, date_range):
    trips = Trip.objects.filter(
        organization=organization, service_date__range=date_range
    )
    active_statuses = [
        Trip.Status.BOARDING,
        Trip.Status.DEPARTED,
        Trip.Status.IN_PROGRESS,
        Trip.Status.DELAYED,
    ]

    departed = trips.exclude(departed_at=None)
    departed_count = departed.count()
    on_time_percent = None
    if departed_count:
        on_time = departed.filter(
            departed_at__lte=F("planned_departure_at")
            + timedelta(minutes=ON_TIME_GRACE_MINUTES)
        ).count()
        on_time_percent = round(on_time / departed_count * 100, 1)

    passengers = (
        Ticket.objects.filter(
            organization=organization,
            trip__service_date__range=date_range,
        )
        .exclude(status=Ticket.Status.CANCELLED)
        .count()
    )
    cargo_today = CargoShipment.objects.filter(
        organization=organization,
        created_at__date__range=date_range,
    ).exclude(
        status__in=[
            CargoShipment.Status.CANCELLED,
            CargoShipment.Status.REFUSED,
        ]
    ).count()

    return {
        "total": trips.count(),
        "running": trips.filter(status__in=active_statuses).count(),
        "delayed": trips.filter(status=Trip.Status.DELAYED).count(),
        "cancelled": trips.filter(status=Trip.Status.CANCELLED).count(),
        "completed": trips.filter(
            status__in=[Trip.Status.COMPLETED, Trip.Status.CLOSED]
        ).count(),
        "passengers": passengers,
        "cargo_today": cargo_today,
        "on_time_percent": on_time_percent,
    }


def _cargo_summary(organization, date_range):
    cargo = CargoShipment.objects.filter(
        organization=organization, created_at__date__range=date_range
    )
    return {
        "accepted": cargo.exclude(
            status__in=[
                CargoShipment.Status.CANCELLED,
                CargoShipment.Status.REFUSED,
            ]
        ).count(),
        "in_transit": cargo.filter(
            status=CargoShipment.Status.IN_TRANSIT
        ).count(),
        "ready_for_pickup": cargo.filter(
            status=CargoShipment.Status.READY_FOR_PICKUP
        ).count(),
        "exceptions": cargo.filter(
            status__in=[
                CargoShipment.Status.DAMAGED,
                CargoShipment.Status.LOST,
                CargoShipment.Status.RETURNED,
            ]
        ).count(),
    }


def _booking_summary(organization, date_range):
    bookings = Booking.objects.filter(
        organization=organization, created_at__date__range=date_range
    )
    return {
        "total": bookings.count(),
        "confirmed": bookings.filter(status=Booking.Status.CONFIRMED).count(),
        "cancelled": bookings.filter(status=Booking.Status.CANCELLED).count(),
        "expired": bookings.filter(status=Booking.Status.EXPIRED).count(),
    }


def _cash_pending_summary(organization, date_range):
    cash = PaymentRecord.objects.filter(
        organization=organization,
        method=PaymentRecord.Method.CASH,
        status=PaymentRecord.Status.CONFIRMED,
        confirmed_at__date__range=date_range,
    ).aggregate(amount=Sum("amount"))

    pending_refunds = RefundRequest.objects.filter(
        organization=organization,
        status=RefundRequest.Status.REQUESTED,
    )
    pending = pending_refunds.aggregate(amount=Sum("requested_amount"))

    return {
        "cash_in_counters": cash["amount"] or Decimal("0"),
        # Bank balance requires a banking/ledger model — future enhancement.
        "pending_refunds": {
            "count": pending_refunds.count(),
            "amount": pending["amount"] or Decimal("0"),
        },
        # Approvals are refund decisions in the current schema. Additional
        # approval types (expenses, leave) arrive with their models.
        "pending_approvals": pending_refunds.count(),
    }


def _fleet_people_summary(organization, date_range):
    vehicles = Vehicle.objects.filter(organization=organization).exclude(
        status__in=[Vehicle.Status.RETIRED, Vehicle.Status.ARCHIVED]
    )
    total_drivers = DriverProfile.objects.filter(
        staff__membership__organization=organization,
        staff__status="active",
    ).count()
    on_duty_drivers = (
        Trip.objects.filter(
            organization=organization, service_date__range=date_range
        )
        .exclude(driver=None)
        .values("driver")
        .distinct()
        .count()
    )

    return {
        "vehicles_running": {
            "count": vehicles.filter(
                status=Vehicle.Status.IN_SERVICE
            ).count(),
            "total": vehicles.count(),
        },
        "vehicles_maintenance": vehicles.filter(
            status=Vehicle.Status.MAINTENANCE
        ).count(),
        "driver_attendance": {
            "on_duty": on_duty_drivers,
            "total": total_drivers,
        },
    }


def _revenue_trend(organization, today, period):
    """Daily (or monthly for year) ticket+cargo revenue buckets."""
    if period == "year":
        return _monthly_trend(organization, today)
    days = TREND_DAYS[period]
    start = today - timedelta(days=days - 1)

    ticket_rows = (
        Ticket.objects.filter(
            organization=organization,
            trip__service_date__range=(start, today),
        )
        .exclude(status=Ticket.Status.CANCELLED)
        .values("trip__service_date")
        .annotate(total=Sum("total_amount"))
    )
    cargo_rows = (
        CargoShipment.objects.filter(
            organization=organization,
            created_at__date__range=(start, today),
        )
        .exclude(status=CargoShipment.Status.CANCELLED)
        .values("created_at__date")
        .annotate(total=Sum("total_charge"))
    )
    tickets_by_day = {row["trip__service_date"]: row["total"] for row in ticket_rows}
    cargo_by_day = {row["created_at__date"]: row["total"] for row in cargo_rows}

    points = []
    for offset in range(days - 1, -1, -1):
        day = today - timedelta(days=offset)
        ticket = tickets_by_day.get(day) or Decimal("0")
        cargo = cargo_by_day.get(day) or Decimal("0")
        points.append(
            {
                "label": day.isoformat(),
                "ticket": ticket,
                "cargo": cargo,
                "total": ticket + cargo,
            }
        )
    return points


def _monthly_trend(organization, today):
    start = today - timedelta(days=364)
    ticket_rows = (
        Ticket.objects.filter(
            organization=organization,
            trip__service_date__gte=start,
            trip__service_date__lte=today,
        )
        .exclude(status=Ticket.Status.CANCELLED)
        .annotate(month=TruncMonth("trip__service_date"))
        .values("month")
        .annotate(total=Sum("total_amount"))
    )
    cargo_rows = (
        CargoShipment.objects.filter(
            organization=organization,
            created_at__date__gte=start,
            created_at__date__lte=today,
        )
        .exclude(status=CargoShipment.Status.CANCELLED)
        .annotate(month=TruncMonth("created_at"))
        .values("month")
        .annotate(total=Sum("total_charge"))
    )
    tickets_by_month = {row["month"]: row["total"] for row in ticket_rows}
    cargo_by_month = {row["month"]: row["total"] for row in cargo_rows}

    points = []
    for offset in range(11, -1, -1):
        month_start = (today.replace(day=1) - timedelta(days=offset * 31)).replace(day=1)
        ticket = tickets_by_month.get(month_start) or Decimal("0")
        cargo = cargo_by_month.get(month_start) or Decimal("0")
        points.append(
            {
                "label": month_start.strftime("%Y-%m"),
                "ticket": ticket,
                "cargo": cargo,
                "total": ticket + cargo,
            }
        )
    return points


def _rankings(organization, date_range):
    """Top branches / routes / vehicles by ticket revenue (real aggregates)."""
    tickets = Ticket.objects.filter(
        organization=organization,
        trip__service_date__range=date_range,
    ).exclude(status=Ticket.Status.CANCELLED)

    branches = _revenue_rows(
        tickets.filter(trip__vehicle__branch__isnull=False)
        .values("trip__vehicle__branch__name")
        .annotate(
            revenue=Sum("total_amount"), trips=Count("trip", distinct=True)
        ),
        "trip__vehicle__branch__name",
    )
    routes = _revenue_rows(
        tickets.filter(trip__route__isnull=False)
        .values("trip__route__name")
        .annotate(revenue=Sum("total_amount"), trips=Count("trip", distinct=True)),
        "trip__route__name",
    )
    vehicles = _revenue_rows(
        tickets.filter(trip__vehicle__isnull=False)
        .values("trip__vehicle__registration_number")
        .annotate(revenue=Sum("total_amount"), trips=Count("trip", distinct=True)),
        "trip__vehicle__registration_number",
    )
    return {"branches": branches, "routes": routes, "vehicles": vehicles}


def _revenue_rows(queryset, name_field):
    return [
        {
            "name": row[name_field],
            "revenue": row["revenue"],
            "trips": row["trips"],
        }
        for row in queryset.order_by("-revenue")[:5]
    ]


def _pulse(organization, date_range, trips, cargo, cash_pending, bookings):
    activities = [
        {
            "actor": _actor_name(event.actor),
            "action": event.action,
            "resource_type": event.resource_type,
            "occurred_at": event.occurred_at,
        }
        for event in AuditEvent.objects.filter(
            organization_id=organization.id
        ).order_by("-occurred_at")[:10]
    ]

    alerts = []
    if trips["delayed"]:
        alerts.append(
            {
                "severity": "warning",
                "message": f"{trips['delayed']} delayed trip(s)",
                "count": trips["delayed"],
            }
        )
    if trips["cancelled"]:
        alerts.append(
            {
                "severity": "danger",
                "message": f"{trips['cancelled']} cancelled trip(s)",
                "count": trips["cancelled"],
            }
        )
    if cargo["exceptions"]:
        alerts.append(
            {
                "severity": "danger",
                "message": f"{cargo['exceptions']} cargo exception(s)",
                "count": cargo["exceptions"],
            }
        )
    if cash_pending["pending_refunds"]["count"]:
        alerts.append(
            {
                "severity": "warning",
                "message": (
                    f"{cash_pending['pending_refunds']['count']} "
                    "refund(s) awaiting decision"
                ),
                "count": cash_pending["pending_refunds"]["count"],
            }
        )
    if bookings["expired"]:
        alerts.append(
            {
                "severity": "info",
                "message": f"{bookings['expired']} expired booking(s)",
                "count": bookings["expired"],
            }
        )

    announcements = [
        {
            "title": n.title,
            "body": n.body,
            "created_at": n.created_at,
        }
        for n in Notification.objects.filter(
            organization=organization,
            category=Notification.Category.INFORMATION,
        ).order_by("-created_at")[:5]
    ]

    return {
        "activities": activities,
        "alerts": alerts,
        "announcements": announcements,
    }


def _actor_name(actor):
    if actor is None:
        return ""
    full = f"{actor.first_name} {actor.last_name}".strip()
    return full or getattr(actor, "phone_number", "") or str(actor)
