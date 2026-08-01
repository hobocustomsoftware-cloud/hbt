import json
from pathlib import Path

from django.db import migrations


SOURCE_VERSION = "mm-nrc-2021-hbt-v1"
TYPE_NAMES = {
    "N": ("Citizen", "နိုင်ငံသား"),
    "E": ("Associate citizen", "ဧည့်နိုင်ငံသား"),
    "P": ("Naturalized citizen", "နိုင်ငံသားပြုခွင့်ရသူ"),
    "T": ("Religious identity", "သာသနာ"),
    "Y": ("Temporary identity", "ယာယီ"),
    "S": ("Special identity", "စ"),
}
REVIEWED_CODES = {("9", "PAMANA"), ("12", "KAMAYA")}


def seed(apps, schema_editor):
    State = apps.get_model("reference_data", "NRCStateRegion")
    Township = apps.get_model("reference_data", "NRCTownship")
    CitizenshipType = apps.get_model(
        "reference_data", "NRCCitizenshipType"
    )
    source_path = (
        Path(__file__).resolve().parent.parent
        / "data"
        / "nrc_reference_v1.json"
    )
    data = json.loads(source_path.read_text(encoding="utf-8-sig"))

    states = {}
    for item in data["nrcStates"]:
        number = item["number"]["en"].replace("*", "")
        if not number.isdigit():
            continue
        code = int(number)
        # NRC input treats Nay Pyi Taw's 9* records under state code 9.
        if code in states:
            continue
        states[code] = State.objects.create(
            code=code,
            number_mm=str(code).translate(
                str.maketrans("0123456789", "၀၁၂၃၄၅၆၇၈၉")
            ),
            name_en=item["name"]["en"].title(),
            name_mm=item["name"]["mm"],
            source_version=SOURCE_VERSION,
        )

    grouped = {}
    for item in data["nrcTownships"]:
        state_code = item["stateCode"].replace("*", "")
        code_en = item["short"]["en"].replace(" ", "").upper()
        code_mm = item["short"]["mm"].replace("၀", "ဝ")
        if not state_code.isdigit() or code_en == "-" or code_mm == "-":
            continue
        key = (state_code, code_en)
        names = {
            "name_en": item["name"]["en"].strip(),
            "name_mm": item["name"]["mm"].strip(),
        }
        if key not in grouped:
            grouped[key] = {
                "code_mm": code_mm,
                "name_en": names["name_en"],
                "name_mm": names["name_mm"],
                "aliases": [],
                "source_ids": [],
            }
        elif names not in grouped[key]["aliases"]:
            grouped[key]["aliases"].append(names)
        grouped[key]["source_ids"].append(item["id"])

    # Reviewed corrections that are material to the approved input examples.
    grouped[("12", "KAMAYA")]["code_mm"] = "ကမရ"
    grouped[("12", "KAMAYA")]["name_en"] = "KAMAYUT"
    grouped[("12", "KAMAYA")]["name_mm"] = "ကမာရွတ်"

    for (state_code, code_en), item in grouped.items():
        Township.objects.create(
            state_region=states[int(state_code)],
            code_en=code_en,
            code_mm=item["code_mm"],
            name_en=item["name_en"],
            name_mm=item["name_mm"],
            name_aliases=item["aliases"],
            source_ids=item["source_ids"],
            source_version=SOURCE_VERSION,
            verification_status=(
                "reviewed"
                if (state_code, code_en) in REVIEWED_CODES
                else "community"
            ),
        )

    for item in data["nrcTypes"]:
        code_en = item["name"]["en"].upper()
        name_en, name_mm = TYPE_NAMES.get(
            code_en, (code_en, item["name"]["mm"])
        )
        CitizenshipType.objects.create(
            code_en=code_en,
            code_mm=item["name"]["mm"],
            name_en=name_en,
            name_mm=name_mm,
            source_version=SOURCE_VERSION,
            verification_status=(
                "reviewed" if code_en in {"N", "E", "P"} else "community"
            ),
        )


def unseed(apps, schema_editor):
    apps.get_model("reference_data", "NRCTownship").objects.all().delete()
    apps.get_model(
        "reference_data", "NRCCitizenshipType"
    ).objects.all().delete()
    apps.get_model("reference_data", "NRCStateRegion").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [("reference_data", "0001_initial")]
    operations = [migrations.RunPython(seed, reverse_code=unseed)]

