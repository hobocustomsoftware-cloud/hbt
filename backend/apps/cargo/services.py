from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils import timezone

from apps.audit.services import record_audit_event
from apps.fleet.models import Vehicle
from apps.network.models import RouteStop
from apps.notifications.models import Notification
from apps.notifications.services import (
    enqueue_event_after_commit,
    recipients_with_permission,
)
from apps.scheduling.models import Trip

from .models import (
    CargoChargeLine,
    CargoContact,
    CargoCustodyEvent,
    CargoItem,
    CargoPolicy,
    CargoShipment,
)


TRANSITIONS = {
    CargoShipment.Status.DRAFT: {CargoShipment.Status.ACCEPTED},
    CargoShipment.Status.ACCEPTED: {
        CargoShipment.Status.ASSIGNED, CargoShipment.Status.CANCELLED
    },
    CargoShipment.Status.ASSIGNED: {
        CargoShipment.Status.LOADED, CargoShipment.Status.CANCELLED
    },
    CargoShipment.Status.LOADED: {CargoShipment.Status.IN_TRANSIT},
    CargoShipment.Status.IN_TRANSIT: {
        CargoShipment.Status.ARRIVED,
        CargoShipment.Status.DAMAGED,
        CargoShipment.Status.LOST,
    },
    CargoShipment.Status.ARRIVED: {CargoShipment.Status.READY_FOR_PICKUP},
    CargoShipment.Status.READY_FOR_PICKUP: {
        CargoShipment.Status.HANDED_OVER,
        CargoShipment.Status.RETURNED,
    },
    CargoShipment.Status.DAMAGED: {
        CargoShipment.Status.ARRIVED, CargoShipment.Status.RETURNED
    },
    CargoShipment.Status.LOST: {CargoShipment.Status.ARRIVED},
}


def _terminal_on_route(trip, operation):
    return RouteStop.objects.filter(
        route=trip.route, terminal=operation.terminal, cargo_allowed=True
    ).exists()


