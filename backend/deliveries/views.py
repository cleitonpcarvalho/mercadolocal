from django.db import transaction
from django.utils import timezone
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework_simplejwt.authentication import JWTAuthentication

from core.api import ApiResponseMixin
from orders.models import Order
from users.permissions import IsCustomer, IsDeliveryDriver

from .models import Delivery, DriverRating
from .serializers import (
    DeliveryLocationSerializer,
    DeliverySerializer,
    DeliveryStatusUpdateSerializer,
    DriverRatingCreateSerializer,
    DriverRatingSerializer,
)


class DeliveryViewSet(ApiResponseMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    authentication_classes = [JWTAuthentication]
    queryset = Delivery.objects.select_related("order", "order__store", "order__customer", "driver").order_by("-created_at")

    def get_permissions(self):
        if self.action in {"available", "accept", "status_update", "update_location", "my_deliveries"}:
            permission_classes = [permissions.IsAuthenticated, IsDeliveryDriver]
        elif self.action == "rate":
            permission_classes = [permissions.IsAuthenticated, IsCustomer]
        else:
            permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in permission_classes]

    def retrieve(self, request, *args, **kwargs):
        delivery = self.get_object()
        serializer = DeliverySerializer(delivery)
        return self.success_response(data=serializer.data, message="Delivery fetched successfully.")

    @action(detail=False, methods=["get"], url_path="available")
    def available(self, request):
        city = (request.user.city or "").strip()
        queryset = Delivery.objects.select_related("order", "order__store", "order__customer", "driver").filter(
            status=Delivery.Status.WAITING
        )
        queryset = queryset.filter(order__status=Order.Status.READY)

        if city:
            queryset = queryset.filter(order__store__city__iexact=city)

        queryset = queryset.order_by("created_at")

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = DeliverySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = DeliverySerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Available deliveries fetched successfully.")

    @action(detail=True, methods=["post"], url_path="accept")
    def accept(self, request, pk=None):
        with transaction.atomic():
            delivery = (
                Delivery.objects.select_for_update()
                .select_related("order", "order__store", "order__customer")
                .filter(id=pk)
                .first()
            )
            if delivery is None:
                raise NotFound("Delivery not found.")

            if delivery.status != Delivery.Status.WAITING:
                raise ValidationError({"status": "This delivery is no longer available."})

            if delivery.order.status != Order.Status.READY:
                raise ValidationError({"order": "Order is not ready for pickup yet."})

            if delivery.driver_id and delivery.driver_id != request.user.id:
                raise ValidationError({"driver": "Delivery already assigned to another driver."})

            delivery.driver = request.user
            delivery.status = Delivery.Status.ACCEPTED
            delivery.save(update_fields=["driver", "status"])

        serializer = DeliverySerializer(delivery)
        return self.success_response(data=serializer.data, message="Delivery accepted successfully.")

    @action(detail=True, methods=["patch"], url_path="status")
    def status_update(self, request, pk=None):
        serializer = DeliveryStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        delivery = self.get_object()
        if delivery.driver_id != request.user.id:
            raise PermissionDenied("Only the assigned driver can update this delivery.")

        next_status = serializer.validated_data["status"]
        allowed_transitions = {
            Delivery.Status.ACCEPTED: Delivery.Status.PICKED_UP,
            Delivery.Status.PICKED_UP: Delivery.Status.DELIVERED,
        }
        expected_next_status = allowed_transitions.get(delivery.status)

        if expected_next_status is None or next_status != expected_next_status:
            raise ValidationError(
                {"status": f"Cannot change status from '{delivery.status}' to '{next_status}'."}
            )

        with transaction.atomic():
            locked_delivery = Delivery.objects.select_for_update().select_related("order").get(id=delivery.id)
            locked_delivery.status = next_status

            if next_status == Delivery.Status.PICKED_UP:
                if locked_delivery.started_at is None:
                    locked_delivery.started_at = timezone.now()
                locked_delivery.order.status = Order.Status.IN_DELIVERY
                locked_delivery.order.save(update_fields=["status", "updated_at"])

            if next_status == Delivery.Status.DELIVERED:
                locked_delivery.delivered_at = timezone.now()
                locked_delivery.order.status = Order.Status.DELIVERED
                locked_delivery.order.save(update_fields=["status", "updated_at"])

            locked_delivery.save(update_fields=["status", "started_at", "delivered_at"])

        locked_delivery.refresh_from_db()
        output = DeliverySerializer(locked_delivery)
        return self.success_response(data=output.data, message="Delivery status updated successfully.")

    @action(detail=True, methods=["patch"], url_path="location")
    def update_location(self, request, pk=None):
        serializer = DeliveryLocationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        delivery = self.get_object()
        if delivery.driver_id != request.user.id:
            raise PermissionDenied("Only the assigned driver can update this delivery location.")

        if delivery.status not in {Delivery.Status.ACCEPTED, Delivery.Status.PICKED_UP}:
            raise ValidationError({"status": "Delivery is not active for location updates."})

        delivery.driver_latitude = serializer.validated_data["driver_latitude"]
        delivery.driver_longitude = serializer.validated_data["driver_longitude"]
        delivery.save(update_fields=["driver_latitude", "driver_longitude"])

        output = DeliverySerializer(delivery)
        return self.success_response(data=output.data, message="Driver location updated successfully.")

    @action(detail=True, methods=["post"], url_path="rate")
    def rate(self, request, pk=None):
        serializer = DriverRatingCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        delivery = self.get_object()

        if delivery.order.customer_id != request.user.id:
            raise PermissionDenied("Only the order customer can rate this delivery.")
        if delivery.status != Delivery.Status.DELIVERED:
            raise ValidationError({"status": "Delivery must be completed before rating."})
        if DriverRating.objects.filter(delivery=delivery, customer=request.user).exists():
            raise ValidationError({"rating": "You have already rated this delivery."})

        rating = DriverRating.objects.create(
            delivery=delivery,
            customer=request.user,
            rating=serializer.validated_data["rating"],
            comment=serializer.validated_data.get("comment", ""),
        )

        output = DriverRatingSerializer(rating)
        return self.success_response(
            data=output.data,
            message="Driver rated successfully.",
            status_code=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=["get"], url_path="my-deliveries")
    def my_deliveries(self, request):
        queryset = Delivery.objects.select_related("order", "order__store", "order__customer", "driver").filter(
            driver=request.user
        ).order_by("-created_at")

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = DeliverySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = DeliverySerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="My deliveries fetched successfully.")
