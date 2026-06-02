from django.contrib import admin

from .models import Category, Product, ProductImage


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "icon", "parent", "created_at")
    search_fields = ("name", "icon")
    ordering = ("name",)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "name",
        "store",
        "category",
        "price",
        "stock",
        "condition",
        "weight_kg",
        "is_available",
        "is_featured",
        "pickup_only",
        "created_at",
    )
    list_filter = ("condition", "is_available", "is_featured", "pickup_only", "store")
    search_fields = ("name", "store__name", "category__name")
    ordering = ("-created_at",)


@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ("id", "product", "order", "created_at")
    search_fields = ("product__name",)
    ordering = ("product", "order", "id")
