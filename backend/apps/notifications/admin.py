from django.contrib import admin

from .models import DeliveryAttempt, Notification, PendingWorkItem

admin.site.register(Notification)
admin.site.register(DeliveryAttempt)
admin.site.register(PendingWorkItem)
