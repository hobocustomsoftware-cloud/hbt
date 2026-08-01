from django.core.exceptions import ValidationError
from django.test import TestCase

from apps.locations.models import (
    Branch,
    CompanyTerminalOperation,
    PhysicalTerminal,
)
from apps.tenancy.models import Organization, Tenant


class LocationModelTests(TestCase):
    def test_terminal_operation_rejects_branch_from_another_organization(self):
        tenant = Tenant.objects.create(name="Tenant", slug="location-tenant")
        first_org = Organization.objects.create(
            tenant=tenant,
            legal_name="First Company",
            display_name="First",
        )
        second_org = Organization.objects.create(
            tenant=tenant,
            legal_name="Second Company",
            display_name="Second",
        )
        branch = Branch.objects.create(
            organization=second_org,
            code="mdy",
            name="Mandalay Branch",
        )
        terminal = PhysicalTerminal.objects.create(
            code="aung-mingalar",
            name="Aung Mingalar Highway Bus Terminal",
        )
        operation = CompanyTerminalOperation(
            organization=first_org,
            branch=branch,
            terminal=terminal,
            code="ygn",
            display_name="Yangon Operation",
        )

        with self.assertRaises(ValidationError):
            operation.full_clean()
