from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from apps.audit.services import record_audit_event
from apps.tenancy.services import active_membership_for, require_permission
from apps.tenancy.views import organization_for_user

from .models import Route, RouteSegment, RouteStop
from .serializers import (
    RouteSegmentSerializer,
    RouteSerializer,
    RouteStopSerializer,
)


class OrganizationNetworkMixin:
    permission_classes = [IsAuthenticated]
    view_permission = "network.route.view"
    manage_permission = "network.route.manage"

    def organization_and_membership(self):
        if not hasattr(self, "_organization"):
            self._organization = organization_for_user(
                self.request.user,
                self.kwargs["organization_id"],
            )
            self._membership = active_membership_for(
                self.request.user,
                self._organization,
            )
        return self._organization, self._membership

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _, membership = self.organization_and_membership()
        permission = (
            self.manage_permission
            if request.method in ("POST", "PUT", "PATCH")
            else self.view_permission
        )
        require_permission(membership, permission)

    def audit(self, action, instance, serializer_class, before=None):
        organization, _ = self.organization_and_membership()
        record_audit_event(
            actor=self.request.user,
            tenant_id=organization.tenant_id,
            organization_id=organization.id,
            action=action,
            resource_type=instance._meta.model_name,
            resource_id=instance.id,
            before=before or {},
            after=serializer_class(instance).data,
        )


class RouteListCreateView(
    OrganizationNetworkMixin,
    generics.ListCreateAPIView,
):
    serializer_class = RouteSerializer

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Route.objects.filter(organization=organization)

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        route = serializer.save(organization=organization)
        self.audit("network.route_created", route, RouteSerializer)


class RouteDetailView(
    OrganizationNetworkMixin,
    generics.RetrieveUpdateAPIView,
):
    serializer_class = RouteSerializer
    lookup_url_kwarg = "route_id"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Route.objects.filter(organization=organization)

    def perform_update(self, serializer):
        before = RouteSerializer(serializer.instance).data
        requested_status = serializer.validated_data.get(
            "status",
            serializer.instance.status,
        )
        if (
            requested_status != serializer.instance.status
            and requested_status in (Route.Status.APPROVED, Route.Status.ACTIVE)
        ):
            _, membership = self.organization_and_membership()
            require_permission(membership, "network.route.approve")
        route = serializer.save()
        self.audit("network.route_updated", route, RouteSerializer, before)


class RouteChildMixin(OrganizationNetworkMixin):
    def route(self):
        if not hasattr(self, "_route"):
            organization, _ = self.organization_and_membership()
            self._route = get_object_or_404(
                Route,
                id=self.kwargs["route_id"],
                organization=organization,
            )
        return self._route


class RouteStopListCreateView(RouteChildMixin, generics.ListCreateAPIView):
    serializer_class = RouteStopSerializer

    def get_queryset(self):
        return RouteStop.objects.filter(route=self.route())

    def perform_create(self, serializer):
        stop = serializer.save(route=self.route())
        self.audit("network.stop_created", stop, RouteStopSerializer)


class RouteStopDetailView(RouteChildMixin, generics.RetrieveUpdateAPIView):
    serializer_class = RouteStopSerializer
    lookup_url_kwarg = "stop_id"

    def get_queryset(self):
        return RouteStop.objects.filter(route=self.route())

    def perform_update(self, serializer):
        before = RouteStopSerializer(serializer.instance).data
        stop = serializer.save()
        self.audit("network.stop_updated", stop, RouteStopSerializer, before)


class RouteSegmentListCreateView(RouteChildMixin, generics.ListCreateAPIView):
    serializer_class = RouteSegmentSerializer

    def get_queryset(self):
        return RouteSegment.objects.filter(route=self.route()).select_related(
            "from_stop", "to_stop"
        )

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["route"] = self.route()
        return context

    def perform_create(self, serializer):
        segment = serializer.save(route=self.route())
        self.audit("network.segment_created", segment, RouteSegmentSerializer)
