from django.db import migrations


PERMISSIONS = {
    "cargo.category.manage": "Manage cargo categories and pricing defaults",
    "cargo.roadside.accept": "Accept cargo within an assigned trip scope",
    "cargo.manifest.view": "View cargo manifest within permitted trip scope",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": tuple(PERMISSIONS),
    "counter-sales": ("cargo.manifest.view",),
    "dispatcher": ("cargo.manifest.view",),
    "conductor": (
        "cargo.view",
        "cargo.roadside.accept",
        "cargo.manifest.view",
    ),
    "inspector": ("cargo.manifest.view",),
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
        resolved = []
        for code in codes:
            permission = permissions.get(code)
            if permission is None:
                permission = Permission.objects.get(code=code)
            resolved.append(permission)
        role.permissions.add(*resolved)


def unseed_permissions(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("tenancy", "0012_seed_payment_integration_permissions"),
    ]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions),
    ]
