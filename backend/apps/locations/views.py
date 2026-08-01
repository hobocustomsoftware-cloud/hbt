from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from apps.audit.services import record_audit_event
from apps.subscriptions.services import enforce_usage_limit
from apps.tenancy.services import active_membership_for, require_permission
from apps.tenancy.views import organization_for_user

from .models import (
    Branch,
    CompanyTerminalOperation,
    OperationalStatus,
    PhysicalTerminal,
    SalesCounter,
)
from .serializers import (
    BranchSerializer,
    PhysicalTerminalSerializer,
    SalesCounterSerializer,
    TerminalOperationSerializer,
)


class OrganizationLocationMixin:
    permission_classes = [IsAuthenticated]
    view_permission = ""
    manage_permission = ""

    def organization_and_membership(self):
        if not hasattr(self, "_organization"):
            self._organization = organization_for_user(
                self.request.user,
                self.kwargs["organization_id"],
            )
            self._membership = active_membership_for(
                self.request.user,
                self._organization,
            )
        return self._organization, self._membership

    def check_location_permission(self):
        _, membership = self.organization_and_membership()
        permission = (
            self.manage_permission
            if self.request.method in ("POST", "PUT", "PATCH")
            else self.view_permission
        )
        require_permission(membership, permission)

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        self.check_location_permission()

    def audit(self, action, instance, before=None):
        organization, _ = self.organization_and_membership()
        record_audit_event(
            actor=self.request.user,
            tenant_id=organization.tenant_id,
            organization_id=organization.id,
            action=action,
            resource_type=instance._meta.model_name,
            resource_id=instance.id,
            before=before or {},
            after=self.get_serializer(instance).data,
        )


class PhysicalTerminalListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PhysicalTerminalSerializer
    queryset = PhysicalTerminal.objects.filter(
        status=OperationalStatus.ACTIVE
    ).order_by("region", "city", "name")


class BranchListCreateView(
    OrganizationLocationMixin,
    generics.ListCreateAPIView,
):
    serializer_class = BranchSerializer
    view_permission = "locations.branch.view"
    manage_permission = "locations.branch.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Branch.objects.filter(organization=organization)

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        branch = serializer.save(organization=organization)
        self.audit("locations.branch_created", branch)


class BranchDetailView(
    OrganizationLocationMixin,
    generics.RetrieveUpdateAPIView,
):
    serializer_class = BranchSerializer
    view_permission = "locations.branch.view"
    manage_permission = "locations.branch.manage"
    lookup_url_kwarg = "branch_id"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Branch.objects.filter(organization=organization)

    def perform_update(self, serializer):
        before = BranchSerializer(serializer.instance).data
        branch = serializer.save()
        self.audit("locations.branch_updated", branch, before)


class TerminalOperationListCreateView(
    OrganizationLocationMixin,
    generics.ListCreateAPIView,
):
    serializer_class = TerminalOperationSerializer
    view_permission = "locations.operation.view"
    manage_permission = "locations.operation.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CompanyTerminalOperation.objects.filter(
            organization=organization
        ).select_related("branch", "terminal")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        organization, _ = self.organization_and_membership()
        context["organization"] = organization
        return context

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        operation = serializer.save(organization=organization)
        self.audit("locations.terminal_operation_created", operation)


class TerminalOperationDetailView(
    OrganizationLocationMixin,
    generics.RetrieveUpdateAPIView,
):
    serializer_class = TerminalOperationSerializer
    view_permission = "locations.operation.view"
    manage_permission = "locations.operation.manage"
    lookup_url_kwarg = "operation_id"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return CompanyTerminalOperation.objects.filter(
            organization=organization
        ).select_related("branch", "terminal")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        organization, _ = self.organization_and_membership()
        context["organization"] = organization
        return context

    def perform_update(self, serializer):
        before = TerminalOperationSerializer(
            serializer.instance,
            context=self.get_serializer_context(),
        ).data
        operation = serializer.save()
        self.audit("locations.terminal_operation_updated", operation, before)


class CounterListCreateView(
    OrganizationLocationMixin,
    generics.ListCreateAPIView,
):
    serializer_class = SalesCounterSerializer
    view_permission = "locations.counter.view"
    manage_permission = "locations.counter.manage"

    def get_operation(self):
        organization, _ = self.organization_and_membership()
        return get_object_or_404(
            CompanyTerminalOperation,
            id=self.kwargs["operation_id"],
            organization=organization,
        )

    def get_queryset(self):
        return SalesCounter.objects.filter(
            terminal_operation=self.get_operation()
        )

    def perform_create(self, serializer):
        operation = self.get_operation()
        organization, _ = self.organization_and_membership()
        subscription = getattr(organization.tenant, "subscription", None)
        enforce_usage_limit(
            subscription=subscription,
            code="counters",
            current_count=SalesCounter.objects.filter(
                terminal_operation__organization=organization
            ).count(),
        )
        counter = serializer.save(terminal_operation=operation)
        self.audit("locations.counter_created", counter)
