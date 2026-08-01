from django.core.management.base import BaseCommand

from apps.subscriptions.services import process_subscription_deadlines


class Command(BaseCommand):
    help = "Apply subscription trial, grace, suspension and overdue deadlines."

    def handle(self, *args, **options):
        changed = process_subscription_deadlines()
        self.stdout.write(
            self.style.SUCCESS(f"Updated {changed} subscriptions.")
        )
