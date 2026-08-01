from django.db import migrations


PERMISSIONS = {
    "network.route.view": "View routes, stops, and segments",
    "network.route.manage": "Create and update routes, stops, and segments",
    "network.route.approve": "Approve and activate routes",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": ("network.route.view",),
    "counter-sales": ("network.route.view",),
    "dispatcher": ("network.route.view",),
    "conductor": ("network.route.view",),
    "driver": ("network.route.view",),
    "finance": ("network.route.view",),
    "inspector": ("network.route.view",),
}


def seed_network_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Role = apps.get_model("tenancy", "Role")
    permissions = {}
    for code, name in PERMISSIONS.items():
        permission, _ = Permission.objects.update_or_create(
            code=code,
            defaults={"name": name},
        )
        permissions[code] = permission

    for role_code, codes in ROLE_PERMISSIONS.items():
        role = Role.objects.get(tenant=None, code=role_code)
        role.permissions.add(*[permissions[code] for code in codes])


def unseed_network_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("tenancy", "0005_seed_location_permissions"),
    ]

    operations = [
        migrations.RunPython(
            seed_network_permissions,
            reverse_code=unseed_network_permissions,
        ),
    ]
