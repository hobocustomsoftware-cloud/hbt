from django.contrib import admin

from .models import LayoutPosition, SeatLayout, Vehicle, VehicleLayoutAssignment

admin.site.register(Vehicle)
admin.site.register(SeatLayout)
admin.site.register(LayoutPosition)
admin.site.register(VehicleLayoutAssignment)
