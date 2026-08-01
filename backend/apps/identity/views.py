from datetime import timedelta

from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, serializers, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from drf_spectacular.utils import extend_schema

from apps.audit.services import record_audit_event

from .serializers import (
    DataSubjectRequestSerializer,
    HBTTokenObtainPairSerializer,
    PrivacyRequestActionSerializer,
    RegistrationSerializer,
    UserSerializer,
    UserDataExportSerializer,
)
from .models import DataSubjectRequest, PlatformAccessGrant


class RegistrationView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegistrationSerializer


class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
    serializer_class = HBTTokenObtainPairSerializer


class RefreshView(TokenRefreshView):
    permission_classes = [AllowAny]


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField(write_only=True)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=LogoutSerializer,
        responses={204: None},
        operation_id="authentication_logout",
    )
    def post(self, request, version=None):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = RefreshToken(serializer.validated_data["refresh"])
        token.blacklist()
        record_audit_event(
            actor=request.user,
            action="authentication.logout",
            resource_type="session",
        )
        return Response(status=status.HTTP_204_NO_CONTENT)
class MeView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def perform_update(self, serializer):
        before = UserSerializer(self.request.user).data
        user = serializer.save()
        record_audit_event(
            actor=user,
            action="identity.profile_updated",
            resource_type="user",
            resource_id=user.id,
            before=before,
            after=UserSerializer(user).data,
        )


class MyPrivacyRequestListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = DataSubjectRequestSerializer

    def get_queryset(self):
        return DataSubjectRequest.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        item = serializer.save(
            user=self.request.user,
            due_at=timezone.now() + timedelta(days=30),
        )
        record_audit_event(
            actor=self.request.user,
            action="privacy.request_submitted",
            resource_type="data_subject_request",
            resource_id=item.id,
            after={"type": item.request_type, "status": item.status},
        )


class MyPrivacyRequestCancelView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(request=None, responses=DataSubjectRequestSerializer)
    def post(self, request, request_id, version=None):
        with transaction.atomic():
            item = get_object_or_404(
                DataSubjectRequest.objects.select_for_update(),
                pk=request_id,
                user=request.user,
            )
            if item.status not in (
                DataSubjectRequest.Status.SUBMITTED,
                DataSubjectRequest.Status.VERIFIED,
            ):
                raise serializers.ValidationError(
                    "Only submitted or verified requests may be cancelled."
                )
            item.status = DataSubjectRequest.Status.CANCELLED
            item.resolved_at = timezone.now()
            item.save(update_fields=["status", "resolved_at", "updated_at"])
            record_audit_event(
                actor=request.user,
                action="privacy.request_cancelled",
                resource_type="data_subject_request",
                resource_id=item.id,
                after={"status": item.status},
            )
        return Response(DataSubjectRequestSerializer(item).data)


def require_privacy_reviewer(user):
    now = timezone.now()
    allowed = PlatformAccessGrant.objects.filter(
        user=user,
        role__in=(
            PlatformAccessGrant.Role.SUPER_ADMIN,
            PlatformAccessGrant.Role.SECURITY,
        ),
        is_active=True,
    ).filter(
        Q(valid_from__isnull=True) | Q(valid_from__lte=now),
        Q(valid_until__isnull=True) | Q(valid_until__gt=now),
    ).exists()
    if not allowed:
        raise PermissionDenied("Active platform privacy authority is required.")


class PlatformPrivacyRequestListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = DataSubjectRequestSerializer

    def get_queryset(self):
        require_privacy_reviewer(self.request.user)
        queryset = DataSubjectRequest.objects.select_related("user", "reviewed_by")
        status_value = self.request.query_params.get("status")
        if status_value:
            queryset = queryset.filter(status=status_value)
        return queryset.order_by("due_at")


