from decimal import Decimal
from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.identity.models import User
from apps.tenancy.models import Organization, Tenant

from ..models import SubscriptionInvoice, SubscriptionPlan, TenantSubscription
from ..services import (
    issue_subscription_invoice,
    process_subscription_deadlines,
    submit_subscription_payment,
    verify_subscription_payment,
)


class SubscriptionPlanApiTests(TestCase):
    def test_public_catalog_exposes_taxed_prices_and_plan_entitlements(self):
        response = APIClient().get("/api/v1/public/subscription-plans/")
        self.assertEqual(response.status_code, 200)
        plans = {item["code"]: item for item in response.data["results"]}
        self.assertEqual(set(plans), {"starter", "growth", "pro", "enterprise"})
        self.assertEqual(plans["starter"]["monthly_total"], Decimal("52500.00"))
        self.assertFalse(plans["starter"]["entitlements"]["media_channel"])
        self.assertTrue(plans["growth"]["entitlements"]["media_channel"])
        self.assertTrue(plans["enterprise"]["contact_sales"])
        self.assertEqual(SubscriptionPlan.objects.count(), 4)


class SubscriptionLifecycleTests(TestCase):
    def setUp(self):
        self.creator = User.objects.create_user(
            phone_number="+959700000001", password="Strong-pass-123"
        )
        self.verifier = User.objects.create_user(
            phone_number="+959700000002", password="Strong-pass-123"
        )
        tenant = Tenant.objects.create(name="Subscriber", slug="subscriber")
        Organization.objects.create(
            tenant=tenant,
            legal_name="Subscriber Express",
            display_name="Subscriber",
            status=Organization.Status.ACTIVE,
        )
        now = timezone.now()
        self.subscription = TenantSubscription.objects.create(
            tenant=tenant,
            plan=SubscriptionPlan.objects.get(code="starter"),
            status=TenantSubscription.Status.TRIAL,
            billing_cycle=TenantSubscription.BillingCycle.MONTHLY,
            starts_at=now,
            current_period_ends_at=now + timedelta(days=30),
            trial_ends_at=now + timedelta(days=30),
            grace_ends_at=now + timedelta(days=37),
            changed_by=self.creator,
        )

    def test_manual_subscription_payment_activates_and_extends_period(self):
        invoice = issue_subscription_invoice(
            subscription=self.subscription,
            actor=self.creator,
            invoice_number="SUB-INV-1",
        )
        self.assertEqual(invoice.total_amount, Decimal("52500.00"))
        invoice = submit_subscription_payment(
            invoice=invoice,
            actor=self.creator,
            reference="BANK-REFERENCE-1",
        )
        self.assertEqual(
            invoice.status, SubscriptionInvoice.Status.PAYMENT_SUBMITTED
        )
        invoice = verify_subscription_payment(
            invoice=invoice,
            actor=self.verifier,
            approve=True,
        )
        self.subscription.refresh_from_db()
        self.assertEqual(invoice.status, SubscriptionInvoice.Status.PAID)
        self.assertEqual(
            self.subscription.status, TenantSubscription.Status.ACTIVE
        )

    def test_expired_grace_suspends_without_deleting_data(self):
        self.subscription.status = TenantSubscription.Status.ACTIVE
        self.subscription.current_period_ends_at = timezone.now() - timedelta(days=8)
        self.subscription.grace_ends_at = timezone.now() - timedelta(days=1)
        self.subscription.save()
        changed = process_subscription_deadlines()
        self.subscription.refresh_from_db()
        self.assertEqual(changed, 1)
        self.assertEqual(
            self.subscription.status, TenantSubscription.Status.SUSPENDED
        )
        self.assertTrue(
            Organization.objects.filter(tenant=self.subscription.tenant).exists()
        )
