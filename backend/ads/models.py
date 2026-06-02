from django.db import models


class Ad(models.Model):
    class AdType(models.TextChoices):
        BANNER = "banner", "Banner"
        FEATURED_PRODUCT = "featured_product", "Featured Product"
        SPONSORED_STORE = "sponsored_store", "Sponsored Store"

    store = models.ForeignKey(
        "stores.Store",
        on_delete=models.SET_NULL,
        related_name="ads",
        blank=True,
        null=True,
    )
    product = models.ForeignKey("products.Product", on_delete=models.SET_NULL, blank=True, null=True, related_name="ads")
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to="ads/images/")
    ad_type = models.CharField(max_length=30, choices=AdType.choices)
    price_paid = models.DecimalField(max_digits=10, decimal_places=2)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)
    impressions = models.PositiveIntegerField(default=0)
    clicks = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Ad"
        verbose_name_plural = "Ads"

    def __str__(self) -> str:
        return f"{self.title} ({self.get_ad_type_display()})"
