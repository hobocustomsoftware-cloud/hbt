from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from apps.network.models import RouteStop

from .models import BoardingRecord
from .services import board_passenger, validate_boarding


class BoardingRecordSerializer(serializers.ModelSerializer):
    passenger_name = serializers.CharField(
        source="passenger.full_name", read_only=True
    )
    ticket_number = serializers.CharField(
        source="ticket.ticket_number", read_only=True
    )
    seat_identifier = serializers.CharField(
        source=(
            "ticket.booking_passenger.seat_reservation."
            "seat_identifier_snapshot"
        ),
        read_only=True,
    )

    class Meta:
        model = BoardingRecord
        fields = (
            "id", "organization", "trip", "ticket", "ticket_number",
            "passenger", "passenger_name", "seat_identifier", "boarding_type",
            "method", "status", "boarding_stop", "validated_at", "boarded_at",
            "validated_by", "boarded_by", "identity_confirmed", "notes",
            "offline", "client_event_id", "latitude", "longitude",
            "created_at", "updated_at",
        )
        read_only_fields = fields


class BoardingValidationSerializer(serializers.Serializer):
    validation_code = serializers.UUIDField()
    boarding_type = serializers.ChoiceField(
        choices=BoardingRecord.Type.choices
    )
    method = serializers.ChoiceField(choices=BoardingRecord.Method.choices)
    boarding_stop = serializers.PrimaryKeyRelatedField(
        queryset=RouteStop.objects.all(), required=False, allow_null=True
    )
    identity_confirmed = serializers.BooleanField(default=False)
    notes = serializers.CharField(required=False, allow_blank=True)
    offline = serializers.BooleanField(default=False)
    client_event_id = serializers.UUIDField(required=False)
    latitude = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False
    )
    longitude = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False
    )

    def create(self, validated_data):
        try:
            return validate_boarding(
                organization=self.context["organization"],
                trip=self.context["trip"],
                actor=self.context["request"].user,
                **validated_data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class BoardPassengerSerializer(serializers.Serializer):
    notes = serializers.CharField(required=False, allow_blank=True)

    def create(self, validated_data):
        try:
            return board_passenger(
                record=self.context["record"],
                actor=self.context["request"].user,
                **validated_data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc

