from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from .models import NRCCitizenshipType, NRCStateRegion, NRCTownship
from .nrc import display_english_code
from .nrc import mask_rendered_nrc, parse_nrc


class NRCStateRegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = NRCStateRegion
        fields = (
            "id", "code", "number_mm", "name_en", "name_mm",
            "source_version",
        )


class NRCTownshipSerializer(serializers.ModelSerializer):
    state_code = serializers.IntegerField(
        source="state_region.code", read_only=True
    )
    code_en_display = serializers.SerializerMethodField()

    class Meta:
        model = NRCTownship
        fields = (
            "id", "state_code", "code_en", "code_en_display", "code_mm",
            "name_en", "name_mm", "verification_status", "source_version",
        )

    @extend_schema_field(serializers.CharField)
    def get_code_en_display(self, obj):
        return display_english_code(obj.code_en)


class NRCCitizenshipTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = NRCCitizenshipType
        fields = (
            "id", "code_en", "code_mm", "name_en", "name_mm",
            "verification_status", "source_version",
        )


class NRCValidateSerializer(serializers.Serializer):
    nrc = serializers.CharField(max_length=100, write_only=True)
    canonical_en = serializers.CharField(read_only=True)
    display_en = serializers.CharField(read_only=True)
    display_mm = serializers.CharField(read_only=True)
    masked_en = serializers.CharField(read_only=True)
    masked_mm = serializers.CharField(read_only=True)
    state_region = NRCStateRegionSerializer(read_only=True)
    township = NRCTownshipSerializer(read_only=True)
    citizenship_type = NRCCitizenshipTypeSerializer(read_only=True)

    def validate(self, data):
        try:
            parsed = parse_nrc(data["nrc"])
        except ValueError as exc:
            raise serializers.ValidationError({"nrc": str(exc)}) from exc
        return {
            "canonical_en": parsed.canonical_en,
            "display_en": parsed.display_en,
            "display_mm": parsed.display_mm,
            "masked_en": mask_rendered_nrc(parsed, "en"),
            "masked_mm": mask_rendered_nrc(parsed, "mm"),
            "state_region": parsed.state_region,
            "township": parsed.township,
            "citizenship_type": parsed.citizenship_type,
        }
