from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from .models import Passenger


class PassengerSerializer(serializers.ModelSerializer):
    national_id = serializers.CharField(
        write_only=True, required=False, allow_blank=True, max_length=100
    )
    organization_id = serializers.UUIDField(read_only=True)
    masked_nrc = serializers.CharField(read_only=True)
    masked_nrc_en = serializers.CharField(read_only=True)

    class Meta:
        model = Passenger
        fields = (
            "id", "organization_id", "account", "managed_by", "passenger_code", "full_name",
            "full_name_myanmar", "category", "gender", "date_of_birth",
            "phone_number", "national_id", "masked_nrc", "masked_nrc_en",
            "nrc_verification_status", "passport_number",
            "emergency_contact_name", "emergency_contact_phone", "travel_notes",
            "special_assistance", "status", "created_at", "updated_at",
        )
        read_only_fields = (
            "id", "managed_by", "nrc_verification_status",
            "created_at", "updated_at",
        )
        extra_kwargs = {"national_id": {"write_only": True}}

    def validate(self, attrs):
        if self.instance and self.instance.status == Passenger.Status.ARCHIVED:
            raise serializers.ValidationError("Archived passengers are read-only.")
        instance = self.instance or Passenger(
            organization=self.context["organization"]
        )
        for key, value in attrs.items():
            setattr(instance, key, value)
        if "national_id" in attrs:
            try:
                instance.set_nrc(attrs["national_id"])
            except ValueError as exc:
                raise serializers.ValidationError(
                    {"national_id": str(exc)}
                ) from exc
            organization = getattr(instance, "organization", None)
            if organization is not None:
                duplicate = Passenger.objects.filter(
                    organization=organization,
                    nrc_blind_index=instance.nrc_blind_index,
                )
                if self.instance:
                    duplicate = duplicate.exclude(pk=self.instance.pk)
                if duplicate.exists():
                    raise serializers.ValidationError(
                        {"national_id": "This NRC already exists for the operator."}
                    )
        try:
            instance.clean()
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.message_dict) from exc
        if "national_id" in attrs:
            attrs.update(
                {
                    "nrc_state_region": instance.nrc_state_region,
                    "nrc_township": instance.nrc_township,
                    "nrc_citizenship_type": instance.nrc_citizenship_type,
                    "nrc_serial": instance.nrc_serial,
                    "encrypted_nrc": instance.encrypted_nrc,
                    "nrc_blind_index": instance.nrc_blind_index,
                    "nrc_verification_status": instance.nrc_verification_status,
                    "nrc_review_reason": instance.nrc_review_reason,
                }
            )
            attrs.pop("national_id", None)
        return attrs
