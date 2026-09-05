from django.shortcuts import get_object_or_404
from rest_framework import generics, serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.fares.models import FareQuote
from apps.fleet.models import LayoutPosition
from apps.scheduling.views import OrganizationSchedulingMixin
from apps.scheduling.models import Trip

from .models import (
    Booking,
    CorporateBookingApproval,
    CorporateCustomer,
    CorporateCustomerMember,
    CorporateInvoice,
    SeatLock,
    SeatReservation,
)
from .seat_lock_services import (
    acquire_seat_lock,
    active_locks_for_trip,
    extend_seat_lock,
    release_seat_lock,
    seat_payload,
)
from .serializers import (
    BookingActionSerializer,
    BookingSerializer,
    CorporateApprovalSerializer,
    CorporateCustomerMemberSerializer,
    CorporateCustomerSerializer,
    CorporateDecisionSerializer,
    CorporateInvoiceIssueSerializer,
    CorporateInvoiceSerializer,
    ReasonSerializer,
    CorporateSubmitSerializer,
)
from .services import (
    decide_corporate_booking,
    issue_corporate_invoice,
    submit_corporate_booking,
    void_corporate_invoice,
)


class BookingListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = BookingSerializer
    view_permission = "booking.view"
    manage_permission = "booking.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Booking.objects.filter(organization=organization).prefetch_related(
            "passenger_items__passenger",
            "passenger_items__seat_reservation",
        )


class CounterTripSeatAvailabilitySerializer(serializers.Serializer):
    trip_id = serializers.UUIDField()
    pickup_stop = serializers.UUIDField()
    dropoff_stop = serializers.UUIDField()
    seats = serializers.ListField(child=serializers.DictField())


class SeatLockAcquireSerializer(serializers.Serializer):
    trip_id = serializers.UUIDField()
    # Accepts either a seat UUID or a layout identifier like "A1".
    seat_position = serializers.CharField(max_length=64)
    held_by_device_id = serializers.CharField(max_length=64, required=False, allow_blank=True)
    idempotency_key = serializers.CharField(max_length=128, required=False, allow_blank=True)


def _resolve_seat_position(trip, value):
    """Resolve a seat by UUID or layout identifier for the trip layout."""
    qs = LayoutPosition.objects.filter(layout_id=trip.seat_layout_id, bookable=True)
    try:
        from uuid import UUID

        candidate = qs.filter(pk=UUID(str(value))).first()
    except (ValueError, AttributeError):
        candidate = None
    return candidate or qs.filter(identifier=value).first()


def _lock_payload(lock):
    return {
        "id": lock.id,
        "trip_id": lock.trip_id,
        "seat_position": lock.seat_position.identifier,
        "seat_position_id": lock.seat_position_id,
        "held_by_user_id": lock.held_by_user_id,
        "held_by_device_id": lock.held_by_device_id or None,
        "held_at": lock.created_at.isoformat(),
        "expires_at": lock.expires_at.isoformat(),
        "status": lock.status,
    }


def _seat_payload(seat, occupied_ids, locks_by_seat):
    """Seat dict for availability responses, including active lock info."""
    return seat_payload(seat, occupied_ids, locks_by_seat)


