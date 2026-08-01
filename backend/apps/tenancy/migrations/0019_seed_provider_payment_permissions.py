from django.db import migrations


PERMISSIONS = {
    "payment.connector.view": "View provider-neutral payment connectors",
    "payment.connector.manage": "Configure, rotate, test and disable payment connectors",
    "payment.provider.initiate": "Initiate a provider payment intent",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "finance": tuple(PERMISSIONS),
    "operations-manager": (
        "payment.connector.view",
        "payment.provider.initiate",
    ),
    "terminal-manager": (
        "payment.connector.view",
        "payment.provider.initiate",
    ),
    "counter-sales": (
        "payment.connector.view",
        "payment.provider.initiate",
    ),
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
    dependencies = [("tenancy", "0018_seed_refund_reissue_permissions")]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]
