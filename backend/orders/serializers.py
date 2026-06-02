from rest_framework import serializers

from .models import Order, OrderItem


class OrderCreateItemSerializer(serializers.Serializer):
    product = serializers.IntegerField(min_value=1)
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateSerializer(serializers.Serializer):
    store = serializers.IntegerField(min_value=1)
    items = OrderCreateItemSerializer(many=True)
    delivery_address = serializers.CharField(max_length=255)
    delivery_latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    delivery_longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    payment_method = serializers.ChoiceField(choices=Order.PaymentMethod.choices)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("At least one item is required.")
        return value


class OrderItemDetailSerializer(serializers.ModelSerializer):
    product_id = serializers.IntegerField(source="product.id", read_only=True)
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = OrderItem
        fields = ("id", "product_id", "product_name", "quantity", "unit_price", "subtotal")


class OrderListSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source="store.name", read_only=True)
    customer_name = serializers.SerializerMethodField()
    customer_phone = serializers.CharField(source="customer.phone", read_only=True)
    customer_email = serializers.EmailField(source="customer.email", read_only=True)
    items = OrderItemDetailSerializer(many=True, read_only=True)

    def get_customer_name(self, obj):
        full_name = f"{obj.customer.first_name} {obj.customer.last_name}".strip()
        return full_name or obj.customer.username

    class Meta:
        model = Order
        fields = (
            "id",
            "store",
            "store_name",
            "customer_name",
            "customer_phone",
            "customer_email",
            "status",
            "delivery_address",
            "subtotal",
            "delivery_fee",
            "commission_fee",
            "total",
            "payment_method",
            "payment_status",
            "notes",
            "items",
            "created_at",
        )


class OrderDetailSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source="customer.first_name", read_only=True)
    store_name = serializers.CharField(source="store.name", read_only=True)
    items = OrderItemDetailSerializer(many=True, read_only=True)
    delivery = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = (
            "id",
            "customer",
            "customer_name",
            "store",
            "store_name",
            "status",
            "delivery_address",
            "delivery_latitude",
            "delivery_longitude",
            "subtotal",
            "delivery_fee",
            "commission_fee",
            "total",
            "payment_method",
            "payment_status",
            "notes",
            "items",
            "delivery",
            "created_at",
            "updated_at",
        )

    def get_delivery(self, obj):
        delivery = getattr(obj, "delivery", None)
        if delivery is None:
            return None

        return {
            "id": delivery.id,
            "driver": delivery.driver_id,
            "status": delivery.status,
            "vehicle_type": delivery.vehicle_type,
            "pickup_latitude": delivery.pickup_latitude,
            "pickup_longitude": delivery.pickup_longitude,
            "delivery_latitude": delivery.delivery_latitude,
            "delivery_longitude": delivery.delivery_longitude,
            "driver_latitude": delivery.driver_latitude,
            "driver_longitude": delivery.driver_longitude,
            "estimated_minutes": delivery.estimated_minutes,
            "started_at": delivery.started_at,
            "delivered_at": delivery.delivered_at,
            "created_at": delivery.created_at,
        }
