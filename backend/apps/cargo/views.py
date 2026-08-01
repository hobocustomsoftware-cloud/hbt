from django.db.models import Count, Q, Sum
from django.core import signing
from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework import serializers as drf_serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema
from apps.core.serializers import EmptySerializer

from apps.scheduling.models import Trip
from apps.scheduling.views import (
    OrganizationSchedulingMixin,
    require_trip_scope,
)
from apps.payments.models import PaymentRecord
from apps.tenancy.models import MembershipRole


def require_cargo_acceptance_scope(membership, origin_terminal, counter=None):
    from django.core.exceptions import PermissionDenied
    from django.utils import timezone

    now = timezone.now()
    assignments = MembershipRole.objects.filter(
        membership=membership,
        role__permissions__code="cargo.accept",
    ).filter(
        Q(valid_from__isnull=True) | Q(valid_from__lte=now),
        Q(valid_until__isnull=True) | Q(valid_until__gt=now),
    )
    allowed = Q(scope_type=MembershipRole.ScopeType.COMPANY)
    allowed |= Q(
        scope_type=MembershipRole.ScopeType.BRANCH,
        scope_id=origin_terminal.branch_id,
    )
    allowed |= Q(
        scope_type=MembershipRole.ScopeType.TERMINAL,
        scope_id=origin_terminal.id,
    )
    if counter:
        allowed |= Q(
            scope_type=MembershipRole.ScopeType.COUNTER,
            scope_id=counter.id,
        )
    if not assignments.filter(allowed).exists():
        raise PermissionDenied(
            "Cargo acceptance permission is not valid for this terminal or counter."
        )

from .models import (
    CargoCategory,
    CargoChargeLine,
    CargoContact,
    CargoPricingRule,
    CargoShipment,
)
from .serializers import (
    CargoAllocationPaidSerializer,
    CargoAssignTripSerializer,
    CargoCategorySerializer,
    CargoChargeLineSerializer,
    CargoContactSerializer,
    CargoPricingRuleSerializer,
    CargoShipmentSerializer,
    CargoTransitionSerializer,
    CargoManifestSerializer,
    CargoOwnerReportSerializer,
    CargoQrResolveSerializer,
)


class CargoCategoryListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = CargoCategorySerializer
    view_permission = "cargo.view"
    manage_permission = "cargo.category.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CargoCategory.objects.filter(
            organization=organization, active=True
        ).order_by("name_myanmar", "name")

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        serializer.save(organization=organization)
        self.audit("cargo.category.created", serializer.instance)


class CargoPricingRuleListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = CargoPricingRuleSerializer
    view_permission = "cargo.view"
    manage_permission = "cargo.category.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CargoPricingRule.objects.filter(
            organization=organization
        ).select_related("category").order_by("name")

    def perform_create(self, serializer):
        rule = serializer.save()
        self.audit("cargo.pricing_rule.created", rule)


class CargoPricingRuleDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = CargoPricingRuleSerializer
    view_permission = "cargo.view"
    manage_permission = "cargo.category.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CargoPricingRule.objects.filter(organization=organization)

    def perform_update(self, serializer):
        before = {"active": serializer.instance.active}
        rule = serializer.save()
        rule.full_clean()
        rule.save()
        self.audit("cargo.pricing_rule.updated", rule, before=before)


class CargoContactListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = CargoContactSerializer
    view_permission = "cargo.view"
    manage_permission = "cargo.accept"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        queryset = CargoContact.objects.filter(
            organization=organization, active=True
        )
        query = self.request.query_params.get("q", "").strip()
        if query:
            queryset = queryset.filter(
                Q(name__icontains=query)
                | Q(phone_number__icontains=query)
                | Q(contact_code__icontains=query)
            )
        return queryset.order_by("-last_used_at", "name")

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        serializer.save(organization=organization)


class CargoShipmentListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = CargoShipmentSerializer
    view_permission = "cargo.view"
    manage_permission = "cargo.accept"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CargoShipment.objects.filter(
            organization=organization
        ).select_related(
            "sender", "receiver", "origin_terminal", "destination_terminal"
        ).prefetch_related("custody_events", "items", "charge_lines")

    def perform_create(self, serializer):
        _, membership = self.organization_and_membership()
        require_cargo_acceptance_scope(
            membership,
            serializer.validated_data["origin_terminal"],
            serializer.validated_data.get("accepting_counter"),
        )
        serializer.save()


class CargoShipmentDetailView(
    OrganizationSchedulingMixin, generics.RetrieveAPIView
):
    serializer_class = CargoShipmentSerializer
    lookup_url_kwarg = "shipment_id"
    view_permission = "cargo.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CargoShipment.objects.filter(
            organization=organization
        ).prefetch_related("custody_events", "items", "charge_lines")


