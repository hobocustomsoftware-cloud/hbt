from django.urls import path

from .views import (
    MyNotificationListView,
    MyNotificationReadView,
    MyNotificationUnreadCountView,
    MyPendingWorkCompleteView,
    MyPendingWorkListView,
    OrganizationNotificationLogView,
    OrganizationNotificationRetryView,
)

urlpatterns = [
    path("me/notifications/", MyNotificationListView.as_view()),
    path("me/notifications/unread-count/", MyNotificationUnreadCountView.as_view()),
    path(
        "me/notifications/<uuid:notification_id>/read/",
        MyNotificationReadView.as_view(),
    ),
    path("me/pending-work/", MyPendingWorkListView.as_view()),
    path(
        "me/pending-work/<uuid:work_item_id>/complete/",
        MyPendingWorkCompleteView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/notification-logs/",
        OrganizationNotificationLogView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/notification-logs/"
        "<uuid:notification_id>/retry/",
        OrganizationNotificationRetryView.as_view(),
    ),
]
