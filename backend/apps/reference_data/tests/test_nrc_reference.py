from django.test import TestCase
from rest_framework.test import APIClient

from apps.core.field_crypto import decrypt_nrc
from apps.identity.models import User
from apps.passengers.models import Passenger
from apps.passengers.serializers import PassengerSerializer
from apps.tenancy.models import Organization, Tenant

from ..models import NRCCitizenshipType, NRCStateRegion, NRCTownship
from ..nrc import mask_rendered_nrc, parse_nrc


class NRCReferenceTests(TestCase):
    def test_seeded_reference_has_approved_examples(self):
        self.assertEqual(NRCStateRegion.objects.count(), 14)
        self.assertGreater(NRCTownship.objects.count(), 400)
        self.assertEqual(NRCCitizenshipType.objects.count(), 6)

        yangon = parse_nrc("၁၂/ကမရ(နိုင်)၁၂၃၄၅၆")
        self.assertEqual(yangon.canonical_en, "12/KAMAYA(N)123456")
        self.assertEqual(yangon.display_en, "12/KaMaYa(N)123456")
        self.assertEqual(yangon.display_mm, "၁၂/ကမရ(နိုင်)၁၂၃၄၅၆")
        self.assertEqual(
            mask_rendered_nrc(yangon, "en"),
            "12/KaMaYa(N)••••56",
        )

        pyinmana = parse_nrc("9/PaMaNa(N)123456")
        self.assertEqual(pyinmana.display_mm, "၉/ပမန(နိုင်)၁၂၃၄၅၆")

    def test_state_township_mismatch_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "does not belong"):
            parse_nrc("1/KaMaYa(N)123456")

    def test_public_reference_and_validation_apis(self):
        client = APIClient()
        states = client.get("/api/v1/public/nrc/states/")
        self.assertEqual(states.status_code, 200)
        townships = client.get(
            "/api/v1/public/nrc/townships/?state_code=12"
        )
        self.assertEqual(townships.status_code, 200)
        self.assertTrue(
            any(item["code_en"] == "KAMAYA" for item in townships.data["results"])
        )
        response = client.post(
            "/api/v1/public/nrc/validate/",
            {"nrc": "12/KaMaYa(N)123456"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["display_mm"], "၁၂/ကမရ(နိုင်)၁၂၃၄၅၆")

    def test_passenger_nrc_is_encrypted_and_api_returns_only_masked_value(self):
        tenant = Tenant.objects.create(name="NRC Tenant", slug="nrc-tenant")
        organization = Organization.objects.create(
            tenant=tenant,
            legal_name="NRC Express Limited",
            display_name="NRC Express",
            status=Organization.Status.ACTIVE,
        )
        user = User.objects.create_user(
            phone_number="+959777300001", password="safe-test-password"
        )
        passenger = Passenger(
            organization=organization,
            managed_by=user,
            passenger_code="NRC-P-1",
            full_name="NRC Passenger",
        )
        passenger.set_nrc("12/KaMaYa(N)123456")
        passenger.full_clean()
        passenger.save()
        self.assertNotIn("123456", passenger.encrypted_nrc)
        self.assertEqual(
            decrypt_nrc(passenger.encrypted_nrc),
            "12/KAMAYA(N)123456",
        )
        data = PassengerSerializer(passenger).data
        self.assertNotIn("national_id", data)
        self.assertNotIn("encrypted_nrc", data)
        self.assertEqual(data["masked_nrc_en"], "12/KaMaYa(N)••••56")
