from django.contrib import admin

from .models import SubscriptionInvoice, SubscriptionPlan, TenantSubscription

admin.site.register(SubscriptionPlan)
admin.site.register(TenantSubscription)
admin.site.register(SubscriptionInvoice)

