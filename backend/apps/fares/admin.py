from django.contrib import admin

from .models import FareQuote, FareQuoteLine, FareRule

admin.site.register(FareRule)
admin.site.register(FareQuote)
admin.site.register(FareQuoteLine)
