import uuid

from django.core.exceptions import ValidationError
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)

from apps.operations.models import PrintAttempt, PrintDocument, PrinterProfile
from apps.operations.services import acknowledge_print


class PrintingAuditTests(APITestCase):
    def setUp(self):
        tenant = Tenant.objects.create(name="Print Tenant", slug="print-tenant")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Print Express",
            display_name="Print Express",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959777700001", password="Strong-pass-123"
        )
        membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.profile = PrinterProfile.objects.create(
            organization=self.organization,
            name="Counter Bluetooth 80mm",
            connection_type=PrinterProfile.ConnectionType.BLUETOOTH,
            paper_width_mm=80,
        )
        self.document = PrintDocument.objects.create(
            organization=self.organization,
            document_type=PrintDocument.Type.TICKET,
            resource_type="ticket",
            resource_id=uuid.uuid4(),
            payload={"reference": "T-001"},
            created_by=self.user,
        )

    def test_offline_print_acknowledgement_is_idempotent(self):
        attempt_id = uuid.uuid4()
        device_id = uuid.uuid4()
        occurred_at = timezone.now()
        first = acknowledge_print(
            document=self.document,
            actor=self.user,
            client_attempt_id=attempt_id,
            status=PrintAttempt.Status.PRINTED,
            occurred_at=occurred_at,
            printer_profile=self.profile,
            device_installation_id=device_id,
            offline=True,
        )
        repeated = acknowledge_print(
            document=self.document,
            actor=self.user,
            client_attempt_id=attempt_id,
            status=PrintAttempt.Status.PRINTED,
            occurred_at=occurred_at,
            printer_profile=self.profile,
            device_installation_id=device_id,
            offline=True,
        )
        self.document.refresh_from_db()
        self.assertEqual(first.id, repeated.id)
        self.assertEqual(self.document.print_count, 1)
        self.assertEqual(PrintAttempt.objects.count(), 1)

    def test_failed_attempt_does_not_increment_print_count(self):
        attempt = acknowledge_print(
            document=self.document,
            actor=self.user,
            client_attempt_id=uuid.uuid4(),
            status=PrintAttempt.Status.FAILED,
            occurred_at=timezone.now(),
            printer_profile=self.profile,
            failure_reason="Bluetooth connection lost",
        )
        self.document.refresh_from_db()
        self.assertEqual(attempt.status, PrintAttempt.Status.FAILED)
        self.assertEqual(self.document.print_count, 0)

    def test_attempt_id_cannot_be_reused_for_another_document(self):
        attempt_id = uuid.uuid4()
        acknowledge_print(
            document=self.document,
            actor=self.user,
            client_attempt_id=attempt_id,
            status=PrintAttempt.Status.PRINTED,
            occurred_at=timezone.now(),
        )
        other = PrintDocument.objects.create(
            organization=self.organization,
            document_type=PrintDocument.Type.CARGO_RECEIPT,
            resource_type="cargo_shipment",
            resource_id=uuid.uuid4(),
            payload={"reference": "C-001"},
            created_by=self.user,
        )
        with self.assertRaises(ValidationError):
            acknowledge_print(
                document=other,
                actor=self.user,
                client_attempt_id=attempt_id,
                status=PrintAttempt.Status.PRINTED,
                occurred_at=timezone.now(),
            )

    def test_owner_csv_export_is_tenant_authorized_and_excel_safe(self):
        self.client.force_authenticate(self.user)
        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/reports/export/",
            {"report": "owner_summary", "date": str(timezone.localdate())},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["X-Content-Type-Options"], "nosniff")
        self.assertIn("attachment;", response["Content-Disposition"])
        self.assertTrue(response.content.startswith(b"\xef\xbb\xbf"))