class SeatLockAcquireView(OrganizationSchedulingMixin, APIView):
    """Acquire a seat hold for a trip (counter workflow)."""

    manage_permission = "booking.manage"

    @extend_schema(
        request=SeatLockAcquireSerializer,
        responses={201: dict, 409: dict},
        operation_id="seat_lock_acquire",
    )
    def post(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        serializer = SeatLockAcquireSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trip = get_object_or_404(
            Trip,
            pk=serializer.validated_data["trip_id"],
            organization=organization,
            status__in=[Trip.Status.PLANNED, Trip.Status.READY],
        )
        seat = _resolve_seat_position(trip, serializer.validated_data["seat_position"])
        if seat is None:
            return Response(
                {"code": "seat_invalid", "detail": "Seat is not part of this trip."},
                status=409,
            )
        lock, conflict = acquire_seat_lock(
            organization=organization,
            trip=trip,
            seat_position=seat,
            actor=request.user,
            held_by_device_id=serializer.validated_data.get("held_by_device_id", ""),
            idempotency_key=serializer.validated_data.get("idempotency_key") or None,
        )
        if lock is None:
            code = conflict or "seat_already_locked"
            detail = {
                "seat_already_locked": "Seat is locked by another counter.",
                "seat_booked": "This seat is already booked.",
                "seat_invalid": "Seat is not part of this trip.",
            }.get(code, "Seat is not available.")
            return Response({"code": code, "detail": detail}, status=409)
        return Response(_lock_payload(lock), status=201)


class SeatLockListByTripView(OrganizationSchedulingMixin, APIView):
    """List active seat holds for a trip."""

    view_permission = "booking.view"

    @extend_schema(responses={200: dict}, operation_id="seat_lock_list")
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        trip_id = request.query_params.get("trip_id")
        trip = get_object_or_404(Trip, pk=trip_id, organization=organization)
        locks = active_locks_for_trip(organization=organization, trip=trip)
        return Response([_lock_payload(lock) for lock in locks])


class SeatLockDetailView(OrganizationSchedulingMixin, APIView):
    """Release a seat hold (best-effort; TTL expires it anyway)."""

    manage_permission = "booking.manage"

    @extend_schema(responses={204: None}, operation_id="seat_lock_release")
    def delete(self, request, organization_id, lock_id, version=None):
        organization, _ = self.organization_and_membership()
        lock = get_object_or_404(
            SeatLock, pk=lock_id, organization=organization
        )
        release_seat_lock(lock=lock, actor=request.user)
        return Response(status=204)


class SeatLockExtendView(OrganizationSchedulingMixin, APIView):
    """Extend the TTL of a held seat lock."""

    manage_permission = "booking.manage"

    @extend_schema(request=None, responses={200: dict}, operation_id="seat_lock_extend")
    def post(self, request, organization_id, lock_id, version=None):
        organization, _ = self.organization_and_membership()
        lock = get_object_or_404(
            SeatLock, pk=lock_id, organization=organization
        )
        lock, conflict = extend_seat_lock(lock=lock, actor=request.user)
        if conflict:
            return Response({"code": conflict, "detail": "Lock has expired."}, status=409)
        return Response(_lock_payload(lock))


class PassengerSeatLockAcquireView(APIView):
    """Acquire a seat hold for a trip (passenger self-service)."""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=SeatLockAcquireSerializer,
        responses={201: dict, 409: dict},
        operation_id="passenger_seat_lock_acquire",
    )
    def post(self, request, version=None):
        serializer = SeatLockAcquireSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trip = get_object_or_404(
            Trip.objects.select_related("seat_layout"),
            pk=serializer.validated_data["trip_id"],
            organization__status="active",
            status__in=[Trip.Status.PLANNED, Trip.Status.READY],
        )
        seat = _resolve_seat_position(trip, serializer.validated_data["seat_position"])
        if seat is None:
            return Response(
                {"code": "seat_invalid", "detail": "Seat is not part of this trip."},
                status=409,
            )
        lock, conflict = acquire_seat_lock(
            organization=trip.organization,
            trip=trip,
            seat_position=seat,
            actor=request.user,
            held_by_device_id=serializer.validated_data.get("held_by_device_id", ""),
            idempotency_key=serializer.validated_data.get("idempotency_key") or None,
        )
        if lock is None:
            code = conflict or "seat_already_locked"
            detail = {
                "seat_already_locked": "This seat was just selected by another passenger.",
                "seat_booked": "This seat is already booked.",
                "seat_invalid": "Seat is not part of this trip.",
            }.get(code, "Seat is not available.")
            return Response({"code": code, "detail": detail}, status=409)
        return Response(_lock_payload(lock), status=201)


