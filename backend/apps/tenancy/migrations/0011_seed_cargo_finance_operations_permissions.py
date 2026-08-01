from django.db import migrations


PERMISSIONS = {
    "cargo.view": "View cargo shipments and contacts",
    "cargo.accept": "Register contacts and accept cargo",
    "cargo.manage": "Assign and transition cargo custody",
    "payment.view": "View payment records",
    "payment.record": "Record manual payments",
    "payment.confirm": "Confirm or reject manual payments",
    "print.view": "View printable document records",
    "print.create": "Create and acknowledge print jobs",
    "trip.close": "Close and reconcile trip operations",
    "settlement.create": "Submit trip cash settlement",
    "settlement.approve": "Verify, approve, reject, and close settlements",
    "report.owner": "View owner and management reports",
    "offline.sync": "Synchronize permitted offline working data",
}

ALL = tuple(PERMISSIONS)
ROLE_PERMISSIONS = {
    "company-owner": ALL,
    "company-administrator": ALL,
    "operations-manager": ALL,
    "terminal-manager": ALL,
    "counter-sales": (
        "cargo.view", "cargo.accept", "cargo.manage", "payment.view",
        "payment.record", "print.view", "print.create", "offline.sync",
    ),
    "dispatcher": (
        "cargo.view", "cargo.manage", "payment.view", "print.view",
        "print.create", "trip.close", "settlement.create", "offline.sync",
    ),
    "conductor": (
        "print.view", "print.create", "settlement.create", "offline.sync",
    ),
    "driver": ("offline.sync",),
    "finance": (
        "cargo.view", "payment.view", "payment.confirm", "print.view",
        "settlement.create", "settlement.approve", "report.owner",
        "offline.sync",
    ),
    "inspector": ("cargo.view", "offline.sync"),
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
        ("tenancy", "0010_seed_passenger_sales_boarding_permissions")
    ]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]

