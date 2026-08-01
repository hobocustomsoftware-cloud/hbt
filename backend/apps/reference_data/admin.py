from django.contrib import admin

from .models import NRCCitizenshipType, NRCStateRegion, NRCTownship

admin.site.register(NRCStateRegion)
admin.site.register(NRCTownship)
admin.site.register(NRCCitizenshipType)

