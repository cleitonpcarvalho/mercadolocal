from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import DecimalField, Q, Sum, Value
from django.db.models.functions import Coalesce
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication

from ads.models import Ad
from core.api import ApiResponseMixin
from deliveries.models import Delivery
from orders.models import Order
from products.models import Product
from stores.models import Store
from users.permissions import IsAdminUser

from .serializers import (
    DashboardAdCreateSerializer,
    DashboardAdSerializer,
    DashboardAdUpdateSerializer,
    DashboardDeliverySerializer,
    DashboardOrderSerializer,
    DashboardProductSerializer,
    DashboardProductUpdateSerializer,
    DashboardStoreSerializer,
    DashboardStoreUpdateSerializer,
    DashboardUserSerializer,
    DashboardUserUpdateSerializer,
)

User = get_user_model()


def parse_bool_param(value):
    if value is None:
        return None

    normalized = str(value).strip().lower()
    if normalized in {"1", "true", "yes", "y"}:
        return True
    if normalized in {"0", "false", "no", "n"}:
        return False
    return None


class DashboardStatsAPIView(ApiResponseMixin, APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]

    def get(self, request):
        today = timezone.localdate()

        paid_orders = Order.objects.filter(payment_status=Order.PaymentStatus.PAID)
        revenue_today = paid_orders.filter(created_at__date=today).aggregate(
            total=Coalesce(Sum("total"), Value(0), output_field=DecimalField(max_digits=12, decimal_places=2))
        )["total"]
        revenue_total = paid_orders.aggregate(
            total=Coalesce(Sum("total"), Value(0), output_field=DecimalField(max_digits=12, decimal_places=2))
        )["total"]

        revenue_last_7_days = []
        for day_offset in range(6, -1, -1):
            target_date = today - timedelta(days=day_offset)
            amount = paid_orders.filter(created_at__date=target_date).aggregate(
                total=Coalesce(Sum("total"), Value(0), output_field=DecimalField(max_digits=12, decimal_places=2))
            )["total"]
            revenue_last_7_days.append(
                {
                    "date": target_date.isoformat(),
                    "amount": amount,
                }
            )

        data = {
            "total_users": User.objects.filter(role=User.Role.CUSTOMER).count(),
            "total_store_owners": User.objects.filter(role=User.Role.STORE_OWNER).count(),
            "total_stores": Store.objects.count(),
            "total_products": Product.objects.count(),
            "total_orders": Order.objects.count(),
            "total_orders_today": Order.objects.filter(created_at__date=today).count(),
            "revenue_today": revenue_today,
            "revenue_total": revenue_total,
            "pending_stores": Store.objects.filter(is_verified=False).count(),
            "active_deliveries": Delivery.objects.filter(
                status__in=[Delivery.Status.ACCEPTED, Delivery.Status.PICKED_UP]
            ).count(),
            "revenue_last_7_days": revenue_last_7_days,
        }
        return self.success_response(data=data, message="Dashboard stats fetched successfully.")


