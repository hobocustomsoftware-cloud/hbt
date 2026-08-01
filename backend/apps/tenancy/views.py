from django.db.models import Q
from rest_framework import generics, status
from rest_framework.exceptions import NotFound
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from .models import Membership, Organization, Permission, Role
from .serializers import (
    CompanyOnboardingSerializer,
    MembershipRoleSerializer,
    MembershipSerializer,
    OrganizationContextSerializer,
    OrganizationSerializer,
    PermissionSerializer,
    RoleCreateSerializer,
    RoleSerializer,
)
from .services import (
    active_membership_for,
    assign_role,
    effective_permission_codes,
    require_permission,
)


def organization_for_user(user, organization_id):
    try:
        return Organization.objects.select_related("tenant").get(
            id=organization_id,
            memberships__user=user,
            memberships__status=Membership.Status.ACTIVE,
        )
    except Organization.DoesNotExist as exc:
        raise NotFound("Organization not found.") from exc


class MyOrganizationListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrganizationSerializer

    def get_queryset(self):
        return Organization.objects.filter(
            memberships__user=self.request.user,
            memberships__status=Membership.Status.ACTIVE,
        ).select_related("tenant").distinct()


class MyOrganizationContextView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(responses={200: OrganizationContextSerializer})
    def get(self, request, organization_id, version=None):
        organization = organization_for_user(request.user, organization_id)
        membership = active_membership_for(request.user, organization)
        return Response(
            {
                "organization": OrganizationSerializer(organization).data,
                "permissions": sorted(effective_permission_codes(membership)),
            }
        )


class OrganizationDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrganizationSerializer
    lookup_url_kwarg = "organization_id"

    def get_queryset(self):
        return Organization.objects.filter(
            memberships__user=self.request.user,
            memberships__status=Membership.Status.ACTIVE,
        ).select_related("tenant")


class OrganizationMembershipListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = MembershipSerializer

    def get_queryset(self):
        organization = organization_for_user(
            self.request.user,
            self.kwargs["organization_id"],
        )
        actor_membership = active_membership_for(
            self.request.user,
            organization,
        )
        require_permission(actor_membership, "access.membership.view")
        return Membership.objects.filter(
            organization=organization
        ).select_related("user")


class PermissionListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PermissionSerializer

    def get_queryset(self):
        organization = organization_for_user(
            self.request.user,
            self.kwargs["organization_id"],
        )
        actor_membership = active_membership_for(
            self.request.user,
            organization,
        )
        require_permission(actor_membership, "access.role.view")
        return Permission.objects.all()


class RoleListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]

    def get_organization_and_membership(self):
        organization = organization_for_user(
            self.request.user,
            self.kwargs["organization_id"],
        )
        return organization, active_membership_for(
            self.request.user,
            organization,
        )

    def get_queryset(self):
        organization, membership = self.get_organization_and_membership()
        require_permission(membership, "access.role.view")
        return Role.objects.filter(
            Q(tenant__isnull=True) | Q(tenant=organization.tenant)
        ).prefetch_related("permissions")

    def get_serializer_class(self):
        if self.request.method == "POST":
            return RoleCreateSerializer
        return RoleSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        if self.request.method == "POST":
            _, membership = self.get_organization_and_membership()
            context["actor_membership"] = membership
        return context


class MembershipRoleAssignView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=MembershipRoleSerializer,
        responses={201: MembershipRoleSerializer},
    )
    def post(self, request, organization_id, version=None):
        organization = organization_for_user(request.user, organization_id)
        actor_membership = active_membership_for(request.user, organization)
        serializer = MembershipRoleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            target_membership = Membership.objects.get(
                id=data["membership_id"],
                organization=organization,
            )
            role = Role.objects.get(
                Q(tenant__isnull=True) | Q(tenant=organization.tenant),
                id=data["role_id"],
            )
        except (Membership.DoesNotExist, Role.DoesNotExist) as exc:
            raise NotFound("Membership or role not found.") from exc

        assignment = assign_role(
            actor_membership=actor_membership,
            target_membership=target_membership,
            role=role,
            scope_type=data["scope_type"],
            scope_id=data.get("scope_id"),
        )
        return Response(
            MembershipRoleSerializer(assignment).data,
            status=status.HTTP_201_CREATED,
        )

class CompanyOnboardingView(APIView):
    """Create a company (tenant + org + branding) with its first Owner account.

    AllowAny: this is the first-run flow before any account exists.
    """

    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = CompanyOnboardingSerializer

    @extend_schema(
        request=CompanyOnboardingSerializer,
        responses={201: CompanyOnboardingSerializer},
        operation_id="onboarding_company_create",
    )
    def post(self, request, version=None):
        serializer = CompanyOnboardingSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = serializer.save()
        return Response(result, status=status.HTTP_201_CREATED)
