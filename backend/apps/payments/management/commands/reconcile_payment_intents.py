from django.core.management.base import BaseCommand
from django.db.models import Q
from django.utils import timezone

from apps.payments.models import PaymentIntent
from apps.payments.services import reconcile_payment_intent


class Command(BaseCommand):
    help = "Reconcile pending provider payment intents using installed adapters."

    def add_arguments(self, parser):
        parser.add_argument("--limit", type=int, default=200)

    def handle(self, *args, **options):
        limit = max(1, min(options["limit"], 2000))
        now = timezone.now()
        ids = list(
            PaymentIntent.objects.filter(
                status__in=(
                    PaymentIntent.Status.PENDING,
                    PaymentIntent.Status.REQUIRES_RECONCILIATION,
                )
            )
            .filter(
                Q(next_reconcile_at__isnull=True)
                | Q(next_reconcile_at__lte=now)
            )
            .order_by("next_reconcile_at", "created_at")
            .values_list("id", flat=True)[:limit]
        )
        counts = {}
        for intent_id in ids:
            intent = reconcile_payment_intent(
                intent=PaymentIntent(pk=intent_id)
            )
            counts[intent.status] = counts.get(intent.status, 0) + 1
        self.stdout.write(
            self.style.SUCCESS(
                f"Payment reconciliation complete: processed={len(ids)}, "
                f"statuses={counts}"
            )
        )
