from django.db import migrations


PERMISSIONS = {
    "passenger.view": "View passenger records",
    "passenger.manage": "Register and update passengers",
    "booking.view": "View passenger bookings",
    "booking.manage": "Create, confirm, and cancel bookings",
    "ticket.view": "View and download electronic tickets",
    "ticket.issue": "Issue tickets from confirmed bookings",
    "boarding.view": "View boarding records",
    "boarding.validate": "Validate passenger tickets for boarding",
    "boarding.record": "Record passenger boarding",
}

ALL = tuple(PERMISSIONS)
ROLE_PERMISSIONS = {
    "company-owner": ALL,
    "company-administrator": ALL,
    "operations-manager": ALL,
    "terminal-manager": ALL,
    "counter-sales": (
        "passenger.view", "passenger.manage", "booking.view", "booking.manage",
        "ticket.view", "ticket.issue", "boarding.view", "boarding.validate",
        "boarding.record",
    ),
    "dispatcher": (
        "passenger.view", "booking.view", "ticket.view", "boarding.view",
        "boarding.validate", "boarding.record",
    ),
    "conductor": (
        "passenger.view", "booking.view", "ticket.view", "boarding.view",
        "boarding.validate", "boarding.record",
    ),
    "driver": ("boarding.view",),
    "finance": ("booking.view", "ticket.view"),
    "inspector": (
        "passenger.view", "booking.view", "ticket.view", "boarding.view",
        "boarding.validate",
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
    dependencies = [("tenancy", "0009_seed_trip_operation_permissions")]
    operations = [
        migrations.RunPython(seed_permissions, reverse_code=unseed_permissions)
    ]

