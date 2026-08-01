import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='AuditEvent',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('occurred_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('tenant_id', models.UUIDField(blank=True, db_index=True, null=True)),
                ('organization_id', models.UUIDField(blank=True, db_index=True, null=True)),
                ('action', models.CharField(db_index=True, max_length=150)),
                ('resource_type', models.CharField(db_index=True, max_length=150)),
                ('resource_id', models.CharField(blank=True, max_length=255)),
                ('correlation_id', models.UUIDField(blank=True, db_index=True, null=True)),
                ('reason', models.TextField(blank=True)),
                ('before', models.JSONField(blank=True, default=dict)),
                ('after', models.JSONField(blank=True, default=dict)),
                ('metadata', models.JSONField(blank=True, default=dict)),
            ],
            options={
                'db_table': 'audit_event',
                'ordering': ('-occurred_at',),
            },
        ),
    ]
