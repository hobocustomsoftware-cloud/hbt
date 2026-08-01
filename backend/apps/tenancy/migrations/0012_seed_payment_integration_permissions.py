from django.db import migrations


PERMISSIONS = {
    "payment.account.view": "View payment receiving accounts",
    "payment.account.manage": "Manage payment receiving accounts and versions",
    "payment.account.approve": "Approve use of personal payment wallets",
    "payment.evidence.upload": "Upload payment evidence and account QR files",
    "payment.evidence.view": "View protected payment evidence and account QR files",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": (
        "payment.account.view",
        "payment.evidence.upload",
        "payment.evidence.view",
    ),
    "terminal-manager": (
        "payment.account.view",
        "payment.account.manage",
        "payment.evidence.upload",
        "payment.evidence.view",
    ),
    "counter-sales": (
        "payment.account.view",
        "payment.evidence.upload",
    ),
    "finance": (
        "payment.account.view",
        "payment.account.approve",
        "payment.evidence.upload",
        "payment.evidence.view",
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
    dependencies = [
        ("tenancy", "0011_seed_cargo_finance_operations_permissions"),
    ]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions),
    ]
