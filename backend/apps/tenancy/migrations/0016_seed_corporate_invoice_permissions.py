from django.db import migrations


PERMISSIONS = {
    "corporate.view": "View corporate customer records",
    "corporate.manage": "Manage corporate customers and authorized members",
    "invoice.view": "View corporate invoices",
    "invoice.issue": "Issue an invoice for an approved corporate booking",
    "invoice.void": "Void an issued corporate invoice with a reason",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": ("corporate.view", "invoice.view"),
    "terminal-manager": ("corporate.view", "invoice.view"),
    "counter-sales": ("corporate.view", "invoice.view"),
    "finance": tuple(PERMISSIONS),
}


def seed(apps, schema_editor):
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


def unseed(apps, schema_editor):
    Permission = apps.get_model("tenancy", "Permission")
    Permission.objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [("tenancy", "0015_seed_fare_feedback_permissions")]
    operations = [migrations.RunPython(seed, reverse_code=unseed)]
