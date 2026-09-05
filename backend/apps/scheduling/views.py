from django.shortcuts import get_object_or_404
from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.audit.services import record_audit_event
from apps.network.models import RouteStop
from apps.tenancy.models import MembershipRole
from apps.tenancy.services import active_membership_for, require_permission, scoped_queryset
from apps.tenancy.views import organization_for_user

from .models import Schedule, Trip
from .serializers import (
    ConductorAssignmentSerializer, DriverAssignmentSerializer,
    GenerateTripSerializer, ScheduleSerializer, TripAssignmentEventSerializer,
    TripOperationSerializer, TripOperationalEventSerializer,
    TripOperationResponseSerializer, TripSerializer, StopReachedSerializer,
    VehicleAssignmentSerializer,
)


class OrganizationSchedulingMixin:
    permission_classes = [IsAuthenticated]
    view_permission = "scheduling.view"
    manage_permission = "scheduling.manage"

    def organization_and_membership(self):
        if not hasattr(self, "_organization"):
            self._organization = organization_for_user(
                self.request.user, self.kwargs["organization_id"]
            )
            self._membership = active_membership_for(
                self.request.user, self._organization
            )
        return self._organization, self._membership

    def get_serializer_context(self):
        context = super().get_serializer_context()
        organization, _ = self.organization_and_membership()
        context["organization"] = organization
        return context

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _, membership = self.organization_and_membership()
        permission = (
            self.manage_permission
            if request.method in ("POST", "PUT", "PATCH")
            else self.view_permission
        )
        require_permission(membership, permission)

    def audit(self, action, instance, before=None):
        organization, _ = self.organization_and_membership()
        record_audit_event(
            actor=self.request.user, tenant_id=organization.tenant_id,
            organization_id=organization.id, action=action,
            resource_type=instance._meta.model_name, resource_id=instance.id,
            before=before or {},
            after={"id": instance.id, "status": getattr(instance, "status", "")},
        )


class ScheduleListCreateView(OrganizationSchedulingMixin, generics.ListCreateAPIView):
    serializer_class = ScheduleSerializer

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Schedule.objects.filter(organization=organization).select_related("route")

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        schedule = serializer.save(organization=organization)
        self.audit("schedule.created", schedule)


class ScheduleDetailView(OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView):
    serializer_class = ScheduleSerializer
    lookup_url_kwarg = "schedule_id"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Schedule.objects.filter(organization=organization)

    def perform_update(self, serializer):
        old_status = serializer.instance.status
        new_status = serializer.validated_data.get("status", old_status)
        if new_status in (Schedule.Status.APPROVED, Schedule.Status.OPERATIONAL, Schedule.Status.ARCHIVED) and new_status != old_status:
            _, membership = self.organization_and_membership()
            require_permission(membership, "scheduling.approve")
        schedule = serializer.save()
        self.audit("schedule.updated", schedule, before={"status": old_status})


class TripListCreateView(OrganizationSchedulingMixin, generics.ListCreateAPIView):
    serializer_class = TripSerializer
    view_permission = "trip.view"
    manage_permission = "trip.manage"

    def get_queryset(self):
        organization, membership = self.organization_and_membership()
        return scoped_queryset(
            membership,
            Trip.objects.filter(organization=organization).select_related(
                "schedule", "route", "vehicle", "driver", "conductor"
            ),
            self.view_permission,
        )

    def perform_create(self, serializer):
        organization, membership = self.organization_and_membership()
        trip = serializer.save(organization=organization)
        require_trip_scope(membership, trip, self.manage_permission)
        self.audit("trip.created", trip)


class TripDetailView(OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView):
    serializer_class = TripSerializer
    lookup_url_kwarg = "trip_id"
    view_permission = "trip.view"
    manage_permission = "trip.manage"

    def get_queryset(self):
        organization, membership = self.organization_and_membership()
        return scoped_queryset(membership, Trip.objects.filter(organization=organization), self.view_permission)

    def perform_update(self, serializer):
        trip = serializer.instance
        _, membership = self.organization_and_membership()
        require_trip_scope(membership, trip, self.manage_permission)
        trip = serializer.save()
        self.audit("trip.updated", trip)


class GenerateTripView(OrganizationSchedulingMixin, APIView):
    manage_permission = "trip.manage"

    @extend_schema(request=GenerateTripSerializer, responses={201: TripSerializer}, operation_id="trip_generate_from_schedule")
    def post(self, request, organization_id, schedule_id, version=None):
        organization, membership = self.organization_and_membership()
        schedule = get_object_or_404(Schedule, pk=schedule_id, organization=organization)
        require_permission(membership, self.manage_permission)
        serializer = GenerateTripSerializer(data=request.data, context={"schedule": schedule, "request": request})
        serializer.is_valid(raise_exception=True)
        trip = serializer.save()
        require_trip_scope(membership, trip, self.manage_permission)
        self.audit("trip.generated", trip)
        return Response(TripSerializer(trip, context={"organization": organization}).data, status=status.HTTP_201_CREATED)


class TripAssignmentView(OrganizationSchedulingMixin, APIView):
    manage_permission = "trip.assign"
    serializer_class = None

    def post(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip, pk=trip_id, organization=organization)
        require_trip_scope(membership, trip, self.manage_permission)
        serializer = self.serializer_class(data=request.data, context={"trip": trip, "request": request})
        serializer.is_valid(raise_exception=True)
        trip = serializer.save()
        return Response(TripSerializer(trip, context={"organization": organization}).data)


class VehicleAssignmentView(TripAssignmentView):
    serializer_class = VehicleAssignmentSerializer

class DriverAssignmentView(TripAssignmentView):
    serializer_class = DriverAssignmentSerializer

class ConductorAssignmentView(TripAssignmentView):
    serializer_class = ConductorAssignmentSerializer


class TripAssignmentHistoryView(OrganizationSchedulingMixin, generics.ListAPIView):
    serializer_class = TripAssignmentEventSerializer
    view_permission = "trip.view"

    def get_queryset(self):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip, pk=self.kwargs["trip_id"], organization=organization)
        require_trip_scope(membership, trip, self.view_permission)
        return trip.assignment_events.select_related("assigned_by")


def require_trip_scope(membership, trip, permission):
    now = timezone.now()
    assignments = MembershipRole.objects.filter(membership=membership, role__permissions__code=permission).filter(
        Q(valid_from__isnull=True) | Q(valid_from__lte=now),
        Q(valid_until__isnull=True) | Q(valid_until__gt=now),
    )
    allowed = Q(scope_type=MembershipRole.ScopeType.COMPANY) | Q(scope_type=MembershipRole.ScopeType.ASSIGNED_TRIP, scope_id=trip.id)
    if trip.vehicle_id:
        allowed |= Q(scope_type=MembershipRole.ScopeType.BRANCH, scope_id=trip.vehicle.branch_id)
    if ((trip.driver_id and trip.driver.staff.membership_id == membership.id) or (trip.conductor_id and trip.conductor.staff.membership_id == membership.id)):
        allowed |= Q(scope_type=MembershipRole.ScopeType.SELF)
    if not assignments.filter(allowed).exists():
        from django.core.exceptions import PermissionDenied
        raise PermissionDenied("Permission is not valid for this trip scope.")


class TripOperationView(OrganizationSchedulingMixin, APIView):
    manage_permission = "trip.operate"
    event_type = None

    @extend_schema(request=TripOperationSerializer, responses=TripOperationResponseSerializer)
    def post(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip.objects.select_related("vehicle__branch", "driver__staff", "conductor__staff"), pk=trip_id, organization=organization)
        require_trip_scope(membership, trip, self.manage_permission)
        serializer = TripOperationSerializer(data=request.data, context={"trip": trip, "event_type": self.event_type, "request": request})
        serializer.is_valid(raise_exception=True)
        trip = serializer.save()
        return Response({"trip": TripSerializer(trip, context={"organization": organization}).data, "event": TripOperationalEventSerializer(serializer.event).data})

class TripReadyView(TripOperationView):
    event_type = "ready"
class BoardingStartView(TripOperationView):
    manage_permission = "boarding.manage"
    event_type = "boarding_started"
class TripDepartView(TripOperationView):
    event_type = "departed"
class TripEnRouteView(TripOperationView):
    event_type = "en_route"
class TripArriveView(TripOperationView):
    event_type = "arrived"


class StopReachedView(OrganizationSchedulingMixin, APIView):
    manage_permission = "trip.operate"

    @extend_schema(request=StopReachedSerializer, responses=TripOperationResponseSerializer, operation_id="trip_stop_reached")
    def post(self, request, organization_id, trip_id, stop_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip.objects.select_related("vehicle__branch", "driver__staff", "conductor__staff"), pk=trip_id, organization=organization)
        require_trip_scope(membership, trip, self.manage_permission)
        route_stop = get_object_or_404(RouteStop, pk=stop_id, route=trip.route)
        serializer = StopReachedSerializer(data=request.data, context={"trip": trip, "route_stop": route_stop, "request": request})
        serializer.is_valid(raise_exception=True)
        trip = serializer.save()
        return Response({"trip": TripSerializer(trip, context={"organization": organization}).data, "event": TripOperationalEventSerializer(serializer.event).data})


class TripOperationalEventListView(OrganizationSchedulingMixin, generics.ListAPIView):
    serializer_class = TripOperationalEventSerializer
    view_permission = "trip.view"

    def get_queryset(self):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip, pk=self.kwargs["trip_id"], organization=organization)
        require_trip_scope(membership, trip, self.view_permission)
        return trip.operational_events.select_related("route_stop", "recorded_by")
