from django.contrib import admin

from .models import (
    Membership,
    MembershipRole,
    Organization,
    Permission,
    Role,
    Tenant,
    TenantSupportAccess,
)

admin.site.register(Tenant)
admin.site.register(Organization)
admin.site.register(Membership)
admin.site.register(MembershipRole)
admin.site.register(Permission)
admin.site.register(Role)
admin.site.register(TenantSupportAccess)
