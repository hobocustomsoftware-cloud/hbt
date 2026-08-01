from django.db import migrations


PERMISSIONS = {
    "locations.branch.view": "View organization branches",
    "locations.branch.manage": "Create and update organization branches",
    "locations.terminal.view": "View shared physical terminals",
    "locations.operation.view": "View company terminal operations",
    "locations.operation.manage": "Create and update terminal operations",
    "locations.counter.view": "View sales counters",
    "locations.counter.manage": "Create and update sales counters",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": (
        "locations.branch.view",
        "locations.terminal.view",
        "locations.operation.view",
        "locations.operation.manage",
        "locations.counter.view",
        "locations.counter.manage",
    ),
    "counter-sales": (
        "locations.branch.view",
        "locations.terminal.view",
        "locations.operation.view",
        "locations.counter.view",
    ),
    "dispatcher": (
        "locations.branch.view",
        "locations.terminal.view",
        "locations.operation.view",
        "locations.counter.view",
    ),
    "conductor": (
        "locations.terminal.view",
        "locations.operation.view",
    ),
    "driver": (
        "locations.terminal.view",
        "locations.operation.view",
    ),
    "finance": (
        "locations.branch.view",
        "locations.operation.view",
        "locations.counter.view",
    ),
    "inspector": (
        "locations.terminal.view",
        "locations.operation.view",
    ),
}


def seed_location_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Role = apps.get_model("tenancy", "Role")

    permission_by_code = {}
    for code, name in PERMISSIONS.items():
        permission, _ = Permission.objects.update_or_create(
            code=code,
            defaults={"name": name},
        )
        permission_by_code[code] = permission

    for role_code, permission_codes in ROLE_PERMISSIONS.items():
        role = Role.objects.get(tenant=None, code=role_code)
        role.permissions.add(
            *[permission_by_code[code] for code in permission_codes]
        )


def unseed_location_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("tenancy", "0004_seed_access_foundation"),
    ]

    operations = [
        migrations.RunPython(
            seed_location_permissions,
            reverse_code=unseed_location_permissions,
        ),
    ]
