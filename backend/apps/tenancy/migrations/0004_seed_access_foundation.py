from django.db import migrations


PERMISSIONS = {
    "organization.view": "View organization",
    "organization.update": "Update organization",
    "access.membership.view": "View organization memberships",
    "access.membership.invite": "Invite organization members",
    "access.membership.update": "Update organization memberships",
    "access.membership.revoke": "Revoke organization memberships",
    "access.role.view": "View roles and permissions",
    "access.role.manage": "Create and update custom roles",
    "access.role.assign": "Assign and remove roles",
    "audit.view": "View organization audit events",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": (
        "organization.view",
        "access.membership.view",
        "access.role.view",
        "audit.view",
    ),
    "terminal-manager": (
        "organization.view",
        "access.membership.view",
        "access.role.view",
    ),
    "counter-sales": ("organization.view",),
    "dispatcher": ("organization.view",),
    "conductor": ("organization.view",),
    "driver": ("organization.view",),
    "finance": ("organization.view", "audit.view"),
    "inspector": ("organization.view",),
}


def seed_access_foundation(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Role = apps.get_model("tenancy", "Role")

    permission_by_code = {}
    for code, name in PERMISSIONS.items():
        permission, _ = Permission.objects.update_or_create(
            code=code,
            defaults={"name": name},
        )
        permission_by_code[code] = permission

    for code, permission_codes in ROLE_PERMISSIONS.items():
        role, _ = Role.objects.update_or_create(
            tenant=None,
            code=code,
            defaults={
                "name": code.replace("-", " ").title(),
                "is_system": True,
            },
        )
        role.permissions.set(
            [permission_by_code[item] for item in permission_codes]
        )


def unseed_access_foundation(apps, schema_editor):
    Role = apps.get_model("tenancy", "Role")
    Permission = apps.get_model("tenancy", "Permission")
    Role.objects.filter(tenant=None, code__in=ROLE_PERMISSIONS).delete()
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("tenancy", "0003_tenantsupportaccess"),
    ]

    operations = [
        migrations.RunPython(
            seed_access_foundation,
            reverse_code=unseed_access_foundation,
        ),
    ]
