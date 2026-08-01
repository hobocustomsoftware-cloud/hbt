from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.bookings.models import Booking
from apps.bookings.services import expire_booking
from apps.notifications.models import Notification
from apps.notifications.services import create_event_notifications


class Command(BaseCommand):
    help = "Warn customers about, then expire, unpaid reserved bookings."

    def add_arguments(self, parser):
        parser.add_argument("--batch-size", type=int, default=500)
        parser.add_argument("--warning-minutes", type=int, default=15)

    def handle(self, *args, **options):
        now = timezone.now()
        batch_size = max(1, min(options["batch_size"], 5000))
        warning_minutes = max(1, options["warning_minutes"])
        warning_limit = now + timedelta(minutes=warning_minutes)

        warnings = 0
        warning_bookings = Booking.objects.filter(
            status=Booking.Status.RESERVED,
            customer_account__isnull=False,
            expires_at__gt=now,
            expires_at__lte=warning_limit,
        ).select_related("organization")[:batch_size]
        for booking in warning_bookings:
            created = create_event_notifications(
                event_type="booking.expiry_warning",
                event_key=f"booking:{booking.id}:expiry-warning:{booking.expires_at.isoformat()}",
                kind=Notification.Kind.BOOKING,
                category=Notification.Category.ACTION_REQUIRED,
                recipients=[booking.customer_account_id],
                organization=booking.organization,
                title="Booking သက်တမ်းကုန်တော့မည်",
                body=f"{warning_minutes} မိနစ်အတွင်း ငွေပေးချေမှုကို အပြီးသတ်ပါ။",
                data={
                    "booking_id": str(booking.id),
                    "expires_at": booking.expires_at.isoformat(),
                },
                deep_link=f"/bookings/{booking.id}",
            )
            warnings += int(bool(created))

        expired = 0
        ids = list(
            Booking.objects.filter(
                status=Booking.Status.RESERVED,
                expires_at__isnull=False,
                expires_at__lte=now,
            )
            .order_by("expires_at")
            .values_list("id", flat=True)[:batch_size]
        )
        for booking_id in ids:
            expired += int(expire_booking(booking=Booking(pk=booking_id)))

        self.stdout.write(
            self.style.SUCCESS(
                f"Booking expiry run complete: warnings={warnings}, expired={expired}"
            )
        )
