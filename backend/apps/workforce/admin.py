from django.contrib import admin

from .models import ConductorProfile, DriverProfile, StaffProfile

admin.site.register(StaffProfile)
admin.site.register(DriverProfile)
admin.site.register(ConductorProfile)
