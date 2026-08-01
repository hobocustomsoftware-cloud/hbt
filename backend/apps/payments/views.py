from django.db import models
from django.http import FileResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema

from apps.scheduling.views import OrganizationSchedulingMixin
from apps.core.serializers import EmptySerializer
from apps.tenancy.services import require_permission

from .models import (
    PaymentReceivingAccount,
    PaymentReceivingAccountVersion,
    PaymentRecord,
    PrivatePaymentUpload,
    RefundPolicy,
    RefundRequest,
    InvoicePaymentAllocation,
    PaymentConnector,
    PaymentWebhookEvent,
)
from .services import resolve_receiving_account_versions
from .serializers import (
    PaymentDecisionSerializer,
    PaymentReceivingAccountSerializer,
    PaymentReceivingAccountVersionSerializer,
    PaymentRecordSerializer,
    PrivatePaymentUploadSerializer,
    RefundCompleteSerializer,
    RefundDecisionSerializer,
    RefundPaidSerializer,
    RefundPolicySerializer,
    RefundRequestSerializer,
    InvoicePaymentAllocationSerializer,
    PaymentConnectorSerializer,
    PaymentIntentSerializer,
    PaymentWebhookEventSerializer,
    PaymentConnectorDisableSerializer,
    PaymentConnectorRotationSerializer,
    PaymentOptionSerializer,
)
from .services import process_provider_webhook, test_payment_connector


class PaymentAccountListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = PaymentReceivingAccountSerializer
    view_permission = "payment.account.view"
    manage_permission = "payment.account.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PaymentReceivingAccount.objects.filter(
            organization=organization
        ).prefetch_related("versions")


class PaymentAccountDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = PaymentReceivingAccountSerializer
    view_permission = "payment.account.view"
    manage_permission = "payment.account.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PaymentReceivingAccount.objects.filter(organization=organization)


class PaymentAccountApproveView(OrganizationSchedulingMixin, APIView):
    manage_permission = "payment.account.approve"

    @extend_schema(
        request=EmptySerializer,
        responses=PaymentReceivingAccountSerializer,
        operation_id="payment_account_approve",
    )
    def post(self, request, organization_id, pk, version=None):
        organization, _ = self.organization_and_membership()
        account = get_object_or_404(
            PaymentReceivingAccount, organization=organization, pk=pk
        )
        if account.account_type != PaymentReceivingAccount.Type.PERSONAL:
            return Response(
                {"detail": "Approval is only required for personal wallets."},
                status=400,
            )
        account.approved_by = request.user
        account.approved_at = timezone.now()
        account.status = PaymentReceivingAccount.Status.ACTIVE
        account.full_clean()
        account.save()
        return Response(PaymentReceivingAccountSerializer(account).data)


class PaymentAccountVersionCreateView(
    OrganizationSchedulingMixin, generics.CreateAPIView
):
    serializer_class = PaymentReceivingAccountVersionSerializer
    manage_permission = "payment.account.manage"

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        account = get_object_or_404(
            PaymentReceivingAccount,
            organization=organization,
            pk=self.kwargs["pk"],
        )
        version = PaymentReceivingAccountVersion(
            account=account,
            created_by=self.request.user,
            **serializer.validated_data,
        )
        version.full_clean()
        version.save()
        serializer.instance = version


class PrivatePaymentUploadView(
    OrganizationSchedulingMixin, generics.CreateAPIView
):
    serializer_class = PrivatePaymentUploadSerializer
    manage_permission = "payment.evidence.upload"


class PrivatePaymentDownloadView(OrganizationSchedulingMixin, APIView):
    view_permission = "payment.evidence.view"

    @extend_schema(
        responses={(200, "application/octet-stream"): OpenApiTypes.BINARY},
        operation_id="private_payment_upload_download",
    )
    def get(self, request, organization_id, upload_id, version=None):
        organization, _ = self.organization_and_membership()
        upload = get_object_or_404(
            PrivatePaymentUpload, organization=organization, pk=upload_id
        )
        return FileResponse(
            upload.file.open("rb"),
            content_type=upload.content_type,
            as_attachment=True,
            filename=upload.original_filename,
        )


