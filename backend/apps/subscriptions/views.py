from rest_framework import generics
from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny

from apps.scheduling.views import OrganizationSchedulingMixin

from .models import SubscriptionInvoice, SubscriptionPlan
from .serializers import (
    SubscriptionInvoiceSerializer,
    SubscriptionPlanSerializer,
    TenantSubscriptionSerializer,
    SubscriptionInvoiceIssueSerializer,
    SubscriptionPaymentDecisionSerializer,
    SubscriptionPaymentSubmitSerializer,
    SubscriptionPlanChangeSerializer,
    SubscriptionSuspendSerializer,
)


class PublicPlanListView(generics.ListAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = SubscriptionPlanSerializer

    def get_queryset(self):
        return SubscriptionPlan.objects.filter(is_public=True, is_active=True)


class OrganizationSubscriptionView(
    OrganizationSchedulingMixin, generics.RetrieveAPIView
):
    serializer_class = TenantSubscriptionSerializer
    view_permission = "subscription.view"
    lookup_field = "tenant_id"

    def get_object(self):
        organization, _ = self.organization_and_membership()
        return organization.tenant.subscription


class OrganizationSubscriptionInvoiceListView(
    OrganizationSchedulingMixin, generics.ListAPIView
):
    serializer_class = SubscriptionInvoiceSerializer
    view_permission = "subscription.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return SubscriptionInvoice.objects.filter(
            subscription__tenant=organization.tenant
        ).order_by("-created_at")


class SubscriptionActionMixin(OrganizationSchedulingMixin):
    manage_permission = "subscription.manage"

    def subscription(self):
        organization, _ = self.organization_and_membership()
        return organization.tenant.subscription


class SubscriptionInvoiceIssueView(SubscriptionActionMixin, APIView):
    @extend_schema(
        request=SubscriptionInvoiceIssueSerializer,
        responses={201: SubscriptionInvoiceSerializer},
        operation_id="subscription_invoice_issue",
    )
    def post(self, request, organization_id, version=None):
        serializer = SubscriptionInvoiceIssueSerializer(
            data=request.data,
            context={"subscription": self.subscription(), "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(
            SubscriptionInvoiceSerializer(serializer.save()).data, status=201
        )


class SubscriptionPaymentSubmitView(SubscriptionActionMixin, APIView):
    @extend_schema(
        request=SubscriptionPaymentSubmitSerializer,
        responses=SubscriptionInvoiceSerializer,
        operation_id="subscription_payment_submit",
    )
    def post(self, request, organization_id, invoice_id, version=None):
        subscription = self.subscription()
        invoice = get_object_or_404(
            SubscriptionInvoice, pk=invoice_id, subscription=subscription
        )
        serializer = SubscriptionPaymentSubmitSerializer(
            data=request.data,
            context={"invoice": invoice, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(SubscriptionInvoiceSerializer(serializer.save()).data)


class SubscriptionPaymentDecisionView(SubscriptionActionMixin, APIView):
    @extend_schema(
        request=SubscriptionPaymentDecisionSerializer,
        responses=SubscriptionInvoiceSerializer,
        operation_id="subscription_payment_decision",
    )
    def post(self, request, organization_id, invoice_id, version=None):
        subscription = self.subscription()
        invoice = get_object_or_404(
            SubscriptionInvoice, pk=invoice_id, subscription=subscription
        )
        serializer = SubscriptionPaymentDecisionSerializer(
            data=request.data,
            context={"invoice": invoice, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(SubscriptionInvoiceSerializer(serializer.save()).data)


class SubscriptionPlanChangeView(SubscriptionActionMixin, APIView):
    @extend_schema(
        request=SubscriptionPlanChangeSerializer,
        responses=TenantSubscriptionSerializer,
        operation_id="subscription_plan_change",
    )
    def post(self, request, organization_id, version=None):
        serializer = SubscriptionPlanChangeSerializer(
            data=request.data,
            context={"subscription": self.subscription(), "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(TenantSubscriptionSerializer(serializer.save()).data)


class SubscriptionSuspendView(SubscriptionActionMixin, APIView):
    @extend_schema(
        request=SubscriptionSuspendSerializer,
        responses=TenantSubscriptionSerializer,
        operation_id="subscription_suspend",
    )
    def post(self, request, organization_id, version=None):
        serializer = SubscriptionSuspendSerializer(
            data=request.data,
            context={"subscription": self.subscription(), "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(TenantSubscriptionSerializer(serializer.save()).data)
