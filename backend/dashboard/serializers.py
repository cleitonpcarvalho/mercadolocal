from decimal import Decimal

from django.contrib.auth import get_user_model
from rest_framework import serializers

from ads.models import Ad
from deliveries.models import Delivery
from orders.models import Order
from products.models import Product
from stores.models import Store

User = get_user_model()


class DashboardUserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="first_name")

    class Meta:
        model = User
        fields = (
            "id",
            "name",
            "email",
            "role",
            "city",
            "state",
            "is_verified",
            "is_active",
            "created_at",
        )


class DashboardUserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("is_verified", "is_active")


class DashboardStoreSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source="owner.first_name", read_only=True)

    class Meta:
        model = Store
        fields = (
            "id",
            "name",
            "owner_name",
            "city",
            "is_verified",
            "is_active",
            "commission_rate",
            "created_at",
        )


class DashboardStoreUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Store
        fields = ("is_verified", "is_active", "commission_rate")


class DashboardOrderSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source="customer.first_name", read_only=True)
    store_name = serializers.CharField(source="store.name", read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "customer_name",
            "store_name",
            "total",
            "status",
            "payment_status",
            "created_at",
        )


class DashboardProductSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source="store.name", read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = Product
        fields = (
            "id",
            "name",
            "store_name",
            "category_name",
            "price",
            "stock",
            "condition",
            "is_available",
            "is_featured",
            "created_at",
        )


class DashboardProductUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ("is_available", "is_featured")


class DashboardDeliverySerializer(serializers.ModelSerializer):
    order_id = serializers.IntegerField(source="order.id", read_only=True)
    driver_name = serializers.SerializerMethodField()

    class Meta:
        model = Delivery
        fields = (
            "id",
            "order_id",
            "driver_name",
            "status",
            "created_at",
            "delivered_at",
        )

    def get_driver_name(self, obj):
        if obj.driver_id is None:
            return None
        return obj.driver.first_name or obj.driver.email


class DashboardAdSerializer(serializers.ModelSerializer):
    store_name = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()

    class Meta:
        model = Ad
        fields = (
            "id",
            "store_name",
            "title",
            "description",
            "image",
            "ad_type",
            "is_active",
            "impressions",
            "clicks",
            "starts_at",
            "ends_at",
            "created_at",
        )

    def get_store_name(self, obj):
        if obj.store_id is None:
            return "Plataforma"
        return obj.store.name

    def get_image(self, obj):
        return str(obj.image) if obj.image else ""


class DashboardAdCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True)
    image = serializers.URLField(max_length=500)
    ad_type = serializers.ChoiceField(choices=Ad.AdType.choices)
    starts_at = serializers.DateTimeField()
    ends_at = serializers.DateTimeField()

    def validate(self, attrs):
        if attrs["ends_at"] <= attrs["starts_at"]:
            raise serializers.ValidationError("ends_at must be greater than starts_at.")
        return attrs

    def create(self, validated_data):
        return Ad.objects.create(
            store=None,
            product=None,
            title=validated_data["title"],
            description=validated_data.get("description", ""),
            image=validated_data["image"],
            ad_type=validated_data["ad_type"],
            price_paid=Decimal("0.00"),
            starts_at=validated_data["starts_at"],
            ends_at=validated_data["ends_at"],
            is_active=True,
        )


class DashboardAdUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ad
        fields = ("is_active", "ends_at")

    def validate(self, attrs):
        ends_at = attrs.get("ends_at")
        starts_at = self.instance.starts_at
        if ends_at is not None and ends_at <= starts_at:
            raise serializers.ValidationError("ends_at must be greater than starts_at.")
        return attrs
