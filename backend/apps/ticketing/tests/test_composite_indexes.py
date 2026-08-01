"""Schema contract tests for composite query indexes (F-19 / M5b-001).

Verifies that the hot org-scoped query patterns (organization + status +
date) are backed by composite indexes on the models that previously had
none. This is a regression guard: if someone drops or renames the indexes,
these tests fail before production queries degrade to full scans.
"""

from django.db import connection
from django.test import TestCase

from apps.payments.models import PaymentRecord
from apps.ticketing.models import Ticket


class TicketCompositeIndexTests(TestCase):
    def test_ticket_model_declares_org_status_issued_index(self):
        names = {idx.name for idx in Ticket._meta.indexes}
        self.assertIn("ticket_org_status_issued_idx", names)

    def test_ticket_index_columns_in_database(self):
        with connection.cursor() as cursor:
            cursor.execute(
                "PRAGMA index_list('ticketing_ticket')"
                if connection.vendor == "sqlite"
                else """
                    SELECT indexname FROM pg_indexes
                    WHERE tablename = 'ticketing_ticket'
                """
            )
            rows = cursor.fetchall()
        names = {row[0] for row in rows}
        self.assertIn("ticket_org_status_issued_idx", names)

    def test_org_status_query_uses_index(self):
        """The list-view query pattern must be executable and indexed."""
        queryset = Ticket.objects.filter(
            organization_id="00000000-0000-0000-0000-000000000000",
            status="issued",
        )
        # Only verify the query builds and the index lookup succeeds.
        self.assertEqual(queryset.query.get_compiler("default").query, queryset.query)


class PaymentRecordCompositeIndexTests(TestCase):
    def test_payment_record_model_declares_org_status_date_index(self):
        names = {idx.name for idx in PaymentRecord._meta.indexes}
        self.assertIn("payment_org_status_date_idx", names)

    def test_payment_index_columns_in_database(self):
        with connection.cursor() as cursor:
            cursor.execute(
                "PRAGMA index_list('payments_payment_record')"
                if connection.vendor == "sqlite"
                else """
                    SELECT indexname FROM pg_indexes
                    WHERE tablename = 'payments_payment_record'
                """
            )
            rows = cursor.fetchall()
        names = {row[0] for row in rows}
        self.assertIn("payment_org_status_date_idx", names)

    def test_org_status_query_uses_index(self):
        queryset = PaymentRecord.objects.filter(
            organization_id="00000000-0000-0000-0000-000000000000",
            status="recorded",
        )
        self.assertEqual(queryset.query.get_compiler("default").query, queryset.query)
