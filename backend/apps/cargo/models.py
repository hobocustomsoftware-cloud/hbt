import uuid

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel
from apps.core.field_crypto import encrypt_nrc, nrc_blind_index
from apps.locations.models import CompanyTerminalOperation
from apps.reference_data.nrc import (
    mask_rendered_nrc,
    parse_nrc,
    render_nrc_from_components,
)
from apps.scheduling.models import Trip
from apps.tenancy.models import Organization


class CargoContact(TimeStampedModel):
    class Type(models.TextChoices):
        INDIVIDUAL = "individual", "Individual"
        BUSINESS = "business", "Business customer"
        AGENT = "agent", "Agent"

    class IdentityType(models.TextChoices):
        NRC = "nrc", "Myanmar NRC"
        PASSPORT = "passport", "Passport"
        OTHER = "other", "Other identity"
        NOT_PROVIDED = "not_provided", "Not provided"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="cargo_contacts"
    )
    contact_code = models.CharField(max_length=50)
    name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=32)
    contact_type = models.CharField(
        max_length=16, choices=Type.choices, default=Type.INDIVIDUAL
    )
    identity_type = models.CharField(
        max_length=16,
        choices=IdentityType.choices,
        default=IdentityType.NOT_PROVIDED,
    )
    nrc_state_region = models.ForeignKey(
        "reference_data.NRCStateRegion",
        on_delete=models.PROTECT,
        related_name="cargo_contacts",
        null=True,
        blank=True,
    )
    nrc_township = models.ForeignKey(
        "reference_data.NRCTownship",
        on_delete=models.PROTECT,
        related_name="cargo_contacts",
        null=True,
        blank=True,
    )
    nrc_citizenship_type = models.ForeignKey(
        "reference_data.NRCCitizenshipType",
        on_delete=models.PROTECT,
        related_name="cargo_contacts",
        null=True,
        blank=True,
    )
    nrc_serial = models.CharField(max_length=6, blank=True)
    encrypted_nrc = models.TextField(blank=True)
    nrc_blind_index = models.CharField(max_length=64, blank=True)
    nrc_verification_status = models.CharField(
        max_length=16, default="not_provided"
    )
    nrc_review_reason = models.CharField(max_length=255, blank=True)
    identity_reference = models.CharField(max_length=100, blank=True)
    identity_missing_reason = models.CharField(max_length=255, blank=True)
    address = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    usage_count = models.PositiveIntegerField(default=0)
    last_used_at = models.DateTimeField(null=True, blank=True)
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "cargo_contact"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "contact_code"],
                name="unique_cargo_contact_code_per_org",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "phone_number"],
                name="cargo_contact_phone_idx",
            ),
        ]

    def set_nrc(self, value):
        if not value:
            self.clear_nrc()
            return
        parsed = parse_nrc(value)
        self.nrc_state_region = parsed.state_region
        self.nrc_township = parsed.township
        self.nrc_citizenship_type = parsed.citizenship_type
        self.nrc_serial = parsed.serial_ascii
        self.encrypted_nrc = encrypt_nrc(parsed.canonical_en)
        self.nrc_blind_index = nrc_blind_index(parsed.canonical_en)
        self.nrc_verification_status = "validated"
        self.nrc_review_reason = ""

    def clear_nrc(self):
        self.nrc_state_region = None
        self.nrc_township = None
        self.nrc_citizenship_type = None
        self.nrc_serial = ""
        self.encrypted_nrc = ""
        self.nrc_blind_index = ""
        self.nrc_verification_status = "not_provided"
        self.nrc_review_reason = ""

    @property
    def parsed_nrc(self):
        return render_nrc_from_components(
            self.nrc_state_region,
            self.nrc_township,
            self.nrc_citizenship_type,
            self.nrc_serial,
        )

    @property
    def masked_nrc(self):
        return mask_rendered_nrc(self.parsed_nrc, "mm")

    @property
    def masked_nrc_en(self):
        return mask_rendered_nrc(self.parsed_nrc, "en")