@transaction.atomic
def accept_shipment(*, organization, actor, **data):
    from apps.subscriptions.services import require_entitlement

    subscription = getattr(organization.tenant, "subscription", None)
    if subscription is not None:
        require_entitlement(subscription, "cargo_lite")
    items = data.pop("items", [])
    charge_lines = data.pop("charge_lines", [])
    client_request_id = data.get("client_request_id")
    if client_request_id:
        existing = CargoShipment.objects.filter(
            client_request_id=client_request_id
        ).first()
        if existing:
            if existing.organization_id != organization.id:
                raise ValidationError("Client request ID is already in use.")
            return existing
    if items:
        base_charge = 0
        normalized_items = []
        for item in items:
            category = item.get("category")
            method = item["pricing_method"]
            quantity = item.get("quantity", 1)
            if method == CargoShipment.PricingMethod.PER_KG:
                if not item.get("weight_kg") or not item.get("rate_per_kg"):
                    raise ValidationError(
                        "Per-kg cargo items require weight and kg rate."
                    )
                amount = item["weight_kg"] * item["rate_per_kg"]
            elif method == CargoShipment.PricingMethod.TIERED_KG:
                rule = item.get("pricing_rule")
                if not rule or not rule.active:
                    raise ValidationError(
                        "Tiered kilogram pricing requires an active company rule."
                    )
                if rule.organization_id != organization.id:
                    raise ValidationError(
                        "Cargo pricing rule belongs to another organization."
                    )
                if not item.get("weight_kg"):
                    raise ValidationError(
                        "Tiered kilogram pricing requires cargo weight."
                    )
                excess = max(item["weight_kg"] - rule.base_weight_kg, 0)
                amount = rule.base_price + (excess * rule.excess_rate_per_kg)
                item["pricing_rule_snapshot"] = {
                    "rule_id": str(rule.id),
                    "code": rule.code,
                    "name": rule.name,
                    "base_weight_kg": str(rule.base_weight_kg),
                    "base_price": str(rule.base_price),
                    "excess_rate_per_kg": str(rule.excess_rate_per_kg),
                }
            elif method == CargoShipment.PricingMethod.ITEMIZED:
                if item.get("unit_price") is None:
                    raise ValidationError(
                        "Itemized cargo pricing requires a per-item rate."
                    )
                amount = item["unit_price"] * quantity
            elif method == CargoShipment.PricingMethod.MANUAL and item.get(
                "manual_amount"
            ) is not None:
                amount = item["manual_amount"]
                item["manual_pricing_reason"] = item.get(
                    "manual_pricing_reason"
                ) or "Manual price set during cargo acceptance."
            else:
                raise ValidationError(
                    "Manual cargo items require an explicit manual amount."
                )
            if amount < 0:
                raise ValidationError("Cargo item amount cannot be negative.")
            item["base_amount"] = amount
            item["category_snapshot"] = (
                category.name_myanmar or category.name
                if category else item.get("category_snapshot", "")
            )
            if not item["category_snapshot"].strip():
                raise ValidationError("Cargo item category is required.")
            base_charge += amount
            normalized_items.append(item)
        charge_total = sum(
            line["amount"]
            for line in charge_lines
            if line["kind"] == CargoChargeLine.Kind.CHARGE
        )
        discount_total = sum(
            line["amount"]
            for line in charge_lines
            if line["kind"] == CargoChargeLine.Kind.DISCOUNT
        )
        data["piece_count"] = sum(item.get("quantity", 1) for item in items)
        data["weight_kg"] = sum(
            (item.get("weight_kg") or 0) for item in items
        ) or data.get("weight_kg")
        data["item_category"] = normalized_items[0]["category_snapshot"]
        methods = {item["pricing_method"] for item in normalized_items}
        data["pricing_method"] = (
            methods.pop()
            if len(methods) == 1
            else CargoShipment.PricingMethod.MIXED
        )
        data["manual_charge"] = base_charge
        data["additional_charge"] = charge_total
        data["discount_amount"] = discount_total
    elif data["pricing_method"] == CargoShipment.PricingMethod.PER_KG:
        if not data.get("weight_kg") or not data.get("rate_per_kg"):
            raise ValidationError("Per-kg pricing requires weight and kg rate.")
        base_charge = data["weight_kg"] * data["rate_per_kg"]
    elif data["pricing_method"] == CargoShipment.PricingMethod.MANUAL:
        if data.get("manual_charge") is None:
            raise ValidationError("Manual pricing requires a manual charge.")
        base_charge = data["manual_charge"]
        data["manual_pricing_reason"] = data.get(
            "manual_pricing_reason"
        ) or "Manual shipment total set during cargo acceptance."
    else:
        raise ValidationError(
            "Itemized or mixed shipment pricing requires cargo item lines."
        )
    data["total_charge"] = (
        base_charge
        + data.get("additional_charge", 0)
        - data.get("discount_amount", 0)
    )
    shipment = CargoShipment(
        organization=organization,
        accepted_by=actor,
        accepted_at=timezone.now(),
        status=CargoShipment.Status.ACCEPTED,
        **data,
    )
    shipment.full_clean()
    policy = CargoPolicy.objects.filter(organization=organization).first()
    if policy:
        if policy.max_weight_kg and shipment.weight_kg:
            if shipment.weight_kg > policy.max_weight_kg:
                raise ValidationError("Shipment exceeds company weight policy.")
        if (
            policy.max_declared_value
            and shipment.declared_value
            and shipment.declared_value > policy.max_declared_value
        ):
            raise ValidationError("Shipment exceeds company declared-value policy.")
        if shipment.item_category in policy.prohibited_categories:
            raise ValidationError("This cargo category is prohibited.")
        dimension_checks = (
            ("length", shipment.length_cm, policy.max_length_cm),
            ("width", shipment.width_cm, policy.max_width_cm),
            ("height", shipment.height_cm, policy.max_height_cm),
        )
        for label, actual, maximum in dimension_checks:
            if actual and maximum and actual > maximum:
                raise ValidationError(
                    f"Shipment exceeds company maximum {label}."
                )
        if policy.require_sender_nrc and not shipment.sender.nrc_blind_index:
            raise ValidationError("Sender NRC is required by company policy.")
        if policy.require_receiver_nrc and not shipment.receiver.nrc_blind_index:
            raise ValidationError("Receiver NRC is required by company policy.")
        if policy.liability_text and not shipment.liability_acknowledged:
            raise ValidationError("Cargo liability acknowledgement is required.")
    shipment.save()
    for item in items:
        cargo_item = CargoItem(
            shipment=shipment,
            priced_by=actor,
            priced_at=timezone.now(),
            **item,
        )
        cargo_item.full_clean()
        cargo_item.save()
    for index, line in enumerate(charge_lines, 1):
        if (
            line["kind"] == CargoChargeLine.Kind.ALLOCATION
            and not line.get("payout_recipient_name", "").strip()
        ):
            raise ValidationError(
                "Internal payout allocation requires a recipient name."
            )
        charge = CargoChargeLine(
            shipment=shipment,
            sequence=line.get("sequence", index),
            **{key: value for key, value in line.items() if key != "sequence"},
        )
        charge.full_clean()
        charge.save()
    for contact in (shipment.sender, shipment.receiver):
        contact.usage_count += 1
        contact.last_used_at = timezone.now()
        contact.save(update_fields=["usage_count", "last_used_at", "updated_at"])
    _event(shipment, CargoShipment.Status.DRAFT, shipment.status, actor)
    return shipment


