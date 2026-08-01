from django.contrib import admin

from .models import Route, RouteSegment, RouteStop

admin.site.register(Route)
admin.site.register(RouteStop)
admin.site.register(RouteSegment)
