from django.core.exceptions import ValidationError
from django.test import TestCase

from apps.audit.models import AuditEvent


class AuditEventTests(TestCase):
    def test_event_cannot_be_updated(self):
        event = AuditEvent.objects.create(
            action="identity.created",
            resource_type="user",
        )
        event.reason = "Changed"

        with self.assertRaises(ValidationError):
            event.save()

    def test_event_cannot_be_deleted(self):
        event = AuditEvent.objects.create(
            action="identity.created",
            resource_type="user",
        )

        with self.assertRaises(ValidationError):
            event.delete()

    def test_queryset_cannot_bulk_update_or_delete(self):
        AuditEvent.objects.create(
            action="identity.created",
            resource_type="user",
        )

        with self.assertRaises(ValidationError):
            AuditEvent.objects.update(reason="Changed")
        with self.assertRaises(ValidationError):
            AuditEvent.objects.all().delete()
