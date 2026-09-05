from django.conf import settings
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

from apps.core.views import (
    HealthView,
    LivenessView,
    ReadinessView,
    UnversionedHealthView,
    UnversionedLivenessView,
    UnversionedReadinessView,
)

urlpatterns = [
    path("admin/", admin.site.urls),
    # Unversioned health probes for container orchestration and clients.
    path("health/", UnversionedHealthView.as_view()),
    path("health/live/", UnversionedLivenessView.as_view()),
    path("health/ready/", UnversionedReadinessView.as_view()),
    path("api/<str:version>/auth/", include("apps.identity.urls")),
    path("api/<str:version>/", include("apps.tenancy.urls")),
    path("api/<str:version>/", include("apps.locations.urls")),
    path("api/<str:version>/", include("apps.network.urls")),
    path("api/<str:version>/", include("apps.fleet.urls")),
    path("api/<str:version>/", include("apps.workforce.urls")),
    path("api/<str:version>/", include("apps.scheduling.urls")),
    path("api/<str:version>/", include("apps.passengers.urls")),
    path("api/<str:version>/", include("apps.bookings.urls")),
    path("api/<str:version>/", include("apps.fares.urls")),
    path("api/<str:version>/", include("apps.ticketing.urls")),
    path("api/<str:version>/", include("apps.boarding.urls")),
    path("api/<str:version>/", include("apps.cargo.urls")),
    path("api/<str:version>/", include("apps.payments.urls")),
    path("api/<str:version>/", include("apps.operations.urls")),
    path("api/<str:version>/", include("apps.offline.urls")),
    path("api/<str:version>/", include("apps.notifications.urls")),
    path("api/<str:version>/", include("apps.feedback.urls")),
    path("api/<str:version>/", include("apps.subscriptions.urls")),
    path("api/<str:version>/", include("apps.branding.urls")),
    path("api/<str:version>/", include("apps.media_channel.urls")),
    path("api/<str:version>/", include("apps.reference_data.urls")),
    path("api/<str:version>/", include("apps.core.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="openapi-schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="openapi-schema"),
        name="swagger-ui",
    ),
    path(
        "api/redoc/",
        SpectacularRedocView.as_view(url_name="openapi-schema"),
        name="redoc",
    ),
]

if settings.DEBUG:
    urlpatterns.append(path("api-auth/", include("rest_framework.urls")))