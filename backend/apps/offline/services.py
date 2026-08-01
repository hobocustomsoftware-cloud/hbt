import hashlib
import json
from datetime import timedelta
from decimal import Decimal
from types import SimpleNamespace

from django.core.exceptions import (
    ObjectDoesNotExist,
    PermissionDenied,
    ValidationError,
)
from django.db import transaction
from django.utils import timezone
from django.utils.dateparse import parse_datetime

from apps.audit.services import record_audit_event
from apps.audit.services import json_safe
from apps.notifications.models import Notification, PendingWorkItem
from apps.notifications.services import mark_read
from apps.tenancy.models import MembershipRole
from apps.tenancy.services import (
    active_membership_for,
    effective_permission_codes,
    require_permission,
)

from .models import AuthorizationSnapshot, SyncChange, SyncOperation

SNAPSHOT_LIFETIME = timedelta(hours=12)


def issue_authorization_snapshot(*, device, membership, actor):
    if device.user_id != actor.id:
        raise PermissionDenied("The device does not belong to this user.")
    now = timezone.now()
    assignments = MembershipRole.objects.filter(
        membership=membership
    ).select_related("role")
    scopes = [
        {
            "role": assignment.role.code,
            "scope_type": assignment.scope_type,
            "scope_id": str(assignment.scope_id) if assignment.scope_id else None,
            "valid_from": assignment.valid_from,
            "valid_until": assignment.valid_until,
        }
        for assignment in assignments
        if (assignment.valid_from is None or assignment.valid_from <= now)
        and (assignment.valid_until is None or assignment.valid_until > now)
    ]
    AuthorizationSnapshot.objects.filter(
        device=device,
        organization=membership.organization,
        revoked_at__isnull=True,
    ).update(revoked_at=now)
    snapshot = AuthorizationSnapshot.objects.create(
        device=device,
        organization=membership.organization,
        membership=membership,
        permissions=sorted(effective_permission_codes(membership)),
        scopes=scopes,
        issued_at=now,
        expires_at=now + SNAPSHOT_LIFETIME,
    )
    record_audit_event(
        actor=actor,
        tenant_id=membership.organization.tenant_id,
        organization_id=membership.organization_id,
        action="offline.authorization_snapshot_issued",
        resource_type="authorization_snapshot",
        resource_id=snapshot.id,
        after={"device_id": device.id, "expires_at": snapshot.expires_at},
    )
    return snapshot


def canonical_payload_hash(operation_type, payload):
    raw = json.dumps(
        {"operation_type": operation_type, "payload": payload},
        sort_keys=True,
        separators=(",", ":"),
        default=str,
    ).encode()
    return hashlib.sha256(raw).hexdigest()


def _apply_notification_read(*, actor, payload, **context):
    notification = Notification.objects.get(
        pk=payload["notification_id"],
        recipient=actor,
        channel=Notification.Channel.IN_APP,
    )
    mark_read(notification, actor)
    return {"notification_id": str(notification.id), "read_at": notification.read_at}


def _apply_pending_work_complete(*, actor, payload, **context):
    item = PendingWorkItem.objects.get(
        pk=payload["work_item_id"], assignee=actor
    )
    if item.status == PendingWorkItem.Status.PENDING:
        item.status = PendingWorkItem.Status.COMPLETED
        item.completed_at = timezone.now()
        item.save(update_fields=["status", "completed_at", "updated_at"])
    return {
        "work_item_id": str(item.id),
        "status": item.status,
        "completed_at": item.completed_at,
    }


def _require_operation_permission(actor, organization, permission):
    membership = active_membership_for(actor, organization)
    require_permission(membership, permission)


def _apply_trip_transition(
    *, actor, organization, payload, client_operation_id, **context
):
    from apps.scheduling.models import Trip, TripOperationalEvent
    from apps.scheduling.services import transition_trip

    _require_operation_permission(actor, organization, "trip.operate")
    trip = Trip.objects.get(pk=payload["trip_id"], organization=organization)
    event_type = payload["event_type"]
    if event_type not in dict(TripOperationalEvent.Type.choices):
        raise ValidationError("Unknown trip event type.")
    trip, event = transition_trip(
        trip=trip,
        event_type=event_type,
        actor=actor,
        occurred_at=(
            parse_datetime(payload["occurred_at"])
            if payload.get("occurred_at")
            else None
        ),
        notes=payload.get("notes", ""),
        offline=True,
        client_event_id=client_operation_id,
        latitude=payload.get("latitude"),
        longitude=payload.get("longitude"),
    )
    return {
        "trip_id": str(trip.id),
        "event_id": str(event.id),
        "status": trip.status,
        "version": trip.updated_at.isoformat(),
    }


