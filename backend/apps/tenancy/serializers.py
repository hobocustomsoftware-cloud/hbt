import uuid

from django.db import transaction
from django.utils.text import slugify
from rest_framework import serializers

from apps.audit.services import record_audit_event
from apps.branding.models import OrganizationBranding
from apps.identity.models import User
from .models import Membership, MembershipRole, Organization, Permission, Role, Tenant
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




class CompanyOnboardingSerializer(serializers.Serializer):
    """Create a company (tenant + org + branding) with its first Owner account."""

    company_name = serializers.CharField(max_length=255)
    legal_name = serializers.CharField(max_length=255, required=False, allow_blank=True)
    public_slug = serializers.SlugField(max_length=120, required=False, allow_blank=True)
    name_my = serializers.CharField(max_length=255, required=False, allow_blank=True)
    name_en = serializers.CharField(max_length=255, required=False, allow_blank=True)
    primary_color = serializers.CharField(max_length=7, default="#1F6FEB")
    secondary_color = serializers.CharField(max_length=7, default="#FFFFFF")
    public_phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    public_email = serializers.EmailField(required=False, allow_blank=True)
    business_type = serializers.CharField(max_length=64, required=False, allow_blank=True)
    default_language = serializers.CharField(max_length=10, default="my")
    timezone = serializers.CharField(max_length=64, default="Asia/Yangon")
    currency = serializers.CharField(max_length=3, default="MMK")
    owner_phone = serializers.CharField(max_length=32)
    owner_password = serializers.CharField(write_only=True, min_length=8)
    owner_first_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    owner_last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    owner_email = serializers.EmailField(required=False, allow_blank=True)

    def validate_owner_phone(self, value):
        if User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError(
                "A user with this phone number already exists."
            )
        return value

    def validate_public_slug(self, value):
        # No hard failure here: create() auto-suffixes colliding slugs so the
        # onboarding flow never blocks on a taken company name/slug.
        return value

    @transaction.atomic
    def create(self, validated_data):
        company_name = validated_data["company_name"]
        slug_base = slugify(validated_data.get("public_slug") or company_name) or "company"
        public_slug = slug_base
        n = 1
        while OrganizationBranding.objects.filter(public_slug=public_slug).exists():
            n += 1
            public_slug = f"{slug_base}-{n}"

        tenant = Tenant.objects.create(
            name=company_name,
            slug=f"t-{uuid.uuid4().hex[:10]}",
            status=Tenant.Status.ACTIVE,
            primary_language=validated_data.get("default_language", "my"),
            timezone=validated_data.get("timezone", "Asia/Yangon"),
            currency=validated_data.get("currency", "MMK"),
        )
        organization = Organization.objects.create(
            tenant=tenant,
            legal_name=validated_data.get("legal_name") or company_name,
            display_name=company_name,
            contact_phone=validated_data.get("public_phone", ""),
            contact_email=validated_data.get("public_email", ""),
            status=Organization.Status.ACTIVE,
        )
        owner = User.objects.create_user(
            phone_number=validated_data["owner_phone"],
            password=validated_data["owner_password"],
            first_name=validated_data.get("owner_first_name", ""),
            last_name=validated_data.get("owner_last_name", ""),
            email=validated_data.get("owner_email", ""),
            preferred_language=validated_data.get("default_language", "my"),
            status=User.Status.ACTIVE,
        )
        OrganizationBranding.objects.create(
            organization=organization,
            public_slug=public_slug,
            name_my=validated_data.get("name_my") or company_name,
            name_en=validated_data.get("name_en") or company_name,
            primary_color=validated_data.get("primary_color", "#1F6FEB"),
            secondary_color=validated_data.get("secondary_color", "#FFFFFF"),
            public_phone=validated_data.get("public_phone", ""),
            public_email=validated_data.get("public_email", ""),
            is_published=True,
            updated_by=owner,
        )
        membership = Membership.objects.create(
            organization=organization,
            user=owner,
            status=Membership.Status.ACTIVE,
        )
        owner_role = Role.objects.filter(code="company-owner").first()
        if owner_role is not None:
            MembershipRole.objects.create(
                membership=membership,
                role=owner_role,
                scope_type="company",
            )
        record_audit_event(
            actor=owner,
            action="onboarding.company_created",
            resource_type="organization",
            resource_id=organization.id,
            after={
                "tenant": str(tenant.id),
                "business_type": validated_data.get("business_type", ""),
                "currency": tenant.currency,
            },
        )
        return {
            "organization_id": organization.id,
            "tenant_id": tenant.id,
            "public_slug": public_slug,
            "owner_phone": owner.phone_number,
        }
