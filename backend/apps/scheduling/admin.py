from django.contrib import admin

from .models import Schedule, Trip, TripAssignmentEvent, TripOperationalEvent

admin.site.register(Schedule)
admin.site.register(Trip)
admin.site.register(TripAssignmentEvent)
admin.site.register(TripOperationalEvent)
