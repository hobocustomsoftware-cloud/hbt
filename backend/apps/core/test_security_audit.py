from types import SimpleNamespace
from unittest.mock import patch

from django.test import SimpleTestCase
from rest_framework import status
from rest_framework.response import Response

from .exceptions import audit_exception_handler


class AuthorizationDenialAuditTests(SimpleTestCase):
    @patch("apps.core.exceptions.record_audit_event")
    @patch("apps.core.exceptions.exception_handler")
    def test_anonymous_denial_is_audited_without_actor(
        self, exception_handler_mock, record_audit_event_mock
    ):
        exception_handler_mock.return_value = Response(
            {"detail": "Authentication credentials were not provided."},
            status=status.HTTP_401_UNAUTHORIZED,
        )
        request = SimpleNamespace(
            method="GET",
            path="/api/v1/private/",
            headers={"X-Request-ID": "11111111-1111-1111-1111-111111111111"},
            user=SimpleNamespace(is_authenticated=False),
        )

        response = audit_exception_handler(Exception("denied"), {"request": request})

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        record_audit_event_mock.assert_called_once_with(
            actor=None,
            action="authorization.access_denied",
            resource_type="api_request",
            correlation_id="11111111-1111-1111-1111-111111111111",
            metadata={
                "method": "GET",
                "path": "/api/v1/private/",
                "status_code": status.HTTP_401_UNAUTHORIZED,
                "request_id": "11111111-1111-1111-1111-111111111111",
                "authenticated": False,
            },
        )

    @patch("apps.core.exceptions.record_audit_event")
    @patch("apps.core.exceptions.exception_handler")
    def test_authenticated_denial_preserves_actor(
        self, exception_handler_mock, record_audit_event_mock
    ):
        exception_handler_mock.return_value = Response(
            {"detail": "Forbidden."}, status=status.HTTP_403_FORBIDDEN
        )
        user = SimpleNamespace(is_authenticated=True)
        request = SimpleNamespace(
            method="POST",
            path="/api/v1/private/",
            headers={},
            user=user,
        )

        response = audit_exception_handler(Exception("denied"), {"request": request})

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        record_audit_event_mock.assert_called_once_with(
            actor=user,
            action="authorization.access_denied",
            resource_type="api_request",
            correlation_id=None,
            metadata={
                "method": "POST",
                "path": "/api/v1/private/",
                "status_code": status.HTTP_403_FORBIDDEN,
                "request_id": None,
                "authenticated": True,
            },
        )

    @patch("apps.core.exceptions.record_audit_event", side_effect=RuntimeError("audit down"))
    @patch("apps.core.exceptions.exception_handler")
    def test_audit_failure_does_not_replace_security_response(
        self, exception_handler_mock, record_audit_event_mock
    ):
        exception_handler_mock.return_value = Response(
            {"detail": "Forbidden."}, status=status.HTTP_403_FORBIDDEN
        )
        request = SimpleNamespace(
            method="GET",
            path="/api/v1/private/",
            headers={},
            user=SimpleNamespace(is_authenticated=False),
        )

        response = audit_exception_handler(Exception("denied"), {"request": request})

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        record_audit_event_mock.assert_called_once()
