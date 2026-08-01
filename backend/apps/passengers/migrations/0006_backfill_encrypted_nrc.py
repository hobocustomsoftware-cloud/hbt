from django.db import migrations


def backfill(apps, schema_editor):
    from apps.core.field_crypto import encrypt_nrc, nrc_blind_index
    from apps.reference_data.nrc import compact_nrc, parse_nrc

    Passenger = apps.get_model("passengers", "Passenger")
    for passenger in Passenger.objects.exclude(
        national_id="", nrc_normalized=""
    ).iterator():
        raw = passenger.national_id or passenger.nrc_normalized
        try:
            parsed = parse_nrc(raw)
            digest = nrc_blind_index(parsed.canonical_en)
            duplicate = Passenger.objects.filter(
                organization_id=passenger.organization_id,
                nrc_blind_index=digest,
            ).exclude(pk=passenger.pk).exists()
            passenger.encrypted_nrc = encrypt_nrc(parsed.canonical_en)
            if duplicate:
                passenger.nrc_verification_status = "needs_review"
                passenger.nrc_review_reason = "Duplicate NRC in organization."
            else:
                passenger.nrc_state_region_id = parsed.state_region.id
                passenger.nrc_township_id = parsed.township.id
                passenger.nrc_citizenship_type_id = parsed.citizenship_type.id
                passenger.nrc_serial = parsed.serial_ascii
                passenger.nrc_blind_index = digest
                passenger.nrc_verification_status = "validated"
        except ValueError as exc:
            passenger.encrypted_nrc = encrypt_nrc(compact_nrc(raw))
            passenger.nrc_verification_status = "needs_review"
            passenger.nrc_review_reason = str(exc)[:255]
        passenger.national_id = ""
        passenger.nrc_normalized = ""
        passenger.save()


class Migration(migrations.Migration):
    dependencies = [("passengers", "0005_passenger_nrc_review_reason_and_more")]
    operations = [migrations.RunPython(backfill, migrations.RunPython.noop)]

