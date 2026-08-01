from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.scheduling.views import OrganizationSchedulingMixin
from apps.core.serializers import CountSerializer, EmptySerializer

from .models import Notification, PendingWorkItem
from .serializers import NotificationSerializer, PendingWorkItemSerializer
from .services import mark_read, retry_notification


class MyNotificationListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        queryset = Notification.objects.filter(
            recipient=self.request.user,
            channel=Notification.Channel.IN_APP,
        ).order_by("-created_at")
        unread = self.request.query_params.get("unread")
        if unread == "true":
            queryset = queryset.filter(read_at__isnull=True)
        return queryset


class MyNotificationUnreadCountView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=CountSerializer,
        operation_id="notifications_unread_count",
    )
    def get(self, request, version=None):
        count = Notification.objects.filter(
            recipient=request.user,
            channel=Notification.Channel.IN_APP,
            read_at__isnull=True,
        ).count()
        return Response({"unread_count": count})


class MyNotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=EmptySerializer,
        responses=NotificationSerializer,
        operation_id="notification_mark_read",
    )
    def post(self, request, notification_id, version=None):
        notification = get_object_or_404(
            Notification,
            pk=notification_id,
            recipient=request.user,
            channel=Notification.Channel.IN_APP,
        )
        return Response(NotificationSerializer(mark_read(notification, request.user)).data)


class MyPendingWorkListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PendingWorkItemSerializer

    def get_queryset(self):
        queryset = PendingWorkItem.objects.filter(
            assignee=self.request.user
        ).order_by("-created_at")
        status_value = self.request.query_params.get(
            "status", PendingWorkItem.Status.PENDING
        )
        if status_value:
            queryset = queryset.filter(status=status_value)
        return queryset


class MyPendingWorkCompleteView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=EmptySerializer,
        responses=PendingWorkItemSerializer,
        operation_id="pending_work_complete",
    )
    def post(self, request, work_item_id, version=None):
        item = get_object_or_404(
            PendingWorkItem, pk=work_item_id, assignee=request.user
        )
        if item.status == PendingWorkItem.Status.PENDING:
            item.status = PendingWorkItem.Status.COMPLETED
            item.completed_at = timezone.now()
            item.save(update_fields=["status", "completed_at", "updated_at"])
        return Response(PendingWorkItemSerializer(item).data)


class OrganizationNotificationLogView(
    OrganizationSchedulingMixin, generics.ListAPIView
):
    serializer_class = NotificationSerializer
    view_permission = "notification.log.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Notification.objects.filter(organization=organization).order_by(
            "-created_at"
        )


class OrganizationNotificationRetryView(OrganizationSchedulingMixin, APIView):
    manage_permission = "notification.retry"

    @extend_schema(
        request=EmptySerializer,
        responses=NotificationSerializer,
        operation_id="organization_notification_retry",
    )
    def post(
        self, request, organization_id, notification_id, version=None
    ):
        organization, _ = self.organization_and_membership()
        notification = get_object_or_404(
            Notification, pk=notification_id, organization=organization
        )
        try:
            notification = retry_notification(notification, request.user)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(NotificationSerializer(notification).data)
