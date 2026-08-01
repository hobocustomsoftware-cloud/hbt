from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import connection
from drf_spectacular.utils import extend_schema

from .serializers import HealthSerializer


class HealthView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    @extend_schema(responses=HealthSerializer, operation_id="system_health")
    def get(self, request, version=None):
        return Response(
            {
                "status": "ok",
                "service": "hbt-backend",
                "api_version": version,
            }
        )


class LivenessView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    @extend_schema(responses=HealthSerializer, operation_id="system_liveness")
    def get(self, request, version=None):
        return Response({"status": "alive", "service": "hbt-backend"})


class ReadinessView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    @extend_schema(responses=HealthSerializer, operation_id="system_readiness")
    def get(self, request, version=None):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        except Exception:
            return Response(
                {"status": "not_ready", "database": "unavailable"},
                status=503,
            )
        return Response({"status": "ready", "database": "ok"})
