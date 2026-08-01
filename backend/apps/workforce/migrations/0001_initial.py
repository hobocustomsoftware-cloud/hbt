import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('locations', '0001_initial'),
        ('tenancy', '0006_seed_network_permissions'),
    ]

    operations = [
        migrations.CreateModel(
            name='StaffProfile',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('employee_code', models.CharField(max_length=50)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('active', 'Active'), ('suspended', 'Suspended'), ('inactive', 'Inactive'), ('retired', 'Retired'), ('archived', 'Archived')], default='pending', max_length=16)),
                ('emergency_contact_name', models.CharField(blank=True, max_length=150)),
                ('emergency_contact_phone', models.CharField(blank=True, max_length=32)),
                ('branch', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='staff_profiles', to='locations.branch')),
                ('membership', models.OneToOneField(on_delete=django.db.models.deletion.PROTECT, related_name='staff_profile', to='tenancy.membership')),
            ],
            options={
                'db_table': 'workforce_staff_profile',
            },
        ),
        migrations.CreateModel(
            name='DriverProfile',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('driver_code', models.CharField(max_length=50)),
                ('license_number', models.CharField(max_length=100)),
                ('license_class', models.CharField(max_length=100)),
                ('license_expiry', models.DateField()),
                ('medical_clearance_expiry', models.DateField(blank=True, null=True)),
                ('certifications', models.JSONField(blank=True, default=list)),
                ('authorized_vehicle_categories', models.JSONField(blank=True, default=list)),
                ('availability', models.CharField(choices=[('available', 'Available'), ('assigned', 'Assigned'), ('on_duty', 'On duty'), ('off_duty', 'Off duty'), ('leave', 'Leave'), ('suspended', 'Suspended'), ('retired', 'Retired')], default='off_duty', max_length=16)),
                ('qualifications_verified_at', models.DateTimeField(blank=True, null=True)),
                ('staff', models.OneToOneField(on_delete=django.db.models.deletion.PROTECT, related_name='driver_profile', to='workforce.staffprofile')),
            ],
            options={
                'db_table': 'workforce_driver_profile',
            },
        ),
        migrations.CreateModel(
            name='ConductorProfile',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('conductor_code', models.CharField(max_length=50)),
                ('availability', models.CharField(choices=[('available', 'Available'), ('assigned', 'Assigned'), ('on_duty', 'On duty'), ('off_duty', 'Off duty'), ('leave', 'Leave'), ('suspended', 'Suspended'), ('retired', 'Retired')], default='off_duty', max_length=16)),
                ('qualifications', models.JSONField(blank=True, default=list)),
                ('trained_for_ticketing', models.BooleanField(default=False)),
                ('trained_for_cargo', models.BooleanField(default=False)),
                ('trained_for_cash_handling', models.BooleanField(default=False)),
                ('qualifications_verified_at', models.DateTimeField(blank=True, null=True)),
                ('staff', models.OneToOneField(on_delete=django.db.models.deletion.PROTECT, related_name='conductor_profile', to='workforce.staffprofile')),
            ],
            options={
                'db_table': 'workforce_conductor_profile',
            },
        ),
        migrations.AddConstraint(
            model_name='staffprofile',
            constraint=models.UniqueConstraint(fields=('branch', 'employee_code'), name='unique_employee_code_per_branch'),
        ),
        migrations.AddConstraint(
            model_name='driverprofile',
            constraint=models.UniqueConstraint(fields=('staff', 'driver_code'), name='unique_driver_code_per_staff'),
        ),
        migrations.AddConstraint(
            model_name='driverprofile',
            constraint=models.UniqueConstraint(fields=('license_number',), name='unique_driver_license_number'),
        ),
        migrations.AddConstraint(
            model_name='conductorprofile',
            constraint=models.UniqueConstraint(fields=('staff', 'conductor_code'), name='unique_conductor_code_per_staff'),
        ),
    ]
