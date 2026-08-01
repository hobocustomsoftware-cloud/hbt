from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import generics, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, extend_schema_field

from apps.bookings.models import Booking, SeatReservation
from apps.bookings.serializers import BookingSerializer
from apps.bookings.services import cancel_booking, create_booking
from apps.bookings.seat_lock_services import (
    active_locks_for_trip,
    seat_payload,
)
from apps.fleet.models import LayoutPosition
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization
from apps.ticketing.models import Ticket
from apps.ticketing.serializers import TicketSerializer

from .models import Passenger
from .serializers import PassengerSerializer


class SelfTravelerSerializer(PassengerSerializer):
    organization = serializers.PrimaryKeyRelatedField(
        queryset=Organization.objects.filter(status=Organization.Status.ACTIVE),
        write_only=True,
    )

    class Meta(PassengerSerializer.Meta):
        fields = PassengerSerializer.Meta.fields + ("organization",)

    def create(self, validated_data):
        organization = validated_data.pop("organization")
        passenger = Passenger(
            organization=organization,
            managed_by=self.context["request"].user,
            **validated_data,
        )
        passenger.full_clean()
        passenger.save()
        return passenger


class SelfTravelerListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SelfTravelerSerializer

    def get_queryset(self):
        return Passenger.objects.filter(
            Q(managed_by=self.request.user) | Q(account=self.request.user)
        )

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["organization"] = None
        return context


class PublicTripSearchSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(
        source="organization.display_name", read_only=True
    )
    available_seat_count = serializers.SerializerMethodField()

    class Meta:
        model = Trip
        fields = (
            "id", "organization", "organization_name", "trip_number",
            "service_date", "planned_departure_at", "planned_arrival_at",
            "route", "available_seat_count",
        )

    @extend_schema_field(serializers.IntegerField)
    def get_available_seat_count(self, trip):
        pickup = self.context["pickup"]
        dropoff = self.context["dropoff"]
        if not trip.seat_layout_id:
            return 0
        occupied = SeatReservation.objects.filter(
            trip=trip,
            status__in=["held", "reserved", "confirmed"],
            pickup_sequence__lt=dropoff.sequence,
            dropoff_sequence__gt=pickup.sequence,
        ).values_list("seat_position_id", flat=True)
        return LayoutPosition.objects.filter(
            layout=trip.seat_layout, bookable=True
        ).exclude(id__in=occupied).count()


class PublicTripSearchView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PublicTripSearchSerializer

    def get_queryset(self):
        service_date = self.request.query_params.get("date")
        pickup_id = self.request.query_params.get("pickup_stop")
        dropoff_id = self.request.query_params.get("dropoff_stop")
        if not all((service_date, pickup_id, dropoff_id)):
            raise serializers.ValidationError(
                "date, pickup_stop, and dropoff_stop are required."
            )
        from apps.network.models import RouteStop

        self.pickup = get_object_or_404(RouteStop, pk=pickup_id)
        self.dropoff = get_object_or_404(
            RouteStop, pk=dropoff_id, route=self.pickup.route
        )
        if self.dropoff.sequence <= self.pickup.sequence:
            raise serializers.ValidationError("Drop-off must follow pickup.")
        return Trip.objects.filter(
            organization__status=Organization.Status.ACTIVE,
            route=self.pickup.route,
            service_date=service_date,
            status__in=[Trip.Status.PLANNED, Trip.Status.READY],
        ).select_related("organization", "seat_layout")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        if not hasattr(self, "pickup"):
            self.get_queryset()
        context.update({"pickup": self.pickup, "dropoff": self.dropoff})
        return context


class TripSeatAvailabilitySerializer(serializers.Serializer):
    trip_id = serializers.UUIDField()
    pickup_stop = serializers.UUIDField()
    dropoff_stop = serializers.UUIDField()
    seats = serializers.ListField(child=serializers.DictField())


class SelfBookingCancelSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True)


