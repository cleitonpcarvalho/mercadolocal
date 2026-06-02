from rest_framework import serializers

from .models import Delivery, DriverRating


class DeliverySerializer(serializers.ModelSerializer):
    order_id = serializers.IntegerField(source="order.id", read_only=True)
    order_status = serializers.CharField(source="order.status", read_only=True)
    store_id = serializers.IntegerField(source="order.store.id", read_only=True)
    store_name = serializers.CharField(source="order.store.name", read_only=True)
    store_city = serializers.CharField(source="order.store.city", read_only=True)
    customer_id = serializers.IntegerField(source="order.customer.id", read_only=True)
    customer_name = serializers.SerializerMethodField()
    delivery_address = serializers.CharField(source="order.delivery_address", read_only=True)
    order_notes = serializers.CharField(source="order.notes", read_only=True)
    delivery_fee = serializers.DecimalField(
        source="order.delivery_fee",
        max_digits=10,
        decimal_places=2,
        read_only=True,
    )
    order_total = serializers.DecimalField(
        source="order.total",
        max_digits=10,
        decimal_places=2,
        read_only=True,
    )

    def get_customer_name(self, obj):
        full_name = f"{obj.order.customer.first_name} {obj.order.customer.last_name}".strip()
        return full_name or obj.order.customer.username

    class Meta:
        model = Delivery
        fields = (
            "id",
            "order_id",
            "order_status",
            "store_id",
            "store_name",
            "store_city",
            "customer_id",
            "customer_name",
            "delivery_address",
            "order_notes",
            "delivery_fee",
            "order_total",
            "driver",
            "status",
            "vehicle_type",
            "pickup_latitude",
            "pickup_longitude",
            "delivery_latitude",
            "delivery_longitude",
            "driver_latitude",
            "driver_longitude",
            "estimated_minutes",
            "started_at",
            "delivered_at",
            "created_at",
        )


class DeliveryStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=[Delivery.Status.PICKED_UP, Delivery.Status.DELIVERED])


class DeliveryLocationSerializer(serializers.Serializer):
    driver_latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    driver_longitude = serializers.DecimalField(max_digits=9, decimal_places=6)


class DriverRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverRating
        fields = ("id", "delivery", "customer", "rating", "comment", "created_at")


class DriverRatingCreateSerializer(serializers.Serializer):
    rating = serializers.IntegerField(min_value=1, max_value=5)
    comment = serializers.CharField(required=False, allow_blank=True)
