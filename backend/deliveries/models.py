from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Delivery(models.Model):
    class Status(models.TextChoices):
        WAITING = "waiting", "Waiting"
        ACCEPTED = "accepted", "Accepted"
        PICKED_UP = "picked_up", "Picked Up"
        DELIVERED = "delivered", "Delivered"
        FAILED = "failed", "Failed"

    class VehicleType(models.TextChoices):
        MOTORCYCLE = "motorcycle", "Motorcycle"
        CAR = "car", "Car"
        PICKUP = "pickup", "Pickup"

    order = models.OneToOneField("orders.Order", on_delete=models.CASCADE, related_name="delivery")
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="deliveries",
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.WAITING)
    vehicle_type = models.CharField(max_length=20, choices=VehicleType.choices, default=VehicleType.MOTORCYCLE)
    pickup_latitude = models.DecimalField(max_digits=9, decimal_places=6)
    pickup_longitude = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_latitude = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_longitude = models.DecimalField(max_digits=9, decimal_places=6)
    driver_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    driver_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    estimated_minutes = models.PositiveIntegerField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Delivery"
        verbose_name_plural = "Deliveries"

    def __str__(self) -> str:
        return f"Delivery for Order #{self.order_id}"


class DriverRating(models.Model):
    delivery = models.ForeignKey(Delivery, on_delete=models.CASCADE, related_name="ratings")
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="driver_ratings")
    rating = models.PositiveIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Driver Rating"
        verbose_name_plural = "Driver Ratings"
        constraints = [
            models.UniqueConstraint(fields=["delivery", "customer"], name="unique_driver_rating_per_customer_delivery"),
        ]

    def __str__(self) -> str:
        return f"{self.rating}/5 - Delivery #{self.delivery_id}"
