from django.urls import path

from .views import (
    ConductorListCreateView,
    DriverListCreateView,
    StaffListCreateView,
)

app_name = "workforce"

urlpatterns = [
    path(
        "organizations/<uuid:organization_id>/staff/",
        StaffListCreateView.as_view(),
        name="staff-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/drivers/",
        DriverListCreateView.as_view(),
        name="driver-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/conductors/",
        ConductorListCreateView.as_view(),
        name="conductor-list-create",
    ),
]
