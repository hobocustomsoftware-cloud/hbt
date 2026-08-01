import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('locations', '0001_initial'),
        ('tenancy', '0005_seed_location_permissions'),
    ]

    operations = [
        migrations.CreateModel(
            name='Route',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField()),
                ('name', models.CharField(max_length=255)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('review', 'In review'), ('approved', 'Approved'), ('active', 'Active'), ('suspended', 'Suspended'), ('retired', 'Retired'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('estimated_distance_km', models.DecimalField(blank=True, decimal_places=2, max_digits=9, null=True)),
                ('estimated_duration_minutes', models.PositiveIntegerField(blank=True, null=True)),
                ('operating_region', models.CharField(blank=True, max_length=150)),
                ('organization', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='routes', to='tenancy.organization')),
            ],
            options={
                'db_table': 'network_route',
            },
        ),
        migrations.CreateModel(
            name='RouteStop',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('code', models.SlugField()),
                ('name', models.CharField(max_length=255)),
                ('sequence', models.PositiveIntegerField()),
                ('stop_type', models.CharField(choices=[('terminal', 'Terminal'), ('major', 'Major stop'), ('minor', 'Minor stop'), ('pickup', 'Pickup point'), ('dropoff', 'Drop-off point')], max_length=16)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('approved', 'Approved'), ('active', 'Active'), ('suspended', 'Suspended'), ('archived', 'Archived')], default='draft', max_length=16)),
                ('boarding_allowed', models.BooleanField(default=True)),
                ('dropoff_allowed', models.BooleanField(default=True)),
                ('cargo_allowed', models.BooleanField(default=False)),
                ('rest_stop', models.BooleanField(default=False)),
                ('meal_stop', models.BooleanField(default=False)),
                ('fuel_stop', models.BooleanField(default=False)),
                ('driver_change_allowed', models.BooleanField(default=False)),
                ('region', models.CharField(blank=True, max_length=100)),
                ('township', models.CharField(blank=True, max_length=100)),
                ('city', models.CharField(blank=True, max_length=100)),
                ('address_line', models.TextField(blank=True)),
                ('latitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('longitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('route', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='stops', to='network.route')),
                ('terminal', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name='route_stops', to='locations.physicalterminal')),
            ],
            options={
                'db_table': 'network_route_stop',
                'ordering': ('sequence',),
            },
        ),
        migrations.CreateModel(
            name='RouteSegment',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('sequence', models.PositiveIntegerField()),
                ('distance_km', models.DecimalField(blank=True, decimal_places=2, max_digits=9, null=True)),
                ('estimated_duration_minutes', models.PositiveIntegerField(blank=True, null=True)),
                ('route', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='segments', to='network.route')),
                ('from_stop', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='outgoing_segments', to='network.routestop')),
                ('to_stop', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='incoming_segments', to='network.routestop')),
            ],
            options={
                'db_table': 'network_route_segment',
                'ordering': ('sequence',),
            },
        ),
        migrations.AddIndex(
            model_name='route',
            index=models.Index(fields=['organization', 'status'], name='route_org_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='route',
            constraint=models.UniqueConstraint(fields=('organization', 'code'), name='unique_route_code_per_org'),
        ),
        migrations.AddConstraint(
            model_name='route',
            constraint=models.CheckConstraint(condition=models.Q(('estimated_distance_km__isnull', True), ('estimated_distance_km__gt', 0), _connector='OR'), name='route_distance_positive'),
        ),
        migrations.AddConstraint(
            model_name='routestop',
            constraint=models.UniqueConstraint(fields=('route', 'sequence'), name='unique_stop_sequence_per_route'),
        ),
        migrations.AddConstraint(
            model_name='routestop',
            constraint=models.UniqueConstraint(fields=('route', 'code'), name='unique_stop_code_per_route'),
        ),
        migrations.AddConstraint(
            model_name='routestop',
            constraint=models.CheckConstraint(condition=models.Q(('sequence__gt', 0)), name='route_stop_sequence_positive'),
        ),
        migrations.AddConstraint(
            model_name='routesegment',
            constraint=models.UniqueConstraint(fields=('route', 'sequence'), name='unique_segment_sequence_per_route'),
        ),
        migrations.AddConstraint(
            model_name='routesegment',
            constraint=models.UniqueConstraint(fields=('route', 'from_stop', 'to_stop'), name='unique_segment_path_per_route'),
        ),
        migrations.AddConstraint(
            model_name='routesegment',
            constraint=models.CheckConstraint(condition=models.Q(('from_stop', models.F('to_stop')), _negated=True), name='segment_stops_different'),
        ),
        migrations.AddConstraint(
            model_name='routesegment',
            constraint=models.CheckConstraint(condition=models.Q(('sequence__gt', 0)), name='route_segment_sequence_positive'),
        ),
    ]
