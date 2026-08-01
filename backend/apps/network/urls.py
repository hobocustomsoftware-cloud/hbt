from django.urls import path

from .views import (
    RouteDetailView,
    RouteListCreateView,
    RouteSegmentListCreateView,
    RouteStopDetailView,
    RouteStopListCreateView,
)

app_name = "network"

urlpatterns = [
    path(
        "organizations/<uuid:organization_id>/routes/",
        RouteListCreateView.as_view(),
        name="route-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/routes/<uuid:route_id>/",
        RouteDetailView.as_view(),
        name="route-detail",
    ),
    path(
        "organizations/<uuid:organization_id>/routes/<uuid:route_id>/stops/",
        RouteStopListCreateView.as_view(),
        name="route-stop-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/routes/<uuid:route_id>/stops/"
        "<uuid:stop_id>/",
        RouteStopDetailView.as_view(),
        name="route-stop-detail",
    ),
    path(
        "organizations/<uuid:organization_id>/routes/<uuid:route_id>/segments/",
        RouteSegmentListCreateView.as_view(),
        name="route-segment-list-create",
    ),
]
