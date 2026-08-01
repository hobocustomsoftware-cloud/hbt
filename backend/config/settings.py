import os
from pathlib import Path

from dotenv import load_dotenv
from django.core.exceptions import ImproperlyConfigured

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def env_or_file(name, default=""):
    value = os.getenv(name)
    if value is not None:
        return value
    path = os.getenv(f"{name}_FILE")
    if path:
        try:
            return Path(path).read_text(encoding="utf-8").strip()
        except OSError as exc:
            raise ImproperlyConfigured(
                f"Unable to read {name}_FILE."
            ) from exc
    return default


DEVELOPMENT_SECRET_KEY = "unsafe-local-development-key"  # nosec B105
SECRET_KEY = env_or_file("DJANGO_SECRET_KEY", DEVELOPMENT_SECRET_KEY)
NRC_ENCRYPTION_KEY = env_or_file("NRC_ENCRYPTION_KEY")
NRC_BLIND_INDEX_KEY = env_or_file("NRC_BLIND_INDEX_KEY")
PAYMENT_CREDENTIAL_ENCRYPTION_KEY = env_or_file(
    "PAYMENT_CREDENTIAL_ENCRYPTION_KEY", ""
)
PUSH_TOKEN_ENCRYPTION_KEY = env_or_file("PUSH_TOKEN_ENCRYPTION_KEY")
PUSH_PROVIDER_BACKEND = os.getenv(
    "PUSH_PROVIDER_BACKEND",
    "apps.notifications.push.DisabledPushProvider",
)
DEBUG = os.getenv("DJANGO_DEBUG", "false").lower() in {"1", "true", "yes", "on"}
if not DEBUG and SECRET_KEY == DEVELOPMENT_SECRET_KEY:
    raise ImproperlyConfigured(
        "DJANGO_SECRET_KEY must be configured outside local debug mode."
    )
ALLOWED_HOSTS = [
    host.strip()
    for host in os.getenv("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if host.strip()
]
CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("DJANGO_CORS_ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]
CORS_ALLOWED_ORIGIN_REGEXES = [
    pattern.strip()
    for pattern in os.getenv("DJANGO_CORS_ALLOWED_ORIGIN_REGEXES", "").split(",")
    if pattern.strip()
]
if DEBUG and not CORS_ALLOWED_ORIGINS and not CORS_ALLOWED_ORIGIN_REGEXES:
    # Development-only Flutter web ports; production must configure explicit origins.
    CORS_ALLOWED_ORIGIN_REGEXES = [r"^http://(localhost|127\\.0\\.0\\.1):[0-9]+$"]
CORS_ALLOW_CREDENTIALS = False

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "drf_spectacular",
    "drf_spectacular_sidecar",
    "rest_framework_simplejwt.token_blacklist",
    "apps.core",
    "apps.identity",
    "apps.tenancy",
    "apps.audit",
    "apps.locations",
    "apps.network",
    "apps.fleet",
    "apps.workforce",
    "apps.scheduling",
    "apps.passengers",
    "apps.bookings",
    "apps.fares",
    "apps.ticketing",
    "apps.boarding",
    "apps.cargo",
    "apps.payments",
    "apps.operations",
    "apps.offline",
    "apps.notifications",
    "apps.feedback",
    "apps.subscriptions",
    "apps.branding",
    "apps.media_channel",
    "apps.reference_data",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

if os.getenv("DJANGO_DB_ENGINE", "postgresql") == "sqlite":
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.getenv("POSTGRES_DB", "hbt"),
            "USER": os.getenv("POSTGRES_USER", "hbt"),
            "PASSWORD": env_or_file(
                "POSTGRES_PASSWORD", "change-me-for-local-development"
            ),
            "HOST": os.getenv("POSTGRES_HOST", "localhost"),
            "PORT": os.getenv("POSTGRES_PORT", "5432"),
            "CONN_MAX_AGE": 60,
            "CONN_HEALTH_CHECKS": True,
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": (
            "django.contrib.auth.password_validation."
            "UserAttributeSimilarityValidator"
        )
    },
    {
        "NAME": (
            "django.contrib.auth.password_validation.MinimumLengthValidator"
        )
    },
    {
        "NAME": (
            "django.contrib.auth.password_validation.CommonPasswordValidator"
        )
    },
    {
        "NAME": (
            "django.contrib.auth.password_validation.NumericPasswordValidator"
        )
    },
]

LANGUAGE_CODE = "my"
TIME_ZONE = "Asia/Yangon"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"
PRIVATE_MEDIA_ROOT = BASE_DIR / "private_media"
PAYMENT_UPLOAD_MAX_BYTES = 10 * 1024 * 1024
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
AUTH_USER_MODEL = "identity.User"

