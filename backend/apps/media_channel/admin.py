from django.contrib import admin

from .models import AdvertiserAccount, MediaCampaign, MediaCreative

admin.site.register(AdvertiserAccount)
admin.site.register(MediaCampaign)
admin.site.register(MediaCreative)