@transaction.atomic
def mark_allocation_paid(*, charge_line, actor):
    line = CargoChargeLine.objects.select_for_update().get(pk=charge_line.pk)
    if line.kind != CargoChargeLine.Kind.ALLOCATION:
        raise ValidationError("Only internal allocations can be paid out.")
    if line.payout_paid:
        return line
    line.payout_paid = True
    line.payout_paid_at = timezone.now()
    line.payout_paid_by = actor
    line.save(
        update_fields=[
            "payout_paid", "payout_paid_at", "payout_paid_by", "updated_at"
        ]
    )
    record_audit_event(
        actor=actor,
        tenant_id=line.shipment.organization.tenant_id,
        organization_id=line.shipment.organization_id,
        action="cargo.allocation.paid",
        resource_type="cargo_charge_line",
        resource_id=line.id,
        after={
            "shipment_id": line.shipment_id,
            "code": line.code,
            "amount": line.amount,
            "recipient": line.payout_recipient_name,
        },
    )
    return line


@transaction.atomic
def assign_trip(*, shipment, trip, actor, notes=""):
    shipment = CargoShipment.objects.select_for_update().get(pk=shipment.pk)
    if shipment.status != CargoShipment.Status.ACCEPTED:
        raise ValidationError("Only accepted cargo can be assigned.")
    if trip.organization_id != shipment.organization_id:
        raise ValidationError("Trip belongs to another organization.")
    if not trip.vehicle_id or not trip.vehicle.cargo_supported:
        raise ValidationError("Trip vehicle does not support cargo.")
    if shipment.weight_kg and trip.vehicle.cargo_weight_capacity_kg:
        assigned_weight = (
            trip.cargo_shipments.exclude(pk=shipment.pk)
            .exclude(status=CargoShipment.Status.CANCELLED)
            .aggregate(total=models.Sum("weight_kg"))["total"]
            or 0
        )
        if (
            assigned_weight + shipment.weight_kg
            > trip.vehicle.cargo_weight_capacity_kg
        ):
            raise ValidationError("Trip cargo weight capacity would be exceeded.")
    if not _terminal_on_route(trip, shipment.origin_terminal):
        raise ValidationError("Trip does not serve the origin terminal.")
    if not _terminal_on_route(trip, shipment.destination_terminal):
        raise ValidationError("Trip does not serve the destination terminal.")
    shipment.assigned_trip = trip
    shipment.save(update_fields=["assigned_trip", "updated_at"])
    return transition_shipment(
        shipment=shipment,
        to_status=CargoShipment.Status.ASSIGNED,
        actor=actor,
        notes=notes,
    )


