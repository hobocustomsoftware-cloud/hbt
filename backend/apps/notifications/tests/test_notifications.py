import uuid

from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.offline.models import Device
from apps.tenancy.models import Membership, Organization, Tenant

from ..models import Notification, PendingWorkItem
from ..delivery import dispatch_one_push
from ..push import PushResult
from ..services import create_event_notifications


class NotificationServiceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959400000001", password="Strong-pass-123"
        )
        tenant = Tenant.objects.create(name="Notify", slug="notify")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Notify Express",
            display_name="Notify",
            status=Organization.Status.ACTIVE,
        )

    def test_event_is_deduplicated_and_creates_pending_work(self):
        kwargs = {
            "event_type": "payment.verification_required",
            "event_key": "payment:test:verification",
            "kind": Notification.Kind.PAYMENT,
            "category": Notification.Category.PAYMENT_VERIFICATION,
            "recipients": [self.user],
            "organization": self.organization,
            "title": "Payment",
            "body": "Review",
            "action_required": True,
            "work_type": "payment_verification",
        }
        create_event_notifications(**kwargs)
        create_event_notifications(**kwargs)
        self.assertEqual(Notification.objects.count(), 2)
        self.assertEqual(PendingWorkItem.objects.count(), 1)

    def test_push_token_is_encrypted_and_delivery_attempt_is_recorded(self):
        class AcceptedProvider:
            name = "test-provider"

            def send(self, *, token, platform, notification):
                self.token = token
                return PushResult(
                    accepted=True, provider_reference="provider-message-1"
                )

        device = Device(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
        )
        device.set_push_token("plain-device-token")
        device.save()
        self.assertNotIn("plain-device-token", device.encrypted_push_token)
        create_event_notifications(
            event_type="ticket.issued",
            event_key="ticket:test:issued",
            kind=Notification.Kind.TICKET,
            category=Notification.Category.INFORMATION,
            recipients=[self.user],
            organization=self.organization,
            title="Ticket",
            body="Issued",
        )
        push = Notification.objects.get(channel=Notification.Channel.PUSH)
        provider = AcceptedProvider()
        push = dispatch_one_push(push, provider=provider)
        self.assertEqual(provider.token, "plain-device-token")
        self.assertEqual(push.status, Notification.Status.SENT)
        self.assertEqual(push.delivery_attempts.count(), 1)

    def test_permanent_push_failure_invalidates_device_token(self):
        class InvalidTokenProvider:
            name = "test-provider"

            def send(self, **kwargs):
                return PushResult(
                    accepted=False,
                    permanent_failure=True,
                    failure_reason="invalid token",
                )

        device = Device(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.IOS,
            app_id="hbt.passenger",
            app_version="1.0.0",
        )
        device.set_push_token("invalid-device-token")
        device.save()
        create_event_notifications(
            event_type="trip.changed",
            event_key="trip:test:push-invalid",
            kind=Notification.Kind.TRIP,
            category=Notification.Category.TRIP_OPERATION,
            recipients=[self.user],
            organization=self.organization,
            title="Trip",
            body="Changed",
        )
        push = Notification.objects.get(channel=Notification.Channel.PUSH)
        dispatch_one_push(push, provider=InvalidTokenProvider())
        device.refresh_from_db()
        self.assertEqual(device.get_push_token(), "")


class NotificationApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959400000002", password="Strong-pass-123"
        )
        tenant = Tenant.objects.create(name="Inbox", slug="inbox")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Inbox Express",
            display_name="Inbox",
            status=Organization.Status.ACTIVE,
        )
        Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        self.client.force_authenticate(self.user)
        create_event_notifications(
            event_type="trip.changed",
            event_key="trip:test:changed",
            kind=Notification.Kind.TRIP,
            category=Notification.Category.TRIP_OPERATION,
            recipients=[self.user],
            organization=self.organization,
            title="Trip",
            body="Changed",
        )

    def test_user_reads_only_own_in_app_notification(self):
        response = self.client.get("/api/v1/me/notifications/")
        self.assertEqual(response.status_code, 200)
        results = response.data["results"]
        self.assertEqual(len(results), 1)
        notification_id = results[0]["id"]
        read = self.client.post(
            f"/api/v1/me/notifications/{notification_id}/read/"
        )
        self.assertEqual(read.status_code, 200)
        self.assertIsNotNone(read.data["read_at"])
