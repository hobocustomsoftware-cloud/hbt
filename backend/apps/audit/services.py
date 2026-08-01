import json

from django.core.serializers.json import DjangoJSONEncoder

from .models import AuditEvent


def json_safe(value):
    return json.loads(json.dumps(value or {}, cls=DjangoJSONEncoder))


def record_audit_event(
    *,
    action,
    resource_type,
    actor=None,
    tenant_id=None,
    organization_id=None,
    resource_id="",
    correlation_id=None,
    reason="",
    before=None,
    after=None,
    metadata=None,
):
    return AuditEvent.objects.create(
        actor=actor,
        tenant_id=tenant_id,
        organization_id=organization_id,
        action=action,
        resource_type=resource_type,
        resource_id=str(resource_id) if resource_id else "",
        correlation_id=correlation_id,
        reason=reason,
        before=json_safe(before),
        after=json_safe(after),
        metadata=json_safe(metadata),
    )
