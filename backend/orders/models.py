from django.conf import settings
from django.db import models


class Order(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"
        PREPARING = "preparing", "Preparing"
        READY = "ready", "Ready"
        IN_DELIVERY = "in_delivery", "In Delivery"
        DELIVERED = "delivered", "Delivered"
        CANCELLED = "cancelled", "Cancelled"

    class PaymentMethod(models.TextChoices):
        PIX = "pix", "PIX"
        CREDIT_CARD = "credit_card", "Credit Card"
        DEBIT_CARD = "debit_card", "Debit Card"

    class PaymentStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        PAID = "paid", "Paid"
        FAILED = "failed", "Failed"
        REFUNDED = "refunded", "Refunded"

    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="customer_orders")
    store = models.ForeignKey("stores.Store", on_delete=models.CASCADE, related_name="orders")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    delivery_address = models.CharField(max_length=255)
    delivery_latitude = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_longitude = models.DecimalField(max_digits=9, decimal_places=6)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2)
    commission_fee = models.DecimalField(max_digits=10, decimal_places=2)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Order"
        verbose_name_plural = "Orders"

    def __str__(self) -> str:
        return f"Order #{self.id} - {self.customer.username}"


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey("products.Product", on_delete=models.CASCADE, related_name="order_items")
    quantity = models.PositiveIntegerField()
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["order", "id"]
        verbose_name = "Order Item"
        verbose_name_plural = "Order Items"

    def __str__(self) -> str:
        return f"{self.quantity}x {self.product.name} (Order #{self.order.id})"
