from django.db import migrations


def encrypt_existing_tokens(apps, schema_editor):
    Device = apps.get_model("offline", "Device")
    from apps.core.field_crypto import encrypt_push_token

    for device in Device.objects.exclude(encrypted_push_token="").iterator():
        plaintext = device.encrypted_push_token
        device.encrypted_push_token = encrypt_push_token(plaintext)
        device.save(update_fields=["encrypted_push_token"])


def clear_tokens_for_reverse(apps, schema_editor):
    # Ciphertext must never be copied back into a plaintext-token column.
    Device = apps.get_model("offline", "Device")
    Device.objects.update(encrypted_push_token="")


class Migration(migrations.Migration):
    dependencies = [("offline", "0001_initial")]
    operations = [
        migrations.RenameField(
            model_name="device",
            old_name="push_token",
            new_name="encrypted_push_token",
        ),
        migrations.RunPython(
            encrypt_existing_tokens,
            reverse_code=clear_tokens_for_reverse,
        ),
    ]
