from django.contrib import admin

from .models import (
    Branch,
    CompanyTerminalOperation,
    PhysicalTerminal,
    SalesCounter,
)

admin.site.register(Branch)
admin.site.register(PhysicalTerminal)
admin.site.register(CompanyTerminalOperation)
admin.site.register(SalesCounter)
