from rest_framework import generics

from apps.scheduling.views import OrganizationSchedulingMixin

from .models import Passenger
from .serializers import PassengerSerializer


class PassengerListCreateView(
    OrganizationSchedulingMixin, generics.ListCreateAPIView
):
    serializer_class = PassengerSerializer
    view_permission = "passenger.view"
    manage_permission = "passenger.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Passenger.objects.filter(organization=organization)

    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        passenger = serializer.save(organization=organization)
        self.audit("passenger.registered", passenger)


class PassengerDetailView(
    OrganizationSchedulingMixin, generics.RetrieveUpdateAPIView
):
    serializer_class = PassengerSerializer
    lookup_url_kwarg = "passenger_id"
    view_permission = "passenger.view"
    manage_permission = "passenger.manage"

    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return Passenger.objects.filter(organization=organization)

    def perform_update(self, serializer):
        passenger = serializer.save()
        self.audit("passenger.updated", passenger)

