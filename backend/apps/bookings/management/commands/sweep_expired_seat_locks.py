from django.core.management.base import BaseCommand

from apps.bookings.seat_lock_services import sweep_expired_seat_locks


class Command(BaseCommand):
    help = "Expire seat locks past their TTL, freeing seats for re-selection."

    def handle(self, *args, **options):
        count = sweep_expired_seat_locks()
        self.stdout.write(
            self.style.SUCCESS(f"Seat lock sweep complete: {count} expired")
        )
