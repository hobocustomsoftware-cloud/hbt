import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('tenancy', '0004_seed_access_foundation'),
    ]

    operations = [
        migrations.CreateModel(
            name='Branch',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('country_code', models.CharField(default='MM', max_length=2)),
                ('region', models.CharField(blank=True, max_length=100)),
                ('township', models.CharField(blank=True, max_length=100)),
                ('city', models.CharField(blank=True, max_length=100)),
                ('address_line', models.TextField(blank=True)),
                ('latitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('longitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('code', models.SlugField()),
                ('name', models.CharField(max_length=255)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('active', 'Active'), ('suspended', 'Suspended'), ('closed', 'Closed'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('contact_phone', models.CharField(blank=True, max_length=32)),
                ('contact_email', models.EmailField(blank=True, max_length=254)),
                ('operating_hours', models.JSONField(blank=True, default=dict)),
                ('organization', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='branches', to='tenancy.organization')),
            ],
            options={
                'db_table': 'locations_branch',
            },
        ),
        migrations.CreateModel(
            name='PhysicalTerminal',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('country_code', models.CharField(default='MM', max_length=2)),
                ('region', models.CharField(blank=True, max_length=100)),
                ('township', models.CharField(blank=True, max_length=100)),
                ('city', models.CharField(blank=True, max_length=100)),
                ('address_line', models.TextField(blank=True)),
                ('latitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('longitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('code', models.SlugField(unique=True)),
                ('name', models.CharField(max_length=255)),
                ('name_myanmar', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('active', 'Active'), ('suspended', 'Suspended'), ('closed', 'Closed'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('contact_phone', models.CharField(blank=True, max_length=32)),
            ],
            options={
                'db_table': 'locations_physical_terminal',
                'indexes': [models.Index(fields=['status', 'region', 'city'], name='terminal_status_location_idx')],
            },
        ),
        migrations.CreateModel(
            name='CompanyTerminalOperation',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField()),
                ('display_name', models.CharField(max_length=255)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('active', 'Active'), ('suspended', 'Suspended'), ('closed', 'Closed'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('operating_hours', models.JSONField(blank=True, default=dict)),
                ('local_contact_phone', models.CharField(blank=True, max_length=32)),
                ('branch', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='terminal_operations', to='locations.branch')),
                ('organization', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='terminal_operations', to='tenancy.organization')),
                ('terminal', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='company_operations', to='locations.physicalterminal')),
            ],
            options={
                'db_table': 'locations_terminal_operation',
            },
        ),
        migrations.CreateModel(
            name='SalesCounter',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField()),
                ('name', models.CharField(max_length=150)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('active', 'Active'), ('suspended', 'Suspended'), ('closed', 'Closed'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('contact_phone', models.CharField(blank=True, max_length=32)),
                ('operating_hours', models.JSONField(blank=True, default=dict)),
                ('supports_printing', models.BooleanField(default=True)),
                ('terminal_operation', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='sales_counters', to='locations.companyterminaloperation')),
            ],
            options={
                'db_table': 'locations_sales_counter',
            },
        ),
        migrations.AddIndex(
            model_name='branch',
            index=models.Index(fields=['organization', 'status'], name='branch_org_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='branch',
            constraint=models.UniqueConstraint(fields=('organization', 'code'), name='unique_branch_code_per_org'),
        ),
        migrations.AddIndex(
            model_name='companyterminaloperation',
            index=models.Index(fields=['organization', 'status'], name='terminal_op_org_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='companyterminaloperation',
            constraint=models.UniqueConstraint(fields=('organization', 'code'), name='unique_terminal_operation_code'),
        ),
        migrations.AddConstraint(
            model_name='companyterminaloperation',
            constraint=models.UniqueConstraint(fields=('organization', 'terminal'), name='unique_org_physical_terminal'),
        ),
        migrations.AddIndex(
            model_name='salescounter',
            index=models.Index(fields=['terminal_operation', 'status'], name='counter_operation_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='salescounter',
            constraint=models.UniqueConstraint(fields=('terminal_operation', 'code'), name='unique_counter_code_per_operation'),
        ),
    ]
