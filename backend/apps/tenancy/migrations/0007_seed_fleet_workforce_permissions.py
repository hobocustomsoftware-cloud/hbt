from django.db import migrations


PERMISSIONS = {
    "fleet.view": "View vehicles and seat layouts",
    "fleet.manage": "Manage vehicles and seat layouts",
    "workforce.view": "View staff, drivers, and conductors",
    "workforce.manage": "Manage staff, drivers, and conductors",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": tuple(PERMISSIONS),
    "counter-sales": ("fleet.view", "workforce.view"),
    "dispatcher": ("fleet.view", "workforce.view"),
    "conductor": ("fleet.view", "workforce.view"),
    "driver": ("fleet.view", "workforce.view"),
    "finance": ("fleet.view",),
    "inspector": ("fleet.view", "workforce.view"),
}


def seed_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Role = apps.get_model("tenancy", "Role")
    permissions = {}
    for code, name in PERMISSIONS.items():
        permission, _ = Permission.objects.update_or_create(
            code=code, defaults={"name": name}
        )
        permissions[code] = permission
    for role_code, codes in ROLE_PERMISSIONS.items():
        role = Role.objects.get(tenant=None, code=role_code)
        role.permissions.add(*[permissions[code] for code in codes])


def unseed_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [("tenancy", "0006_seed_network_permissions")]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]