API_RENDERER_CLASSES = [
    "rest_framework.renderers.JSONRenderer",
]
API_AUTHENTICATION_CLASSES = [
    "rest_framework_simplejwt.authentication.JWTAuthentication",
]
if DEBUG:
    API_RENDERER_CLASSES.append(
        "rest_framework.renderers.BrowsableAPIRenderer"
    )
    API_AUTHENTICATION_CLASSES.append(
        "rest_framework.authentication.SessionAuthentication"
    )

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": API_AUTHENTICATION_CLASSES,
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_RENDERER_CLASSES": API_RENDERER_CLASSES,
    "DEFAULT_VERSIONING_CLASS": "rest_framework.versioning.URLPathVersioning",
    "DEFAULT_VERSION": "v1",
    "ALLOWED_VERSIONS": ["v1"],
    "EXCEPTION_HANDLER": "apps.core.exceptions.audit_exception_handler",
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": os.getenv("API_ANON_RATE", "120/min"),
        "user": os.getenv("API_USER_RATE", "1200/min"),
    },
}

SPECTACULAR_SETTINGS = {
    "TITLE": "HBT API",
    "DESCRIPTION": (
        "Myanmar-first intercity express bus SaaS API for HBT Passenger and "
        "HBT Business."
    ),
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "SWAGGER_UI_DIST": "SIDECAR",
    "SWAGGER_UI_FAVICON_HREF": "SIDECAR",
    "REDOC_DIST": "SIDECAR",
    "COMPONENT_SPLIT_REQUEST": True,
    "SORT_OPERATIONS": True,
    "ENUM_NAME_OVERRIDES": {
        "FeedbackStatus": "apps.feedback.models.Feedback.Status",
        "BookingStatus": "apps.bookings.models.Booking.Status",
        "PassengerStatus": "apps.passengers.models.Passenger.Status",
        "OrganizationStatus": "apps.tenancy.models.Organization.Status",
        "LocationOperationalStatus": "apps.locations.models.OperationalStatus",
        "BoardingValidationMethod": "apps.boarding.models.BoardingRecord.Method",
        "BookingChannel": "apps.bookings.models.Booking.Channel",
        "MediaCampaignKind": "apps.media_channel.models.MediaCampaign.Kind",
        "TripStatus": "apps.scheduling.models.Trip.Status",
        "CargoShipmentStatus": "apps.cargo.models.CargoShipment.Status",
        "PassengerCategory": "apps.passengers.models.Passenger.Category",
    },
}

from datetime import timedelta

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
}

SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_SSL_REDIRECT = (
    os.getenv("DJANGO_SECURE_SSL_REDIRECT", "false").lower()
    in {"1", "true", "yes", "on"}
)
SECURE_HSTS_SECONDS = int(os.getenv("DJANGO_SECURE_HSTS_SECONDS", "0"))
SECURE_HSTS_INCLUDE_SUBDOMAINS = SECURE_HSTS_SECONDS > 0
SECURE_HSTS_PRELOAD = (
    os.getenv("DJANGO_SECURE_HSTS_PRELOAD", "false").lower()
    in {"1", "true", "yes", "on"}
)
MALWARE_SCAN_COMMAND = os.getenv("MALWARE_SCAN_COMMAND", "")
MALWARE_SCAN_REQUIRED = (
    os.getenv("MALWARE_SCAN_REQUIRED", str(not DEBUG)).lower()
    in {"1", "true", "yes", "on"}
)
MALWARE_SCAN_TIMEOUT_SECONDS = int(
    os.getenv("MALWARE_SCAN_TIMEOUT_SECONDS", "30")
)
SECURE_REFERRER_POLICY = "same-origin"
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
SECURE_PROXY_SSL_HEADER = (
    ("HTTP_X_FORWARDED_PROTO", "https")
    if os.getenv("DJANGO_TRUST_PROXY_SSL_HEADER", "false").lower()
    in {"1", "true", "yes", "on"}
    else None
)

# -- Structured logging ----------------------------------------------
# JSON-ish console output for production; human-readable in DEBUG.
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {
            "format": (
                '{"timestamp": "%(asctime)s", "level": "%(levelname)s", '
                '"logger": "%(name)s", "message": "%(message)s"}'
            ),
        },
        "verbose": {
            "format": "%(asctime)s %(levelname)s %(name)s %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "json" if not DEBUG else "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": os.getenv("DJANGO_LOG_LEVEL", "INFO"),
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": os.getenv("DJANGO_LOG_LEVEL", "INFO"),
            "propagate": False,
        },
        "django.request": {
            "handlers": ["console"],
            "level": "WARNING",
            "propagate": False,
        },
        "apps": {
            "handlers": ["console"],
            "level": os.getenv("DJANGO_LOG_LEVEL", "INFO"),
            "propagate": False,
        },
    },
}

# -- API pagination (bounded list responses) -------------------------
REST_FRAMEWORK.setdefault("DEFAULT_PAGINATION_CLASS",
    "rest_framework.pagination.PageNumberPagination")
REST_FRAMEWORK.setdefault("PAGE_SIZE", int(os.getenv("API_PAGE_SIZE", "100")))
