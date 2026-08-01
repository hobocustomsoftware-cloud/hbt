from rest_framework import serializers

from .models import FareQuote, FareQuoteLine, FareRule, Promotion
from .services import create_fare_quote, lock_fare_quote, override_quote_line


class FareRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = FareRule
        exclude = ("organization", "created_by")
        read_only_fields = ("id", "created_at", "updated_at")


class FareQuoteLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = FareQuoteLine
        fields = "__all__"
        read_only_fields = (
            "id", "quote", "booking_passenger", "fare_rule", "base_fare",
            "discount_amount", "tax_amount", "total_amount", "overridden",
            "override_reason", "overridden_by", "rule_snapshot", "created_at",
            "updated_at",
        )


class FareQuoteSerializer(serializers.ModelSerializer):
    lines = FareQuoteLineSerializer(many=True, read_only=True)

    class Meta:
        model = FareQuote
        fields = "__all__"
        read_only_fields = (
            "id", "booking", "version", "status", "currency", "subtotal",
            "discount_amount", "tax_amount", "total_amount", "expires_at",
            "locked_at", "created_by", "snapshot", "lines", "created_at",
            "updated_at",
        )


class FareQuoteCreateSerializer(serializers.Serializer):
    coupon_code = serializers.CharField(
        max_length=64, required=False, allow_blank=True
    )


class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        exclude = ("organization", "created_by")
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_coupon_code(self, value):
        value = value.strip().upper()
        if not value:
            return ""
        organization = self.context["organization"]
        queryset = Promotion.objects.filter(
            organization=organization, coupon_code__iexact=value
        )
        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError(
                "This coupon code already exists for the organization."
            )
        return value


class FareOverrideSerializer(serializers.Serializer):
    base_fare = serializers.DecimalField(max_digits=12, decimal_places=2)
    reason = serializers.CharField()

    def create(self, data):
        return override_quote_line(
            line=self.context["line"],
            actor=self.context["request"].user,
            **data,
        )