class CargoCategory(TimeStampedModel):
    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="cargo_categories"
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=150)
    name_myanmar = models.CharField(max_length=150, blank=True)
    default_pricing_method = models.CharField(
        max_length=12,
        choices=(
            ("manual", "Manual total"),
            ("per_kg", "Per kilogram"),
            ("itemized", "Per item / station breakdown"),
            ("tiered_kg", "Base weight plus decimal excess rate"),
        ),
        default="manual",
    )
    default_rate = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    prohibited = models.BooleanField(default=False)
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "cargo_category"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_cargo_category_code_per_org",
            )
        ]


class CargoPricingRule(TimeStampedModel):
    class Method(models.TextChoices):
        TIERED_KG = "tiered_kg", "Base weight plus decimal excess rate"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="cargo_pricing_rules"
    )
    category = models.ForeignKey(
        CargoCategory, on_delete=models.PROTECT, null=True, blank=True,
        related_name="pricing_rules"
    )
    code = models.SlugField(max_length=50)
    name = models.CharField(max_length=150)
    method = models.CharField(
        max_length=16, choices=Method.choices, default=Method.TIERED_KG
    )
    base_weight_kg = models.DecimalField(max_digits=10, decimal_places=3)
    base_price = models.DecimalField(max_digits=12, decimal_places=2)
    excess_rate_per_kg = models.DecimalField(max_digits=12, decimal_places=2)
    active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT,
        related_name="created_cargo_pricing_rules"
    )

    class Meta:
        db_table = "cargo_pricing_rule"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "code"],
                name="unique_cargo_pricing_rule_code_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(base_weight_kg__gt=0)
                & models.Q(base_price__gte=0)
                & models.Q(excess_rate_per_kg__gte=0),
                name="cargo_pricing_rule_values_valid",
            ),
        ]

    def clean(self):
        if self.category_id and self.category.organization_id != self.organization_id:
            raise ValidationError("Cargo category belongs to another organization.")


class CargoPolicy(TimeStampedModel):
    organization = models.OneToOneField(
        Organization, on_delete=models.PROTECT, related_name="cargo_policy"
    )
    max_weight_kg = models.DecimalField(
        max_digits=10, decimal_places=3, null=True, blank=True
    )
    max_declared_value = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    max_length_cm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    max_width_cm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    max_height_cm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    prohibited_categories = models.JSONField(default=list, blank=True)
    require_sender_nrc = models.BooleanField(default=False)
    require_receiver_nrc = models.BooleanField(default=False)
    liability_text = models.TextField(blank=True)

    class Meta:
        db_table = "cargo_policy"


