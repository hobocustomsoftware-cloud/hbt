from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("operations", "0002_printerprofile_printattempt_printtemplate_and_more"),
    ]

    operations = [
        migrations.AddIndex(
            model_name="printdocument",
            index=models.Index(fields=["organization", "created_at"], name="print_doc_org_created_idx"),
        ),
        migrations.AddIndex(
            model_name="tripclosing",
            index=models.Index(fields=["organization", "closed_at"], name="trip_closing_org_time_idx"),
        ),
        migrations.AddIndex(
            model_name="cashsettlement",
            index=models.Index(fields=["organization", "status"], name="cash_settlement_org_status_idx"),
        ),
        migrations.AddIndex(
            model_name="offlineoperationreceipt",
            index=models.Index(fields=["organization", "occurred_at"], name="offline_receipt_org_time_idx"),
        ),
    ]
