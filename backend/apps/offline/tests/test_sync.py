import uuid

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.notifications.models import Notification
from apps.notifications.services import create_event_notifications
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)

from ..models import Device, SyncChange, SyncOperation
from ..services import apply_sync_operation, issue_authorization_snapshot


class OfflineServiceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959500000001", password="Strong-pass-123"
        )
        tenant = Tenant.objects.create(name="Offline", slug="offline")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Offline Express",
            display_name="Offline",
            status=Organization.Status.ACTIVE,
        )
        self.membership = Membership.objects.create(
            organization=self.organization,
            user=self.user,
            status=Membership.Status.ACTIVE,
        )
        MembershipRole.objects.create(
            membership=self.membership,
            role=Role.objects.get(tenant=None, code="company-owner"),
            scope_type=MembershipRole.ScopeType.COMPANY,
        )
        self.device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="0.1.0",
        )

    def test_snapshot_is_time_bounded_and_contains_effective_access(self):
        snapshot = issue_authorization_snapshot(
            device=self.device,
            membership=self.membership,
            actor=self.user,
        )
        self.assertGreater(snapshot.expires_at, timezone.now())
        self.assertIn("offline.sync", snapshot.permissions)
        self.assertEqual(snapshot.scopes[0]["scope_type"], "company")

    def test_sync_operation_is_idempotent(self):
        create_event_notifications(
            event_type="test",
            event_key="offline:read",
            kind=Notification.Kind.SYSTEM,
            category=Notification.Category.INFORMATION,
            recipients=[self.user],
            organization=self.organization,
            title="Test",
            body="Test",
        )
        notification = Notification.objects.get(
            recipient=self.user, channel=Notification.Channel.IN_APP
        )
        operation_id = uuid.uuid4()
        first = apply_sync_operation(
            device=self.device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=operation_id,
            operation_type="notification.read",
            payload={"notification_id": str(notification.id)},
        )
        second = apply_sync_operation(
            device=self.device,
            organization=self.organization,
            actor=self.user,
            client_operation_id=operation_id,
            operation_type="notification.read",
            payload={"notification_id": str(notification.id)},
        )
        self.assertEqual(first.id, second.id)
        self.assertEqual(SyncOperation.objects.count(), 1)
        self.assertEqual(first.status, SyncOperation.Status.APPLIED)


class OfflineApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959500000002", password="Strong-pass-123"
        )
        tenant = Tenant.objects.create(name="Sync API", slug="sync-api")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Sync API Express",
            display_name="Sync API",
            status=Organization.Status.ACTIVE,
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

    def test_device_enrollment_and_delta_pull_are_user_scoped(self):
        enrollment = self.client.post(
            "/api/v1/me/devices/",
            {
                "installation_id": str(uuid.uuid4()),
                "platform": "android",
                "app_id": "hbt.business",
                "app_version": "0.1.0",
                "device_name": "Counter Phone",
            },
            format="json",
        )
        self.assertEqual(enrollment.status_code, 201)
        device_id = enrollment.data["id"]
        change = SyncChange.objects.create(
            organization=self.organization,
            resource_type="trip",
            resource_id=uuid.uuid4(),
            operation="updated",
            payload={"status": "ready"},
        )
        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/devices/"
            f"{device_id}/sync/pull/?cursor=0"
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["next_cursor"], change.sequence)
        self.assertEqual(len(response.data["changes"]), 1)
