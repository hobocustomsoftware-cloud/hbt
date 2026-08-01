from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from apps.bookings.models import BookingPassenger

from .models import Ticket
from .services import issue_ticket, reissue_ticket


class TicketSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)
    passenger_name = serializers.CharField(
        source="passenger.full_name", read_only=True
    )
    trip_number = serializers.CharField(
        source="trip.trip_number", read_only=True
    )
    planned_departure_at = serializers.DateTimeField(
        source="trip.planned_departure_at", read_only=True
    )
    seat_identifier = serializers.CharField(
        source="booking_passenger.seat_reservation.seat_identifier_snapshot",
        read_only=True,
    )
    qr_payload = serializers.SerializerMethodField()

    class Meta:
        model = Ticket
        fields = (
            "id", "organization_id", "booking", "booking_passenger",
            "passenger", "passenger_name", "trip", "trip_number",
            "planned_departure_at", "seat_position", "seat_identifier",
            "ticket_number", "ticket_type", "status", "validation_code",
            "qr_payload", "fare_amount", "discount_amount", "tax_amount",
            "service_charge", "total_amount", "currency", "issuing_channel",
            "issued_by", "issued_at", "created_at", "updated_at",
            "replacement_of", "revoked_at", "revoked_by", "revocation_reason",
        )
        read_only_fields = fields

    @extend_schema_field(serializers.CharField)
    def get_qr_payload(self, obj):
        return f"HBT:TICKET:{obj.validation_code}"


class TicketIssueSerializer(serializers.Serializer):
    booking_passenger = serializers.PrimaryKeyRelatedField(
        queryset=BookingPassenger.objects.all()
    )
    ticket_number = serializers.CharField(max_length=64)
    ticket_type = serializers.ChoiceField(
        choices=Ticket.Type.choices, default=Ticket.Type.ELECTRONIC
    )
    fare_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    discount_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    tax_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    service_charge = serializers.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField(max_length=3, default="MMK")
    issuing_channel = serializers.CharField(max_length=16)

    def create(self, validated_data):
        booking_passenger = validated_data.pop("booking_passenger")
        if (
            booking_passenger.booking.organization_id
            != self.context["organization"].id
        ):
            raise serializers.ValidationError("Booking passenger not found.")
        try:
            return issue_ticket(
                booking_passenger=booking_passenger,
                actor=self.context["request"].user,
                **validated_data,
            )
        except DjangoValidationError as exc:
            if hasattr(exc, "message_dict"):
                raise serializers.ValidationError(exc.message_dict) from exc
            raise serializers.ValidationError(exc.messages) from exc


class TicketReissueSerializer(serializers.Serializer):
    ticket_number = serializers.CharField(max_length=64)
    reason = serializers.CharField()

    def create(self, validated_data):
        try:
            return reissue_ticket(
                ticket=self.context["ticket"],
                actor=self.context["request"].user,
                **validated_data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc
