from django.urls import path

from .views import (
    LayoutPositionListCreateView,
    SeatLayoutListCreateView,
    VehicleLayoutAssignmentCreateView,
    VehicleListCreateView,
)

app_name = "fleet"

urlpatterns = [
    path(
        "organizations/<uuid:organization_id>/vehicles/",
        VehicleListCreateView.as_view(),
        name="vehicle-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/seat-layouts/",
        SeatLayoutListCreateView.as_view(),
        name="layout-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/seat-layouts/<uuid:layout_id>/positions/",
        LayoutPositionListCreateView.as_view(),
        name="position-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/vehicles/<uuid:vehicle_id>/layout-assignments/",
        VehicleLayoutAssignmentCreateView.as_view(),
        name="layout-assignment-create",
    ),
]
