from django.contrib import admin

from .models import Ad


@admin.register(Ad)
class AdAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "title",
        "store",
        "product",
        "ad_type",
        "price_paid",
        "starts_at",
        "ends_at",
        "is_active",
        "impressions",
        "clicks",
        "created_at",
    )
    list_filter = ("ad_type", "is_active", "store")
    search_fields = ("title", "store__name", "product__name")
    ordering = ("-created_at",)
