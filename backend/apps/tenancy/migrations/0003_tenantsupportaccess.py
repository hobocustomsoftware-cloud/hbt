import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tenancy', '0002_remove_membershiprole_unique_membership_role_scope_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='TenantSupportAccess',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('level', models.CharField(choices=[('read_only', 'Read only'), ('limited_write', 'Limited write')], max_length=20)),
                ('status', models.CharField(choices=[('requested', 'Requested'), ('approved', 'Approved'), ('rejected', 'Rejected'), ('revoked', 'Revoked'), ('expired', 'Expired')], default='requested', max_length=16)),
                ('reason', models.TextField()),
                ('starts_at', models.DateTimeField()),
                ('expires_at', models.DateTimeField()),
                ('approved_at', models.DateTimeField(blank=True, null=True)),
                ('revoked_at', models.DateTimeField(blank=True, null=True)),
                ('approved_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name='support_access_approvals', to=settings.AUTH_USER_MODEL)),
                ('permissions', models.ManyToManyField(blank=True, related_name='support_access_grants', to='tenancy.permission')),
                ('requester', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='support_access_requests', to=settings.AUTH_USER_MODEL)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='support_access_grants', to='tenancy.tenant')),
            ],
            options={
                'db_table': 'tenancy_support_access',
                'indexes': [models.Index(fields=['tenant', 'status', 'expires_at'], name='support_tenant_status_idx'), models.Index(fields=['requester', 'status'], name='support_requester_idx')],
            },
        ),
    ]
