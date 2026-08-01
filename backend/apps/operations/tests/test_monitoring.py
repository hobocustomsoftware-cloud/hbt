import uuid
from datetime import timedelta
from unittest.mock import patch

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.notifications.models import Notification
from apps.offline.models import Device, SyncOperation
from apps.payments.models import PaymentConnector, PaymentWebhookEvent
from apps.tenancy.models import Membership, MembershipRole, Organization, Role, Tenant


class MonitoringEndpointTests(APITestCase):
    def setUp(self):
        tenant = Tenant.objects.create(name="Monitor Tenant", slug="monitor-tenant")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Monitor Express",
            display_name="Monitor Express",
            status=Organization.Status.ACTIVE,
        )
        self.user = User.objects.create_user(
            phone_number="+959777700777", password="Strong-pass-123"
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
        self.client.force_authenticate(self.user)

    def test_monitoring_dashboard_returns_operational_snapshot(self):
        now = timezone.now()
        device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
            status=Device.Status.ACTIVE,
            last_seen_at=now - timedelta(minutes=10),
        )
        Notification.objects.create(
            organization=self.organization,
            recipient=self.user,
            event_type="trip.delay",
            event_key="trip-delay-1",
            kind=Notification.Kind.TRIP,
            category=Notification.Category.URGENT_EXCEPTION,
            channel=Notification.Channel.PUSH,
            title="Trip delayed",
            body="Delayed",
            available_at=now - timedelta(minutes=6),
            status=Notification.Status.QUEUED,
        )
        sync = SyncOperation.objects.create(
            device=device,
            organization=self.organization,
            client_operation_id=uuid.uuid4(),
            operation_type="ticket.validate",
            payload_hash="a" * 64,
        )
        SyncOperation.objects.filter(pk=sync.pk).update(
            created_at=now - timedelta(minutes=35)
        )
        connector = PaymentConnector.objects.create(
            organization=self.organization,
            code="kbzpay",
            adapter="payments.adapters.manual.ManualSandboxAdapter",
            environment=PaymentConnector.Environment.SANDBOX,
            status=PaymentConnector.Status.ACTIVE,
            merchant_id="merchant-1",
            encrypted_credentials="{}",
            webhook_secret_encrypted="secret",
            created_by=self.user,
        )
        webhook = PaymentWebhookEvent.objects.create(
            connector=connector,
            event_id="evt-1",
            payload_sha256="b" * 64,
            payload={"id": "evt-1"},
        )
        PaymentWebhookEvent.objects.filter(pk=webhook.pk).update(
            created_at=now - timedelta(minutes=8)
        )

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/monitoring/dashboard/"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["service_overview"]["active_devices_24h"], 1)
        self.assertEqual(
            response.data["service_overview"]["pending_push_notifications"], 1
        )
        self.assertEqual(response.data["service_overview"]["sync_backlog_count"], 1)
        self.assertEqual(response.data["service_overview"]["webhook_backlog_count"], 1)
        self.assertEqual(response.data["infrastructure"]["database"], "ok")

    @patch.dict("os.environ", {}, clear=False)
    def test_monitoring_alerts_flag_backlog_and_unavailable_backup_evidence(self):
        now = timezone.now()
        device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
            status=Device.Status.ACTIVE,
        )
        Notification.objects.create(
            organization=self.organization,
            recipient=self.user,
            event_type="payment.pending",
            event_key="payment-pending-1",
            kind=Notification.Kind.PAYMENT,
            category=Notification.Category.ACTION_REQUIRED,
            channel=Notification.Channel.PUSH,
            title="Payment pending",
            body="Pending",
            available_at=now - timedelta(minutes=7),
            status=Notification.Status.QUEUED,
        )
        sync = SyncOperation.objects.create(
            device=device,
            organization=self.organization,
            client_operation_id=uuid.uuid4(),
            operation_type="booking.walk_up",
            payload_hash="c" * 64,
        )
        SyncOperation.objects.filter(pk=sync.pk).update(
            created_at=now - timedelta(minutes=31)
        )
        connector = PaymentConnector.objects.create(
            organization=self.organization,
            code="aya-pay",
            adapter="payments.adapters.manual.ManualSandboxAdapter",
            environment=PaymentConnector.Environment.SANDBOX,
            status=PaymentConnector.Status.ACTIVE,
            merchant_id="merchant-2",
            encrypted_credentials="{}",
            webhook_secret_encrypted="secret",
            created_by=self.user,
        )
        webhook = PaymentWebhookEvent.objects.create(
            connector=connector,
            event_id="evt-2",
            payload_sha256="d" * 64,
            payload={"id": "evt-2"},
        )
        PaymentWebhookEvent.objects.filter(pk=webhook.pk).update(
            created_at=now - timedelta(minutes=6)
        )

        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/monitoring/alerts/"
        )

        self.assertEqual(response.status_code, 200)
        alerts = {item["code"]: item for item in response.data["alerts"]}
        self.assertEqual(alerts["payment_webhook_backlog"]["status"], "triggered")
        self.assertEqual(alerts["offline_sync_backlog"]["status"], "triggered")
        self.assertEqual(alerts["push_queue_backlog"]["status"], "triggered")
        self.assertEqual(alerts["backup_age"]["status"], "unavailable")
