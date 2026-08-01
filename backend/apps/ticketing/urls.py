from django.urls import path

from .views import (
    TicketDetailView,
    TicketIssueView,
    TicketListView,
    TicketReissueView,
    TicketValidateActionView,
    TicketValidateView,
)

urlpatterns = [
    path(
        "organizations/<uuid:organization_id>/tickets/",
        TicketListView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/tickets/issue/",
        TicketIssueView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/tickets/validate/",
        TicketValidateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/tickets/<uuid:ticket_id>/",
        TicketDetailView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/tickets/<uuid:ticket_id>/validate/",
        TicketValidateActionView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/tickets/<uuid:ticket_id>/reissue/",
        TicketReissueView.as_view(),
    ),
]
