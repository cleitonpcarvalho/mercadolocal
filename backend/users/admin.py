from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = (
        "id",
        "username",
        "email",
        "role",
        "phone",
        "city",
        "state",
        "is_verified",
        "is_active",
        "created_at",
    )
    list_filter = ("role", "is_verified", "is_active", "is_staff", "city", "state")
    search_fields = ("username", "email", "phone", "city", "state")
    ordering = ("-created_at",)

    fieldsets = UserAdmin.fieldsets + (
        (
            "Mercado Local Profile",
            {
                "fields": (
                    "role",
                    "phone",
                    "avatar",
                    "city",
                    "state",
                    "latitude",
                    "longitude",
                    "is_verified",
                    "created_at",
                    "updated_at",
                )
            },
        ),
    )
    readonly_fields = ("created_at", "updated_at")
