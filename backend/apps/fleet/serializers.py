from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from .models import LayoutPosition, SeatLayout, Vehicle, VehicleLayoutAssignment


class VehicleSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = Vehicle
        fields = "__all__"
        read_only_fields = ("id", "organization", "created_at", "updated_at")

    def validate_branch(self, branch):
        if branch.organization_id != self.context["organization"].id:
            raise serializers.ValidationError(
                "Branch must belong to this organization."
            )
        return branch


class SeatLayoutSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)
    bookable_seat_count = serializers.SerializerMethodField()

    class Meta:
        model = SeatLayout
        fields = "__all__"
        read_only_fields = ("id", "organization", "created_at", "updated_at")

    @extend_schema_field(serializers.IntegerField)
    def get_bookable_seat_count(self, obj):
        return obj.positions.filter(bookable=True).count()


class LayoutPositionSerializer(serializers.ModelSerializer):
    layout_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = LayoutPosition
        fields = "__all__"
        read_only_fields = ("id", "layout", "created_at", "updated_at")

    def validate(self, attrs):
        layout = self.context["layout"]
        if layout.status not in (
            SeatLayout.Status.DRAFT,
            SeatLayout.Status.REVIEW,
        ):
            raise serializers.ValidationError(
                "Positions may only be changed on draft or review layouts."
            )
        instance = LayoutPosition(layout=layout, **attrs)
        instance.clean()
        return attrs


class VehicleLayoutAssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleLayoutAssignment
        fields = "__all__"
        read_only_fields = (
            "id",
            "vehicle",
            "assigned_by",
            "created_at",
            "updated_at",
        )

    def validate(self, attrs):
        instance = VehicleLayoutAssignment(
            vehicle=self.context["vehicle"],
            assigned_by=self.context["request"].user,
            **attrs,
        )
        instance.clean()
        return attrs
