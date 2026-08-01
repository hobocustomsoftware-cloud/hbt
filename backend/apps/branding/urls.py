from django.urls import path

from .views import (
    OrganizationBrandingView,
    PublicOperatorDetailView,
    PublicOperatorListView,
)

urlpatterns = [
    path("public/operators/", PublicOperatorListView.as_view()),
    path(
        "public/operators/<slug:public_slug>/",
        PublicOperatorDetailView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/branding/",
        OrganizationBrandingView.as_view(),
    ),
]

