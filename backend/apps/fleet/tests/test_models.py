from django.core.exceptions import ValidationError
from django.test import TestCase

from apps.fleet.models import LayoutPosition, SeatLayout, Vehicle
from apps.locations.models import Branch
from apps.tenancy.models import Organization, Tenant


class FleetModelTests(TestCase):
    def test_vehicle_rejects_branch_from_another_organization(self):
        tenant = Tenant.objects.create(name="Fleet Tenant", slug="fleet")
        first = Organization.objects.create(
            tenant=tenant, legal_name="First Fleet", display_name="First"
        )
        second = Organization.objects.create(
            tenant=tenant, legal_name="Second Fleet", display_name="Second"
        )
        branch = Branch.objects.create(
            organization=second, code="mdy", name="Mandalay"
        )
        vehicle = Vehicle(
            organization=first,
            branch=branch,
            code="bus-1",
            registration_number="YGN-1",
            category=Vehicle.Category.EXPRESS_BUS,
        )
        with self.assertRaises(ValidationError):
            vehicle.full_clean()

    def test_aisle_cannot_be_bookable(self):
        tenant = Tenant.objects.create(name="Layout Tenant", slug="layout")
        organization = Organization.objects.create(
            tenant=tenant, legal_name="Layout Company", display_name="Layout"
        )
        layout = SeatLayout.objects.create(
            organization=organization,
            code="2-2",
            name="Standard",
            layout_type=SeatLayout.Type.STANDARD_2_2,
            row_count=10,
            column_count=5,
        )
        position = LayoutPosition(
            layout=layout,
            identifier="aisle-1",
            position_type=LayoutPosition.Type.AISLE,
            row=1,
            column=3,
            bookable=True,
        )
        with self.assertRaises(ValidationError):
            position.full_clean()
