from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.scheduling.models import Trip
from apps.scheduling.views import (
    OrganizationSchedulingMixin,
    require_trip_scope,
)

from .models import BoardingRecord
from .serializers import (
    BoardingRecordSerializer,
    BoardingValidationSerializer,
    BoardPassengerSerializer,
)


class BoardingListView(OrganizationSchedulingMixin, generics.ListAPIView):
    serializer_class = BoardingRecordSerializer
    view_permission = "boarding.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return BoardingRecord.objects.filter(
            organization=organization
        ).select_related(
            "passenger",
            "ticket__booking_passenger__seat_reservation",
        )


class BoardingValidateView(OrganizationSchedulingMixin, APIView):
    manage_permission = "boarding.validate"

    @extend_schema(
        request=BoardingValidationSerializer,
        responses={201: BoardingRecordSerializer},
        operation_id="boarding_validate",
    )
    def post(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(
            Trip.objects.select_related(
                "vehicle__branch",
                "driver__staff",
                "conductor__staff",
            ),
            pk=trip_id,
            organization=organization,
        )
        require_trip_scope(membership, trip, self.manage_permission)
        serializer = BoardingValidationSerializer(
            data=request.data,
            context={
                "organization": organization,
                "trip": trip,
                "request": request,
            },
        )
        serializer.is_valid(raise_exception=True)
        record = serializer.save()
        return Response(
            BoardingRecordSerializer(record).data,
            status=status.HTTP_201_CREATED,
        )


class BoardPassengerView(OrganizationSchedulingMixin, APIView):
    manage_permission = "boarding.record"

    @extend_schema(
        request=BoardPassengerSerializer,
        responses=BoardingRecordSerializer,
        operation_id="boarding_record",
    )
    def post(self, request, organization_id, boarding_id, version=None):
        organization, membership = self.organization_and_membership()
        record = get_object_or_404(
            BoardingRecord.objects.select_related(
                "trip__vehicle__branch",
                "trip__driver__staff",
                "trip__conductor__staff",
            ),
            pk=boarding_id,
            organization=organization,
        )
        require_trip_scope(membership, record.trip, self.manage_permission)
        serializer = BoardPassengerSerializer(
            data=request.data,
            context={"record": record, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        record = serializer.save()
        return Response(BoardingRecordSerializer(record).data)
