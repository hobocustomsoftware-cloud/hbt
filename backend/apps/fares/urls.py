from django.urls import path

from .views import (
    BookingQuoteCreateView,
    BookingQuoteListView,
    FareRuleDetailView,
    FareRuleListCreateView,
    PromotionDetailView,
    PromotionListCreateView,
    QuoteLockView,
    QuoteOverrideView,
    SelfBookingQuoteView,
)

urlpatterns = [
    path(
        "organizations/<uuid:organization_id>/promotions/",
        PromotionListCreateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/promotions/<uuid:pk>/",
        PromotionDetailView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/fare-rules/",
        FareRuleListCreateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/fare-rules/<uuid:pk>/",
        FareRuleDetailView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/bookings/<uuid:booking_id>/fare-quotes/",
        BookingQuoteListView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/bookings/<uuid:booking_id>/fare-quotes/create/",
        BookingQuoteCreateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/fare-quotes/<uuid:quote_id>/lock/",
        QuoteLockView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/fare-quotes/<uuid:quote_id>/"
        "lines/<uuid:line_id>/override/",
        QuoteOverrideView.as_view(),
    ),
    path(
        "passenger/bookings/<uuid:booking_id>/fare-quote/",
        SelfBookingQuoteView.as_view(),
    ),
]
