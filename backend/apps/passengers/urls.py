from django.urls import path

from .views import PassengerDetailView, PassengerListCreateView
from .self_service import (
    PublicTripSearchView,
    PublicTripSeatAvailabilityView,
    SelfBookingListCreateView,
    SelfBookingDetailView,
    SelfBookingCancelView,
    SelfTicketListView,
    SelfTravelerListCreateView,
)

urlpatterns = [
    path("passenger/travelers/", SelfTravelerListCreateView.as_view()),
    path("passenger/trips/search/", PublicTripSearchView.as_view()),
    path(
        "passenger/trips/<uuid:trip_id>/seats/",
        PublicTripSeatAvailabilityView.as_view(),
    ),
    path("passenger/bookings/", SelfBookingListCreateView.as_view()),
    path(
        "passenger/bookings/<uuid:booking_id>/",
        SelfBookingDetailView.as_view(),
    ),
    path(
        "passenger/bookings/<uuid:booking_id>/cancel/",
        SelfBookingCancelView.as_view(),
    ),
    path("passenger/tickets/", SelfTicketListView.as_view()),
    path(
        "organizations/<uuid:organization_id>/passengers/",
        PassengerListCreateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/passengers/<uuid:passenger_id>/",
        PassengerDetailView.as_view(),
    ),
]
