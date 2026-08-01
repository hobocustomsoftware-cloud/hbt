from rest_framework import serializers

from .models import Membership, MembershipRole, Organization, Permission, Role
from .services import create_custom_role


class OrganizationSerializer(serializers.ModelSerializer):
    tenant_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = Organization
        fields = (
            "id",
            "tenant_id",
            "legal_name",
            "display_name",
            "registration_number",
            "contact_phone",
            "contact_email",
            "status",
        )


class OrganizationContextSerializer(serializers.Serializer):
    organization = OrganizationSerializer(read_only=True)
    permissions = serializers.ListField(
        child=serializers.CharField(),
        read_only=True,
    )


class MembershipSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(
        source="user.phone_number",
        read_only=True,
    )

    class Meta:
        model = Membership
        fields = ("id", "user_id", "phone_number", "status", "joined_at")


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ("id", "code", "name", "description")


class RoleSerializer(serializers.ModelSerializer):
    permissions = PermissionSerializer(many=True, read_only=True)

    class Meta:
        model = Role
        fields = (
            "id",
            "tenant_id",
            "code",
            "name",
            "description",
            "is_system",
            "permissions",
        )


class RoleCreateSerializer(serializers.Serializer):
    code = serializers.SlugField(max_length=100)
    name = serializers.CharField(max_length=150)
    description = serializers.CharField(required=False, allow_blank=True)
    permission_codes = serializers.ListField(
        child=serializers.CharField(max_length=150),
        allow_empty=False,
    )

    def validate_code(self, code):
        tenant = self.context["actor_membership"].organization.tenant
        if Role.objects.filter(tenant=tenant, code=code).exists():
            raise serializers.ValidationError(
                "A custom role with this code already exists."
            )
        return code

    def validate_permission_codes(self, codes):
        unique_codes = set(codes)
        permissions = list(Permission.objects.filter(code__in=unique_codes))
        found = {permission.code for permission in permissions}
        missing = sorted(unique_codes - found)
        if missing:
            raise serializers.ValidationError(
                f"Unknown permission codes: {', '.join(missing)}"
            )
        return permissions

    def create(self, validated_data):
        return create_custom_role(
            actor_membership=self.context["actor_membership"],
            code=validated_data["code"],
            name=validated_data["name"],
            description=validated_data.get("description", ""),
            permissions=validated_data["permission_codes"],
        )

    def to_representation(self, instance):
        return RoleSerializer(instance).data


class MembershipRoleSerializer(serializers.ModelSerializer):
    membership_id = serializers.UUIDField()
    role_id = serializers.UUIDField()

    class Meta:
        model = MembershipRole
        fields = (
            "id",
            "membership_id",
            "role_id",
            "scope_type",
            "scope_id",
            "valid_from",
            "valid_until",
        )
        read_only_fields = ("id",)