class CargoActionView(OrganizationSchedulingMixin, APIView):
    manage_permission = "cargo.manage"
    serializer_class = None

    def post(self, request, organization_id, shipment_id, version=None):
        organization, _ = self.organization_and_membership()
        shipment = get_object_or_404(
            CargoShipment, pk=shipment_id, organization=organization
        )
        serializer = self.serializer_class(
            data=request.data,
            context={"shipment": shipment, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        shipment = serializer.save()
        return Response(CargoShipmentSerializer(shipment).data)


class CargoAssignTripView(CargoActionView):
    serializer_class = CargoAssignTripSerializer


class CargoTransitionView(CargoActionView):
    serializer_class = CargoTransitionSerializer


class TripCargoManifestView(OrganizationSchedulingMixin, APIView):
    view_permission = "cargo.manifest.view"

    @extend_schema(
        responses=CargoManifestSerializer,
        operation_id="trip_cargo_manifest",
    )
    def get(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip, organization=organization, pk=trip_id)
        require_trip_scope(membership, trip, self.view_permission)
        shipments = CargoShipment.objects.filter(
            organization=organization,
            assigned_trip=trip,
        ).select_related(
            "sender", "receiver", "origin_terminal", "destination_terminal"
        ).prefetch_related("items", "charge_lines", "custody_events")
        return Response(
            {
                "trip_id": trip.id,
                "trip_number": trip.trip_number,
                "status": trip.status,
                "shipment_count": shipments.count(),
                "piece_count": sum(item.piece_count for item in shipments),
                "weight_kg": sum(
                    (item.weight_kg or 0) for item in shipments
                ),
                "total_charge": sum(item.total_charge for item in shipments),
                "shipments": CargoShipmentSerializer(
                    shipments, many=True
                ).data,
            }
        )


class RoadsideCargoAcceptView(OrganizationSchedulingMixin, APIView):
    manage_permission = "cargo.roadside.accept"

    @extend_schema(
        request=CargoShipmentSerializer,
        responses={201: CargoShipmentSerializer},
        operation_id="roadside_cargo_accept",
    )
    def post(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(
            Trip.objects.select_related("vehicle", "route"),
            organization=organization,
            pk=trip_id,
        )
        require_trip_scope(membership, trip, self.manage_permission)
        if trip.status not in (
            Trip.Status.READY,
            Trip.Status.BOARDING,
            Trip.Status.DEPARTED,
            Trip.Status.IN_PROGRESS,
        ):
            raise drf_serializers.ValidationError(
                "Trip is not accepting roadside cargo."
            )
        if not request.data.get("pickup_location_text"):
            raise drf_serializers.ValidationError(
                {"pickup_location_text": "Roadside pickup location is required."}
            )
        if not request.data.get("acceptance_device_id"):
            raise drf_serializers.ValidationError(
                {"acceptance_device_id": "Authenticated device reference is required."}
            )
        payload = request.data.copy()
        payload["acceptance_channel"] = CargoShipment.AcceptanceChannel.CONDUCTOR
        serializer = CargoShipmentSerializer(
            data=payload,
            context={"organization": organization, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        shipment = serializer.save()
        shipment = assign_trip(
            shipment=shipment,
            trip=trip,
            actor=request.user,
            notes="Accepted for assigned trip by authorized crew.",
        )
        return Response(CargoShipmentSerializer(shipment).data, status=201)


class CargoQrResolveView(OrganizationSchedulingMixin, APIView):
    view_permission = "cargo.view"

    @extend_schema(
        request=CargoQrResolveSerializer,
        responses=CargoShipmentSerializer,
        operation_id="cargo_qr_resolve",
    )
    def post(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        value = str(request.data.get("qr_payload", ""))
        prefix = "HBT:CARGO:V1:"
        if not value.startswith(prefix):
            raise drf_serializers.ValidationError("Invalid cargo QR format.")
        try:
            payload = signing.loads(
                value[len(prefix):],
                salt="hbt.cargo.tracking.v1",
            )
        except signing.BadSignature as exc:
            raise drf_serializers.ValidationError(
                "Cargo QR signature is invalid."
            ) from exc
        shipment = get_object_or_404(
            CargoShipment,
            organization=organization,
            tracking_code=payload.get("tracking_code"),
        )
        return Response(CargoShipmentSerializer(shipment).data)


class CargoOwnerReportView(OrganizationSchedulingMixin, APIView):
    view_permission = "report.owner"

    @extend_schema(
        responses=CargoOwnerReportSerializer,
        operation_id="cargo_owner_report",
    )
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        queryset = CargoShipment.objects.filter(organization=organization)
        date_from = request.query_params.get("date_from")
        date_to = request.query_params.get("date_to")
        status_value = request.query_params.get("status")
        acceptance_channel = request.query_params.get("acceptance_channel")
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)
        if status_value:
            queryset = queryset.filter(status=status_value)
        if acceptance_channel:
            queryset = queryset.filter(acceptance_channel=acceptance_channel)
        totals = queryset.aggregate(
            shipment_count=Count("id"),
            piece_count=Sum("piece_count"),
            weight_kg=Sum("weight_kg"),
            total_charge=Sum("total_charge"),
        )
        confirmed_payment = PaymentRecord.objects.filter(
            organization=organization,
            cargo_shipment__in=queryset,
            status=PaymentRecord.Status.CONFIRMED,
        ).aggregate(total=Sum("amount"))["total"] or 0
        by_channel = list(
            queryset.values("acceptance_channel")
            .annotate(
                shipment_count=Count("id"),
                total_charge=Sum("total_charge"),
            )
            .order_by("acceptance_channel")
        )
        total_charge = totals["total_charge"] or 0
        return Response(
            {
                **{key: value or 0 for key, value in totals.items()},
                "confirmed_payment": confirmed_payment,
                "outstanding_amount": max(total_charge - confirmed_payment, 0),
                "by_acceptance_channel": by_channel,
            }
        )


class CargoAllocationPaidView(OrganizationSchedulingMixin, APIView):
    manage_permission = "settlement.approve"

    @extend_schema(
        request=EmptySerializer,
        responses=CargoChargeLineSerializer,
        operation_id="cargo_allocation_mark_paid",
    )
    def post(
        self,
        request,
        organization_id,
        shipment_id,
        charge_line_id,
        version=None,
    ):
        organization, _ = self.organization_and_membership()
        line = get_object_or_404(
            CargoChargeLine,
            pk=charge_line_id,
            shipment_id=shipment_id,
            shipment__organization=organization,
        )
        serializer = CargoAllocationPaidSerializer(
            data={},
            context={"charge_line": line, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        line = serializer.save()
        return Response(CargoChargeLineSerializer(line).data)
