from django.contrib import admin
from .models import CashSettlement, OfflineOperationReceipt, PrintDocument, TripClosing
admin.site.register(PrintDocument)
admin.site.register(TripClosing)
admin.site.register(CashSettlement)
admin.site.register(OfflineOperationReceipt)