class SelfPaymentOptionsView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=PaymentOptionSerializer(many=True),
        operation_id="passenger_payment_options",
    )
    def get(self, request, booking_id, version=None):
        from apps.bookings.models import Booking

        booking = get_object_or_404(
            Booking, pk=booking_id, customer_account=request.user
        )
        versions = resolve_receiving_account_versions(
            organization=booking.organization
        )
        return Response(
            [
                {
                    "account_version_id": version.id,
                    "provider_name": version.account.provider_name,
                    "account_name": version.account.account_name,
                    "account_identifier_masked": (
                        f"{'*' * max(len(version.account.account_identifier) - 4, 0)}"
                        f"{version.account.account_identifier[-4:]}"
                    ),
                    "display_label": version.display_label,
                    "has_qr": bool(version.qr_upload_id),
                }
                for version in versions
            ]
        )


class SelfPaymentEvidenceUploadView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PrivatePaymentUploadSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        from apps.bookings.models import Booking

        booking = get_object_or_404(
            Booking,
            pk=self.kwargs["booking_id"],
            customer_account=self.request.user,
        )
        context["organization"] = booking.organization
        return context

    def perform_create(self, serializer):
        serializer.save(
            purpose=PrivatePaymentUpload.Purpose.PAYMENT_EVIDENCE
        )


class SelfPaymentCreateView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentRecordSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        from apps.bookings.models import Booking

        self.booking = get_object_or_404(
            Booking,
            pk=self.kwargs["booking_id"],
            customer_account=self.request.user,
        )
        context["organization"] = self.booking.organization
        return context

    def perform_create(self, serializer):
        if not hasattr(self, "booking"):
            self.get_serializer_context()
        serializer.save(booking=self.booking)


class PaymentListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = PaymentRecordSerializer
    view_permission = "payment.view"
    manage_permission = "payment.record"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PaymentRecord.objects.filter(organization=organization).select_related(
            "receiving_account_version__account"
        )


