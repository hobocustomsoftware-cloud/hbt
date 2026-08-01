from django.core.exceptions import PermissionDenied, ValidationError
from django.db import transaction

from apps.audit.services import record_audit_event

from .models import Membership, MembershipRole, Permission, Role

ROLE_MANAGE = "access.role.manage"
ROLE_ASSIGN = "access.role.assign"


def active_membership_for(user, organization):
    try:
        return Membership.objects.select_related(
            "organization__tenant"
        ).get(
            user=user,
            organization=organization,
            status=Membership.Status.ACTIVE,
        )
    except Membership.DoesNotExist as exc:
        raise PermissionDenied(
            "An active organization membership is required."
        ) from exc


def effective_permission_codes(membership):
    return set(
        Permission.objects.filter(
            roles__membership_assignments__membership=membership
        ).values_list("code", flat=True)
    )


def require_permission(membership, code):
    if code not in effective_permission_codes(membership):
        raise PermissionDenied(f"Missing required permission: {code}")


@transaction.atomic
def create_custom_role(*, actor_membership, code, name, description, permissions):
    require_permission(actor_membership, ROLE_MANAGE)
    actor_permissions = effective_permission_codes(actor_membership)
    requested_codes = {permission.code for permission in permissions}
    if not requested_codes.issubset(actor_permissions):
        raise PermissionDenied(
            "A role cannot grant permissions the actor cannot delegate."
        )

    role = Role.objects.create(
        tenant=actor_membership.organization.tenant,
        code=code,
        name=name,
        description=description,
        is_system=False,
    )
    role.permissions.set(permissions)
    record_audit_event(
        actor=actor_membership.user,
        tenant_id=actor_membership.organization.tenant_id,
        organization_id=actor_membership.organization_id,
        action="authorization.role_created",
        resource_type="role",
        resource_id=role.id,
        after={
            "code": role.code,
            "permissions": sorted(requested_codes),
        },
    )
    return role


@transaction.atomic
def assign_role(
    *,
    actor_membership,
    target_membership,
    role,
    scope_type,
    scope_id=None,
):
    require_permission(actor_membership, ROLE_ASSIGN)
    if (
        actor_membership.organization_id
        != target_membership.organization_id
    ):
        raise ValidationError(
            "Actor and target memberships must share an organization."
        )
    if role.tenant_id not in (
        None,
        actor_membership.organization.tenant_id,
    ):
        raise ValidationError("Role belongs to another tenant.")

    actor_permissions = effective_permission_codes(actor_membership)
    role_permissions = set(
        role.permissions.values_list("code", flat=True)
    )
    if not role_permissions.issubset(actor_permissions):
        raise PermissionDenied(
            "A role cannot be assigned beyond the actor's authority."
        )

    assignment = MembershipRole(
        membership=target_membership,
        role=role,
        scope_type=scope_type,
        scope_id=scope_id,
    )
    assignment.full_clean()
    assignment.save()
    record_audit_event(
        actor=actor_membership.user,
        tenant_id=actor_membership.organization.tenant_id,
        organization_id=actor_membership.organization_id,
        action="authorization.role_assigned",
        resource_type="membership_role",
        resource_id=assignment.id,
        after={
            "membership_id": str(target_membership.id),
            "role_id": str(role.id),
            "scope_type": scope_type,
            "scope_id": str(scope_id) if scope_id else None,
        },
    )
    return assignment
