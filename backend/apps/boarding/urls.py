from django.urls import path

from .views import BoardingListView, BoardingValidateView, BoardPassengerView

urlpatterns = [
    path(
        "organizations/<uuid:organization_id>/boardings/",
        BoardingListView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/trips/<uuid:trip_id>/boarding/validate/",
        BoardingValidateView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/boardings/<uuid:boarding_id>/board/",
        BoardPassengerView.as_view(),
    ),
]