class PassengerSeatLockDetailView(APIView):
    """Release a passenger seat hold."""

    permission_classes = [IsAuthenticated]

    @extend_schema(responses={204: None}, operation_id="passenger_seat_lock_release")
    def delete(self, request, lock_id, version=None):
        lock = get_object_or_404(
            SeatLock, pk=lock_id, held_by_user=request.user
        )
        release_seat_lock(lock=lock, actor=request.user)
        return Response(status=204)


class CounterTripSeatAvailabilityView(OrganizationSchedulingMixin, APIView):
    view_permission = "trip.view"

    @extend_schema(responses=CounterTripSeatAvailabilitySerializer)
    def get(self, request, organization_id, trip_id, version=None):
        organization, _ = self.organization_and_membership()
        trip = get_object_or_404(
            Trip.objects.select_related("seat_layout"),
            pk=trip_id,
            organization=organization,
            status__in=[Trip.Status.PLANNED, Trip.Status.READY],
        )
        if trip.seat_layout_id is None:
            raise serializers.ValidationError("Trip has no assigned vehicle seat layout.")
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
            status__in=[
                SeatReservation.Status.HELD,
                SeatReservation.Status.RESERVED,
                SeatReservation.Status.CONFIRMED,
            ],
            pickup_sequence__lt=dropoff.sequence,
            dropoff_sequence__gt=pickup.sequence,
        ).values_list("seat_position_id", flat=True)
        occupied_ids = {str(value) for value in occupied}
        locks_by_seat = {
            str(lock.seat_position_id): lock
            for lock in active_locks_for_trip(organization=organization, trip=trip)
        }
        seats = LayoutPosition.objects.filter(
            layout=trip.seat_layout, bookable=True
        ).order_by("deck", "row", "column")
        return Response(
            {
                "trip_id": trip.id,
                "pickup_stop": pickup.id,
                "dropoff_stop": dropoff.id,
                "seats": [
                    seat_payload(seat, occupied_ids, locks_by_seat)
                    for seat in seats
                ],
            }
        )


class BookingDetailView(
    OrganizationSchedulingMixin, generics.RetrieveAPIView
):
    serializer_class = BookingSerializer
    lookup_url_kwarg = "booking_id"
    view_permission = "booking.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Booking.objects.filter(organization=organization).prefetch_related(
            "passenger_items__passenger",
            "passenger_items__seat_reservation",
        )


class BookingActionView(OrganizationSchedulingMixin, APIView):
    manage_permission = "booking.manage"
    action = None

    @extend_schema(
        request=BookingActionSerializer,
        responses=BookingSerializer,
    )
    def post(self, request, organization_id, booking_id, version=None):
        organization, _ = self.organization_and_membership()
        booking = get_object_or_404(
            Booking, pk=booking_id, organization=organization
        )
        serializer = BookingActionSerializer(
            data=request.data,
            context={
                "booking": booking,
                "action": self.action,
                "request": request,
            },
        )
        serializer.is_valid(raise_exception=True)
        booking = serializer.save()
        return Response(
            BookingSerializer(
                booking,
                context={"organization": organization, "request": request},
            ).data
        )


class BookingConfirmView(BookingActionView):
    action = "confirm"


class BookingCancelView(BookingActionView):
    action = "cancel"


class CorporateCustomerListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = CorporateCustomerSerializer
    view_permission = "corporate.view"
    manage_permission = "corporate.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CorporateCustomer.objects.filter(
            organization=organization
        ).prefetch_related("members")

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        serializer.save(organization=organization)


class CorporateMemberCreateView(
    OrganizationSchedulingMixin, generics.CreateAPIView
):
    serializer_class = CorporateCustomerMemberSerializer
    manage_permission = "corporate.manage"

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        customer = get_object_or_404(
            CorporateCustomer,
            pk=self.kwargs["customer_id"],
            organization=organization,
        )
        serializer.save(corporate_customer=customer)


class MyCorporateCustomerListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = CorporateCustomerMemberSerializer

    def get_queryset(self):
        return CorporateCustomerMember.objects.filter(
            user=self.request.user,
            status=CorporateCustomerMember.Status.ACTIVE,
        ).select_related("corporate_customer")


