from django.urls import path

from .views import (
    OrganizationSubscriptionInvoiceListView,
    OrganizationSubscriptionView,
    PublicPlanListView,
    SubscriptionInvoiceIssueView,
    SubscriptionPaymentDecisionView,
    SubscriptionPaymentSubmitView,
    SubscriptionPlanChangeView,
    SubscriptionSuspendView,
)


urlpatterns = [
    path("public/subscription-plans/", PublicPlanListView.as_view()),
    path(
        "organizations/<uuid:organization_id>/subscription/",
        OrganizationSubscriptionView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/subscription/invoices/",
        OrganizationSubscriptionInvoiceListView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/subscription/invoices/issue/",
        SubscriptionInvoiceIssueView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/subscription/invoices/"
        "<uuid:invoice_id>/submit-payment/",
        SubscriptionPaymentSubmitView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/subscription/invoices/"
        "<uuid:invoice_id>/decision/",
        SubscriptionPaymentDecisionView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/subscription/change-plan/",
        SubscriptionPlanChangeView.as_view(),
    ),
    path(
        "organizations/<uuid:organization_id>/subscription/suspend/",
        SubscriptionSuspendView.as_view(),
    ),
]
