from django.urls import path

from .views import (
    BranchDetailView,
    BranchListCreateView,
    CounterListCreateView,
    PhysicalTerminalListView,
    TerminalOperationDetailView,
    TerminalOperationListCreateView,
)

app_name = "locations"

urlpatterns = [
    path("terminals/", PhysicalTerminalListView.as_view(), name="terminal-list"),
    path(
        "organizations/<uuid:organization_id>/branches/",
        BranchListCreateView.as_view(),
        name="branch-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/branches/<uuid:branch_id>/",
        BranchDetailView.as_view(),
        name="branch-detail",
    ),
    path(
        "organizations/<uuid:organization_id>/terminal-operations/",
        TerminalOperationListCreateView.as_view(),
        name="terminal-operation-list-create",
    ),
    path(
        "organizations/<uuid:organization_id>/terminal-operations/"
        "<uuid:operation_id>/",
        TerminalOperationDetailView.as_view(),
        name="terminal-operation-detail",
    ),
    path(
        "organizations/<uuid:organization_id>/terminal-operations/"
        "<uuid:operation_id>/counters/",
        CounterListCreateView.as_view(),
        name="counter-list-create",
    ),
]