class PlatformPrivacyRequestActionView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=PrivacyRequestActionSerializer,
        responses=DataSubjectRequestSerializer,
    )
    def post(self, request, request_id, version=None):
        require_privacy_reviewer(request.user)
        with transaction.atomic():
            item = get_object_or_404(
                DataSubjectRequest.objects.select_for_update(), pk=request_id
            )
            if item.user_id == request.user.id:
                raise PermissionDenied("A requester cannot review their own request.")
            serializer = PrivacyRequestActionSerializer(
                data=request.data, context={"privacy_request": item}
            )
            serializer.is_valid(raise_exception=True)
            data = serializer.validated_data
            action = data["action"]
            transitions = {
                "verify": (
                    DataSubjectRequest.Status.SUBMITTED,
                    DataSubjectRequest.Status.VERIFIED,
                ),
                "start": (
                    DataSubjectRequest.Status.VERIFIED,
                    DataSubjectRequest.Status.IN_PROGRESS,
                ),
                "fulfill": (
                    DataSubjectRequest.Status.IN_PROGRESS,
                    DataSubjectRequest.Status.FULFILLED,
                ),
                "reject": (
                    (
                        DataSubjectRequest.Status.VERIFIED,
                        DataSubjectRequest.Status.IN_PROGRESS,
                    ),
                    DataSubjectRequest.Status.REJECTED,
                ),
            }
            expected, target = transitions[action]
            sources = expected if isinstance(expected, tuple) else (expected,)
            if item.status not in sources:
                raise serializers.ValidationError(
                    "Invalid privacy request state transition."
                )
            before = item.status
            item.status = target
            item.reviewed_by = request.user
            if action == "verify":
                item.verification_method = data["verification_method"]
                item.verified_at = timezone.now()
            if action in ("fulfill", "reject"):
                item.response_summary = data["reason"]
                item.evidence_reference = data.get("evidence_reference", "")
                item.retention_hold = data.get("retention_hold", False)
                item.retention_reason = (
                    data["reason"] if item.retention_hold else ""
                )
                item.resolved_at = timezone.now()
            item.save()
            record_audit_event(
                actor=request.user,
                action=f"privacy.request_{action}",
                resource_type="data_subject_request",
                resource_id=item.id,
                before={"status": before},
                after={
                    "status": target,
                    "retention_hold": item.retention_hold,
                    "evidence_reference": item.evidence_reference,
                },
            )
        return Response(DataSubjectRequestSerializer(item).data)


class MyDataExportView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(responses=UserDataExportSerializer)
    def get(self, request, version=None):
        from apps.bookings.models import Booking
        from apps.notifications.models import Notification
        from apps.tenancy.models import Membership
        from apps.ticketing.models import Ticket

        limit = 5000
        memberships = list(
            Membership.objects.filter(user=request.user).values(
                "id", "organization_id", "status", "joined_at", "created_at"
            )[:limit]
        )
        bookings = list(
            Booking.objects.filter(customer_account=request.user)
            .order_by("-created_at")
            .values(
                "id", "organization_id", "trip_id", "booking_number",
                "booking_type", "channel", "status", "contact_name",
                "contact_phone", "expires_at", "confirmed_at", "created_at",
            )[:limit]
        )
        tickets = list(
            Ticket.objects.filter(booking__customer_account=request.user)
            .order_by("-issued_at")
            .values(
                "id", "organization_id", "booking_id", "trip_id",
                "passenger_id", "ticket_number", "ticket_type", "status",
                "total_amount", "currency", "issued_at",
            )[:limit]
        )
        notifications = list(
            Notification.objects.filter(recipient=request.user)
            .order_by("-created_at")
            .values(
                "id", "organization_id", "event_type", "kind", "category",
                "channel", "title", "body", "deep_link", "status",
                "read_at", "created_at",
            )[:limit]
        )
        payload = {
            "generated_at": timezone.now(),
            "user": UserSerializer(request.user).data,
            "memberships": memberships,
            "bookings": bookings,
            "tickets": tickets,
            "notifications": notifications,
            "limits": {
                "per_section": limit,
                "truncated": {
                    "memberships": len(memberships) == limit,
                    "bookings": len(bookings) == limit,
                    "tickets": len(tickets) == limit,
                    "notifications": len(notifications) == limit,
                },
            },
        }
        record_audit_event(
            actor=request.user,
            action="privacy.self_export_generated",
            resource_type="user",
            resource_id=request.user.id,
            metadata={
                "membership_count": len(memberships),
                "booking_count": len(bookings),
                "ticket_count": len(tickets),
                "notification_count": len(notifications),
            },
        )
        return Response(payload)
