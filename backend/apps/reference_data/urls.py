from django.urls import path

from .views import (
    NRCCitizenshipTypeListView,
    NRCStateRegionListView,
    NRCTownshipListView,
    NRCValidateView,
)

urlpatterns = [
    path("public/nrc/states/", NRCStateRegionListView.as_view()),
    path("public/nrc/townships/", NRCTownshipListView.as_view()),
    path("public/nrc/citizenship-types/", NRCCitizenshipTypeListView.as_view()),
    path("public/nrc/validate/", NRCValidateView.as_view()),
]