def _apply_ticket_validation(
    *, actor, organization, payload, client_operation_id, **context
):
    from apps.boarding.models import BoardingRecord
    from apps.boarding.services import validate_boarding
    from apps.network.models import RouteStop
    from apps.scheduling.models import Trip

    _require_operation_permission(actor, organization, "boarding.validate")
    trip = Trip.objects.get(pk=payload["trip_id"], organization=organization)
    stop = None
    if payload.get("boarding_stop_id"):
        stop = RouteStop.objects.get(
            pk=payload["boarding_stop_id"], route=trip.route
        )
    boarding_type = payload.get(
        "boarding_type", BoardingRecord.Type.TERMINAL
    )
    record = validate_boarding(
        organization=organization,
        trip=trip,
        validation_code=payload["validation_code"],
        actor=actor,
        boarding_type=boarding_type,
        method=BoardingRecord.Method.OFFLINE,
        boarding_stop=stop,
        identity_confirmed=bool(payload.get("identity_confirmed", False)),
        notes=payload.get("notes", ""),
        offline=True,
        client_event_id=client_operation_id,
        latitude=payload.get("latitude"),
        longitude=payload.get("longitude"),
    )
    return {
        "boarding_record_id": str(record.id),
        "ticket_id": str(record.ticket_id),
        "status": record.status,
    }


def _apply_cargo_transition(
    *, actor, organization, payload, client_operation_id, **context
):
    from apps.cargo.models import CargoShipment
    from apps.cargo.services import transition_shipment

    _require_operation_permission(actor, organization, "cargo.manage")
    shipment = CargoShipment.objects.get(
        pk=payload["shipment_id"], organization=organization
    )
    expected_version = str(payload.get("expected_updated_at", ""))
    if not expected_version:
        raise ValidationError("Cargo expected_updated_at is required.")
    if shipment.updated_at.isoformat() != expected_version:
        raise ValidationError("Cargo was changed on the server.")
    shipment = transition_shipment(
        shipment=shipment,
        to_status=payload["to_status"],
        actor=actor,
        notes=payload.get("notes", ""),
        evidence=payload.get("evidence"),
        offline=True,
        client_event_id=client_operation_id,
    )
    return {
        "shipment_id": str(shipment.id),
        "status": shipment.status,
        "version": shipment.updated_at.isoformat(),
    }


def _apply_cargo_accept(
    *, actor, organization, payload, client_operation_id, **context
):
    from apps.cargo.serializers import CargoShipmentSerializer
    from rest_framework.exceptions import ValidationError as DRFValidationError

    _require_operation_permission(actor, organization, "cargo.accept")
    data = dict(payload)
    data["client_request_id"] = str(client_operation_id)
    serializer = CargoShipmentSerializer(
        data=data,
        context={
            "organization": organization,
            "request": SimpleNamespace(user=actor),
        },
    )
    try:
        serializer.is_valid(raise_exception=True)
        shipment = serializer.save()
    except DRFValidationError as exc:
        raise ValidationError(str(exc.detail)) from exc
    return {
        "shipment_id": str(shipment.id),
        "shipment_number": shipment.shipment_number,
        "tracking_code": str(shipment.tracking_code),
        "status": shipment.status,
        "version": shipment.updated_at.isoformat(),
    }


def _apply_manual_payment(
    *, actor, organization, payload, client_operation_id, **context
):
    from apps.bookings.models import Booking
    from apps.cargo.models import CargoShipment
    from apps.payments.models import PaymentRecord
    from apps.payments.services import create_payment

    _require_operation_permission(actor, organization, "payment.record")
    booking = None
    cargo = None
    if payload.get("booking_id"):
        booking = Booking.objects.get(
            pk=payload["booking_id"], organization=organization
        )
    if payload.get("cargo_shipment_id"):
        cargo = CargoShipment.objects.get(
            pk=payload["cargo_shipment_id"], organization=organization
        )
    if bool(booking) == bool(cargo):
        raise ValidationError("Exactly one offline payment target is required.")
    if payload.get("method", PaymentRecord.Method.CASH) != PaymentRecord.Method.CASH:
        raise ValidationError(
            "Offline payment recording supports cash only; electronic evidence "
            "must be submitted online."
        )
    payment = create_payment(
        organization=organization,
        actor=actor,
        client_request_id=client_operation_id,
        payment_number=payload["payment_number"],
        booking=booking,
        cargo_shipment=cargo,
        method=PaymentRecord.Method.CASH,
        amount=Decimal(str(payload["amount"])),
        currency=payload.get("currency", "MMK"),
        paid_at=(
            parse_datetime(payload["paid_at"])
            if payload.get("paid_at")
            else timezone.now()
        ),
    )
    return {
        "payment_id": str(payment.id),
        "payment_number": payment.payment_number,
        "status": payment.status,
        "amount": str(payment.amount),
    }