class CargoShipment(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        ACCEPTED = "accepted", "Accepted"
        ASSIGNED = "assigned", "Assigned"
        LOADED = "loaded", "Loaded"
        IN_TRANSIT = "in_transit", "In transit"
        ARRIVED = "arrived", "Arrived"
        READY_FOR_PICKUP = "ready_pickup", "Ready for pickup"
        HANDED_OVER = "handed_over", "Handed over"
        REFUSED = "refused", "Refused"
        CANCELLED = "cancelled", "Cancelled"
        DAMAGED = "damaged", "Damaged"
        LOST = "lost", "Lost"
        RETURNED = "returned", "Returned"

    class PricingMethod(models.TextChoices):
        MANUAL = "manual", "Manual total"
        PER_KG = "per_kg", "Per kilogram"
        ITEMIZED = "itemized", "Per item / station breakdown"
        TIERED_KG = "tiered_kg", "Base weight plus decimal excess rate"
        MIXED = "mixed", "Mixed pricing"

    class WeightSource(models.TextChoices):
        DECLARED = "declared", "Declared"
        MEASURED = "measured", "Measured"

    class AcceptanceChannel(models.TextChoices):
        COUNTER = "counter", "Counter"
        TERMINAL = "terminal", "Terminal cargo desk"
        ROADSIDE = "roadside", "Roadside"
        CONDUCTOR = "conductor", "Conductor"
        AGENT = "agent", "Agent"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="cargo_shipments"
    )
    shipment_number = models.CharField(max_length=64)
    tracking_code = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    sender = models.ForeignKey(
        CargoContact, on_delete=models.PROTECT, related_name="sent_shipments"
    )
    receiver = models.ForeignKey(
        CargoContact, on_delete=models.PROTECT, related_name="received_shipments"
    )
    origin_terminal = models.ForeignKey(
        CompanyTerminalOperation,
        on_delete=models.PROTECT,
        related_name="origin_cargo_shipments",
    )
    destination_terminal = models.ForeignKey(
        CompanyTerminalOperation,
        on_delete=models.PROTECT,
        related_name="destination_cargo_shipments",
    )
    assigned_trip = models.ForeignKey(
        Trip,
        on_delete=models.PROTECT,
        related_name="cargo_shipments",
        null=True,
        blank=True,
    )
    acceptance_channel = models.CharField(
        max_length=16,
        choices=AcceptanceChannel.choices,
        default=AcceptanceChannel.COUNTER,
    )
    accepting_counter = models.ForeignKey(
        "locations.SalesCounter",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="accepted_cargo_shipments",
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.DRAFT
    )
    item_category = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    piece_count = models.PositiveIntegerField()
    weight_kg = models.DecimalField(
        max_digits=10, decimal_places=3, null=True, blank=True
    )
    weight_source = models.CharField(
        max_length=12, choices=WeightSource.choices, blank=True
    )
    length_cm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    width_cm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    height_cm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    packaging_condition = models.CharField(max_length=255, blank=True)
    inspection_notes = models.TextField(blank=True)
    liability_acknowledged = models.BooleanField(default=False)
    declared_value = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    pricing_method = models.CharField(
        max_length=12, choices=PricingMethod.choices
    )
    rate_per_kg = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    manual_charge = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    additional_charge = models.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    discount_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )
    total_charge = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="MMK")
    accepted_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="accepted_cargo_shipments",
    )
    accepted_at = models.DateTimeField(null=True, blank=True)
    actual_delivery_at = models.DateTimeField(null=True, blank=True)
    pickup_location_text = models.CharField(max_length=255, blank=True)
    pickup_latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    pickup_longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    acceptance_device_id = models.CharField(max_length=100, blank=True)
    expected_pickup_date = models.DateField(null=True, blank=True)
    client_request_id = models.UUIDField(null=True, blank=True, unique=True)
    notes = models.TextField(blank=True)
    manual_pricing_reason = models.CharField(max_length=255, blank=True)

    class Meta:
        db_table = "cargo_shipment"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "shipment_number"],
                name="unique_cargo_shipment_number_per_org",
            ),
            models.CheckConstraint(
                condition=models.Q(piece_count__gt=0),
                name="cargo_piece_count_positive",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "status", "created_at"],
                name="cargo_org_status_date_idx",
            ),
        ]

    @property
    def immutable(self):
        return self.status == self.Status.HANDED_OVER

    def clean(self):
        related = [
            self.sender.organization_id,
            self.receiver.organization_id,
            self.origin_terminal.organization_id,
            self.destination_terminal.organization_id,
        ]
        if any(value != self.organization_id for value in related):
            raise ValidationError("Cargo parties and terminals must share an organization.")
        if self.origin_terminal_id == self.destination_terminal_id:
            raise ValidationError("Origin and destination must be different.")
        if (
            self.assigned_trip_id
            and self.assigned_trip.organization_id != self.organization_id
        ):
            raise ValidationError("Assigned trip belongs to another organization.")
        if (
            self.accepting_counter_id
            and self.accepting_counter.organization_id != self.organization_id
        ):
            raise ValidationError("Accepting counter belongs to another organization.")
        if (
            self.accepting_counter_id
            and self.accepting_counter.terminal_operation_id
            != self.origin_terminal_id
        ):
            raise ValidationError(
                "Accepting counter must belong to the origin terminal operation."
            )
        if self.pricing_method == self.PricingMethod.PER_KG:
            if not self.weight_kg or not self.rate_per_kg:
                raise ValidationError("Per-kg pricing requires weight and kg rate.")
            base = self.weight_kg * self.rate_per_kg
        else:
            if self.manual_charge is None:
                raise ValidationError("Manual pricing requires a manual charge.")
            base = self.manual_charge
        expected = base + self.additional_charge - self.discount_amount
        if expected < 0 or self.total_charge != expected:
            raise ValidationError({"total_charge": "Cargo charge does not reconcile."})


