from django.db import migrations


def backfill(apps, schema_editor):
    from apps.core.field_crypto import encrypt_nrc, nrc_blind_index
    from apps.reference_data.nrc import compact_nrc, parse_nrc

    Contact = apps.get_model("cargo", "CargoContact")
    for contact in Contact.objects.exclude(nrc_normalized="").iterator():
        raw = contact.nrc_normalized
        try:
            parsed = parse_nrc(raw)
            contact.nrc_state_region_id = parsed.state_region.id
            contact.nrc_township_id = parsed.township.id
            contact.nrc_citizenship_type_id = parsed.citizenship_type.id
            contact.nrc_serial = parsed.serial_ascii
            contact.encrypted_nrc = encrypt_nrc(parsed.canonical_en)
            contact.nrc_blind_index = nrc_blind_index(parsed.canonical_en)
            contact.nrc_verification_status = "validated"
        except ValueError as exc:
            contact.encrypted_nrc = encrypt_nrc(compact_nrc(raw))
            contact.nrc_verification_status = "needs_review"
            contact.nrc_review_reason = str(exc)[:255]
        contact.nrc_normalized = ""
        contact.save()


class Migration(migrations.Migration):
    dependencies = [("cargo", "0007_cargocontact_nrc_review_reason_and_more")]
    operations = [migrations.RunPython(backfill, migrations.RunPython.noop)]

