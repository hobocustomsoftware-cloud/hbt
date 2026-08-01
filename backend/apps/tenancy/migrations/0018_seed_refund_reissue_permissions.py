from django.db import migrations


PERMISSIONS = {
    "refund.view": "View refund policy and requests",
    "refund.request": "Request a refund",
    "refund.approve": "Approve or reject refunds",
    "refund.pay": "Record refund payouts",
    "refund.complete": "Complete refunds and revoke tickets",
    "refund.policy.manage": "Configure the operator refund policy",
    "ticket.reissue": "Revoke and reissue unboarded tickets",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": (
        "refund.view", "refund.request", "refund.approve", "refund.complete",
        "ticket.reissue",
    ),
    "counter-sales": ("refund.view", "refund.request", "ticket.reissue"),
    "finance": (
        "refund.view", "refund.approve", "refund.pay", "refund.complete",
    ),
    "inspector": ("refund.view",),
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
    dependencies = [("tenancy", "0017_seed_commercial_branding_media_permissions")]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]
