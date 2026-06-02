from decimal import Decimal
from math import asin, cos, radians, sin, sqrt

from django.db import transaction
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework_simplejwt.authentication import JWTAuthentication

from core.api import ApiResponseMixin
from deliveries.models import Delivery
from products.models import Product
from stores.models import Store
from users.models import CustomUser
from users.permissions import IsCustomer, IsStoreOwner

from .models import Order, OrderItem
from .serializers import OrderCreateSerializer, OrderDetailSerializer, OrderListSerializer


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    earth_radius_km = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = (
        sin(d_lat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
    )
    c = 2 * asin(sqrt(a))
    return earth_radius_km * c


def _calculate_delivery_fee(*, store: Store, delivery_latitude: Decimal, delivery_longitude: Decimal) -> Decimal:
    """
    MVP fee model:
    - base fee + distance fee
    - minimum fee to avoid zero/too-low values
    """
    distance_km = _haversine_km(
        float(store.latitude),
        float(store.longitude),
        float(delivery_latitude),
        float(delivery_longitude),
    )
    base_fee = Decimal("4.00")
    per_km_fee = Decimal("1.20")
    minimum_fee = Decimal("5.00")
    variable_fee = base_fee + (Decimal(str(distance_km)) * per_km_fee)
    return max(variable_fee.quantize(Decimal("0.01")), minimum_fee)


class OrderViewSet(
    ApiResponseMixin,
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]

    def get_permissions(self):
        if self.action in {"create", "cancel"}:
            permission_classes = [permissions.IsAuthenticated, IsCustomer]
        elif self.action == "status_update":
            permission_classes = [permissions.IsAuthenticated, IsStoreOwner]
        else:
            permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in permission_classes]

    def get_serializer_class(self):
        if self.action == "create":
            return OrderCreateSerializer
        if self.action == "list":
            return OrderListSerializer
        return OrderDetailSerializer

    def get_queryset(self):
        queryset = (
            Order.objects.select_related("customer", "store", "delivery", "delivery__driver")
            .prefetch_related("items__product")
            .order_by("-created_at")
        )

        user = self.request.user
        if not user.is_authenticated:
            return queryset.none()

        if user.role == CustomUser.Role.CUSTOMER:
            queryset = queryset.filter(customer=user)
        elif user.role == CustomUser.Role.STORE_OWNER:
            queryset = queryset.filter(store__owner=user)
        elif user.role == CustomUser.Role.DELIVERY_DRIVER:
            queryset = queryset.filter(delivery__driver=user)
        elif user.role != CustomUser.Role.ADMIN:
            queryset = queryset.none()

        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        return queryset

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Orders fetched successfully.")

    def retrieve(self, request, *args, **kwargs):
        order = self.get_object()
        serializer = self.get_serializer(order)
        return self.success_response(data=serializer.data, message="Order fetched successfully.")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        validated = serializer.validated_data
        store = Store.objects.filter(id=validated["store"], is_active=True).first()
        if store is None:
            raise ValidationError({"store": "Store not found or inactive."})

        items_data = validated["items"]
        product_ids = [item["product"] for item in items_data]

        with transaction.atomic():
            products = list(
                Product.objects.select_for_update()
                .filter(id__in=product_ids, store=store)
                .order_by("id")
            )
            products_map = {product.id: product for product in products}

            if len(products_map) != len(set(product_ids)):
                raise ValidationError({"items": "All products must belong to the selected store."})

            requested_quantities = {}
            for item in items_data:
                requested_quantities[item["product"]] = requested_quantities.get(item["product"], 0) + item["quantity"]

            for product_id, total_quantity in requested_quantities.items():
                product = products_map[product_id]
                if not product.is_available:
                    raise ValidationError({"items": f"Product '{product.name}' is unavailable."})
                if product.stock < total_quantity:
                    raise ValidationError({"items": f"Insufficient stock for '{product.name}'."})

            subtotal = Decimal("0.00")
            order_items_to_create = []

            for item in items_data:
                product = products_map[item["product"]]
                quantity = item["quantity"]

                unit_price = product.price
                line_subtotal = (unit_price * quantity).quantize(Decimal("0.01"))
                subtotal += line_subtotal

                order_items_to_create.append(
                    {
                        "product": product,
                        "quantity": quantity,
                        "unit_price": unit_price,
                        "subtotal": line_subtotal,
                    }
                )

            subtotal = subtotal.quantize(Decimal("0.01"))
            delivery_fee = _calculate_delivery_fee(
                store=store,
                delivery_latitude=validated["delivery_latitude"],
                delivery_longitude=validated["delivery_longitude"],
            )
            commission_fee = (subtotal * store.commission_rate / Decimal("100")).quantize(Decimal("0.01"))
            total = (subtotal + delivery_fee + commission_fee).quantize(Decimal("0.01"))

            order = Order.objects.create(
                customer=request.user,
                store=store,
                status=Order.Status.PENDING,
                delivery_address=validated["delivery_address"],
                delivery_latitude=validated["delivery_latitude"],
                delivery_longitude=validated["delivery_longitude"],
                subtotal=subtotal,
                delivery_fee=delivery_fee,
                commission_fee=commission_fee,
                total=total,
                payment_method=validated["payment_method"],
                payment_status=Order.PaymentStatus.PENDING,
                notes=validated.get("notes", ""),
            )

            order_item_models = []
            for item_data in order_items_to_create:
                product = item_data["product"]
                quantity = item_data["quantity"]

                order_item_models.append(
                    OrderItem(
                        order=order,
                        product=product,
                        quantity=quantity,
                        unit_price=item_data["unit_price"],
                        subtotal=item_data["subtotal"],
                    )
                )

                product.stock -= quantity
                if product.stock <= 0:
                    product.stock = 0
                    product.is_available = False
                product.save(update_fields=["stock", "is_available", "updated_at"])

            OrderItem.objects.bulk_create(order_item_models)

            Delivery.objects.create(
                order=order,
                status=Delivery.Status.WAITING,
                pickup_latitude=store.latitude,
                pickup_longitude=store.longitude,
                delivery_latitude=validated["delivery_latitude"],
                delivery_longitude=validated["delivery_longitude"],
            )

        order.refresh_from_db()
        output = OrderDetailSerializer(order, context={"request": request})
        return self.success_response(
            data=output.data,
            message="Order created successfully.",
            status_code=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["patch"], url_path="status")
    def status_update(self, request, pk=None):
        order = self.get_object()

        if order.store.owner_id != request.user.id:
            raise PermissionDenied("You can only update status for your own store orders.")

        next_status = request.data.get("status")
        allowed_sequence = {
            Order.Status.PENDING: [Order.Status.CONFIRMED],
            Order.Status.CONFIRMED: [Order.Status.PREPARING],
            Order.Status.PREPARING: [Order.Status.READY],
            Order.Status.READY: [],
        }

        if next_status not in {
            Order.Status.PENDING,
            Order.Status.CONFIRMED,
            Order.Status.PREPARING,
            Order.Status.READY,
        }:
            raise ValidationError({"status": "Invalid status for store owner flow."})

        valid_next_statuses = allowed_sequence.get(order.status, [])
        if next_status not in valid_next_statuses:
            raise ValidationError({"status": f"Cannot change status from '{order.status}' to '{next_status}'."})

        order.status = next_status
        order.save(update_fields=["status", "updated_at"])

        output = OrderDetailSerializer(order, context={"request": request})
        return self.success_response(data=output.data, message="Order status updated successfully.")

    @action(detail=True, methods=["post"], url_path="cancel")
    def cancel(self, request, pk=None):
        order = self.get_object()

        if order.customer_id != request.user.id:
            raise PermissionDenied("You can only cancel your own orders.")
        if order.status != Order.Status.PENDING:
            raise ValidationError({"status": "Only pending orders can be cancelled."})

        with transaction.atomic():
            locked_order = (
                Order.objects.select_for_update()
                .select_related("delivery")
                .prefetch_related("items__product")
                .get(id=order.id)
            )

            items = list(locked_order.items.all())
            product_ids = [item.product_id for item in items]
            products = Product.objects.select_for_update().filter(id__in=product_ids)
            products_map = {product.id: product for product in products}

            for item in items:
                product = products_map[item.product_id]
                product.stock += item.quantity
                product.is_available = True
                product.save(update_fields=["stock", "is_available", "updated_at"])

            locked_order.status = Order.Status.CANCELLED
            locked_order.save(update_fields=["status", "updated_at"])

            delivery = getattr(locked_order, "delivery", None)
            if delivery is not None:
                delivery.status = Delivery.Status.FAILED
                delivery.save(update_fields=["status"])

        order.refresh_from_db()
        output = OrderDetailSerializer(order, context={"request": request})
        return self.success_response(data=output.data, message="Order cancelled successfully.")
