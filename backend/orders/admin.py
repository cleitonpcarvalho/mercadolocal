from django.contrib import admin

from .models import Order, OrderItem


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "customer",
        "store",
        "status",
        "payment_method",
        "payment_status",
        "subtotal",
        "delivery_fee",
        "commission_fee",
        "total",
        "created_at",
    )
    list_filter = ("status", "payment_method", "payment_status", "store")
    search_fields = ("id", "customer__username", "store__name", "delivery_address")
    ordering = ("-created_at",)


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ("id", "order", "product", "quantity", "unit_price", "subtotal")
    list_filter = ("order__status",)
    search_fields = ("order__id", "product__name")
    ordering = ("order", "id")
