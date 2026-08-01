from django.core.exceptions import ValidationError
from django.db import models

from apps.core.models import TimeStampedModel
from apps.tenancy.models import Organization
from apps.core.field_crypto import encrypt_nrc, nrc_blind_index
from apps.reference_data.nrc import (
    mask_rendered_nrc,
    parse_nrc,
    render_nrc_from_components,
)


class Passenger(TimeStampedModel):
    class Category(models.TextChoices):
        ADULT = "adult", "Adult"
        CHILD = "child", "Child"
        INFANT = "infant", "Infant"
        SENIOR = "senior", "Senior citizen"
        VIP = "vip", "VIP"
        STAFF = "staff", "Staff passenger"

    class Gender(models.TextChoices):
        FEMALE = "female", "Female"
        MALE = "male", "Male"
        OTHER = "other", "Other"
        UNSPECIFIED = "unspecified", "Prefer not to say"

    class Status(models.TextChoices):
        REGISTERED = "registered", "Registered"
        ACTIVE = "active", "Active"
        ARCHIVED = "archived", "Archived"

    organization = models.ForeignKey(
        Organization, on_delete=models.PROTECT, related_name="passengers"
    )
    account = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="passenger_profiles",
        null=True,
        blank=True,
    )
    managed_by = models.ForeignKey(
        "identity.User",
        on_delete=models.PROTECT,
        related_name="managed_travelers",
        null=True,
        blank=True,
    )
    passenger_code = models.CharField(max_length=50)
    full_name = models.CharField(max_length=255)
    full_name_myanmar = models.CharField(max_length=255, blank=True)
    category = models.CharField(
        max_length=12, choices=Category.choices, default=Category.ADULT
    )
    gender = models.CharField(
        max_length=12, choices=Gender.choices, default=Gender.UNSPECIFIED
    )
    date_of_birth = models.DateField(null=True, blank=True)
    phone_number = models.CharField(max_length=32, blank=True)
    nrc_state_region = models.ForeignKey(
        "reference_data.NRCStateRegion",
        on_delete=models.PROTECT,
        related_name="passengers",
        null=True,
        blank=True,
    )
    nrc_township = models.ForeignKey(
        "reference_data.NRCTownship",
        on_delete=models.PROTECT,
        related_name="passengers",
        null=True,
        blank=True,
    )
    nrc_citizenship_type = models.ForeignKey(
        "reference_data.NRCCitizenshipType",
        on_delete=models.PROTECT,
        related_name="passengers",
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
    passport_number = models.CharField(max_length=100, blank=True)
    emergency_contact_name = models.CharField(max_length=255, blank=True)
    emergency_contact_phone = models.CharField(max_length=32, blank=True)
    travel_notes = models.TextField(blank=True)
    special_assistance = models.JSONField(default=list, blank=True)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.REGISTERED
    )

    class Meta:
        db_table = "passengers_passenger"
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "passenger_code"],
                name="unique_passenger_code_per_org",
            ),
            models.UniqueConstraint(
                fields=["organization", "nrc_blind_index"],
                condition=~models.Q(nrc_blind_index=""),
                name="unique_passenger_nrc_blind_per_org",
            ),
            models.UniqueConstraint(
                fields=["organization", "passport_number"],
                condition=~models.Q(passport_number=""),
                name="unique_passenger_passport_per_org",
            ),
        ]
        indexes = [
            models.Index(
                fields=["organization", "phone_number"],
                name="passenger_org_phone_idx",
            ),
        ]

    def clean(self):
        if not self.full_name.strip():
            raise ValidationError({"full_name": "Passenger name is required."})
        if self.nrc_township_id and (
            self.nrc_township.state_region_id != self.nrc_state_region_id
        ):
            raise ValidationError(
                {"nrc_township": "NRC township and state/region do not match."}
            )

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