def _apply_walk_up_booking(
    *, actor, organization, payload, client_operation_id, **context
):
    from apps.bookings.serializers import BookingSerializer
    from rest_framework.exceptions import ValidationError as DRFValidationError

    _require_operation_permission(actor, organization, "booking.manage")
    data = dict(payload)
    data["client_request_id"] = str(client_operation_id)
    data.setdefault("channel", "roadside")
    serializer = BookingSerializer(
        data=data,
        context={
            "organization": organization,
            "request": SimpleNamespace(user=actor),
        },
    )
    try:
        serializer.is_valid(raise_exception=True)
        booking = serializer.save()
    except DRFValidationError as exc:
        raise ValidationError(str(exc.detail)) from exc
    return {
        "booking_id": str(booking.id),
        "booking_number": booking.booking_number,
        "status": booking.status,
        "version": booking.updated_at.isoformat(),
    }


OFFLINE_OPERATION_HANDLERS = {
    "notification.read": _apply_notification_read,
    "pending_work.complete": _apply_pending_work_complete,
    "trip.transition": _apply_trip_transition,
    "ticket.validate": _apply_ticket_validation,
    "cargo.transition": _apply_cargo_transition,
    "cargo.accept": _apply_cargo_accept,
    "payment.record_cash": _apply_manual_payment,
    "booking.walk_up": _apply_walk_up_booking,
}


def record_sync_change(
    *, organization, resource_type, resource_id, operation, payload, version=1
):
    return SyncChange.objects.create(
        organization=organization,
        resource_type=resource_type,
        resource_id=resource_id,
        operation=operation,
        version=version,
        payload=json_safe(payload),
    )


@transaction.atomic
def apply_sync_operation(
    *,
    device,
    organization,
    actor,
    client_operation_id,
    operation_type,
    payload,
):
    payload_hash = canonical_payload_hash(operation_type, payload)
    existing = SyncOperation.objects.filter(
        device=device, client_operation_id=client_operation_id
    ).first()
    if existing:
        if existing.payload_hash != payload_hash:
            raise ValidationError(
                "The client operation ID was already used with different content."
            )
        return existing

    operation = SyncOperation.objects.create(
        device=device,
        organization=organization,
        client_operation_id=client_operation_id,
        operation_type=operation_type,
        payload_hash=payload_hash,
        request_payload=payload,
    )
    handler = OFFLINE_OPERATION_HANDLERS.get(operation_type)
    if handler is None:
        operation.status = SyncOperation.Status.REJECTED
        operation.error_code = "offline_operation_not_supported"
        operation.response_payload = {
            "detail": "This operation is not approved for offline execution."
        }
    else:
        try:
            operation.response_payload = json_safe(
                handler(
                    actor=actor,
                    organization=organization,
                    device=device,
                    client_operation_id=client_operation_id,
                    payload=payload,
                )
            )
            operation.status = SyncOperation.Status.APPLIED
        except (
            KeyError,
            Notification.DoesNotExist,
            PendingWorkItem.DoesNotExist,
            ObjectDoesNotExist,
            PermissionDenied,
        ):
            operation.status = SyncOperation.Status.REJECTED
            operation.error_code = "offline_target_not_found"
            operation.response_payload = {
                "detail": "The target is missing or outside the user's scope."
            }
        except ValidationError as exc:
            operation.status = SyncOperation.Status.CONFLICT
            operation.error_code = "offline_business_conflict"
            operation.response_payload = {"detail": exc.messages}
    operation.save(
        update_fields=[
            "status",
            "response_payload",
            "error_code",
            "updated_at",
        ]
    )
    record_audit_event(
        actor=actor,
        tenant_id=organization.tenant_id,
        organization_id=organization.id,
        action=f"offline.operation_{operation.status}",
        resource_type="sync_operation",
        resource_id=operation.id,
        correlation_id=client_operation_id,
        after={
            "operation_type": operation_type,
            "status": operation.status,
            "device_id": device.id,
        },
    )
    return operation
