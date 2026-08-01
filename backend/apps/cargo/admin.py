from django.contrib import admin

from .models import CargoContact, CargoCustodyEvent, CargoPolicy, CargoShipment

admin.site.register(CargoContact)
admin.site.register(CargoPolicy)
admin.site.register(CargoShipment)
admin.site.register(CargoCustodyEvent)

