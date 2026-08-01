from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from apps.fleet.models import LayoutPosition
from apps.passengers.models import Passenger

from .models import (
    Booking,
    BookingPassenger,
    CorporateBookingApproval,
    CorporateCustomer,
    CorporateCustomerMember,
    CorporateInvoice,
    SeatReservation,
)
from .services import cancel_booking, confirm_booking, create_booking


class PassengerSeatSerializer(serializers.Serializer):
    passenger = serializers.PrimaryKeyRelatedField(
        queryset=Passenger.objects.all()
    )
    seat_position = serializers.PrimaryKeyRelatedField(
        queryset=LayoutPosition.objects.filter(bookable=True)
    )


class SeatReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SeatReservation
        fields = (
            "id", "seat_position", "seat_identifier_snapshot", "status",
            "pickup_sequence", "dropoff_sequence",
        )


class BookingPassengerSerializer(serializers.ModelSerializer):
    passenger_name = serializers.CharField(
        source="passenger.full_name", read_only=True
    )
    seat_reservation = SeatReservationSerializer(read_only=True)

    class Meta:
        model = BookingPassenger
        fields = ("id", "passenger", "passenger_name", "seat_reservation")


class BookingSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)
    passenger_seats = PassengerSeatSerializer(
        many=True, write_only=True, required=True
    )
    passenger_items = BookingPassengerSerializer(many=True, read_only=True)

    class Meta:
        model = Booking
        fields = (
            "id", "organization_id", "trip", "booking_number", "booking_type",
            "channel", "status", "contact_name", "contact_phone", "pickup_stop",
            "dropoff_stop", "expires_at", "confirmed_at",
            "authorization_reference", "notes", "client_request_id",
            "passenger_seats", "passenger_items", "created_by", "created_at",
            "customer_account", "updated_at",
        )
        read_only_fields = (
            "id", "status", "confirmed_at", "authorization_reference",
            "customer_account",
            "created_by", "created_at", "updated_at"
        )

    def create(self, validated_data):
        passenger_seats = validated_data.pop("passenger_seats")
        try:
            return create_booking(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                passenger_seats=passenger_seats,
                **validated_data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class BookingActionSerializer(serializers.Serializer):
    authorization_reference = serializers.CharField(
        max_length=255, required=False
    )
    reason = serializers.CharField(max_length=255, required=False)

    def create(self, validated_data):
        try:
            if self.context["action"] == "confirm":
                return confirm_booking(
                    booking=self.context["booking"],
                    actor=self.context["request"].user,
                    authorization_reference=validated_data.get(
                        "authorization_reference", ""
                    ),
                )
            return cancel_booking(
                booking=self.context["booking"],
                actor=self.context["request"].user,
                reason=validated_data.get("reason", ""),
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class CorporateCustomerMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = CorporateCustomerMember
        fields = "__all__"
        read_only_fields = (
            "id", "corporate_customer", "created_at", "updated_at"
        )


class CorporateCustomerSerializer(serializers.ModelSerializer):
    members = CorporateCustomerMemberSerializer(many=True, read_only=True)

    class Meta:
        model = CorporateCustomer
        exclude = ("organization",)
        read_only_fields = ("id", "created_at", "updated_at")


class CorporateApprovalSerializer(serializers.ModelSerializer):
    booking_number = serializers.CharField(
        source="booking.booking_number", read_only=True
    )
    total_amount = serializers.DecimalField(
        source="fare_quote.total_amount",
        max_digits=14,
        decimal_places=2,
        read_only=True,
    )

    class Meta:
        model = CorporateBookingApproval
        fields = (
            "id", "booking", "booking_number", "corporate_customer",
            "fare_quote", "total_amount", "status", "requested_by",
            "submitted_at", "decided_by", "decided_at", "decision_reason",
            "created_at", "updated_at",
        )
        read_only_fields = fields


class CorporateInvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CorporateInvoice
        fields = (
            "id", "organization", "approval", "replaces", "invoice_number",
            "status", "currency", "subtotal", "discount_amount", "tax_amount",
            "total_amount", "due_at", "issued_at", "issued_by", "voided_at",
            "voided_by", "void_reason", "snapshot", "created_at", "updated_at",
        )
        read_only_fields = fields


class CorporateDecisionSerializer(serializers.Serializer):
    approve = serializers.BooleanField()
    reason = serializers.CharField(required=False, allow_blank=True)


class CorporateInvoiceIssueSerializer(serializers.Serializer):
    invoice_number = serializers.CharField(max_length=64)
    replaces = serializers.PrimaryKeyRelatedField(
        queryset=CorporateInvoice.objects.all(), required=False
    )


class ReasonSerializer(serializers.Serializer):
    reason = serializers.CharField()


class CorporateSubmitSerializer(serializers.Serializer):
    corporate_customer = serializers.UUIDField()
    fare_quote = serializers.UUIDField()
