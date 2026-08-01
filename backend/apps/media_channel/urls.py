from django.urls import path

from .views import (
    AdvertiserAccountCreateView,
    AdvertiserCampaignListCreateView,
    AdvertiserCampaignSubmitView,
    AdvertiserCreativeCreateView,
    MyAdvertiserAccountView,
    OrganizationCampaignDetailView,
    OrganizationCampaignListCreateView,
    OrganizationCampaignSubmitView,
    OrganizationCreativeCreateView,
    PlatformCampaignReviewView,
    PlatformCampaignPaymentConfirmView,
    PlatformAdvertiserReviewView,
    PublicMediaFeedView,
)

urlpatterns = [
    path("public/media/", PublicMediaFeedView.as_view()),
    path("advertiser/register/", AdvertiserAccountCreateView.as_view()),
    path("advertiser/me/", MyAdvertiserAccountView.as_view()),
    path("advertiser/campaigns/", AdvertiserCampaignListCreateView.as_view()),
    path(
        "advertiser/campaigns/<uuid:campaign_id>/creatives/",
        AdvertiserCreativeCreateView.as_view(),
    ),
    path(
        "advertiser/campaigns/<uuid:campaign_id>/submit/",
        AdvertiserCampaignSubmitView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/media-campaigns/",
        OrganizationCampaignListCreateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/media-campaigns/<uuid:pk>/",
        OrganizationCampaignDetailView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/media-campaigns/"
        "<uuid:campaign_id>/creatives/",
        OrganizationCreativeCreateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/media-campaigns/"
        "<uuid:campaign_id>/submit/",
        OrganizationCampaignSubmitView.as_view(),
    ),
    path(
        "platform/media-campaigns/<uuid:campaign_id>/review/",
        PlatformCampaignReviewView.as_view(),
    ),
    path(
        "platform/media-campaigns/<uuid:campaign_id>/confirm-payment/",
        PlatformCampaignPaymentConfirmView.as_view(),
    ),
    path(
        "platform/advertisers/<uuid:advertiser_id>/review/",
        PlatformAdvertiserReviewView.as_view(),
    ),
]
