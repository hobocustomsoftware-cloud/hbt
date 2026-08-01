import uuid

from rest_framework.test import APITestCase

from apps.identity.models import User
from apps.cargo.models import CargoContact
from apps.notifications.models import Notification
from apps.notifications.services import create_event_notifications
from apps.offline.models import Device
from apps.tenancy.models import (
    Membership,
    MembershipRole,
    Organization,
    Role,
    Tenant,
)


class SecurityAbuseTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="+959600000001", password="Strong-pass-123"
        )
        self.attacker = User.objects.create_user(
            phone_number="+959600000002", password="Strong-pass-456"
        )
        tenant = Tenant.objects.create(name="Security", slug="security-tests")
        self.organization = Organization.objects.create(
            tenant=tenant,
            legal_name="Security Express",
            display_name="Security",
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

    def test_registration_never_returns_password_and_stores_hash(self):
        response = self.client.post(
            "/api/v1/auth/register/",
            {
                "phone_number": "+959600000003",
                "password": "Another-Strong-123",
                "first_name": "New",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertNotIn("password", response.data)
        created = User.objects.get(phone_number="+959600000003")
        self.assertNotEqual(created.password, "Another-Strong-123")
        self.assertTrue(created.check_password("Another-Strong-123"))

    def test_notification_idor_is_denied(self):
        create_event_notifications(
            event_type="security.test",
            event_key="security:idor",
            kind=Notification.Kind.SECURITY,
            category=Notification.Category.INFORMATION,
            recipients=[self.user],
            organization=self.organization,
            title="Security",
            body="Test",
        )
        notification = Notification.objects.get(
            recipient=self.user, channel=Notification.Channel.IN_APP
        )
        self.client.force_authenticate(self.attacker)
        response = self.client.post(
            f"/api/v1/me/notifications/{notification.id}/read/"
        )
        self.assertEqual(response.status_code, 404)

    def test_device_installation_cannot_be_hijacked(self):
        installation_id = uuid.uuid4()
        Device.objects.create(
            user=self.user,
            installation_id=installation_id,
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
        )
        self.client.force_authenticate(self.attacker)
        response = self.client.post(
            "/api/v1/me/devices/",
            {
                "installation_id": str(installation_id),
                "platform": "android",
                "app_id": "hbt.business",
                "app_version": "1.0.1",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            Device.objects.get(installation_id=installation_id).user,
            self.user,
        )

    def test_sync_rejects_oversized_batch_before_processing(self):
        self.client.force_authenticate(self.user)
        device = Device.objects.create(
            user=self.user,
            installation_id=uuid.uuid4(),
            platform=Device.Platform.ANDROID,
            app_id="hbt.business",
            app_version="1.0.0",
        )
        response = self.client.post(
            f"/api/v1/organizations/{self.organization.id}/devices/"
            f"{device.id}/sync/push/",
            [{} for _ in range(101)],
            format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_sql_injection_string_cannot_bypass_login(self):
        response = self.client.post(
            "/api/v1/auth/login/",
            {
                "phone_number": "' OR 1=1 --",
                "password": "' OR 1=1 --",
            },
            format="json",
        )
        self.assertIn(response.status_code, (400, 401))
        self.assertNotIn("access", response.data)

    def test_sql_injection_search_does_not_escape_tenant_filter(self):
        other_tenant = Tenant.objects.create(
            name="Other Security", slug="other-security"
        )
        other_organization = Organization.objects.create(
            tenant=other_tenant,
            legal_name="Other Security Express",
            display_name="Other Security",
            status=Organization.Status.ACTIVE,
        )
        secret_contact = CargoContact.objects.create(
            organization=other_organization,
            contact_code="SECRET",
            name="Other Tenant Secret",
            phone_number="+959611111111",
        )
        self.client.force_authenticate(self.user)
        response = self.client.get(
            f"/api/v1/organizations/{self.organization.id}/cargo/contacts/",
            {"q": "%' OR 1=1 --"},
        )
        self.assertEqual(response.status_code, 200)
        serialized = str(response.data)
        self.assertNotIn(secret_contact.name, serialized)
        self.assertNotIn(secret_contact.phone_number, serialized)

    def test_registration_cannot_mass_assign_staff_privilege(self):
        self.client.force_authenticate(None)
        response = self.client.post(
            "/api/v1/auth/register/",
            {
                "phone_number": "+959600000004",
                "password": "Another-Strong-456",
                "is_staff": True,
                "is_superuser": True,
                "status": "active",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        created = User.objects.get(phone_number="+959600000004")
        self.assertFalse(created.is_staff)
        self.assertFalse(created.is_superuser)
