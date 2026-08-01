from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.scheduling.views import OrganizationSchedulingMixin

from .models import AdvertiserAccount, MediaCampaign
from .serializers import (
    AdvertiserAccountSerializer,
    AdvertiserReviewSerializer,
    CampaignReviewSerializer,
    CampaignPaymentConfirmSerializer,
    MediaCampaignSerializer,
    MediaCreativeSerializer,
    PublicMediaCampaignSerializer,
)
from .services import (
    confirm_campaign_payment,
    review_advertiser,
    review_campaign,
    submit_campaign,
)


class PublicMediaFeedView(generics.ListAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = PublicMediaCampaignSerializer

    def get_queryset(self):
        now = timezone.now()
        queryset = MediaCampaign.objects.filter(
            status__in=(MediaCampaign.Status.APPROVED, MediaCampaign.Status.ACTIVE),
            starts_at__lte=now,
            ends_at__gt=now,
        ).filter(
            Q(kind__in=(MediaCampaign.Kind.OPERATOR, MediaCampaign.Kind.PLATFORM))
            | Q(
                kind=MediaCampaign.Kind.SPONSORED,
                payment_status=MediaCampaign.PaymentStatus.CONFIRMED,
            )
        )
        placement = self.request.query_params.get("placement")
        if placement:
            queryset = queryset.filter(placement=placement)
        return queryset.select_related(
            "organization__branding", "advertiser"
        ).prefetch_related("creatives").order_by("-priority", "-created_at")


class OrganizationCampaignListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = MediaCampaignSerializer
    view_permission = "media.view"
    manage_permission = "media.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return MediaCampaign.objects.filter(organization=organization)

    def get_serializer_context(self):
        context = super().get_serializer_context()
        organization, _ = self.organization_and_membership()
        context["organization"] = organization
        return context


class OrganizationCampaignDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = MediaCampaignSerializer
    view_permission = "media.view"
    manage_permission = "media.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return MediaCampaign.objects.filter(
            organization=organization, status=MediaCampaign.Status.DRAFT
        )


class OrganizationCreativeCreateView(OrganizationSchedulingMixin, APIView):
    manage_permission = "media.manage"

    @extend_schema(request=MediaCreativeSerializer, responses={201: MediaCreativeSerializer})
    def post(self, request, organization_id, campaign_id, version=None):
        organization, _ = self.organization_and_membership()
        campaign = get_object_or_404(
            MediaCampaign,
            pk=campaign_id,
            organization=organization,
            status=MediaCampaign.Status.DRAFT,
        )
        serializer = MediaCreativeSerializer(
            data=request.data,
            context={"request": request, "campaign": campaign},
        )
        serializer.is_valid(raise_exception=True)
        creative = serializer.save()
        return Response(
            MediaCreativeSerializer(creative).data,
            status=status.HTTP_201_CREATED,
        )


class OrganizationCampaignSubmitView(OrganizationSchedulingMixin, APIView):
    manage_permission = "media.manage"

    @extend_schema(request=None, responses=MediaCampaignSerializer)
    def post(self, request, organization_id, campaign_id, version=None):
        organization, _ = self.organization_and_membership()
        campaign = get_object_or_404(
            MediaCampaign, pk=campaign_id, organization=organization
        )
        campaign = submit_campaign(campaign, request.user)
        return Response(MediaCampaignSerializer(campaign).data)


class MyAdvertiserAccountView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AdvertiserAccountSerializer

    def get_object(self):
        return get_object_or_404(AdvertiserAccount, owner=self.request.user)


class AdvertiserAccountCreateView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AdvertiserAccountSerializer

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class AdvertiserCampaignListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = MediaCampaignSerializer

    def advertiser(self):
        return get_object_or_404(AdvertiserAccount, owner=self.request.user)

    def get_queryset(self):
        return MediaCampaign.objects.filter(advertiser=self.advertiser())

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["advertiser"] = self.advertiser()
        return context


class AdvertiserCreativeCreateView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(request=MediaCreativeSerializer, responses={201: MediaCreativeSerializer})
    def post(self, request, campaign_id, version=None):
        campaign = get_object_or_404(
            MediaCampaign,
            pk=campaign_id,
            advertiser__owner=request.user,
            status=MediaCampaign.Status.DRAFT,
        )
        serializer = MediaCreativeSerializer(
            data=request.data,
            context={"request": request, "campaign": campaign},
        )
        serializer.is_valid(raise_exception=True)
        creative = serializer.save()
        return Response(
            MediaCreativeSerializer(creative).data,
            status=status.HTTP_201_CREATED,
        )


class AdvertiserCampaignSubmitView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(request=None, responses=MediaCampaignSerializer)
    def post(self, request, campaign_id, version=None):
        campaign = get_object_or_404(
            MediaCampaign, pk=campaign_id, advertiser__owner=request.user
        )
        return Response(
            MediaCampaignSerializer(submit_campaign(campaign, request.user)).data
        )


class PlatformCampaignReviewView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(request=CampaignReviewSerializer, responses=MediaCampaignSerializer)
    def post(self, request, campaign_id, version=None):
        campaign = get_object_or_404(MediaCampaign, pk=campaign_id)
        serializer = CampaignReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        campaign = review_campaign(
            campaign=campaign,
            actor=request.user,
            **serializer.validated_data,
        )
        return Response(MediaCampaignSerializer(campaign).data)


class PlatformCampaignPaymentConfirmView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=CampaignPaymentConfirmSerializer, responses=MediaCampaignSerializer
    )
    def post(self, request, campaign_id, version=None):
        campaign = get_object_or_404(MediaCampaign, pk=campaign_id)
        serializer = CampaignPaymentConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        campaign = confirm_campaign_payment(
            campaign,
            request.user,
            serializer.validated_data["payment_reference"],
        )
        return Response(MediaCampaignSerializer(campaign).data)


class PlatformAdvertiserReviewView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=AdvertiserReviewSerializer, responses=AdvertiserAccountSerializer
    )
    def post(self, request, advertiser_id, version=None):
        advertiser = get_object_or_404(AdvertiserAccount, pk=advertiser_id)
        serializer = AdvertiserReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        advertiser = review_advertiser(
            advertiser,
            request.user,
            serializer.validated_data["approve"],
        )
        return Response(AdvertiserAccountSerializer(advertiser).data)
