from rest_framework import serializers

from .models import (
    Branch,
    CompanyTerminalOperation,
    PhysicalTerminal,
    SalesCounter,
)


ADDRESS_FIELDS = (
    "country_code",
    "region",
    "township",
    "city",
    "address_line",
    "latitude",
    "longitude",
)


class BranchSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = Branch
        fields = (
            "id",
            "organization_id",
            "code",
            "name",
            "status",
            "contact_phone",
            "contact_email",
            "operating_hours",
            *ADDRESS_FIELDS,
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class PhysicalTerminalSerializer(serializers.ModelSerializer):
    class Meta:
        model = PhysicalTerminal
        fields = (
            "id",
            "code",
            "name",
            "name_myanmar",
            "status",
            "contact_phone",
            *ADDRESS_FIELDS,
        )


class TerminalOperationSerializer(serializers.ModelSerializer):
    organization_id = serializers.UUIDField(read_only=True)
    terminal_detail = PhysicalTerminalSerializer(
        source="terminal",
        read_only=True,
    )

    class Meta:
        model = CompanyTerminalOperation
        fields = (
            "id",
            "organization_id",
            "branch",
            "terminal",
            "terminal_detail",
            "code",
            "display_name",
            "status",
            "operating_hours",
            "local_contact_phone",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate(self, attrs):
        organization = self.context["organization"]
        branch = attrs.get("branch", getattr(self.instance, "branch", None))
        if branch and branch.organization_id != organization.id:
            raise serializers.ValidationError(
                {"branch": "Branch must belong to this organization."}
            )
        return attrs


class SalesCounterSerializer(serializers.ModelSerializer):
    terminal_operation_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = SalesCounter
        fields = (
            "id",
            "terminal_operation_id",
            "code",
            "name",
            "status",
            "contact_phone",
            "operating_hours",
            "supports_printing",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")
