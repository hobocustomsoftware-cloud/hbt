from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tenancy', '0001_initial'),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name='membershiprole',
            name='unique_membership_role_scope',
        ),
        migrations.RemoveConstraint(
            model_name='role',
            name='unique_role_code_per_tenant',
        ),
        migrations.AddConstraint(
            model_name='membershiprole',
            constraint=models.UniqueConstraint(condition=models.Q(('scope_id__isnull', False)), fields=('membership', 'role', 'scope_type', 'scope_id'), name='unique_membership_role_scope'),
        ),
        migrations.AddConstraint(
            model_name='membershiprole',
            constraint=models.UniqueConstraint(condition=models.Q(('scope_id__isnull', True)), fields=('membership', 'role', 'scope_type'), name='unique_membership_role_null_scope'),
        ),
        migrations.AddConstraint(
            model_name='role',
            constraint=models.UniqueConstraint(condition=models.Q(('tenant__isnull', False)), fields=('tenant', 'code'), name='unique_role_code_per_tenant'),
        ),
        migrations.AddConstraint(
            model_name='role',
            constraint=models.UniqueConstraint(condition=models.Q(('tenant__isnull', True)), fields=('code',), name='unique_platform_role_code'),
        ),
    ]
