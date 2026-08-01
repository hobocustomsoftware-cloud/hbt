from django.db import migrations


PERMISSIONS = {
    "notification.log.view": "View organization notification delivery logs",
    "notification.retry": "Retry failed organization notifications",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": ("notification.log.view",),
    "finance": ("notification.log.view", "notification.retry"),
}


def seed_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Role = apps.get_model("tenancy", "Role")
    resolved = {}
    for code, name in PERMISSIONS.items():
        permission, _ = Permission.objects.update_or_create(
            code=code, defaults={"name": name}
        )
        resolved[code] = permission
    for role_code, codes in ROLE_PERMISSIONS.items():
        role = Role.objects.get(tenant=None, code=role_code)
        role.permissions.add(*[resolved[code] for code in codes])


def unseed_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("tenancy", "0013_seed_cargo_roadside_permissions"),
    ]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions),
    ]
