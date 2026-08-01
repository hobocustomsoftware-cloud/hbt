from django.db import migrations


PERMISSIONS = {
    "boarding.manage": "Start and manage trip boarding operations",
    "trip.operate": "Record departure, route progression, stops, and arrival",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": tuple(PERMISSIONS),
    "dispatcher": tuple(PERMISSIONS),
    "conductor": tuple(PERMISSIONS),
    "driver": ("trip.operate",),
    "inspector": ("trip.operate",),
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
    dependencies = [("tenancy", "0008_seed_scheduling_permissions")]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]

