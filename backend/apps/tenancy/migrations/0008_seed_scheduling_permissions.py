from django.db import migrations


PERMISSIONS = {
    "scheduling.view": "View schedules",
    "scheduling.manage": "Create and manage schedules",
    "scheduling.approve": "Approve and activate schedules",
    "trip.view": "View operational trips",
    "trip.manage": "Create and manage operational trips",
    "trip.assign": "Assign trip vehicles and crew",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": (
        "scheduling.view",
        "trip.view",
        "trip.manage",
        "trip.assign",
    ),
    "dispatcher": ("scheduling.view", "trip.view", "trip.manage", "trip.assign"),
    "counter-sales": ("scheduling.view", "trip.view"),
    "driver": ("trip.view",),
    "conductor": ("trip.view",),
    "finance": ("scheduling.view", "trip.view"),
    "inspector": ("scheduling.view", "trip.view"),
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
    dependencies = [("tenancy", "0007_seed_fleet_workforce_permissions")]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]

