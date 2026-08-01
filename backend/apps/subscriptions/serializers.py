from decimal import Decimal

from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from .models import SubscriptionInvoice, SubscriptionPlan, TenantSubscription
from .services import (
    change_subscription_plan,
    issue_subscription_invoice,
    submit_subscription_payment,
    suspend_subscription,
    verify_subscription_payment,
)


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    monthly_tax_amount = serializers.SerializerMethodField()
    monthly_total = serializers.SerializerMethodField()
    annual_tax_amount = serializers.SerializerMethodField()
    annual_total = serializers.SerializerMethodField()

    class Meta:
        model = SubscriptionPlan
        fields = "__all__"

    @staticmethod
    def _tax(amount, rate):
        return (amount * rate / Decimal("100")).quantize(Decimal("0.01"))

    @extend_schema_field(serializers.DecimalField(max_digits=14, decimal_places=2))
    def get_monthly_tax_amount(self, obj):
        return self._tax(obj.monthly_price, obj.tax_rate)

    @extend_schema_field(serializers.DecimalField(max_digits=14, decimal_places=2))
    def get_monthly_total(self, obj):
        return obj.monthly_price + self.get_monthly_tax_amount(obj)

    @extend_schema_field(serializers.DecimalField(max_digits=14, decimal_places=2))
    def get_annual_tax_amount(self, obj):
        return self._tax(obj.annual_price, obj.tax_rate)

    @extend_schema_field(serializers.DecimalField(max_digits=14, decimal_places=2))
    def get_annual_total(self, obj):
        return obj.annual_price + self.get_annual_tax_amount(obj)


class TenantSubscriptionSerializer(serializers.ModelSerializer):
    plan = SubscriptionPlanSerializer(read_only=True)
    effective_entitlements = serializers.JSONField(read_only=True)
    effective_limits = serializers.JSONField(read_only=True)

    class Meta:
        model = TenantSubscription
        fields = "__all__"


class SubscriptionInvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionInvoice
        fields = "__all__"


class SubscriptionInvoiceIssueSerializer(serializers.Serializer):
    invoice_number = serializers.CharField(max_length=64)

    def create(self, data):
        return issue_subscription_invoice(
            subscription=self.context["subscription"],
            actor=self.context["request"].user,
            **data,
        )


class SubscriptionPaymentSubmitSerializer(serializers.Serializer):
    reference = serializers.CharField(max_length=160)
    evidence_note = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        return submit_subscription_payment(
            invoice=self.context["invoice"],
            actor=self.context["request"].user,
            **data,
        )


class SubscriptionPaymentDecisionSerializer(serializers.Serializer):
    approve = serializers.BooleanField()
    reason = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        return verify_subscription_payment(
            invoice=self.context["invoice"],
            actor=self.context["request"].user,
            **data,
        )


class SubscriptionPlanChangeSerializer(serializers.Serializer):
    plan = serializers.PrimaryKeyRelatedField(
        queryset=SubscriptionPlan.objects.filter(is_active=True)
    )
    immediate = serializers.BooleanField(default=False)

    def create(self, data):
        return change_subscription_plan(
            subscription=self.context["subscription"],
            actor=self.context["request"].user,
            **data,
        )


class SubscriptionSuspendSerializer(serializers.Serializer):
    reason = serializers.CharField()

    def create(self, data):
        return suspend_subscription(
            subscription=self.context["subscription"],
            actor=self.context["request"].user,
            **data,
        )
