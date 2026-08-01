from django.core.exceptions import PermissionDenied, ValidationError
from django.db import transaction
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.identity.models import PlatformAccessGrant
from apps.subscriptions.services import effective_limit, require_entitlement

from .models import AdvertiserAccount, MediaCampaign


def active_platform_grant(user, roles):
    now = timezone.now()
    queryset = PlatformAccessGrant.objects.filter(
        user=user, role__in=roles, is_active=True
    )
    return any(
        (grant.valid_from is None or grant.valid_from <= now)
        and (grant.valid_until is None or grant.valid_until > now)
        for grant in queryset
    )


def media_limits_for_organization(organization):
    subscription = getattr(organization.tenant, "subscription", None)
    require_entitlement(subscription, "media_channel")
    return {
        "active_campaigns": int(
            effective_limit(subscription, "media_active_campaigns", 0)
        ),
        "monthly_videos": int(
            effective_limit(subscription, "media_monthly_videos", 0)
        ),
        "video_seconds": int(
            effective_limit(subscription, "media_video_seconds", 0)
        ),
        "video_bytes": int(
            effective_limit(subscription, "media_video_bytes", 0)
        ),
    }


@transaction.atomic
def submit_campaign(campaign, actor):
    campaign = MediaCampaign.objects.select_for_update().get(pk=campaign.pk)
    if campaign.status != MediaCampaign.Status.DRAFT:
        raise ValidationError("Only a draft campaign may be submitted.")
    if not campaign.creatives.exists():
        raise ValidationError("At least one creative is required.")
    if campaign.organization_id:
        limits = media_limits_for_organization(campaign.organization)
        active_count = MediaCampaign.objects.filter(
            organization=campaign.organization,
            status__in=(
                MediaCampaign.Status.SUBMITTED,
                MediaCampaign.Status.APPROVED,
                MediaCampaign.Status.ACTIVE,
            ),
        ).exclude(pk=campaign.pk).count()
        if active_count >= limits["active_campaigns"]:
            raise PermissionDenied("The plan active-campaign limit is reached.")
        month_start = timezone.now().replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        existing_monthly_videos = (
            campaign.organization.media_campaigns.filter(
                creatives__kind="video",
                creatives__created_at__gte=month_start,
            )
            .exclude(pk=campaign.pk)
            .count()
        )
        submitted_video_count = campaign.creatives.filter(kind="video").count()
        if (
            existing_monthly_videos + submitted_video_count
            > limits["monthly_videos"]
        ):
            raise PermissionDenied("The monthly video limit is reached.")
        for creative in campaign.creatives.filter(kind="video"):
            if (
                not creative.duration_seconds
                or creative.duration_seconds > limits["video_seconds"]
                or creative.size_bytes > limits["video_bytes"]
            ):
                raise ValidationError("A video exceeds the subscription limit.")
    elif campaign.advertiser.status != AdvertiserAccount.Status.VERIFIED:
        raise PermissionDenied("The advertiser account must be verified.")
    else:
        for creative in campaign.creatives.filter(kind="video"):
            if (
                not creative.duration_seconds
                or creative.duration_seconds > 30
                or creative.size_bytes > 200 * 1024 * 1024
            ):
                raise ValidationError("An advertiser video exceeds the limit.")
    campaign.full_clean()
    campaign.status = MediaCampaign.Status.SUBMITTED
    campaign.save(update_fields=["status", "updated_at"])
    _audit(campaign, actor, "media.campaign_submitted")
    return campaign


@transaction.atomic
def confirm_campaign_payment(campaign, actor, reference):
    if not active_platform_grant(
        actor,
        (
            PlatformAccessGrant.Role.SUPER_ADMIN,
        ),
    ):
        raise PermissionDenied("Platform payment-review authority is required.")
    campaign = MediaCampaign.objects.select_for_update().get(pk=campaign.pk)
    if campaign.kind != MediaCampaign.Kind.SPONSORED:
        raise ValidationError("Only sponsored campaigns have ad payment.")
    if not reference.strip():
        raise ValidationError("A verified payment reference is required.")
    campaign.payment_status = MediaCampaign.PaymentStatus.CONFIRMED
    campaign.payment_reference = reference.strip()
    campaign.save(
        update_fields=["payment_status", "payment_reference", "updated_at"]
    )
    _audit(campaign, actor, "media.payment_confirmed")
    return campaign


@transaction.atomic
def review_campaign(campaign, actor, approve, reason=""):
    if not active_platform_grant(
        actor,
        (
            PlatformAccessGrant.Role.SUPER_ADMIN,
        ),
    ):
        raise PermissionDenied("Platform media-review authority is required.")
    campaign = MediaCampaign.objects.select_for_update().get(pk=campaign.pk)
    if campaign.status != MediaCampaign.Status.SUBMITTED:
        raise ValidationError("Only a submitted campaign may be reviewed.")
    if approve and (
        campaign.kind == MediaCampaign.Kind.SPONSORED
        and campaign.payment_status != MediaCampaign.PaymentStatus.CONFIRMED
    ):
        raise ValidationError(
            "Sponsored payment must be confirmed before approval."
        )
    if not approve and not reason.strip():
        raise ValidationError("A rejection reason is required.")
    campaign.status = (
        MediaCampaign.Status.APPROVED
        if approve
        else MediaCampaign.Status.REJECTED
    )
    campaign.review_reason = reason
    campaign.reviewed_by = actor
    campaign.reviewed_at = timezone.now()
    campaign.save()
    _audit(campaign, actor, "media.campaign_reviewed", reason)
    return campaign


@transaction.atomic
def review_advertiser(advertiser, actor, approve):
    if not active_platform_grant(
        actor, (PlatformAccessGrant.Role.SUPER_ADMIN,)
    ):
        raise PermissionDenied("Platform advertiser-review authority is required.")
    advertiser = AdvertiserAccount.objects.select_for_update().get(
        pk=advertiser.pk
    )
    if advertiser.status != AdvertiserAccount.Status.PENDING:
        raise ValidationError("Only a pending advertiser may be reviewed.")
    advertiser.status = (
        AdvertiserAccount.Status.VERIFIED
        if approve
        else AdvertiserAccount.Status.REJECTED
    )
    advertiser.reviewed_by = actor
    advertiser.reviewed_at = timezone.now()
    advertiser.save()
    record_audit_event(
        actor=actor,
        action="media.advertiser_reviewed",
        resource_type="advertiser_account",
        resource_id=advertiser.id,
        after={"status": advertiser.status},
    )
    return advertiser


def _audit(campaign, actor, action, reason=""):
    record_audit_event(
        actor=actor,
        tenant_id=(
            campaign.organization.tenant_id if campaign.organization_id else None
        ),
        organization_id=campaign.organization_id,
        action=action,
        resource_type="media_campaign",
        resource_id=campaign.id,
        reason=reason,
        after={
            "status": campaign.status,
            "kind": campaign.kind,
            "placement": campaign.placement,
            "payment_status": campaign.payment_status,
        },
    )
