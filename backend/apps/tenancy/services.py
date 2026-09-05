from django.core.exceptions import PermissionDenied, ValidationError
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.audit.services import record_audit_event

from .models import Membership, MembershipRole, Permission, Role

ROLE_MANAGE = "access.role.manage"
ROLE_ASSIGN = "access.role.assign"


def active_membership_for(user, organization):
    try:
        return Membership.objects.select_related("organization__tenant").get(user=user, organization=organization, status=Membership.Status.ACTIVE)
    except Membership.DoesNotExist as exc:
        raise PermissionDenied("An active organization membership is required.") from exc


def effective_permission_codes(membership):
    now = timezone.now()
    return set(Permission.objects.filter(roles__membership_assignments__membership=membership).filter(Q(roles__membership_assignments__valid_from__isnull=True) | Q(roles__membership_assignments__valid_from__lte=now), Q(roles__membership_assignments__valid_until__isnull=True) | Q(roles__membership_assignments__valid_until__gte=now)).values_list("code", flat=True))


def require_permission(membership, code):
    if code not in effective_permission_codes(membership):
        raise PermissionDenied(f"Missing required permission: {code}")


def _resource_scope_ids(resource):
    from apps.locations.models import Branch, CompanyTerminalOperation, PhysicalTerminal, SalesCounter
    from apps.scheduling.models import Trip
    if isinstance(resource, Branch): return {"branch": resource.pk}
    if isinstance(resource, PhysicalTerminal): return {"terminal": resource.pk}
    if isinstance(resource, CompanyTerminalOperation): return {"branch": resource.branch_id, "terminal": resource.terminal_id}
    if isinstance(resource, SalesCounter): return {"branch": resource.terminal_operation.branch_id, "terminal": resource.terminal_operation.terminal_id, "counter": resource.pk}
    if isinstance(resource, Trip): return {"assigned_trip": resource.pk}
    return {}


def _resource_organization_id(resource):
    organization_id = getattr(resource, "organization_id", None)
    if organization_id is not None: return organization_id
    terminal_operation = getattr(resource, "terminal_operation", None)
    return terminal_operation.organization_id if terminal_operation is not None else None


def _resource_self_user_id(resource):
    for field in ("user_id", "owner_id", "created_by_id", "managed_by_id"):
        value = getattr(resource, field, None)
        if value is not None: return value
    return None


def has_resource_scope(membership, resource, code=None):
    if _resource_organization_id(resource) != membership.organization_id: return False
    now = timezone.now()
    resource_scope_ids = _resource_scope_ids(resource)
    self_user_id = _resource_self_user_id(resource)
    assignments = MembershipRole.objects.filter(membership=membership, role__permissions__isnull=False)
    if code is not None: assignments = assignments.filter(role__permissions__code=code)
    assignments = assignments.filter(Q(valid_from__isnull=True) | Q(valid_from__lte=now), Q(valid_until__isnull=True) | Q(valid_until__gte=now)).distinct()
    for assignment in assignments:
        if assignment.scope_type == MembershipRole.ScopeType.COMPANY: return True
        if assignment.scope_type == MembershipRole.ScopeType.SELF:
            if self_user_id == membership.user_id: return True
            continue
        if assignment.scope_id == resource_scope_ids.get(assignment.scope_type): return True
    return False


def require_scoped_permission(membership, code, resource):
    require_permission(membership, code)
    if not has_resource_scope(membership, resource, code=code):
        raise PermissionDenied("The actor is not authorized for this operational scope.")


def _organization_scope_filter(model_name, organization_id):
    """Return an ORM filter that always anchors supported resources to the actor's org."""
    direct = {
        "branch": "organization_id",
        "companyterminaloperation": "organization_id",
        "trip": "organization_id",
        "ticket": "organization_id",
        "booking": "organization_id",
        "seatlock": "organization_id",
        "boardingrecord": "organization_id",
        "cashsettlement": "organization_id",
        "cargoshipment": "organization_id",
        "paymentrecord": "organization_id",
    }
    if model_name in direct:
        return Q(**{direct[model_name]: organization_id})
    if model_name == "physicalterminal":
        return Q(companyterminaloperation__organization_id=organization_id)
    if model_name == "salescounter":
        return Q(terminal_operation__organization_id=organization_id)
    return Q(pk__in=[])


