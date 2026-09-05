import logging

from rest_framework import status
from rest_framework.views import exception_handler

from apps.audit.services import record_audit_event

logger = logging.getLogger(__name__)


def audit_exception_handler(exc, context):
    response = exception_handler(exc, context)
    request = context.get("request")
    if (
        response is not None
        and response.status_code
        in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN)
        and request is not None
    ):
        user = getattr(request, "user", None)
        actor = user if user is not None and user.is_authenticated else None
        try:
            record_audit_event(
                actor=actor,
                action="authorization.access_denied",
                resource_type="api_request",
                correlation_id=request.headers.get("X-Request-ID") or None,
                metadata={
                    "method": request.method,
                    "path": request.path,
                    "status_code": response.status_code,
                    "request_id": request.headers.get("X-Request-ID") or None,
                    "authenticated": actor is not None,
                },
            )
        except Exception:
            # Audit logging must not replace the original security response.
            logger.exception("Failed to persist authorization denial audit event")
    return response
