import uuid

from rest_framework import generics, status
from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.audit.services import record_audit_event
from apps.scheduling.views import OrganizationSchedulingMixin

from .models import Ticket
from .serializers import (
    TicketIssueSerializer,
    TicketReissueSerializer,
    TicketSerializer,
)


class TicketValidateActionView(OrganizationSchedulingMixin, APIView):
    """Record that a ticket was validated at the gate (QR scan).

    Transitions a ticket from `issued` to `validated` exactly once and
    leaves an audit trail. Idempotent: validating an already-validated
    ticket returns 200 with the current state.
    """

    manage_permission = "ticket.validate"

    @extend_schema(
        request=None,
        responses={200: TicketSerializer},
        operation_id="ticket_validate_action",
    )
    def post(self, request, organization_id, ticket_id, version=None):
        organization, _ = self.organization_and_membership()
        ticket = get_object_or_404(
            Ticket.objects.select_related("passenger", "trip"),
            pk=ticket_id,
            organization=organization,
        )
        if ticket.status in (
            Ticket.Status.CANCELLED,
            Ticket.Status.REISSUED,
            Ticket.Status.ARCHIVED,
        ):
            return Response(
                {
                    "error": (
                        f"Ticket is {ticket.status} and cannot be validated."
                    )
                },
                status=status.HTTP_409_CONFLICT,
            )
        if ticket.status == Ticket.Status.ISSUED:
            ticket.status = Ticket.Status.VALIDATED
            ticket.save(update_fields=["status", "updated_at"])
            record_audit_event(
                actor=request.user,
                tenant_id=organization.tenant_id,
                organization_id=organization.id,
                action="ticket.validated",
                resource_type="ticket",
                resource_id=ticket.id,
                after={
                    "ticket_number": ticket.ticket_number,
                    "status": ticket.status,
                },
            )
        return Response(TicketSerializer(ticket).data)


class TicketValidateView(OrganizationSchedulingMixin, APIView):
    """Look up a ticket by validation code (QR scan result).

    Returns ticket details if found and valid.
    The QR payload format is HBT:TICKET:{validation_code}.
    This endpoint accepts both the full payload and the bare UUID.
    """
    view_permission = "ticket.view"

    @extend_schema(
        parameters=[],
        responses={200: TicketSerializer, 404: None},
        operation_id="ticket_validate",
    )
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        code_param = request.query_params.get("code", "")

        # Strip prefix if present
        if code_param.startswith("HBT:TICKET:"):
            code_param = code_param.removeprefix("HBT:TICKET:")

        try:
            validation_code = uuid.UUID(code_param)
        except (ValueError, AttributeError):
            return Response(
                {"error": "Invalid validation code format."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ticket = get_object_or_404(
            Ticket,
            organization=organization,
            validation_code=validation_code,
        )
        return Response(TicketSerializer(ticket).data)


class TicketListView(OrganizationSchedulingMixin, generics.ListAPIView):
    serializer_class = TicketSerializer
    view_permission = "ticket.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Ticket.objects.filter(organization=organization).select_related(
            "booking_passenger__seat_reservation",
            "passenger",
            "trip",
        )


class TicketDetailView(OrganizationSchedulingMixin, generics.RetrieveAPIView):
    serializer_class = TicketSerializer
    lookup_url_kwarg = "ticket_id"
    view_permission = "ticket.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Ticket.objects.filter(organization=organization).select_related(
            "booking_passenger__seat_reservation",
            "passenger",
            "trip",
        )


class TicketIssueView(OrganizationSchedulingMixin, APIView):
    manage_permission = "ticket.issue"

    @extend_schema(
        request=TicketIssueSerializer,
        responses={201: TicketSerializer},
        operation_id="ticket_issue",
    )
    def post(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        serializer = TicketIssueSerializer(
            data=request.data,
            context={"organization": organization, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        ticket = serializer.save()
        return Response(
            TicketSerializer(ticket).data, status=status.HTTP_201_CREATED
        )


class TicketReissueView(OrganizationSchedulingMixin, APIView):
    manage_permission = "ticket.reissue"

    @extend_schema(
        request=TicketReissueSerializer,
        responses={201: TicketSerializer},
        operation_id="ticket_reissue",
    )
    def post(self, request, organization_id, ticket_id, version=None):
        organization, _ = self.organization_and_membership()
        ticket = get_object_or_404(
            Ticket, organization=organization, pk=ticket_id
        )
        serializer = TicketReissueSerializer(
            data=request.data,
            context={"ticket": ticket, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(
            TicketSerializer(serializer.save()).data,
            status=status.HTTP_201_CREATED,
        )