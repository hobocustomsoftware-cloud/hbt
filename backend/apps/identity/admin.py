from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import PlatformAccessGrant, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ("phone_number",)
    list_display = ("phone_number", "email", "status", "is_staff")
    search_fields = ("phone_number", "email", "first_name", "last_name")
    fieldsets = (
        (None, {"fields": ("phone_number", "password")}),
        (
            "Profile",
            {
                "fields": (
                    "email",
                    "first_name",
                    "last_name",
                    "preferred_language",
                    "status",
                )
            },
        ),
        (
            "Verification",
            {"fields": ("phone_verified_at", "email_verified_at")},
        ),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Dates", {"fields": ("last_login", "date_joined", "updated_at")}),
    )
    readonly_fields = ("date_joined", "updated_at")
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "phone_number",
                    "password1",
                    "password2",
                    "is_staff",
                    "is_active",
                ),
            },
        ),
    )


@admin.register(PlatformAccessGrant)
class PlatformAccessGrantAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "is_active", "valid_from", "valid_until")
    list_filter = ("role", "is_active")
    search_fields = ("user__phone_number", "reason")
