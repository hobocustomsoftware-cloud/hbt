from django.db import migrations


PLANS = (
    {
        "code": "starter",
        "name_my": "စတင်အသုံးပြု",
        "name_en": "Starter",
        "display_order": 10,
        "monthly_price": 50000,
        "annual_price": 500000,
        "contact_sales": False,
        "entitlements": {
            "public_booking": True,
            "ticketing": True,
            "cargo_lite": True,
            "basic_reports": True,
            "branding": True,
            "promotion": False,
            "media_channel": False,
            "existing_ticket_validation": True,
            "active_trip_operations": True,
            "cargo_handover": True,
            "reconciliation": True,
            "invoice_payment": True,
            "lawful_data_export": True,
        },
        "limits": {
            "counters": 1,
            "staff_accounts": 5,
            "media_active_campaigns": 0,
            "media_monthly_videos": 0,
            "media_video_seconds": 0,
            "media_video_bytes": 0,
        },
    },
    {
        "code": "growth",
        "name_my": "တိုးတက်လုပ်ငန်း",
        "name_en": "Growth",
        "display_order": 20,
        "monthly_price": 100000,
        "annual_price": 1000000,
        "contact_sales": False,
        "entitlements": {
            "public_booking": True,
            "ticketing": True,
            "cargo_lite": True,
            "advanced_reports": True,
            "branding": True,
            "promotion": True,
            "media_channel": True,
            "existing_ticket_validation": True,
            "active_trip_operations": True,
            "cargo_handover": True,
            "reconciliation": True,
            "invoice_payment": True,
            "lawful_data_export": True,
        },
        "limits": {
            "counters": 3,
            "staff_accounts": 15,
            "media_active_campaigns": 2,
            "media_monthly_videos": 5,
            "media_video_seconds": 15,
            "media_video_bytes": 104857600,
        },
    },
    {
        "code": "pro",
        "name_my": "ပရော်ဖက်ရှင်နယ်",
        "name_en": "Pro",
        "display_order": 30,
        "monthly_price": 200000,
        "annual_price": 2000000,
        "contact_sales": False,
        "entitlements": {
            "public_booking": True,
            "ticketing": True,
            "cargo_lite": True,
            "advanced_reports": True,
            "branding": True,
            "promotion": True,
            "media_channel": True,
            "advanced_targeting": True,
            "existing_ticket_validation": True,
            "active_trip_operations": True,
            "cargo_handover": True,
            "reconciliation": True,
            "invoice_payment": True,
            "lawful_data_export": True,
        },
        "limits": {
            "counters": 10,
            "staff_accounts": 50,
            "media_active_campaigns": 5,
            "media_monthly_videos": 20,
            "media_video_seconds": 30,
            "media_video_bytes": 209715200,
        },
    },
    {
        "code": "enterprise",
        "name_my": "လုပ်ငန်းကြီး",
        "name_en": "Enterprise",
        "display_order": 40,
        "monthly_price": 0,
        "annual_price": 0,
        "contact_sales": True,
        "entitlements": {
            "public_booking": True,
            "ticketing": True,
            "cargo_lite": True,
            "advanced_reports": True,
            "branding": True,
            "promotion": True,
            "media_channel": True,
            "advanced_targeting": True,
            "custom_domain": True,
            "existing_ticket_validation": True,
            "active_trip_operations": True,
            "cargo_handover": True,
            "reconciliation": True,
            "invoice_payment": True,
            "lawful_data_export": True,
        },
        "limits": {
            "counters": None,
            "staff_accounts": None,
            "media_active_campaigns": 100,
            "media_monthly_videos": 1000,
            "media_video_seconds": 60,
            "media_video_bytes": 524288000,
        },
    },
)


def seed(apps, schema_editor):
    Plan = apps.get_model("subscriptions", "SubscriptionPlan")
    for plan in PLANS:
        Plan.objects.update_or_create(
            code=plan["code"],
            defaults={
                **plan,
                "tax_rate": 5,
                "is_public": True,
                "is_active": True,
            },
        )


def unseed(apps, schema_editor):
    apps.get_model("subscriptions", "SubscriptionPlan").objects.filter(
        code__in=[plan["code"] for plan in PLANS]
    ).delete()


class Migration(migrations.Migration):
    dependencies = [("subscriptions", "0001_initial")]
    operations = [migrations.RunPython(seed, reverse_code=unseed)]
