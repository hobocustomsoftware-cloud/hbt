from django.contrib import admin

from .models import AuthorizationSnapshot, Device, SyncChange, SyncOperation

admin.site.register(Device)
admin.site.register(AuthorizationSnapshot)
admin.site.register(SyncChange)
admin.site.register(SyncOperation)