class PublicTripSeatAvailabilityView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(responses=TripSeatAvailabilitySerializer)
    def get(self, request, trip_id, version=None):
        trip = get_object_or_404(
            Trip.objects.select_related("seat_layout"),
            pk=trip_id,
            organization__status=Organization.Status.ACTIVE,
            status__in=[Trip.Status.PLANNED, Trip.Status.READY],
        )
        pickup = get_object_or_404(
            trip.route.stops, pk=request.query_params.get("pickup_stop")
        )
        dropoff = get_object_or_404(
            trip.route.stops, pk=request.query_params.get("dropoff_stop")
        )
        if dropoff.sequence <= pickup.sequence:
            raise serializers.ValidationError("Drop-off must follow pickup.")
        occupied = SeatReservation.objects.filter(
            trip=trip,
            status__in=["held", "reserved", "confirmed"],
            pickup_sequence__lt=dropoff.sequence,
            dropoff_sequence__gt=pickup.sequence,
        ).values_list("seat_position_id", flat=True)
        seats = LayoutPosition.objects.filter(
            layout=trip.seat_layout, bookable=True
        ).order_by("deck", "row", "column")
        occupied_ids = {str(value) for value in occupied}
        locks_by_seat = {
            str(lock.seat_position_id): lock
            for lock in active_locks_for_trip(
                organization=trip.organization, trip=trip
            )
        }
        return Response({
            "trip_id": trip.id,
            "pickup_stop": pickup.id,
            "dropoff_stop": dropoff.id,
            "seats": [
                seat_payload(seat, occupied_ids, locks_by_seat)
                for seat in seats
            ],
        })


class SelfBookingSerializer(BookingSerializer):
    def validate(self, attrs):
        organization = attrs["trip"].organization
        for item in attrs.get("passenger_seats", []):
            passenger = item["passenger"]
            if passenger.organization_id != organization.id or (
                passenger.managed_by_id != self.context["request"].user.id
                and passenger.account_id != self.context["request"].user.id
            ):
                raise serializers.ValidationError("Traveler is not managed by this account.")
        return attrs

    def create(self, validated_data):
        passenger_seats = validated_data.pop("passenger_seats")
        trip = validated_data["trip"]
        return create_booking(
            organization=trip.organization,
            actor=self.context["request"].user,
            customer_account=self.context["request"].user,
            passenger_seats=passenger_seats,
            **validated_data,
        )


class SelfBookingListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SelfBookingSerializer

    def get_queryset(self):
        return Booking.objects.filter(
            customer_account=self.request.user
        ).prefetch_related(
            "passenger_items__passenger", "passenger_items__seat_reservation"
        )

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["organization"] = None
        return context


class SelfBookingDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SelfBookingSerializer
    lookup_url_kwarg = "booking_id"

    def get_queryset(self):
        return Booking.objects.filter(
            customer_account=self.request.user
        ).prefetch_related(
            "passenger_items__passenger", "passenger_items__seat_reservation"
        )

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["organization"] = None
        return context


class SelfBookingCancelView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=SelfBookingCancelSerializer,
        responses=SelfBookingSerializer,
    )
    def post(self, request, booking_id, version=None):
        booking = get_object_or_404(
            Booking, pk=booking_id, customer_account=request.user
        )
        reason = request.data.get("reason", "")
        try:
            booking = cancel_booking(
                booking=booking, actor=request.user, reason=reason
            )
        except Exception as exc:
            from django.core.exceptions import ValidationError

            if isinstance(exc, ValidationError):
                raise serializers.ValidationError(exc.messages) from exc
            raise
        return Response(
            SelfBookingSerializer(
                booking, context={"request": request, "organization": None}
            ).data
        )


class SelfTicketListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = TicketSerializer

    def get_queryset(self):
        return Ticket.objects.filter(
            booking__customer_account=self.request.user
        ).select_related(
            "passenger", "trip", "booking_passenger__seat_reservation"
        )
