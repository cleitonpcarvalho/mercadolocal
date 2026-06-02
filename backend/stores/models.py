from decimal import Decimal

from django.conf import settings
from django.db import models


class Store(models.Model):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="stores")
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    logo = models.URLField(max_length=500, blank=True, null=True)
    phone = models.CharField(max_length=20)
    city = models.CharField(max_length=120)
    state = models.CharField(max_length=120)
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("10.00"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Store"
        verbose_name_plural = "Stores"

    def __str__(self) -> str:
        return self.name


class StoreCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    icon = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Store Category"
        verbose_name_plural = "Store Categories"

    def __str__(self) -> str:
        return self.name


class StoreCategoryRelation(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="category_relations")
    category = models.ForeignKey(StoreCategory, on_delete=models.CASCADE, related_name="store_relations")

    class Meta:
        ordering = ["store__name", "category__name"]
        verbose_name = "Store Category Relation"
        verbose_name_plural = "Store Category Relations"
        constraints = [
            models.UniqueConstraint(fields=["store", "category"], name="unique_store_category_relation"),
        ]

    def __str__(self) -> str:
        return f"{self.store.name} - {self.category.name}"
