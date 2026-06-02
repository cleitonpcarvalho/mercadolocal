from django.db import models


class Category(models.Model):
    name = models.CharField(max_length=120, unique=True)
    icon = models.CharField(max_length=100)
    parent = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="children")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Category"
        verbose_name_plural = "Categories"

    def __str__(self) -> str:
        return self.name


class Product(models.Model):
    class Condition(models.TextChoices):
        NEW = "new", "New"
        USED = "used", "Used"

    store = models.ForeignKey("stores.Store", on_delete=models.CASCADE, related_name="products")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name="products")
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.PositiveIntegerField()
    condition = models.CharField(max_length=10, choices=Condition.choices)
    weight_kg = models.DecimalField(max_digits=7, decimal_places=3)
    is_available = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    pickup_only = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Product"
        verbose_name_plural = "Products"

    def __str__(self) -> str:
        return self.name


class ProductImage(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="images")
    image = models.URLField(max_length=500)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["product", "order", "id"]
        verbose_name = "Product Image"
        verbose_name_plural = "Product Images"

    def __str__(self) -> str:
        return f"{self.product.name} - Image {self.order}"
