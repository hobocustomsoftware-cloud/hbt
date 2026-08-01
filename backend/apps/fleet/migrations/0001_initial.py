import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('locations', '0001_initial'),
        ('tenancy', '0006_seed_network_permissions'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='SeatLayout',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField()),
                ('name', models.CharField(max_length=150)),
                ('layout_type', models.CharField(choices=[('standard_2_2', '2+2 Standard'), ('vip_2_1', '2+1 VIP'), ('sleeper', 'Sleeper'), ('mini_bus', 'Mini Bus'), ('custom', 'Custom')], max_length=20)),
                ('version', models.PositiveIntegerField(default=1)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('review', 'In review'), ('approved', 'Approved'), ('active', 'Active'), ('retired', 'Retired'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('deck_count', models.PositiveSmallIntegerField(default=1)),
                ('row_count', models.PositiveSmallIntegerField()),
                ('column_count', models.PositiveSmallIntegerField()),
                ('organization', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='seat_layouts', to='tenancy.organization')),
            ],
            options={
                'db_table': 'fleet_seat_layout',
            },
        ),
        migrations.CreateModel(
            name='LayoutPosition',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('identifier', models.CharField(max_length=20)),
                ('position_type', models.CharField(choices=[('standard', 'Standard seat'), ('vip', 'VIP seat'), ('sleeper', 'Sleeper bed'), ('reserved', 'Reserved seat'), ('crew', 'Crew seat'), ('accessible', 'Accessible seat'), ('aisle', 'Aisle'), ('empty', 'Empty space'), ('stairs', 'Stairs'), ('restroom', 'Restroom'), ('driver', 'Driver area')], max_length=16)),
                ('deck', models.PositiveSmallIntegerField(default=1)),
                ('row', models.PositiveSmallIntegerField()),
                ('column', models.PositiveSmallIntegerField()),
                ('label', models.CharField(blank=True, max_length=30)),
                ('bookable', models.BooleanField(default=True)),
                ('window', models.BooleanField(default=False)),
                ('aisle', models.BooleanField(default=False)),
                ('layout', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='positions', to='fleet.seatlayout')),
            ],
            options={
                'db_table': 'fleet_layout_position',
                'ordering': ('deck', 'row', 'column'),
            },
        ),
        migrations.CreateModel(
            name='Vehicle',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField()),
                ('registration_number', models.CharField(max_length=50)),
                ('fleet_number', models.CharField(blank=True, max_length=50)),
                ('category', models.CharField(choices=[('express_bus', 'Express Bus'), ('mini_bus', 'Mini Bus'), ('cargo_truck', 'Cargo Truck'), ('shuttle', 'Shuttle')], max_length=20)),
                ('brand', models.CharField(blank=True, max_length=100)),
                ('model', models.CharField(blank=True, max_length=100)),
                ('manufacturing_year', models.PositiveSmallIntegerField(blank=True, null=True)),
                ('color', models.CharField(blank=True, max_length=50)),
                ('fuel_type', models.CharField(blank=True, max_length=50)),
                ('passenger_capacity', models.PositiveSmallIntegerField(default=0)),
                ('cargo_supported', models.BooleanField(default=True)),
                ('air_conditioned', models.BooleanField(default=False)),
                ('wifi_available', models.BooleanField(default=False)),
                ('gps_available', models.BooleanField(default=False)),
                ('accessible', models.BooleanField(default=False)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('available', 'Available'), ('reserved', 'Reserved'), ('in_service', 'In service'), ('maintenance', 'Under maintenance'), ('out_of_service', 'Out of service'), ('retired', 'Retired'), ('archived', 'Archived')], default='draft', max_length=20)),
                ('branch', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='vehicles', to='locations.branch')),
                ('organization', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='vehicles', to='tenancy.organization')),
            ],
            options={
                'db_table': 'fleet_vehicle',
            },
        ),
        migrations.CreateModel(
            name='VehicleLayoutAssignment',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('effective_from', models.DateTimeField()),
                ('effective_until', models.DateTimeField(blank=True, null=True)),
                ('assigned_by', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='vehicle_layout_assignments', to=settings.AUTH_USER_MODEL)),
                ('layout', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='vehicle_assignments', to='fleet.seatlayout')),
                ('vehicle', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='layout_assignments', to='fleet.vehicle')),
            ],
            options={
                'db_table': 'fleet_vehicle_layout_assignment',
            },
        ),
        migrations.AddIndex(
            model_name='seatlayout',
            index=models.Index(fields=['organization', 'status'], name='layout_org_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='seatlayout',
            constraint=models.UniqueConstraint(fields=('organization', 'code', 'version'), name='unique_layout_code_version'),
        ),
        migrations.AddConstraint(
            model_name='layoutposition',
            constraint=models.UniqueConstraint(fields=('layout', 'identifier'), name='unique_position_identifier'),
        ),
        migrations.AddConstraint(
            model_name='layoutposition',
            constraint=models.UniqueConstraint(fields=('layout', 'deck', 'row', 'column'), name='unique_layout_coordinate'),
        ),
        migrations.AddIndex(
            model_name='vehicle',
            index=models.Index(fields=['organization', 'status'], name='vehicle_org_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='vehicle',
            constraint=models.UniqueConstraint(fields=('organization', 'code'), name='unique_vehicle_code_per_org'),
        ),
        migrations.AddConstraint(
            model_name='vehicle',
            constraint=models.UniqueConstraint(fields=('organization', 'registration_number'), name='unique_registration_per_org'),
        ),
        migrations.AddConstraint(
            model_name='vehicle',
            constraint=models.UniqueConstraint(condition=models.Q(('fleet_number', ''), _negated=True), fields=('organization', 'fleet_number'), name='unique_fleet_number_per_org'),
        ),
        migrations.AddIndex(
            model_name='vehiclelayoutassignment',
            index=models.Index(fields=['vehicle', 'effective_from', 'effective_until'], name='vehicle_layout_period_idx'),
        ),
    ]
