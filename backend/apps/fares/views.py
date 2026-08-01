from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema
from apps.core.serializers import EmptySerializer

from apps.bookings.models import Booking
from apps.scheduling.views import OrganizationSchedulingMixin
from apps.tenancy.services import require_permission

from .models import FareQuote, FareQuoteLine, FareRule, Promotion
from .serializers import (
    FareOverrideSerializer,
    FareQuoteCreateSerializer,
    FareQuoteSerializer,
    FareRuleSerializer,
    PromotionSerializer,
)
from .services import create_fare_quote, lock_fare_quote


class FareRuleListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = FareRuleSerializer
    view_permission = "fare.view"
    manage_permission = "fare.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return FareRule.objects.filter(organization=organization)

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        rule = serializer.save(
            organization=organization, created_by=self.request.user
        )
        rule.full_clean()
        rule.save()
        self.audit("fare.rule_created", rule)


class FareRuleDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = FareRuleSerializer
    view_permission = "fare.view"
    manage_permission = "fare.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return FareRule.objects.filter(organization=organization)


class BookingQuoteCreateView(OrganizationSchedulingMixin, APIView):
    manage_permission = "fare.quote"

    @extend_schema(
        request=FareQuoteCreateSerializer,
        responses={201: FareQuoteSerializer},
        operation_id="booking_fare_quote_create",
    )
    def post(self, request, organization_id, booking_id, version=None):
        organization, _ = self.organization_and_membership()
        booking = get_object_or_404(
            Booking, pk=booking_id, organization=organization
        )
        serializer = FareQuoteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        quote = create_fare_quote(
            booking=booking,
            actor=request.user,
            coupon_code=serializer.validated_data.get("coupon_code", ""),
        )
        return Response(FareQuoteSerializer(quote).data, status=201)


class PromotionListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = PromotionSerializer
    view_permission = "promotion.view"
    manage_permission = "promotion.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Promotion.objects.filter(organization=organization)

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        item = serializer.save(
            organization=organization, created_by=self.request.user
        )
        item.full_clean()
        item.save()
        self.audit("promotion.created", item)


class PromotionDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = PromotionSerializer
    view_permission = "promotion.view"
    manage_permission = "promotion.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Promotion.objects.filter(organization=organization)


class BookingQuoteListView(OrganizationSchedulingMixin, generics.ListAPIView):
    serializer_class = FareQuoteSerializer
    view_permission = "fare.view"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return FareQuote.objects.filter(
            booking_id=self.kwargs["booking_id"],
            booking__organization=organization,
        ).prefetch_related("lines")


class QuoteOverrideView(OrganizationSchedulingMixin, APIView):
    manage_permission = "fare.override"

    @extend_schema(
        request=FareOverrideSerializer,
        responses=FareQuoteSerializer,
        operation_id="fare_quote_line_override",
    )
    def post(self, request, organization_id, quote_id, line_id, version=None):
        organization, _ = self.organization_and_membership()
        line = get_object_or_404(
            FareQuoteLine,
            pk=line_id,
            quote_id=quote_id,
            quote__booking__organization=organization,
        )
        serializer = FareOverrideSerializer(
            data=request.data, context={"line": line, "request": request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(FareQuoteSerializer(line.quote).data)


class QuoteLockView(OrganizationSchedulingMixin, APIView):
    manage_permission = "fare.quote"

    @extend_schema(
        request=EmptySerializer,
        responses=FareQuoteSerializer,
        operation_id="fare_quote_lock",
    )
    def post(self, request, organization_id, quote_id, version=None):
        organization, _ = self.organization_and_membership()
        quote = get_object_or_404(
            FareQuote, pk=quote_id, booking__organization=organization
        )
        return Response(FareQuoteSerializer(lock_fare_quote(
            quote=quote, actor=request.user
        )).data)


class SelfBookingQuoteView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=FareQuoteSerializer,
        operation_id="passenger_booking_fare_quote",
    )
    def get(self, request, booking_id, version=None):
        booking = get_object_or_404(
            Booking, pk=booking_id, customer_account=request.user
        )
        quote = booking.fare_quotes.order_by("-version").first()
        if quote is None:
            return Response({"detail": "No fare quote exists."}, status=404)
        return Response(FareQuoteSerializer(quote).data)
