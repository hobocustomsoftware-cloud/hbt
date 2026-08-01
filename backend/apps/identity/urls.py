from django.urls import path

from .views import (
    LoginView,
    LogoutView,
    MeView,
    MyPrivacyRequestCancelView,
    MyPrivacyRequestListCreateView,
    MyDataExportView,
    PlatformPrivacyRequestActionView,
    PlatformPrivacyRequestListView,
    RefreshView,
    RegistrationView,
)

app_name = "identity"

urlpatterns = [
    path("register/", RegistrationView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("token/refresh/", RefreshView.as_view(), name="token-refresh"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("me/", MeView.as_view(), name="me"),
    path("me/data-export/", MyDataExportView.as_view(), name="my-data-export"),
    path(
        "me/privacy-requests/",
        MyPrivacyRequestListCreateView.as_view(),
        name="my-privacy-requests",
    ),
    path(
        "me/privacy-requests/<uuid:request_id>/cancel/",
        MyPrivacyRequestCancelView.as_view(),
        name="my-privacy-request-cancel",
    ),
    path(
        "platform/privacy-requests/",
        PlatformPrivacyRequestListView.as_view(),
        name="platform-privacy-requests",
    ),
    path(
        "platform/privacy-requests/<uuid:request_id>/action/",
        PlatformPrivacyRequestActionView.as_view(),
        name="platform-privacy-request-action",
    ),
]
