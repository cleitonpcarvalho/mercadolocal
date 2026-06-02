from rest_framework import serializers

from products.models import Product
from stores.models import Store

from .models import Ad


class AdSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source="store.name", read_only=True)
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = Ad
        fields = (
            "id",
            "store",
            "store_name",
            "product",
            "product_name",
            "title",
            "description",
            "image",
            "ad_type",
            "price_paid",
            "starts_at",
            "ends_at",
            "is_active",
            "impressions",
            "clicks",
            "created_at",
        )


class AdCreateSerializer(serializers.ModelSerializer):
    store = serializers.PrimaryKeyRelatedField(queryset=Store.objects.all(), required=False)
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all(), required=False, allow_null=True)

    class Meta:
        model = Ad
        fields = (
            "id",
            "store",
            "product",
            "title",
            "description",
            "image",
            "ad_type",
            "price_paid",
            "starts_at",
            "ends_at",
            "is_active",
            "created_at",
        )
        read_only_fields = ("id", "created_at")

    def validate(self, attrs):
        starts_at = attrs.get("starts_at")
        ends_at = attrs.get("ends_at")
        if starts_at and ends_at and ends_at <= starts_at:
            raise serializers.ValidationError("ends_at must be greater than starts_at.")
        return attrs