class DashboardUserViewSet(
    ApiResponseMixin,
    mixins.ListModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = User.objects.all().order_by("-created_at")

    def get_queryset(self):
        queryset = User.objects.all().order_by("-created_at")

        if self.action == "list":
            role = self.request.query_params.get("role")
            city = self.request.query_params.get("city")
            search = self.request.query_params.get("search")

            if role:
                queryset = queryset.filter(role=role)
            if city:
                queryset = queryset.filter(city__iexact=city.strip())
            if search:
                cleaned = search.strip()
                queryset = queryset.filter(
                    Q(first_name__icontains=cleaned)
                    | Q(email__icontains=cleaned)
                    | Q(username__icontains=cleaned)
                )

        return queryset

    def get_serializer_class(self):
        if self.action in {"update", "partial_update"}:
            return DashboardUserUpdateSerializer
        return DashboardUserSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Users fetched successfully.")

    def partial_update(self, request, *args, **kwargs):
        user = self.get_object()
        serializer = self.get_serializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        output = DashboardUserSerializer(user)
        return self.success_response(data=output.data, message="User updated successfully.")


class DashboardStoreViewSet(
    ApiResponseMixin,
    mixins.ListModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Store.objects.select_related("owner").all().order_by("-created_at")

    def get_queryset(self):
        queryset = Store.objects.select_related("owner").all().order_by("-created_at")

        if self.action == "list":
            verified_param = parse_bool_param(self.request.query_params.get("is_verified"))
            active_param = parse_bool_param(self.request.query_params.get("is_active"))
            city = self.request.query_params.get("city")
            search = self.request.query_params.get("search")

            if verified_param is not None:
                queryset = queryset.filter(is_verified=verified_param)
            if active_param is not None:
                queryset = queryset.filter(is_active=active_param)
            if city:
                queryset = queryset.filter(city__iexact=city.strip())
            if search:
                cleaned = search.strip()
                queryset = queryset.filter(
                    Q(name__icontains=cleaned)
                    | Q(owner__first_name__icontains=cleaned)
                    | Q(owner__email__icontains=cleaned)
                )

        return queryset

    def get_serializer_class(self):
        if self.action in {"update", "partial_update"}:
            return DashboardStoreUpdateSerializer
        return DashboardStoreSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Stores fetched successfully.")

    def partial_update(self, request, *args, **kwargs):
        store = self.get_object()
        serializer = self.get_serializer(store, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        output = DashboardStoreSerializer(store)
        return self.success_response(data=output.data, message="Store updated successfully.")


class DashboardOrderViewSet(ApiResponseMixin, mixins.ListModelMixin, viewsets.GenericViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Order.objects.select_related("customer", "store").all().order_by("-created_at")
    serializer_class = DashboardOrderSerializer

    def get_queryset(self):
        queryset = Order.objects.select_related("customer", "store").all().order_by("-created_at")

        status_filter = self.request.query_params.get("status")
        payment_status = self.request.query_params.get("payment_status")
        start_date = self.request.query_params.get("start_date")
        end_date = self.request.query_params.get("end_date")

        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if payment_status:
            queryset = queryset.filter(payment_status=payment_status)

        parsed_start = parse_date(start_date) if start_date else None
        parsed_end = parse_date(end_date) if end_date else None

        if parsed_start is not None:
            queryset = queryset.filter(created_at__date__gte=parsed_start)
        if parsed_end is not None:
            queryset = queryset.filter(created_at__date__lte=parsed_end)

        return queryset

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Orders fetched successfully.")


class DashboardProductViewSet(
    ApiResponseMixin,
    mixins.ListModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Product.objects.select_related("store", "category").all().order_by("-created_at")

    def get_queryset(self):
        queryset = Product.objects.select_related("store", "category").all().order_by("-created_at")

        if self.action == "list":
            store = self.request.query_params.get("store")
            category = self.request.query_params.get("category")
            is_available = parse_bool_param(self.request.query_params.get("is_available"))
            search = self.request.query_params.get("search")

            if store:
                queryset = queryset.filter(store_id=store)
            if category:
                queryset = queryset.filter(category_id=category)
            if is_available is not None:
                queryset = queryset.filter(is_available=is_available)
            if search:
                cleaned = search.strip()
                queryset = queryset.filter(
                    Q(name__icontains=cleaned)
                    | Q(store__name__icontains=cleaned)
                    | Q(category__name__icontains=cleaned)
                )

        return queryset

    def get_serializer_class(self):
        if self.action in {"update", "partial_update"}:
            return DashboardProductUpdateSerializer
        return DashboardProductSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Products fetched successfully.")

    def partial_update(self, request, *args, **kwargs):
        product = self.get_object()
        serializer = self.get_serializer(product, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        output = DashboardProductSerializer(product)
        return self.success_response(data=output.data, message="Product updated successfully.")


class DashboardDeliveryViewSet(ApiResponseMixin, mixins.ListModelMixin, viewsets.GenericViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Delivery.objects.select_related("order", "order__store", "order__customer", "driver").all().order_by(
        "-created_at"
    )
    serializer_class = DashboardDeliverySerializer

    def get_queryset(self):
        queryset = Delivery.objects.select_related(
            "order",
            "order__store",
            "order__customer",
            "driver",
        ).all().order_by("-created_at")

        status_filter = self.request.query_params.get("status")
        city = self.request.query_params.get("city")

        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if city:
            cleaned = city.strip()
            queryset = queryset.filter(
                Q(order__store__city__iexact=cleaned) | Q(order__customer__city__iexact=cleaned)
            )

        return queryset

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Deliveries fetched successfully.")


class DashboardAdViewSet(
    ApiResponseMixin,
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Ad.objects.select_related("store", "product").all().order_by("-created_at")

    def get_queryset(self):
        queryset = Ad.objects.select_related("store", "product").all().order_by("-created_at")
        ad_type = self.request.query_params.get("ad_type")
        if ad_type:
            queryset = queryset.filter(ad_type=ad_type)
        return queryset

    def get_serializer_class(self):
        if self.action == "create":
            return DashboardAdCreateSerializer
        if self.action in {"update", "partial_update"}:
            return DashboardAdUpdateSerializer
        return DashboardAdSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Ads fetched successfully.")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ad = serializer.save()
        output = DashboardAdSerializer(ad)
        return self.success_response(
            data=output.data,
            message="Platform ad created successfully.",
            status_code=status.HTTP_201_CREATED,
        )

    def partial_update(self, request, *args, **kwargs):
        ad = self.get_object()
        serializer = self.get_serializer(ad, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        output = DashboardAdSerializer(ad)
        return self.success_response(data=output.data, message="Ad updated successfully.")
