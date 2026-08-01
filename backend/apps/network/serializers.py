from rest_framework import serializers

from .models import Route, RouteSegment, RouteStop


class RouteSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)
    stop_count = serializers.IntegerField(source="stops.count", read_only=True)

    class Meta:
        model = Route
        fields = (
            "id",
            "organization_id",
            "code",
            "name",
            "status",
            "estimated_distance_km",
            "estimated_duration_minutes",
            "operating_region",
            "stop_count",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate(self, attrs):
        if self.instance:
            if self.instance.status == Route.Status.ARCHIVED:
                raise serializers.ValidationError(
                    "Archived routes are read-only."
                )
            if attrs.get("code", self.instance.code) != self.instance.code:
                raise serializers.ValidationError(
                    {"code": "Route code is immutable."}
                )
        return attrs


class RouteStopSerializer(serializers.ModelSerializer):
    route_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = RouteStop
        fields = (
            "id",
            "route_id",
            "terminal",
            "code",
            "name",
            "sequence",
            "stop_type",
            "status",
            "boarding_allowed",
            "dropoff_allowed",
            "cargo_allowed",
            "rest_stop",
            "meal_stop",
            "fuel_stop",
            "driver_change_allowed",
            "region",
            "township",
            "city",
            "address_line",
            "latitude",
            "longitude",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate(self, attrs):
        if self.instance:
            if self.instance.status == RouteStop.Status.ARCHIVED:
                raise serializers.ValidationError(
                    "Archived stops are read-only."
                )
            if attrs.get("code", self.instance.code) != self.instance.code:
                raise serializers.ValidationError(
                    {"code": "Stop code is immutable."}
                )
        stop_type = attrs.get(
            "stop_type",
            getattr(self.instance, "stop_type", None),
        )
        terminal = attrs.get("terminal", getattr(self.instance, "terminal", None))
        if stop_type == RouteStop.Type.TERMINAL and terminal is None:
            raise serializers.ValidationError(
                {"terminal": "A terminal stop requires a physical terminal."}
            )
        if terminal is not None and stop_type != RouteStop.Type.TERMINAL:
            raise serializers.ValidationError(
                {"stop_type": "Select terminal type for a physical terminal."}
            )
        return attrs


class RouteSegmentSerializer(serializers.ModelSerializer):
    route_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = RouteSegment
        fields = (
            "id",
            "route_id",
            "from_stop",
            "to_stop",
            "sequence",
            "distance_km",
            "estimated_duration_minutes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate(self, attrs):
        route = self.context["route"]
        from_stop = attrs.get(
            "from_stop",
            getattr(self.instance, "from_stop", None),
        )
        to_stop = attrs.get("to_stop", getattr(self.instance, "to_stop", None))
        if (
            from_stop is None
            or to_stop is None
            or from_stop.route_id != route.id
            or to_stop.route_id != route.id
        ):
            raise serializers.ValidationError(
                "Both stops must belong to this route."
            )
        if to_stop.sequence <= from_stop.sequence:
            raise serializers.ValidationError(
                "A segment must move forward through the stop sequence."
            )
        return attrs
