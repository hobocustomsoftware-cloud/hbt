import uuid
from unittest.mock import Mock, patch

from django.core.exceptions import PermissionDenied
from django.test import SimpleTestCase
from rest_framework.test import APIRequestFactory

from apps.payments.views import PaymentDecisionView


class PaymentDecisionAuthorizationTests(SimpleTestCase):
    def test_ticket_allocation_requires_ticket_issue_permission(self):
        raw_request = APIRequestFactory().post(
            "/payments/decision/",
            {"approve": True, "tickets": [{}]},
            format="json",
        )
        membership = object()
        view = PaymentDecisionView()
        request = view.initialize_request(raw_request)
        view.organization_and_membership = Mock(
            return_value=(object(), membership)
        )

        with (
            patch("apps.payments.views.get_object_or_404", return_value=object()),
            patch(
                "apps.payments.views.require_permission",
                side_effect=PermissionDenied("Missing required permission: ticket.issue"),
            ) as require_permission,
        ):
            with self.assertRaises(PermissionDenied):
                view.post(
                    request,
                    organization_id=uuid.uuid4(),
                    payment_id=uuid.uuid4(),
                )

        require_permission.assert_called_once_with(membership, "ticket.issue")
