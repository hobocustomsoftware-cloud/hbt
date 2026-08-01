import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('identity', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='PlatformAccessGrant',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('role', models.CharField(choices=[('super_admin', 'Platform Super Admin'), ('support', 'Platform Support'), ('security', 'Platform Security'), ('auditor', 'Platform Auditor')], max_length=32)),
                ('is_active', models.BooleanField(default=True)),
                ('valid_from', models.DateTimeField(blank=True, null=True)),
                ('valid_until', models.DateTimeField(blank=True, null=True)),
                ('reason', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('revoked_at', models.DateTimeField(blank=True, null=True)),
                ('granted_by', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='platform_grants_issued', to=settings.AUTH_USER_MODEL)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='platform_access_grants', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'identity_platform_access_grant',
                'indexes': [models.Index(fields=['user', 'role', 'is_active'], name='platform_grant_active_idx')],
            },
        ),
    ]
