from django.core.management.base import BaseCommand

from apps.notifications.delivery import dispatch_push_batch


class Command(BaseCommand):
    help = "Dispatch a bounded batch of queued push notifications."

    def add_arguments(self, parser):
        parser.add_argument("--limit", type=int, default=100)

    def handle(self, *args, **options):
        limit = min(max(options["limit"], 1), 1000)
        dispatched = dispatch_push_batch(limit=limit)
        self.stdout.write(
            self.style.SUCCESS(f"Processed {len(dispatched)} push notifications.")
        )
