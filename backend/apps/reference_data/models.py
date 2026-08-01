from django.db import models

from apps.core.models import TimeStampedModel


class NRCStateRegion(TimeStampedModel):
    code = models.PositiveSmallIntegerField(unique=True)
    number_mm = models.CharField(max_length=4)
    name_en = models.CharField(max_length=100)
    name_mm = models.CharField(max_length=100)
    source_version = models.CharField(max_length=32, default="mm-nrc-2021")
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "reference_nrc_state_region"
        ordering = ("code",)


class NRCTownship(TimeStampedModel):
    state_region = models.ForeignKey(
        NRCStateRegion, on_delete=models.PROTECT, related_name="townships"
    )
    code_en = models.CharField(max_length=32)
    code_mm = models.CharField(max_length=16)
    name_en = models.CharField(max_length=160)
    name_mm = models.CharField(max_length=160)
    name_aliases = models.JSONField(default=list, blank=True)
    source_ids = models.JSONField(default=list, blank=True)
    source_version = models.CharField(max_length=32, default="mm-nrc-2021")
    verification_status = models.CharField(max_length=16, default="community")
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "reference_nrc_township"
        ordering = ("state_region__code", "code_en")
        constraints = [
            models.UniqueConstraint(
                fields=["state_region", "code_en"],
                name="unique_nrc_township_code_per_state",
            ),
        ]
        indexes = [
            models.Index(
                fields=["state_region", "active"],
                name="nrc_township_state_active_idx",
            ),
        ]


class NRCCitizenshipType(TimeStampedModel):
    code_en = models.CharField(max_length=4, unique=True)
    code_mm = models.CharField(max_length=32, unique=True)
    name_en = models.CharField(max_length=120)
    name_mm = models.CharField(max_length=120)
    source_version = models.CharField(max_length=32, default="mm-nrc-2021")
    verification_status = models.CharField(max_length=16, default="community")
    active = models.BooleanField(default=True)

    class Meta:
        db_table = "reference_nrc_citizenship_type"
        ordering = ("code_en",)