class SelfCorporateBookingSubmitView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=CorporateSubmitSerializer,
        responses={201: CorporateApprovalSerializer},
        operation_id="passenger_corporate_booking_submit",
    )
    def post(self, request, booking_id, version=None):
        booking = get_object_or_404(
            Booking, pk=booking_id, customer_account=request.user
        )
        customer = get_object_or_404(
            CorporateCustomer, pk=request.data.get("corporate_customer")
        )
        quote = get_object_or_404(
            FareQuote, pk=request.data.get("fare_quote"), booking=booking
        )
        try:
            approval = submit_corporate_booking(
                booking=booking,
                corporate_customer=customer,
                fare_quote=quote,
                actor=request.user,
            )
        except Exception as exc:
            from django.core.exceptions import ValidationError
            from rest_framework.exceptions import ValidationError as DRFValidationError

            if isinstance(exc, ValidationError):
                raise DRFValidationError(exc.messages) from exc
            raise
        return Response(CorporateApprovalSerializer(approval).data, status=201)


class MyCorporateApprovalListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = CorporateApprovalSerializer

    def get_queryset(self):
        customer_ids = CorporateCustomerMember.objects.filter(
            user=self.request.user,
            status=CorporateCustomerMember.Status.ACTIVE,
            can_approve=True,
        ).values_list("corporate_customer_id", flat=True)
        return CorporateBookingApproval.objects.filter(
            corporate_customer_id__in=customer_ids,
            status=CorporateBookingApproval.Status.SUBMITTED,
        ).select_related("booking", "fare_quote")


class SelfCorporateDecisionView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=CorporateDecisionSerializer,
        responses=CorporateApprovalSerializer,
        operation_id="passenger_corporate_approval_decision",
    )
    def post(self, request, approval_id, version=None):
        approval = get_object_or_404(CorporateBookingApproval, pk=approval_id)
        serializer = CorporateDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            approval = decide_corporate_booking(
                approval=approval, actor=request.user, **serializer.validated_data
            )
        except Exception as exc:
            from django.core.exceptions import ValidationError
            from rest_framework.exceptions import ValidationError as DRFValidationError

            if isinstance(exc, ValidationError):
                raise DRFValidationError(exc.messages) from exc
            raise
        return Response(CorporateApprovalSerializer(approval).data)


class CorporateInvoiceListView(
    OrganizationSchedulingMixin, generics.ListAPIView
):
    serializer_class = CorporateInvoiceSerializer
    view_permission = "invoice.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CorporateInvoice.objects.filter(organization=organization)


class CorporateInvoiceIssueView(OrganizationSchedulingMixin, APIView):
    manage_permission = "invoice.issue"

    @extend_schema(
        request=CorporateInvoiceIssueSerializer,
        responses={201: CorporateInvoiceSerializer},
        operation_id="corporate_invoice_issue",
    )
    def post(self, request, organization_id, approval_id, version=None):
        organization, _ = self.organization_and_membership()
        approval = get_object_or_404(
            CorporateBookingApproval,
            pk=approval_id,
            booking__organization=organization,
        )
        serializer = CorporateInvoiceIssueSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        invoice = issue_corporate_invoice(
            approval=approval,
            actor=request.user,
            **serializer.validated_data,
        )
        return Response(CorporateInvoiceSerializer(invoice).data, status=201)


class CorporateInvoiceVoidView(OrganizationSchedulingMixin, APIView):
    manage_permission = "invoice.void"

    @extend_schema(
        request=ReasonSerializer,
        responses=CorporateInvoiceSerializer,
        operation_id="corporate_invoice_void",
    )
    def post(self, request, organization_id, invoice_id, version=None):
        organization, _ = self.organization_and_membership()
        invoice = get_object_or_404(
            CorporateInvoice, pk=invoice_id, organization=organization
        )
        serializer = ReasonSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        invoice = void_corporate_invoice(
            invoice=invoice,
            actor=request.user,
            reason=serializer.validated_data["reason"],
        )
        return Response(CorporateInvoiceSerializer(invoice).data)