def scoped_queryset(membership, queryset, code):
    """Fail-closed queryset restriction for supported operational resources."""
    require_permission(membership, code)
    now = timezone.now()
    assignments = MembershipRole.objects.filter(membership=membership, role__permissions__code=code).filter(Q(valid_from__isnull=True) | Q(valid_from__lte=now), Q(valid_until__isnull=True) | Q(valid_until__gte=now)).distinct()
    model_name = queryset.model._meta.model_name
    organization_q = _organization_scope_filter(model_name, membership.organization_id)
    if not organization_q.children or organization_q.children == [("pk__in", [])]:
        return queryset.none()
    if assignments.filter(scope_type=MembershipRole.ScopeType.COMPANY).exists():
        return queryset.filter(organization_q).distinct()
    scope_q = Q(pk__in=[])
    branch_ids = assignments.filter(scope_type=MembershipRole.ScopeType.BRANCH).values("scope_id")
    terminal_ids = assignments.filter(scope_type=MembershipRole.ScopeType.TERMINAL).values("scope_id")
    counter_ids = assignments.filter(scope_type=MembershipRole.ScopeType.COUNTER).values("scope_id")
    trip_ids = assignments.filter(scope_type=MembershipRole.ScopeType.ASSIGNED_TRIP).values("scope_id")
    if model_name == "branch":
        scope_q = Q(pk__in=branch_ids)
    elif model_name == "physicalterminal":
        scope_q = Q(pk__in=terminal_ids)
    elif model_name == "companyterminaloperation":
        scope_q = Q(branch_id__in=branch_ids) | Q(terminal_id__in=terminal_ids)
    elif model_name == "salescounter":
        scope_q = Q(pk__in=counter_ids) | Q(terminal_operation__branch_id__in=branch_ids) | Q(terminal_operation__terminal_id__in=terminal_ids)
    elif model_name == "trip":
        scope_q = Q(pk__in=trip_ids) | Q(vehicle__branch_id__in=branch_ids) | Q(driver__staff__membership_id=membership.id) | Q(conductor__staff__membership_id=membership.id)
    elif model_name in {"ticket", "booking", "seatlock", "boardingrecord", "cashsettlement"}:
        path = {"ticket": "trip", "booking": "trip", "seatlock": "trip", "boardingrecord": "trip", "cashsettlement": "trip"}[model_name]
        scope_q = Q(**{f"{path}__pk__in": trip_ids}) | Q(**{f"{path}__vehicle__branch_id__in": branch_ids}) | Q(**{f"{path}__driver__staff__membership_id": membership.id}) | Q(**{f"{path}__conductor__staff__membership_id": membership.id})
    elif model_name == "cargoshipment":
        scope_q = Q(assigned_trip__pk__in=trip_ids) | Q(assigned_trip__vehicle__branch_id__in=branch_ids) | Q(origin_terminal_id__in=terminal_ids) | Q(accepting_counter_id__in=counter_ids)
    elif model_name == "paymentrecord":
        booking_model = queryset.model._meta.get_field("booking").remote_field.model
        cargo_model = queryset.model._meta.get_field("cargo_shipment").remote_field.model
        booking_scope = scoped_queryset(membership, booking_model.objects.all(), code)
        cargo_scope = scoped_queryset(membership, cargo_model.objects.all(), code)
        scope_q = Q(booking__in=booking_scope) | Q(cargo_shipment__in=cargo_scope)
    else:
        return queryset.none()
    return queryset.filter(organization_q & scope_q).distinct()


@transaction.atomic
def create_custom_role(*, actor_membership, code, name, description, permissions):
    require_permission(actor_membership, ROLE_MANAGE)
    actor_permissions = effective_permission_codes(actor_membership)
    requested_codes = {permission.code for permission in permissions}
    if not requested_codes.issubset(actor_permissions): raise PermissionDenied("A role cannot grant permissions the actor cannot delegate.")
    role = Role.objects.create(tenant=actor_membership.organization.tenant, code=code, name=name, description=description, is_system=False)
    role.permissions.set(permissions)
    record_audit_event(actor=actor_membership.user, tenant_id=actor_membership.organization.tenant.id, organization_id=actor_membership.organization_id, action="authorization.role_created", resource_type="role", resource_id=role.id, after={"code": role.code, "permissions": sorted(requested_codes)})
    return role


@transaction.atomic
def assign_role(*, actor_membership, target_membership, role, scope_type, scope_id=None):
    require_permission(actor_membership, ROLE_ASSIGN)
    if actor_membership.organization_id != target_membership.organization_id: raise ValidationError("Actor and target memberships must share an organization.")
    if role.tenant_id not in (None, actor_membership.organization.tenant_id): raise ValidationError("Role belongs to another tenant.")
    actor_permissions = effective_permission_codes(actor_membership)
    role_permissions = set(role.permissions.values_list("code", flat=True))
    if not role_permissions.issubset(actor_permissions): raise PermissionDenied("A role cannot be assigned beyond the actor's authority.")
    assignment = MembershipRole(membership=target_membership, role=role, scope_type=scope_type, scope_id=scope_id)
    assignment.full_clean(); assignment.save()
    record_audit_event(actor=actor_membership.user, tenant_id=actor_membership.organization.tenant_id, organization_id=actor_membership.organization_id, action="authorization.role_assigned", resource_type="membership_role", resource_id=assignment.id, after={"membership_id": str(target_membership.id), "role_id": str(role.id), "scope_type": scope_type, "scope_id": str(scope_id) if scope_id else None})
    return assignment
