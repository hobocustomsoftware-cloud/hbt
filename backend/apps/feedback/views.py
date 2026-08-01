from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.audit.services import record_audit_event
from apps.bookings.models import Booking
from apps.scheduling.views import OrganizationSchedulingMixin
from apps.tenancy.views import organization_for_user

from .models import Feedback
from .serializers import FeedbackSerializer, FeedbackTriageSerializer


class MyFeedbackListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = FeedbackSerializer

    def get_queryset(self):
        return Feedback.objects.filter(submitted_by=self.request.user).order_by(
            "-created_at"
        )

    def perform_create(self, serializer):
        organization = serializer.validated_data.get("organization")
        if organization is not None:
            is_member = self.request.user.organization_memberships.filter(
                organization=organization, status="active"
            ).exists()
            is_customer = Booking.objects.filter(
                organization=organization,
                customer_account=self.request.user,
            ).exists()
            if not (is_member or is_customer):
                from rest_framework.exceptions import PermissionDenied

                raise PermissionDenied(
                    "Feedback may target only an organization you use."
                )
        item = serializer.save()
        record_audit_event(
            actor=self.request.user,
            tenant_id=organization.tenant_id if organization else None,
            organization_id=organization.id if organization else None,
            action="feedback.submitted",
            resource_type="feedback",
            resource_id=item.id,
            after={"category": item.category, "source": item.source},
        )


class OrganizationFeedbackListView(
    OrganizationSchedulingMixin, generics.ListAPIView
):
    serializer_class = FeedbackSerializer
    view_permission = "feedback.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        queryset = Feedback.objects.filter(organization=organization)
        status_value = self.request.query_params.get("status")
        category = self.request.query_params.get("category")
        if status_value:
            queryset = queryset.filter(status=status_value)
        if category:
            queryset = queryset.filter(category=category)
        return queryset.order_by("-created_at")


class OrganizationFeedbackTriageView(OrganizationSchedulingMixin, APIView):
    manage_permission = "feedback.manage"

    @extend_schema(request=FeedbackTriageSerializer, responses=FeedbackSerializer)
    def post(self, request, organization_id, feedback_id, version=None):
        organization, _ = self.organization_and_membership()
        item = get_object_or_404(
            Feedback, pk=feedback_id, organization=organization
        )
        serializer = FeedbackTriageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        before = {"status": item.status, "priority": item.priority}
        for field, value in serializer.validated_data.items():
            setattr(item, field, value)
        item.reviewed_by = request.user
        item.reviewed_at = timezone.now()
        item.save()
        record_audit_event(
            actor=request.user,
            tenant_id=organization.tenant_id,
            organization_id=organization.id,
            action="feedback.triaged",
            resource_type="feedback",
            resource_id=item.id,
            before=before,
            after={"status": item.status, "priority": item.priority},
        )
        return Response(FeedbackSerializer(item).data)
