from django.contrib import admin

from .models import Store, StoreCategory, StoreCategoryRelation


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "name",
        "owner",
        "city",
        "state",
        "phone",
        "commission_rate",
        "is_active",
        "is_verified",
        "created_at",
    )
    list_filter = ("is_active", "is_verified", "city", "state")
    search_fields = ("name", "owner__username", "phone", "city", "state")
    ordering = ("name",)


@admin.register(StoreCategory)
class StoreCategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "icon", "created_at")
    search_fields = ("name", "icon")
    ordering = ("name",)


@admin.register(StoreCategoryRelation)
class StoreCategoryRelationAdmin(admin.ModelAdmin):
    list_display = ("id", "store", "category")
    search_fields = ("store__name", "category__name")
    ordering = ("store__name", "category__name")
