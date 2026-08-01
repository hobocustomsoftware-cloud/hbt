from rest_framework import generics

from apps.audit.services import record_audit_event
from apps.subscriptions.services import enforce_usage_limit
from apps.tenancy.services import active_membership_for, require_permission
from apps.tenancy.views import organization_for_user

from .models import ConductorProfile, DriverProfile, StaffProfile
from .serializers import (
    ConductorProfileSerializer,
    DriverProfileSerializer,
    StaffProfileSerializer,
)


class WorkforceMixin:
    def context(self):
        if not hasattr(self, "_org"):
            self._org = organization_for_user(
                self.request.user, self.kwargs["organization_id"]
            )
            self._membership = active_membership_for(
                self.request.user, self._org
            )
        return self._org, self._membership

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _, membership = self.context()
        require_permission(
            membership,
            "workforce.manage"
            if request.method in ("POST", "PUT", "PATCH")
            else "workforce.view",
        )

    def audit(self, action, instance, serializer):
        org, _ = self.context()
        record_audit_event(
            actor=self.request.user,
            tenant_id=org.tenant_id,
            organization_id=org.id,
            action=action,
            resource_type=instance._meta.model_name,
            resource_id=instance.id,
            after=serializer(instance).data,
        )


class StaffListCreateView(WorkforceMixin, generics.ListCreateAPIView):
    serializer_class = StaffProfileSerializer

    def get_queryset(self):
        org, _ = self.context()
        return StaffProfile.objects.filter(
            membership__organization=org
        ).select_related("membership__user", "branch")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["organization"], _ = self.context()
        return context

    def perform_create(self, serializer):
        org, _ = self.context()
        subscription = getattr(org.tenant, "subscription", None)
        enforce_usage_limit(
            subscription=subscription,
            code="staff_accounts",
            current_count=StaffProfile.objects.filter(
                membership__organization=org
            ).count(),
        )
        profile = serializer.save()
        self.audit("workforce.staff_created", profile, StaffProfileSerializer)


class DriverListCreateView(WorkforceMixin, generics.ListCreateAPIView):
    serializer_class = DriverProfileSerializer

    def get_queryset(self):
        org, _ = self.context()
        return DriverProfile.objects.filter(
            staff__membership__organization=org
        ).select_related("staff")

    def perform_create(self, serializer):
        org, _ = self.context()
        staff = serializer.validated_data["staff"]
        if staff.membership.organization_id != org.id:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Staff belongs to another organization.")
        driver = serializer.save()
        self.audit("workforce.driver_created", driver, DriverProfileSerializer)


class ConductorListCreateView(WorkforceMixin, generics.ListCreateAPIView):
    serializer_class = ConductorProfileSerializer

    def get_queryset(self):
        org, _ = self.context()
        return ConductorProfile.objects.filter(
            staff__membership__organization=org
        ).select_related("staff")

    def perform_create(self, serializer):
        org, _ = self.context()
        staff = serializer.validated_data["staff"]
        if staff.membership.organization_id != org.id:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Staff belongs to another organization.")
        conductor = serializer.save()
        self.audit(
            "workforce.conductor_created",
            conductor,
            ConductorProfileSerializer,
        )
