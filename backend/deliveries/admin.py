from django.contrib import admin

from .models import Delivery, DriverRating


@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "order",
        "driver",
        "status",
        "vehicle_type",
        "estimated_minutes",
        "started_at",
        "delivered_at",
        "created_at",
    )
    list_filter = ("status", "vehicle_type")
    search_fields = ("order__id", "driver__username")
    ordering = ("-created_at",)


@admin.register(DriverRating)
class DriverRatingAdmin(admin.ModelAdmin):
    list_display = ("id", "delivery", "customer", "rating", "created_at")
    list_filter = ("rating",)
    search_fields = ("delivery__order__id", "customer__username")
    ordering = ("-created_at",)
