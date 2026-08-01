import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Organization',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('legal_name', models.CharField(max_length=255)),
                ('display_name', models.CharField(max_length=255)),
                ('registration_number', models.CharField(blank=True, max_length=100)),
                ('tax_identifier', models.CharField(blank=True, max_length=100)),
                ('contact_phone', models.CharField(blank=True, max_length=32)),
                ('contact_email', models.EmailField(blank=True, max_length=254)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('active', 'Active'), ('suspended', 'Suspended'), ('closed', 'Closed'), ('archived', 'Archived')], default='pending', max_length=16)),
            ],
            options={
                'db_table': 'tenancy_organization',
            },
        ),
        migrations.CreateModel(
            name='Permission',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.CharField(max_length=150, unique=True)),
                ('name', models.CharField(max_length=255)),
                ('description', models.TextField(blank=True)),
            ],
            options={
                'db_table': 'tenancy_permission',
                'ordering': ('code',),
            },
        ),
        migrations.CreateModel(
            name='Membership',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('status', models.CharField(choices=[('invited', 'Invited'), ('active', 'Active'), ('suspended', 'Suspended'), ('revoked', 'Revoked')], default='invited', max_length=16)),
                ('invited_at', models.DateTimeField(blank=True, null=True)),
                ('joined_at', models.DateTimeField(blank=True, null=True)),
                ('ended_at', models.DateTimeField(blank=True, null=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='organization_memberships', to=settings.AUTH_USER_MODEL)),
                ('organization', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='memberships', to='tenancy.organization')),
            ],
            options={
                'db_table': 'tenancy_membership',
            },
        ),
        migrations.CreateModel(
            name='Role',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField(max_length=100)),
                ('name', models.CharField(max_length=150)),
                ('description', models.TextField(blank=True)),
                ('is_system', models.BooleanField(default=False)),
                ('permissions', models.ManyToManyField(blank=True, related_name='roles', to='tenancy.permission')),
            ],
            options={
                'db_table': 'tenancy_role',
            },
        ),
        migrations.CreateModel(
            name='MembershipRole',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('scope_type', models.CharField(choices=[('company', 'Company-wide'), ('branch', 'Branch'), ('terminal', 'Terminal'), ('counter', 'Counter'), ('assigned_trip', 'Assigned trip'), ('self', 'Self only')], max_length=32)),
                ('scope_id', models.UUIDField(blank=True, null=True)),
                ('valid_from', models.DateTimeField(blank=True, null=True)),
                ('valid_until', models.DateTimeField(blank=True, null=True)),
                ('membership', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='role_assignments', to='tenancy.membership')),
                ('role', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='membership_assignments', to='tenancy.role')),
            ],
            options={
                'db_table': 'tenancy_membership_role',
            },
        ),
        migrations.CreateModel(
            name='Tenant',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('name', models.CharField(max_length=255)),
                ('slug', models.SlugField(max_length=100, unique=True)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('active', 'Active'), ('suspended', 'Suspended'), ('disabled', 'Disabled'), ('archived', 'Archived')], default='pending', max_length=16)),
                ('primary_language', models.CharField(default='my', max_length=10)),
                ('timezone', models.CharField(default='Asia/Yangon', max_length=64)),
                ('currency', models.CharField(default='MMK', max_length=3)),
            ],
            options={
                'db_table': 'tenancy_tenant',
                'indexes': [models.Index(fields=['status'], name='tenant_status_idx')],
            },
        ),
        migrations.AddField(
            model_name='role',
            name='tenant',
            field=models.ForeignKey(blank=True, help_text='Null identifies a platform-provided role template.', null=True, on_delete=django.db.models.deletion.PROTECT, related_name='roles', to='tenancy.tenant'),
        ),
        migrations.AddField(
            model_name='organization',
            name='tenant',
            field=models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='organizations', to='tenancy.tenant'),
        ),
        migrations.AddIndex(
            model_name='membership',
            index=models.Index(fields=['organization', 'status'], name='membership_org_status_idx'),
        ),
        migrations.AddIndex(
            model_name='membership',
            index=models.Index(fields=['user', 'status'], name='membership_user_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='membership',
            constraint=models.UniqueConstraint(fields=('organization', 'user'), name='unique_org_user_membership'),
        ),
        migrations.AddIndex(
            model_name='membershiprole',
            index=models.Index(fields=['membership', 'scope_type', 'scope_id'], name='member_role_scope_idx'),
        ),
        migrations.AddConstraint(
            model_name='membershiprole',
            constraint=models.UniqueConstraint(fields=('membership', 'role', 'scope_type', 'scope_id'), name='unique_membership_role_scope', nulls_distinct=False),
        ),
        migrations.AddConstraint(
            model_name='role',
            constraint=models.UniqueConstraint(fields=('tenant', 'code'), name='unique_role_code_per_tenant', nulls_distinct=False),
        ),
        migrations.AddIndex(
            model_name='organization',
            index=models.Index(fields=['tenant', 'status'], name='org_tenant_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='organization',
            constraint=models.UniqueConstraint(fields=('tenant', 'legal_name'), name='unique_legal_name_per_tenant'),
        ),
        migrations.AddConstraint(
            model_name='organization',
            constraint=models.UniqueConstraint(condition=models.Q(('registration_number', ''), _negated=True), fields=('tenant', 'registration_number'), name='unique_registration_per_tenant'),
        ),
    ]
