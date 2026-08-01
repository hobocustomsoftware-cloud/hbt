from rest_framework import serializers

from .models import ConductorProfile, DriverProfile, StaffProfile


class StaffProfileSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = StaffProfile
        fields = "__all__"
        read_only_fields = ("id", "created_at", "updated_at")

    def validate(self, attrs):
        organization = self.context["organization"]
        membership = attrs.get(
            "membership", getattr(self.instance, "membership", None)
        )
        branch = attrs.get("branch", getattr(self.instance, "branch", None))
        if membership and membership.organization_id != organization.id:
            raise serializers.ValidationError(
                {"membership": "Membership belongs to another organization."}
            )
        if branch and branch.organization_id != organization.id:
            raise serializers.ValidationError(
                {"branch": "Branch belongs to another organization."}
            )
        return attrs


class DriverProfileSerializer(serializers.ModelSerializer):
    operationally_eligible = serializers.BooleanField(read_only=True)

    class Meta:
        model = DriverProfile
        fields = "__all__"
        read_only_fields = ("id", "created_at", "updated_at")


class ConductorProfileSerializer(serializers.ModelSerializer):
    operationally_eligible = serializers.BooleanField(read_only=True)

    class Meta:
        model = ConductorProfile
        fields = "__all__"
        read_only_fields = ("id", "created_at", "updated_at")
