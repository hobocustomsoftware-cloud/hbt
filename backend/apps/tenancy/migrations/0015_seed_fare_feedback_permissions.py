from django.db import migrations


PERMISSIONS = {
    "fare.view": "View fare rules and quotes",
    "fare.manage": "Create and update fare rules",
    "fare.quote": "Create and lock server fare quotes",
    "fare.override": "Override an unlocked fare quote with a reason",
    "feedback.view": "View organization feedback",
    "feedback.manage": "Triage and respond to organization feedback",
}

ROLE_PERMISSIONS = {
    "company-owner": tuple(PERMISSIONS),
    "company-administrator": tuple(PERMISSIONS),
    "operations-manager": tuple(PERMISSIONS),
    "terminal-manager": (
        "fare.view", "fare.quote", "fare.override",
        "feedback.view", "feedback.manage",
    ),
    "counter-sales": ("fare.view", "fare.quote"),
    "finance": ("fare.view", "feedback.view"),
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
    dependencies = [("tenancy", "0014_seed_notification_permissions")]
    operations = [migrations.RunPython(seed, reverse_code=unseed)]
