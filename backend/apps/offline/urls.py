from django.urls import path

from .views import (
    AuthorizationSnapshotIssueView,
    MyDeviceListCreateView,
    MyDeviceRevokeView,
    SyncCapabilitiesView,
    SyncPullView,
    SyncPushView,
)

urlpatterns = [
    path("me/devices/", MyDeviceListCreateView.as_view()),
    path("me/devices/<uuid:device_id>/revoke/", MyDeviceRevokeView.as_view()),
    path("sync/capabilities/", SyncCapabilitiesView.as_view()),
    path(
        "organizations/<uuid:organization_id>/devices/<uuid:device_id>/"
        "authorization-snapshot/",
        AuthorizationSnapshotIssueView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/devices/<uuid:device_id>/sync/push/",
        SyncPushView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/devices/<uuid:device_id>/sync/pull/",
        SyncPullView.as_view(),
    ),
]
