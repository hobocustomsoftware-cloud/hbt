from django.shortcuts import get_object_or_404
from rest_framework import generics

from apps.audit.services import record_audit_event
from apps.tenancy.services import active_membership_for, require_permission
from apps.tenancy.views import organization_for_user

from .models import LayoutPosition, SeatLayout, Vehicle, VehicleLayoutAssignment
from .serializers import (
    LayoutPositionSerializer,
    SeatLayoutSerializer,
    VehicleLayoutAssignmentSerializer,
    VehicleSerializer,
)


class FleetMixin:
    view_permission = "fleet.view"
    manage_permission = "fleet.manage"

    def context(self):
        if not hasattr(self, "_org"):
            self._org = organization_for_user(
                self.request.user, self.kwargs["organization_id"]
            )
            self._membership = active_membership_for(
                self.request.user, self._org
            )
        return self._org, self._membership

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _, membership = self.context()
        require_permission(
            membership,
            self.manage_permission
            if request.method in ("POST", "PUT", "PATCH")
            else self.view_permission,
        )

    def audit(self, action, instance, serializer):
        org, _ = self.context()
        record_audit_event(
            actor=self.request.user,
            tenant_id=org.tenant_id,
            organization_id=org.id,
            action=action,
            resource_type=instance._meta.model_name,
            resource_id=instance.id,
            after=serializer(instance, context=self.get_serializer_context()).data,
        )


class VehicleListCreateView(FleetMixin, generics.ListCreateAPIView):
    serializer_class = VehicleSerializer

    def get_queryset(self):
        org, _ = self.context()
        return Vehicle.objects.filter(organization=org).select_related("branch")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["organization"], _ = self.context()
        return context

    def perform_create(self, serializer):
        org, _ = self.context()
        vehicle = serializer.save(organization=org)
        self.audit("fleet.vehicle_created", vehicle, VehicleSerializer)


class SeatLayoutListCreateView(FleetMixin, generics.ListCreateAPIView):
    serializer_class = SeatLayoutSerializer

    def get_queryset(self):
        org, _ = self.context()
        return SeatLayout.objects.filter(organization=org)

    def perform_create(self, serializer):
        org, _ = self.context()
        layout = serializer.save(organization=org)
        self.audit("fleet.layout_created", layout, SeatLayoutSerializer)


class LayoutPositionListCreateView(FleetMixin, generics.ListCreateAPIView):
    serializer_class = LayoutPositionSerializer

    def layout(self):
        org, _ = self.context()
        return get_object_or_404(
            SeatLayout, id=self.kwargs["layout_id"], organization=org
        )

    def get_queryset(self):
        return LayoutPosition.objects.filter(layout=self.layout())

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["layout"] = self.layout()
        return context

    def perform_create(self, serializer):
        position = serializer.save(layout=self.layout())
        self.audit("fleet.layout_position_created", position, LayoutPositionSerializer)


class VehicleLayoutAssignmentCreateView(FleetMixin, generics.CreateAPIView):
    serializer_class = VehicleLayoutAssignmentSerializer

    def vehicle(self):
        org, _ = self.context()
        return get_object_or_404(
            Vehicle, id=self.kwargs["vehicle_id"], organization=org
        )

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["vehicle"] = self.vehicle()
        return context

    def perform_create(self, serializer):
        assignment = serializer.save(
            vehicle=self.vehicle(), assigned_by=self.request.user
        )
        self.audit(
            "fleet.layout_assigned",
            assignment,
            VehicleLayoutAssignmentSerializer,
        )