class PaymentDecisionView(OrganizationSchedulingMixin, APIView):
    manage_permission = "payment.confirm"

    @extend_schema(
        request=PaymentDecisionSerializer,
        responses=PaymentRecordSerializer,
        operation_id="payment_decision",
    )
    def post(self, request, organization_id, payment_id, version=None):
        organization, membership = self.organization_and_membership()
        payment = get_object_or_404(
            PaymentRecord, pk=payment_id, organization=organization
        )
        if request.data.get("tickets"):
            require_permission(membership, "ticket.issue")
        serializer = PaymentDecisionSerializer(
            data=request.data,
            context={"payment": payment, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(PaymentRecordSerializer(serializer.save()).data)


class RefundPolicyView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = RefundPolicySerializer
    view_permission = "refund.view"
    manage_permission = "refund.policy.manage"

    def get_object(self):
        organization, _ = self.organization_and_membership()
        try:
            return RefundPolicy.objects.get(organization=organization)
        except RefundPolicy.DoesNotExist:
            return RefundPolicy(
                organization=organization,
                configured_by=self.request.user,
            )


class RefundListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = RefundRequestSerializer
    view_permission = "refund.view"
    manage_permission = "refund.request"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return RefundRequest.objects.filter(
            organization=organization
        ).select_related("payment", "ticket")


class RefundDecisionView(OrganizationSchedulingMixin, APIView):
    manage_permission = "refund.approve"

    @extend_schema(
        request=RefundDecisionSerializer,
        responses=RefundRequestSerializer,
        operation_id="refund_decision",
    )
    def post(self, request, organization_id, refund_id, version=None):
        organization, _ = self.organization_and_membership()
        refund = get_object_or_404(
            RefundRequest, organization=organization, pk=refund_id
        )
        serializer = RefundDecisionSerializer(
            data=request.data,
            context={"refund": refund, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(RefundRequestSerializer(serializer.save()).data)


class RefundPaidView(OrganizationSchedulingMixin, APIView):
    manage_permission = "refund.pay"

    @extend_schema(
        request=RefundPaidSerializer,
        responses=RefundRequestSerializer,
        operation_id="refund_mark_paid",
    )
    def post(self, request, organization_id, refund_id, version=None):
        organization, _ = self.organization_and_membership()
        refund = get_object_or_404(
            RefundRequest, organization=organization, pk=refund_id
        )
        serializer = RefundPaidSerializer(
            data=request.data,
            context={"refund": refund, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(RefundRequestSerializer(serializer.save()).data)


class RefundCompleteView(OrganizationSchedulingMixin, APIView):
    manage_permission = "refund.complete"

    @extend_schema(
        request=RefundCompleteSerializer,
        responses=RefundRequestSerializer,
        operation_id="refund_complete",
    )
    def post(self, request, organization_id, refund_id, version=None):
        organization, _ = self.organization_and_membership()
        refund = get_object_or_404(
            RefundRequest, organization=organization, pk=refund_id
        )
        serializer = RefundCompleteSerializer(
            data=request.data,
            context={"refund": refund, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(RefundRequestSerializer(serializer.save()).data)


class InvoiceAllocationListView(
    OrganizationSchedulingMixin, generics.ListAPIView
):
    serializer_class = InvoicePaymentAllocationSerializer
    view_permission = "invoice.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return InvoicePaymentAllocation.objects.filter(
            invoice__organization=organization,
            invoice_id=self.kwargs["invoice_id"],
        )


class PaymentConnectorListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = PaymentConnectorSerializer
    view_permission = "payment.connector.view"
    manage_permission = "payment.connector.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PaymentConnector.objects.filter(organization=organization)


class PaymentConnectorDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = PaymentConnectorSerializer
    view_permission = "payment.connector.view"
    manage_permission = "payment.connector.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PaymentConnector.objects.filter(organization=organization)


class PaymentConnectorTestView(OrganizationSchedulingMixin, APIView):
    manage_permission = "payment.connector.manage"

    @extend_schema(
        request=EmptySerializer,
        responses=PaymentConnectorSerializer,
        operation_id="payment_connector_test",
    )
    def post(self, request, organization_id, connector_id, version=None):
        organization, _ = self.organization_and_membership()
        connector = get_object_or_404(
            PaymentConnector, organization=organization, pk=connector_id
        )
        connector = test_payment_connector(
            connector=connector, actor=request.user
        )
        return Response(PaymentConnectorSerializer(connector).data)


class PaymentConnectorRotateView(OrganizationSchedulingMixin, APIView):
    manage_permission = "payment.connector.manage"

    @extend_schema(
        request=PaymentConnectorRotationSerializer,
        responses=PaymentConnectorSerializer,
        operation_id="payment_connector_rotate",
    )
    def post(self, request, organization_id, connector_id, version=None):
        organization, _ = self.organization_and_membership()
        connector = get_object_or_404(
            PaymentConnector, organization=organization, pk=connector_id
        )
        serializer = PaymentConnectorRotationSerializer(
            data=request.data,
            context={"connector": connector, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(PaymentConnectorSerializer(serializer.save()).data)


class PaymentConnectorDisableView(OrganizationSchedulingMixin, APIView):
    manage_permission = "payment.connector.manage"

    @extend_schema(
        request=PaymentConnectorDisableSerializer,
        responses=PaymentConnectorSerializer,
        operation_id="payment_connector_disable",
    )
    def post(self, request, organization_id, connector_id, version=None):
        organization, _ = self.organization_and_membership()
        connector = get_object_or_404(
            PaymentConnector, organization=organization, pk=connector_id
        )
        serializer = PaymentConnectorDisableSerializer(
            data=request.data,
            context={"connector": connector, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        return Response(PaymentConnectorSerializer(serializer.save()).data)


class ProviderPaymentIntentCreateView(
    OrganizationSchedulingMixin, generics.CreateAPIView
):
    serializer_class = PaymentIntentSerializer
    manage_permission = "payment.provider.initiate"


class PaymentConnectorWebhookView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    @extend_schema(
        request=OpenApiTypes.OBJECT,
        responses=PaymentWebhookEventSerializer,
        operation_id="payment_provider_webhook",
        auth=[],
    )
    def post(self, request, connector_id, version=None):
        connector = get_object_or_404(
            PaymentConnector,
            pk=connector_id,
            status=PaymentConnector.Status.ACTIVE,
        )
        signature = request.headers.get("X-HBT-Signature", "")
        try:
            event = process_provider_webhook(
                connector=connector,
                raw_body=request.body,
                signature=signature,
                payload=request.data,
            )
        except Exception as exc:
            from django.core.exceptions import ValidationError
            from rest_framework.exceptions import ValidationError as DRFValidationError
            if isinstance(exc, ValidationError):
                raise DRFValidationError(exc.messages) from exc
            raise
        return Response(PaymentWebhookEventSerializer(event).data)
