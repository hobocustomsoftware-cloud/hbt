from rest_framework import generics
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from .models import NRCCitizenshipType, NRCStateRegion, NRCTownship
from .serializers import (
    NRCCitizenshipTypeSerializer,
    NRCStateRegionSerializer,
    NRCTownshipSerializer,
    NRCValidateSerializer,
)


class NRCStateRegionListView(generics.ListAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = NRCStateRegionSerializer
    queryset = NRCStateRegion.objects.filter(active=True)


class NRCTownshipListView(generics.ListAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = NRCTownshipSerializer

    def get_queryset(self):
        queryset = NRCTownship.objects.filter(active=True).select_related(
            "state_region"
        )
        state_code = self.request.query_params.get("state_code")
        if state_code:
            queryset = queryset.filter(state_region__code=state_code)
        return queryset


class NRCCitizenshipTypeListView(generics.ListAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = NRCCitizenshipTypeSerializer
    queryset = NRCCitizenshipType.objects.filter(active=True)


class NRCValidateView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    @extend_schema(
        request=NRCValidateSerializer,
        responses=NRCValidateSerializer,
    )
    def post(self, request, version=None):
        serializer = NRCValidateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(NRCValidateSerializer(serializer.validated_data).data)
