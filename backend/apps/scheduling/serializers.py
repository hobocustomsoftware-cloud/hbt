from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import models
from rest_framework import serializers

from apps.fleet.models import Vehicle
from apps.network.models import Route
from apps.workforce.models import ConductorProfile, DriverProfile

from .models import (
    Schedule,
    Trip,
    TripAssignmentEvent,
    TripOperationalEvent,
)
from .services import (
    assign_conductor,
    assign_driver,
    assign_vehicle,
    generate_trip,
    record_stop_reached,
    transition_trip,
)


class ScheduleSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = Schedule
        fields = (
            "id",
            "organization_id",
            "route",
            "code",
            "name",
            "planned_departure_time",
            "planned_arrival_time",
            "arrival_day_offset",
            "operating_days",
            "effective_from",
            "expires_on",
            "operates_on_public_holidays",
            "status",
            "version",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "version", "created_at", "updated_at")

    def validate_route(self, route):
        organization = self.context["organization"]
        if route.organization_id != organization.id:
            raise serializers.ValidationError(
                "Route must belong to this organization."
            )
        return route

    def validate(self, attrs):
        if self.instance is None:
            from apps.subscriptions.services import require_entitlement

            organization = self.context["organization"]
            subscription = getattr(organization.tenant, "subscription", None)
            if subscription is not None:
                require_entitlement(subscription, "ticketing")
        if self.instance is None and attrs.get(
            "status", Schedule.Status.DRAFT
        ) != Schedule.Status.DRAFT:
            raise serializers.ValidationError(
                {"status": "New schedules must begin in draft status."}
            )
        instance = self.instance or Schedule(
            organization=self.context["organization"]
        )
        for name, value in attrs.items():
            setattr(instance, name, value)
        try:
            instance.clean()
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.message_dict) from exc
        if self.instance and self.instance.status == Schedule.Status.ARCHIVED:
            raise serializers.ValidationError("Archived schedules are read-only.")
        if self.instance and attrs.get("code", self.instance.code) != self.instance.code:
            raise serializers.ValidationError({"code": "Schedule code is immutable."})
        if self.instance and "status" in attrs:
            transitions = {
                Schedule.Status.DRAFT: {Schedule.Status.REVIEW},
                Schedule.Status.REVIEW: {
                    Schedule.Status.DRAFT,
                    Schedule.Status.APPROVED,
                },
                Schedule.Status.APPROVED: {
                    Schedule.Status.OPERATIONAL,
                    Schedule.Status.ARCHIVED,
                },
                Schedule.Status.OPERATIONAL: {
                    Schedule.Status.SUSPENDED,
                    Schedule.Status.EXPIRED,
                },
                Schedule.Status.SUSPENDED: {
                    Schedule.Status.OPERATIONAL,
                    Schedule.Status.EXPIRED,
                },
                Schedule.Status.EXPIRED: {Schedule.Status.ARCHIVED},
                Schedule.Status.ARCHIVED: set(),
            }
            old_status = self.instance.status
            new_status = attrs["status"]
            if new_status != old_status and new_status not in transitions[old_status]:
                raise serializers.ValidationError(
                    {"status": f"Invalid transition from {old_status} to {new_status}."}
                )
        route = attrs.get("route", getattr(self.instance, "route", None))
        if route and route.status not in (Route.Status.APPROVED, Route.Status.ACTIVE):
            raise serializers.ValidationError(
                {"route": "Schedules require an approved or active route."}
            )
        departure = attrs.get(
            "planned_departure_time",
            getattr(self.instance, "planned_departure_time", None),
        )
        effective_from = attrs.get(
            "effective_from", getattr(self.instance, "effective_from", None)
        )
        expires_on = attrs.get(
            "expires_on", getattr(self.instance, "expires_on", None)
        )
        if route and departure and effective_from:
            duplicates = Schedule.objects.filter(
                organization=self.context["organization"],
                route=route,
                planned_departure_time=departure,
            ).filter(
                models.Q(expires_on__isnull=True)
                | models.Q(expires_on__gte=effective_from)
            )
            if expires_on:
                duplicates = duplicates.filter(effective_from__lte=expires_on)
            if self.instance:
                duplicates = duplicates.exclude(pk=self.instance.pk)
            if duplicates.exists():
                raise serializers.ValidationError(
                    "An overlapping schedule already uses this route and departure time."
                )
        return attrs


class TripSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)
    resources_complete = serializers.BooleanField(read_only=True)

    class Meta:
        model = Trip
        fields = (
            "id",
            "organization_id",
            "schedule",
            "route",
            "trip_number",
            "service_date",
            "planned_departure_at",
            "planned_arrival_at",
            "status",
            "operational_notes",
            "boarding_started_at",
            "departed_at",
            "arrived_at",
            "current_stop",
            "schedule_snapshot",
            "route_snapshot",
            "vehicle",
            "driver",
            "conductor",
            "seat_layout",
            "seat_layout_snapshot",
            "resources_complete",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "status",
            "boarding_started_at",
            "departed_at",
            "arrived_at",
            "current_stop",
            "schedule_snapshot",
            "route_snapshot",
            "vehicle",
            "driver",
            "conductor",
            "seat_layout",
            "seat_layout_snapshot",
            "created_at",
            "updated_at",
        )

    def validate(self, attrs):
        organization = self.context["organization"]
        route = attrs.get("route", getattr(self.instance, "route", None))
        schedule = attrs.get("schedule", getattr(self.instance, "schedule", None))
        if route and route.organization_id != organization.id:
            raise serializers.ValidationError(
                {"route": "Route must belong to this organization."}
            )
        if route and route.status not in (Route.Status.APPROVED, Route.Status.ACTIVE):
            raise serializers.ValidationError(
                {"route": "Trips require an approved or active route."}
            )
        if schedule and schedule.organization_id != organization.id:
            raise serializers.ValidationError(
                {"schedule": "Schedule must belong to this organization."}
            )
        instance = self.instance or Trip(organization=organization)
        for name, value in attrs.items():
            setattr(instance, name, value)
        try:
            instance.clean()
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.message_dict) from exc
        if self.instance and self.instance.immutable:
            raise serializers.ValidationError("Completed trips are immutable.")
        return attrs

    def create(self, validated_data):
        route = validated_data["route"]
        validated_data["route_snapshot"] = {
            "id": str(route.id),
            "code": route.code,
            "name": route.name,
            "stops": [
                {
                    "id": str(stop.id),
                    "code": stop.code,
                    "name": stop.name,
                    "sequence": stop.sequence,
                }
                for stop in route.stops.order_by("sequence")
            ],
        }
        schedule = validated_data.get("schedule")
        if schedule:
            validated_data["schedule_snapshot"] = {
                "id": str(schedule.id),
                "code": schedule.code,
                "name": schedule.name,
                "version": schedule.version,
                "operating_days": schedule.operating_days,
            }
        return super().create(validated_data)


class GenerateTripSerializer(serializers.Serializer):
    service_date = serializers.DateField()
    trip_number = serializers.CharField(max_length=50)

    def create(self, validated_data):
        try:
            return generate_trip(
                schedule=self.context["schedule"], **validated_data
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class AssignmentSerializer(serializers.Serializer):
    resource_id = serializers.UUIDField()
    reason = serializers.CharField(max_length=255, required=False, allow_blank=True)

    model = None
    service = None
    keyword = None

    def validate_resource_id(self, value):
        try:
            self.resource = self.model.objects.select_related(
                *self.select_related
            ).get(pk=value)
        except self.model.DoesNotExist as exc:
            raise serializers.ValidationError("Resource not found.") from exc
        return value

    def create(self, validated_data):
        kwargs = {
            "trip": self.context["trip"],
            self.keyword: self.resource,
            "actor": self.context["request"].user,
            "reason": validated_data.get("reason", ""),
        }
        try:
            return self.service(**kwargs)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class VehicleAssignmentSerializer(AssignmentSerializer):
    model = Vehicle
    service = staticmethod(assign_vehicle)
    keyword = "vehicle"
    select_related = ("organization",)


class DriverAssignmentSerializer(AssignmentSerializer):
    model = DriverProfile
    service = staticmethod(assign_driver)
    keyword = "driver"
    select_related = ("staff__membership__organization",)


class ConductorAssignmentSerializer(AssignmentSerializer):
    model = ConductorProfile
    service = staticmethod(assign_conductor)
    keyword = "conductor"
    select_related = ("staff__membership__organization",)


class TripAssignmentEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripAssignmentEvent
        fields = (
            "id",
            "resource_type",
            "previous_resource_id",
            "resource_id",
            "assigned_by",
            "reason",
            "created_at",
        )


class TripOperationSerializer(serializers.Serializer):
    occurred_at = serializers.DateTimeField(required=False)
    notes = serializers.CharField(required=False, allow_blank=True)
    offline = serializers.BooleanField(required=False, default=False)
    client_event_id = serializers.UUIDField(required=False)
    latitude = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False
    )
    longitude = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False
    )

    def create(self, validated_data):
        try:
            trip, event = transition_trip(
                trip=self.context["trip"],
                event_type=self.context["event_type"],
                actor=self.context["request"].user,
                **validated_data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc
        self.event = event
        return trip


class StopReachedSerializer(TripOperationSerializer):
    def create(self, validated_data):
        try:
            trip, event = record_stop_reached(
                trip=self.context["trip"],
                route_stop=self.context["route_stop"],
                actor=self.context["request"].user,
                **validated_data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc
        self.event = event
        return trip


class TripOperationalEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripOperationalEvent
        fields = (
            "id",
            "event_type",
            "from_status",
            "to_status",
            "route_stop",
            "occurred_at",
            "recorded_by",
            "notes",
            "offline",
            "client_event_id",
            "latitude",
            "longitude",
            "created_at",
        )


class TripOperationResponseSerializer(serializers.Serializer):
    trip = TripSerializer()
    event = TripOperationalEventSerializer()
