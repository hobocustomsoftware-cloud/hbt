from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.audit.services import record_audit_event
from apps.scheduling.views import OrganizationSchedulingMixin

from .models import OrganizationBranding
from .serializers import (
    OrganizationBrandingSerializer,
    PublicOrganizationBrandingSerializer,
)


class PublicOperatorListView(generics.ListAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = PublicOrganizationBrandingSerializer

    def get_queryset(self):
        return OrganizationBranding.objects.filter(
            is_published=True, organization__status="active"
        ).select_related("organization")


class PublicOperatorDetailView(generics.RetrieveAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = PublicOrganizationBrandingSerializer
    lookup_field = "public_slug"

    def get_queryset(self):
        return OrganizationBranding.objects.filter(
            is_published=True, organization__status="active"
        ).select_related("organization")


class OrganizationBrandingView(OrganizationSchedulingMixin, APIView):
    serializer_class = OrganizationBrandingSerializer
    view_permission = "branding.view"
    manage_permission = "branding.manage"

    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        try:
            item = organization.branding
        except OrganizationBranding.DoesNotExist:
            return Response(
                {"detail": "Branding has not been configured."}, status=404
            )
        return Response(OrganizationBrandingSerializer(item).data)

    def put(self, request, organization_id, version=None):
        return self._write(request, partial=False)

    def patch(self, request, organization_id, version=None):
        return self._write(request, partial=True)

    def _write(self, request, partial):
        organization, _ = self.organization_and_membership()
        item = OrganizationBranding.objects.filter(
            organization=organization
        ).first()
        serializer = OrganizationBrandingSerializer(
            item,
            data=request.data,
            partial=partial and item is not None,
            context={
                "request": request,
                "organization": organization,
            },
        )
        serializer.is_valid(raise_exception=True)
        before = {
            "public_slug": item.public_slug if item else "",
            "is_published": item.is_published if item else False,
        }
        item = serializer.save(
            organization=organization, updated_by=request.user
        )
        record_audit_event(
            actor=request.user,
            tenant_id=organization.tenant_id,
            organization_id=organization.id,
            action="branding.updated",
            resource_type="organization_branding",
            resource_id=item.id,
            before=before,
            after={
                "public_slug": item.public_slug,
                "is_published": item.is_published,
            },
        )
        return Response(
            OrganizationBrandingSerializer(item).data,
            status=status.HTTP_200_OK if before["public_slug"] else status.HTTP_201_CREATED,
        )