@transaction.atomic
def transition_shipment(
    *, shipment, to_status, actor, notes="", evidence=None, offline=False,
    client_event_id=None, save_fields=None
):
    if client_event_id:
        existing = CargoCustodyEvent.objects.filter(
            client_event_id=client_event_id
        ).select_related("shipment").first()
        if existing:
            return existing.shipment
    shipment = CargoShipment.objects.select_for_update().get(pk=shipment.pk)
    if to_status not in TRANSITIONS.get(shipment.status, set()):
        raise ValidationError(
            f"Cannot move cargo from {shipment.status} to {to_status}."
        )
    if to_status in (
        CargoShipment.Status.LOADED, CargoShipment.Status.IN_TRANSIT
    ) and not shipment.assigned_trip_id:
        raise ValidationError("Cargo requires an assigned trip.")
    if to_status == CargoShipment.Status.IN_TRANSIT:
        if shipment.assigned_trip.status not in (
            Trip.Status.DEPARTED, Trip.Status.IN_PROGRESS, Trip.Status.DELAYED
        ):
            raise ValidationError("Assigned trip has not departed.")
    verification = {}
    if to_status == CargoShipment.Status.HANDED_OVER:
        supplied = evidence or {}
        method = supplied.get("verification_method", "")
        reference = str(supplied.get("verification_reference_last4", "")).strip()
        recipient_name = str(supplied.get("recipient_name", "")).strip()
        if method not in {
            value for value, _ in CargoCustodyEvent.VerificationMethod.choices
            if value
        }:
            raise ValidationError("Approved receiver verification method is required.")
        if not reference or len(reference) > 8:
            raise ValidationError(
                "A masked receiver verification reference is required."
            )
        if not recipient_name:
            raise ValidationError("Recipient name is required for handover.")
        verification = {
            "verification_method": method,
            "verification_reference_masked": f"***{reference[-4:]}",
            "recipient_name": recipient_name,
        }
        evidence = {
            key: value
            for key, value in supplied.items()
            if key not in {
                "verification_method",
                "verification_reference_last4",
                "recipient_name",
            }
        }
    old = shipment.status
    shipment.status = to_status
    update_fields = [*(save_fields or []), "status", "updated_at"]
    if to_status == CargoShipment.Status.HANDED_OVER:
        shipment.actual_delivery_at = timezone.now()
        update_fields.append("actual_delivery_at")
    shipment.save(update_fields=update_fields)
    _event(
        shipment, old, to_status, actor, notes, evidence, offline,
        client_event_id, verification
    )
    return shipment


def _event(
    shipment, old, new, actor, notes="", evidence=None, offline=False,
    client_event_id=None, verification=None
):
    event = CargoCustodyEvent.objects.create(
        shipment=shipment,
        from_status=old,
        to_status=new,
        trip=shipment.assigned_trip,
        terminal_operation=(
            shipment.destination_terminal
            if new in (
                CargoShipment.Status.ARRIVED,
                CargoShipment.Status.READY_FOR_PICKUP,
                CargoShipment.Status.HANDED_OVER,
            )
            else shipment.origin_terminal
        ),
        performed_by=actor,
        occurred_at=timezone.now(),
        notes=notes,
        evidence=evidence or {},
        offline=offline,
        client_event_id=client_event_id,
        **(verification or {}),
    )
    record_audit_event(
        actor=actor,
        tenant_id=shipment.organization.tenant_id,
        organization_id=shipment.organization_id,
        action=f"cargo.{new}",
        resource_type="cargo_shipment",
        resource_id=shipment.id,
        reason=notes,
        before={"status": old},
        after={"status": new, "event_id": event.id},
    )
    from apps.offline.services import record_sync_change

    record_sync_change(
        organization=shipment.organization,
        resource_type="cargo_shipment",
        resource_id=shipment.id,
        operation="created" if old == CargoShipment.Status.DRAFT else "updated",
        payload={
            "id": shipment.id,
            "shipment_number": shipment.shipment_number,
            "status": new,
            "assigned_trip_id": shipment.assigned_trip_id,
            "updated_at": shipment.updated_at,
        },
    )
    if new in (
        CargoShipment.Status.ARRIVED,
        CargoShipment.Status.READY_FOR_PICKUP,
        CargoShipment.Status.DAMAGED,
        CargoShipment.Status.LOST,
        CargoShipment.Status.RETURNED,
    ):
        recipient_ids = list(
            recipients_with_permission(shipment.organization, "cargo.manage")
        )
        is_exception = new in (
            CargoShipment.Status.DAMAGED,
            CargoShipment.Status.LOST,
            CargoShipment.Status.RETURNED,
        )
        enqueue_event_after_commit(
            event_type=f"cargo.{new}",
            event_key=f"cargo:{shipment.id}:{event.id}:{new}",
            kind=Notification.Kind.CARGO,
            category=(
                Notification.Category.URGENT_EXCEPTION
                if is_exception
                else Notification.Category.ACTION_REQUIRED
            ),
            recipients=recipient_ids,
            organization=shipment.organization,
            title=(
                "ကုန်ပစ္စည်း ပြဿနာရှိသည်"
                if is_exception
                else "ကုန်ပစ္စည်း ရောက်ရှိပါပြီ"
            ),
            body="အသေးစိတ်ကို Cargo လုပ်ငန်းစာရင်းတွင် စစ်ဆေးပါ။",
            data={"shipment_id": str(shipment.id), "status": new},
            deep_link=f"hbt-business://cargo/{shipment.id}",
            action_required=True,
            work_type="cargo_exception" if is_exception else "cargo_handover",
        )
    return event
