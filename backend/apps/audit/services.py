import json

from django.core.serializers.json import DjangoJSONEncoder

from .models import AuditEvent


_SENSITIVE_KEYS = {
    "password",
    "password1",
    "password2",
    "token",
    "access_token",
    "refresh_token",
    "authorization",
    "api_key",
    "secret",
    "client_secret",
    "private_key",
    "otp",
    "nrc",
}


def _redact(value):
    if isinstance(value, dict):
        return {
            key: "[REDACTED]" if str(key).lower() in _SENSITIVE_KEYS else _redact(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [_redact(item) for item in value]
    if isinstance(value, tuple):
        return [_redact(item) for item in value]
    return value


def json_safe(value):
    return json.loads(json.dumps(_redact(value or {}), cls=DjangoJSONEncoder))


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
