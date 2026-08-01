from django.core.exceptions import ValidationError as DjangoValidationError
from django.core import signing
from django.db.models import Sum
from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from apps.scheduling.models import Trip

from .models import (
    CargoCategory,
    CargoChargeLine,
    CargoContact,
    CargoCustodyEvent,
    CargoItem,
    CargoPricingRule,
    CargoShipment,
)
from .services import (
    accept_shipment,
    assign_trip,
    mark_allocation_paid,
    transition_shipment,
)


class CargoContactSerializer(serializers.ModelSerializer):
    nrc_normalized = serializers.CharField(
        write_only=True, required=False, allow_blank=True, max_length=100
    )
    masked_nrc = serializers.SerializerMethodField()
    masked_nrc_en = serializers.SerializerMethodField()

    class Meta:
        model = CargoContact
        fields = (
            "id", "contact_code", "name", "phone_number", "nrc_normalized",
            "masked_nrc", "masked_nrc_en", "nrc_verification_status",
            "contact_type", "identity_type",
            "identity_reference", "identity_missing_reason", "address",
            "notes", "usage_count", "last_used_at", "active", "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id", "masked_nrc", "usage_count", "last_used_at",
            "nrc_verification_status",
            "created_at", "updated_at",
        )
        extra_kwargs = {"nrc_normalized": {"write_only": True}}

    @extend_schema_field(serializers.CharField)
    def get_masked_nrc(self, obj):
        return obj.masked_nrc

    @extend_schema_field(serializers.CharField)
    def get_masked_nrc_en(self, obj):
        return obj.masked_nrc_en

    def validate_nrc_normalized(self, value):
        return value

    def validate(self, attrs):
        identity_type = attrs.get(
            "identity_type",
            getattr(self.instance, "identity_type", CargoContact.IdentityType.NOT_PROVIDED),
        )
        nrc_supplied = "nrc_normalized" in attrs
        nrc = attrs.get("nrc_normalized", "")
        has_nrc = (
            bool(nrc)
            if nrc_supplied
            else bool(getattr(self.instance, "nrc_blind_index", ""))
        )
        reason = attrs.get(
            "identity_missing_reason",
            getattr(self.instance, "identity_missing_reason", ""),
        )
        if identity_type == CargoContact.IdentityType.NRC and not has_nrc:
            raise serializers.ValidationError(
                {"nrc_normalized": "NRC value is required for NRC identity."}
            )
        if identity_type == CargoContact.IdentityType.NOT_PROVIDED and not reason:
            raise serializers.ValidationError(
                {"identity_missing_reason": "Reason is required when identity is absent."}
            )
        if "nrc_normalized" in attrs:
            instance = self.instance or CargoContact(
                organization=self.context["organization"]
            )
            try:
                instance.set_nrc(attrs["nrc_normalized"])
            except ValueError as exc:
                raise serializers.ValidationError(
                    {"nrc_normalized": str(exc)}
                ) from exc
            attrs.update(
                {
                    "nrc_state_region": instance.nrc_state_region,
                    "nrc_township": instance.nrc_township,
                    "nrc_citizenship_type": instance.nrc_citizenship_type,
                    "nrc_serial": instance.nrc_serial,
                    "encrypted_nrc": instance.encrypted_nrc,
                    "nrc_blind_index": instance.nrc_blind_index,
                    "nrc_verification_status": instance.nrc_verification_status,
                    "nrc_review_reason": instance.nrc_review_reason,
                }
            )
            attrs.pop("nrc_normalized", None)
        return attrs


class CargoCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = CargoCategory
        fields = (
            "id", "code", "name", "name_myanmar",
            "default_pricing_method", "default_rate", "prohibited", "active",
            "created_at", "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class CargoPricingRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = CargoPricingRule
        fields = (
            "id", "category", "code", "name", "method", "base_weight_kg",
            "base_price", "excess_rate_per_kg", "active", "created_by",
            "created_at", "updated_at",
        )
        read_only_fields = ("id", "created_by", "created_at", "updated_at")

    def create(self, data):
        rule = CargoPricingRule(
            organization=self.context["organization"],
            created_by=self.context["request"].user,
            **data,
        )
        try:
            rule.full_clean()
            rule.save()
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc
        return rule


class CargoItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = CargoItem
        fields = (
            "id", "category", "category_snapshot", "description", "quantity",
            "weight_kg", "pricing_method", "unit_price", "rate_per_kg",
            "pricing_rule", "pricing_rule_snapshot", "manual_amount",
            "base_amount", "notice", "manual_pricing_reason", "priced_by",
            "priced_at",
        )
        read_only_fields = (
            "id", "category_snapshot", "pricing_rule_snapshot", "base_amount",
            "priced_by", "priced_at",
        )


class CargoChargeLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = CargoChargeLine
        fields = (
            "id", "code", "label", "kind", "amount", "sequence",
            "payout_recipient_name", "payout_recipient_contact",
            "payout_paid", "payout_paid_at", "payout_paid_by",
        )
        read_only_fields = (
            "id", "payout_paid", "payout_paid_at", "payout_paid_by",
        )


class CargoCustodyEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CargoCustodyEvent
        fields = (
            "id", "from_status", "to_status", "trip", "terminal_operation",
            "performed_by", "occurred_at", "notes", "evidence", "offline",
            "verification_method", "verification_reference_masked",
            "recipient_name", "client_event_id", "created_at",
        )


class CargoShipmentSerializer(serializers.ModelSerializer):
    qr_payload = serializers.SerializerMethodField()
    custody_events = CargoCustodyEventSerializer(many=True, read_only=True)
    items = CargoItemSerializer(many=True, required=False)
    charge_lines = CargoChargeLineSerializer(many=True, required=False)
    confirmed_paid_amount = serializers.SerializerMethodField()
    outstanding_amount = serializers.SerializerMethodField()
    payment_status = serializers.SerializerMethodField()
    pricing_breakdown = serializers.SerializerMethodField()

    class Meta:
        model = CargoShipment
        fields = (
            "id", "organization", "shipment_number", "tracking_code",
            "qr_payload", "sender", "receiver", "origin_terminal",
            "destination_terminal", "assigned_trip", "status", "item_category",
            "acceptance_channel", "accepting_counter",
            "description", "piece_count", "weight_kg", "weight_source",
            "length_cm", "width_cm", "height_cm", "packaging_condition",
            "inspection_notes", "liability_acknowledged",
            "declared_value", "pricing_method", "rate_per_kg", "manual_charge",
            "additional_charge", "discount_amount", "total_charge", "currency",
            "accepted_by", "accepted_at", "expected_pickup_date",
            "actual_delivery_at", "pickup_location_text", "pickup_latitude",
            "pickup_longitude", "acceptance_device_id",
            "client_request_id", "notes", "custody_events", "created_at",
            "manual_pricing_reason",
            "updated_at", "items", "charge_lines",
            "confirmed_paid_amount", "outstanding_amount", "payment_status",
            "pricing_breakdown",
        )
        read_only_fields = (
            "id", "organization", "tracking_code", "qr_payload",
            "assigned_trip", "status", "accepted_by", "accepted_at",
            "actual_delivery_at", "total_charge",
            "custody_events", "created_at", "updated_at",
        )

    @extend_schema_field(serializers.CharField)
    def get_qr_payload(self, obj):
        token = signing.dumps(
            {"tracking_code": str(obj.tracking_code)},
            salt="hbt.cargo.tracking.v1",
            compress=True,
        )
        return f"HBT:CARGO:V1:{token}"

    @extend_schema_field(serializers.DecimalField(max_digits=14, decimal_places=2))
    def get_confirmed_paid_amount(self, obj):
        return (
            obj.payment_records.filter(status="confirmed").aggregate(
                total=Sum("amount")
            )["total"]
            or 0
        )

    @extend_schema_field(serializers.DecimalField(max_digits=14, decimal_places=2))
    def get_outstanding_amount(self, obj):
        return max(obj.total_charge - self.get_confirmed_paid_amount(obj), 0)

    @extend_schema_field(serializers.CharField)
    def get_payment_status(self, obj):
        paid = self.get_confirmed_paid_amount(obj)
        if paid <= 0:
            return "unpaid"
        if paid < obj.total_charge:
            return "partially_paid"
        return "paid"

    @extend_schema_field(serializers.DictField)
    def get_pricing_breakdown(self, obj):
        items = list(obj.items.all())
        lines = list(obj.charge_lines.all())
        item_base = sum(item.base_amount for item in items) if items else (
            obj.manual_charge
            if obj.pricing_method != CargoShipment.PricingMethod.PER_KG
            else (obj.weight_kg or 0) * (obj.rate_per_kg or 0)
        )
        charges = sum(
            line.amount
            for line in lines
            if line.kind == CargoChargeLine.Kind.CHARGE
        )
        discounts = sum(
            line.amount
            for line in lines
            if line.kind == CargoChargeLine.Kind.DISCOUNT
        )
        allocations = sum(
            line.amount
            for line in lines
            if line.kind == CargoChargeLine.Kind.ALLOCATION
        )
        return {
            "pricing_method": obj.pricing_method,
            "item_base_amount": item_base or 0,
            "additional_charges": charges if lines else obj.additional_charge,
            "discounts": discounts if lines else obj.discount_amount,
            "internal_allocations": allocations,
            "customer_total": obj.total_charge,
        }

    def create(self, validated_data):
        items = validated_data.pop("items", [])
        charge_lines = validated_data.pop("charge_lines", [])
        try:
            return accept_shipment(
                organization=self.context["organization"],
                actor=self.context["request"].user,
                items=items,
                charge_lines=charge_lines,
                **validated_data,
            )
        except DjangoValidationError as exc:
            if hasattr(exc, "message_dict"):
                raise serializers.ValidationError(exc.message_dict) from exc
            raise serializers.ValidationError(exc.messages) from exc


class CargoAssignTripSerializer(serializers.Serializer):
    trip = serializers.PrimaryKeyRelatedField(queryset=Trip.objects.all())
    notes = serializers.CharField(required=False, allow_blank=True)

    def create(self, data):
        try:
            return assign_trip(
                shipment=self.context["shipment"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class CargoTransitionSerializer(serializers.Serializer):
    to_status = serializers.ChoiceField(choices=CargoShipment.Status.choices)
    notes = serializers.CharField(required=False, allow_blank=True)
    evidence = serializers.JSONField(required=False)
    offline = serializers.BooleanField(default=False)
    client_event_id = serializers.UUIDField(required=False)

    def create(self, data):
        try:
            return transition_shipment(
                shipment=self.context["shipment"],
                actor=self.context["request"].user,
                **data,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class CargoAllocationPaidSerializer(serializers.Serializer):
    def create(self, data):
        try:
            return mark_allocation_paid(
                charge_line=self.context["charge_line"],
                actor=self.context["request"].user,
            )
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class CargoQrResolveSerializer(serializers.Serializer):
    qr_payload = serializers.CharField()


class CargoManifestSerializer(serializers.Serializer):
    trip_id = serializers.UUIDField()
    trip_number = serializers.CharField()
    status = serializers.CharField()
    shipment_count = serializers.IntegerField()
    piece_count = serializers.IntegerField()
    weight_kg = serializers.DecimalField(max_digits=14, decimal_places=3)
    total_charge = serializers.DecimalField(max_digits=14, decimal_places=2)
    shipments = CargoShipmentSerializer(many=True)


class CargoReportChannelSerializer(serializers.Serializer):
    acceptance_channel = serializers.CharField()
    shipment_count = serializers.IntegerField()
    total_charge = serializers.DecimalField(max_digits=14, decimal_places=2)


class CargoOwnerReportSerializer(serializers.Serializer):
    shipment_count = serializers.IntegerField()
    piece_count = serializers.IntegerField()
    weight_kg = serializers.DecimalField(max_digits=14, decimal_places=3)
    total_charge = serializers.DecimalField(max_digits=14, decimal_places=2)
    confirmed_payment = serializers.DecimalField(max_digits=14, decimal_places=2)
    outstanding_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    by_acceptance_channel = CargoReportChannelSerializer(many=True)
