from django.urls import path

from .views import (
    CompanyOnboardingView,
    MembershipRoleAssignView,
    MyOrganizationContextView,
    MyOrganizationListView,
    OrganizationDetailView,
    OrganizationMembershipListView,
    PermissionListView,
    RoleListCreateView,
)

app_name = "tenancy"

urlpatterns = [
    path("onboarding/company/", CompanyOnboardingView.as_view(), name="onboarding-company"),
    path("me/organizations/", MyOrganizationListView.as_view(), name="my-orgs"),
    path(
        "me/organizations/<uuid:organization_id>/context/",
        MyOrganizationContextView.as_view(),
        name="my-organization-context",
    ),
    path(
        "organizations/<uuid:organization_id>/",
        OrganizationDetailView.as_view(),
        name="organization-detail",
    ),
    path(
        "organizations/<uuid:organization_id>/memberships/",
        OrganizationMembershipListView.as_view(),
        name="membership-list",
    ),
    path(
        "organizations/<uuid:organization_id>/permissions/",
        PermissionListView.as_view(),
        name="permission-list",
    ),
    path(
        "organizations/<uuid:organization_id>/roles/",
        RoleListCreateView.as_view(),
        name="role-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/role-assignments/",
        MembershipRoleAssignView.as_view(),
        name="role-assign",
    ),
]
