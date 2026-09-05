from django.core.exceptions import ValidationError as DjangoValidationError
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.audit.services import record_audit_event
from apps.tenancy.services import active_membership_for, require_permission
from apps.tenancy.views import organization_for_user

from .models import Device, SyncChange
from .serializers import (
    AuthorizationSnapshotSerializer,
    DeviceSerializer,
    SyncChangeSerializer,
    SyncOperationInputSerializer,
    SyncOperationSerializer,
    SyncCapabilitiesSerializer,
    SyncPullResponseSerializer,
    SyncPushResponseSerializer,
)
from apps.core.serializers import EmptySerializer
from .services import OFFLINE_OPERATION_HANDLERS, apply_sync_operation
from .services import issue_authorization_snapshot


def _has_valid_authorization_snapshot(*, device, organization, membership):
    return device.authorization_snapshots.filter(
        organization=organization,
        membership=membership,
        revoked_at__isnull=True,
        expires_at__gt=timezone.now(),
    ).exists()


class MyDeviceListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = DeviceSerializer

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        installation_id = serializer.validated_data["installation_id"]
        existing = Device.objects.filter(installation_id=installation_id).first()
        if existing and existing.user_id != self.request.user.id:
            raise serializers.ValidationError(
                {"installation_id": "This installation is already enrolled."}
            )
        if existing:
            token = serializer.validated_data.pop("push_token", None)
            for field, value in serializer.validated_data.items():
                setattr(existing, field, value)
            if token is not None:
                existing.set_push_token(token)
            existing.status = Device.Status.ACTIVE
            existing.last_seen_at = timezone.now()
            existing.save()
            serializer.instance = existing
        else:
            serializer.save(user=self.request.user, last_seen_at=timezone.now())


class MyDeviceRevokeView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=EmptySerializer,
        responses=DeviceSerializer,
        operation_id="device_revoke",
    )
    def post(self, request, device_id, version=None):
        device = get_object_or_404(Device, pk=device_id, user=request.user)
        device.status = Device.Status.REVOKED
        device.revoked_at = timezone.now()
        # Emptying this field revokes a push token; it is not a password.
        device.set_push_token("")
        device.save(
            update_fields=[
                "status",
                "revoked_at",
                "encrypted_push_token",
                "updated_at",
            ]
        )
        device.authorization_snapshots.filter(revoked_at__isnull=True).update(
            revoked_at=timezone.now()
        )
        record_audit_event(
            actor=request.user,
            action="offline.device_revoked",
            resource_type="device",
            resource_id=device.id,
        )
        return Response(DeviceSerializer(device).data)


class AuthorizationSnapshotIssueView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=EmptySerializer,
        responses={201: AuthorizationSnapshotSerializer},
        operation_id="offline_authorization_snapshot_issue",
    )
    def post(self, request, organization_id, device_id, version=None):
        organization = organization_for_user(request.user, organization_id)
        membership = active_membership_for(request.user, organization)
        require_permission(membership, "offline.sync")
        device = get_object_or_404(
            Device,
            pk=device_id,
            user=request.user,
            status=Device.Status.ACTIVE,
        )
        snapshot = issue_authorization_snapshot(
            device=device, membership=membership, actor=request.user
        )
        return Response(
            AuthorizationSnapshotSerializer(snapshot).data,
            status=status.HTTP_201_CREATED,
        )


class SyncCapabilitiesView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=SyncCapabilitiesSerializer,
        operation_id="offline_sync_capabilities",
    )
    def get(self, request, version=None):
        return Response(
            {
                "protocol_version": 1,
                "authorization_snapshot_hours": 12,
                "supported_upload_operations": sorted(
                    OFFLINE_OPERATION_HANDLERS
                ),
                "delta_download": True,
                "manual_sync": True,
                "max_batch_size": 100,
            }
        )


class SyncPushView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=SyncOperationInputSerializer(many=True),
        responses=SyncPushResponseSerializer,
        operation_id="offline_sync_push",
    )
    def post(self, request, organization_id, device_id, version=None):
        organization = organization_for_user(request.user, organization_id)
        membership = active_membership_for(request.user, organization)
        require_permission(membership, "offline.sync")
        device = get_object_or_404(
            Device,
            pk=device_id,
            user=request.user,
            status=Device.Status.ACTIVE,
        )
        if not _has_valid_authorization_snapshot(
            device=device, organization=organization, membership=membership
        ):
            return Response(
                {"detail": "A valid offline authorization snapshot is required."},
                status=403,
            )
        if not isinstance(request.data, list):
            return Response(
                {"detail": "A list of operations is required."}, status=400
            )
        if len(request.data) > 100:
            return Response(
                {"detail": "A maximum of 100 operations is allowed."}, status=400
            )
        input_serializer = SyncOperationInputSerializer(
            data=request.data, many=True
        )
        input_serializer.is_valid(raise_exception=True)
        results = []
        for item in input_serializer.validated_data:
            try:
                operation = apply_sync_operation(
                    device=device,
                    organization=organization,
                    actor=request.user,
                    **item,
                )
                results.append(SyncOperationSerializer(operation).data)
            except DjangoValidationError as exc:
                results.append(
                    {
                        "client_operation_id": item["client_operation_id"],
                        "status": "conflict",
                        "error_code": "idempotency_key_reused",
                        "response_payload": {"detail": exc.messages},
                    }
                )
        device.last_seen_at = timezone.now()
        device.save(update_fields=["last_seen_at", "updated_at"])
        return Response({"operations": results})


class SyncPullView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=SyncPullResponseSerializer,
        operation_id="offline_sync_pull",
    )
    def get(self, request, organization_id, device_id, version=None):
        organization = organization_for_user(request.user, organization_id)
        membership = active_membership_for(request.user, organization)
        require_permission(membership, "offline.sync")
        device = get_object_or_404(
            Device,
            pk=device_id,
            user=request.user,
            status=Device.Status.ACTIVE,
        )
        if not _has_valid_authorization_snapshot(
            device=device, organization=organization, membership=membership
        ):
            return Response(
                {"detail": "A valid offline authorization snapshot is required."},
                status=403,
            )
        try:
            cursor = max(int(request.query_params.get("cursor", 0)), 0)
            limit = min(max(int(request.query_params.get("limit", 100)), 1), 500)
        except ValueError:
            return Response({"detail": "Invalid cursor or limit."}, status=400)
        changes = list(
            SyncChange.objects.filter(
                organization=organization, sequence__gt=cursor
            ).order_by("sequence")[:limit]
        )
        next_cursor = changes[-1].sequence if changes else cursor
        device.last_seen_at = timezone.now()
        device.save(update_fields=["last_seen_at", "updated_at"])
        return Response(
            {
                "changes": SyncChangeSerializer(changes, many=True).data,
                "next_cursor": next_cursor,
                "has_more": SyncChange.objects.filter(
                    organization=organization, sequence__gt=next_cursor
                ).exists(),
                "server_time": timezone.now(),
            }
        )
