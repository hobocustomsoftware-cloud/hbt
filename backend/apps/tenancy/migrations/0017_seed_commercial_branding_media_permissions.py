from django.db import migrations


PERMISSIONS = {
    "subscription.view": "View subscription, usage and invoices",
    "subscription.manage": "Request or manage subscription changes",
    "branding.view": "View organization branding configuration",
    "branding.manage": "Manage organization branding",
    "promotion.view": "View promotions and coupon use",
    "promotion.manage": "Manage promotions and coupons",
    "media.view": "View organization media campaigns",
    "media.manage": "Manage organization media campaigns",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": (
        "branding.view",
        "promotion.view",
        "promotion.manage",
        "media.view",
        "media.manage",
    ),
    "terminal-manager": (
        "promotion.view",
        "media.view",
    ),
    "finance": (
        "subscription.view",
        "promotion.view",
        "media.view",
    ),
    "counter-sales": ("promotion.view",),
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
    apps.get_model("tenancy", "Permission").objects.filter(
        code__in=PERMISSIONS
    ).delete()


class Migration(migrations.Migration):
    dependencies = [("tenancy", "0016_seed_corporate_invoice_permissions")]
    operations = [migrations.RunPython(seed, reverse_code=unseed)]

