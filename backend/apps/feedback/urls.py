from django.urls import path

from .views import (
    MyFeedbackListCreateView,
    OrganizationFeedbackListView,
    OrganizationFeedbackTriageView,
)

urlpatterns = [
    path("me/feedback/", MyFeedbackListCreateView.as_view()),
    path(
        "organizations/<uuid:organization_id>/feedback/",
        OrganizationFeedbackListView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/feedback/<uuid:feedback_id>/triage/",
        OrganizationFeedbackTriageView.as_view(),
    ),
]