class CargoItem(TimeStampedModel):
    shipment = models.ForeignKey(
        CargoShipment, on_delete=models.PROTECT, related_name="items"
    )
    category = models.ForeignKey(
        CargoCategory, on_delete=models.PROTECT, null=True, blank=True
    )
    category_snapshot = models.CharField(max_length=150)
    pricing_rule = models.ForeignKey(
        CargoPricingRule, on_delete=models.PROTECT, null=True, blank=True
    )
    pricing_rule_snapshot = models.JSONField(default=dict, blank=True)
    description = models.CharField(max_length=255, blank=True)
    quantity = models.PositiveIntegerField(default=1)
    weight_kg = models.DecimalField(
        max_digits=10, decimal_places=3, null=True, blank=True
    )
    pricing_method = models.CharField(
        max_length=12, choices=CargoShipment.PricingMethod.choices
    )
    unit_price = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    rate_per_kg = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    manual_amount = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    base_amount = models.DecimalField(max_digits=12, decimal_places=2)
    notice = models.CharField(max_length=255, blank=True)
    manual_pricing_reason = models.CharField(max_length=255, blank=True)
    priced_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="priced_cargo_items"
    )
    priced_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "cargo_item"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(quantity__gt=0),
                name="cargo_item_quantity_positive",
            ),
            models.CheckConstraint(
                condition=models.Q(base_amount__gte=0),
                name="cargo_item_base_amount_nonnegative",
            ),
        ]

    def clean(self):
        if self.category_id:
            if self.category.organization_id != self.shipment.organization_id:
                raise ValidationError("Cargo category belongs to another organization.")
            if self.category.prohibited:
                raise ValidationError("This cargo category is prohibited.")


class CargoChargeLine(TimeStampedModel):
    class Kind(models.TextChoices):
        CHARGE = "charge", "Charge"
        DISCOUNT = "discount", "Discount"
        ALLOCATION = "allocation", "Internal terminal/partner allocation"

    shipment = models.ForeignKey(
        CargoShipment, on_delete=models.PROTECT, related_name="charge_lines"
    )
    code = models.SlugField(max_length=50)
    label = models.CharField(max_length=150)
    kind = models.CharField(max_length=12, choices=Kind.choices)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    sequence = models.PositiveIntegerField(default=1)
    payout_recipient_name = models.CharField(max_length=150, blank=True)
    payout_recipient_contact = models.CharField(max_length=32, blank=True)
    payout_paid = models.BooleanField(default=False)
    payout_paid_at = models.DateTimeField(null=True, blank=True)
    payout_paid_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT, null=True, blank=True,
        related_name="paid_cargo_allocations"
    )

    class Meta:
        db_table = "cargo_charge_line"
        ordering = ("sequence", "created_at")
        constraints = [
            models.UniqueConstraint(
                fields=["shipment", "code"],
                name="unique_cargo_charge_code_per_shipment",
            ),
            models.CheckConstraint(
                condition=models.Q(amount__gte=0),
                name="cargo_charge_line_amount_nonnegative",
            ),
        ]


class CargoCustodyEvent(TimeStampedModel):
    class VerificationMethod(models.TextChoices):
        NONE = "", "Not applicable"
        QR = "qr", "Shipment QR"
        PHONE = "phone", "Phone confirmation"
        OTP = "otp", "One-time code"
        IDENTITY = "identity", "Identity check"
        DELEGATED = "delegated", "Delegated pickup authorization"

    shipment = models.ForeignKey(
        CargoShipment, on_delete=models.PROTECT, related_name="custody_events"
    )
    from_status = models.CharField(
        max_length=16, choices=CargoShipment.Status.choices
    )
    to_status = models.CharField(
        max_length=16, choices=CargoShipment.Status.choices
    )
    trip = models.ForeignKey(
        Trip, on_delete=models.PROTECT, null=True, blank=True
    )
    terminal_operation = models.ForeignKey(
        CompanyTerminalOperation,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
    )
    performed_by = models.ForeignKey(
        "identity.User", on_delete=models.PROTECT
    )
    occurred_at = models.DateTimeField()
    notes = models.TextField(blank=True)
    evidence = models.JSONField(default=dict, blank=True)
    verification_method = models.CharField(
        max_length=16,
        choices=VerificationMethod.choices,
        blank=True,
    )
    verification_reference_masked = models.CharField(max_length=16, blank=True)
    recipient_name = models.CharField(max_length=150, blank=True)
    offline = models.BooleanField(default=False)
    client_event_id = models.UUIDField(null=True, blank=True, unique=True)

    class Meta:
        db_table = "cargo_custody_event"
        ordering = ("occurred_at", "created_at")
