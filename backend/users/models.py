from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    class Role(models.TextChoices):
        CUSTOMER = "customer", "Customer"
        STORE_OWNER = "store_owner", "Store Owner"
        DELIVERY_DRIVER = "delivery_driver", "Delivery Driver"
        ADMIN = "admin", "Admin"

    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CUSTOMER)
    phone = models.CharField(max_length=20, blank=True)
    avatar = models.URLField(max_length=500, blank=True, null=True)
    city = models.CharField(max_length=120, blank=True)
    state = models.CharField(max_length=120, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "User"
        verbose_name_plural = "Users"

    def __str__(self) -> str:
        return f"{self.username} ({self.get_role_display()})"
