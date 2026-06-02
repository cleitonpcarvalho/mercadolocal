from django.db.models import Max
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework_simplejwt.authentication import JWTAuthentication

from core.api import ApiResponseMixin
from stores.models import Store
from users.permissions import IsStoreOwner

from .models import Category, Product, ProductImage
from .serializers import (
    CategoryTreeSerializer,
    ProductCreateUpdateSerializer,
    ProductDetailSerializer,
    ProductListSerializer,
)


class ProductViewSet(
    ApiResponseMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]
    queryset = Product.objects.select_related("store", "category").prefetch_related("images")

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy", "my_products"}:
            permission_classes = [permissions.IsAuthenticated, IsStoreOwner]
        else:
            permission_classes = [permissions.AllowAny]
        return [permission() for permission in permission_classes]

    def get_queryset(self):
        queryset = Product.objects.select_related("store", "category").prefetch_related("images")

        if self.action == "list":
            queryset = queryset.filter(is_available=True, pickup_only=False)

            store = self.request.query_params.get("store")
            category = self.request.query_params.get("category")
            search = self.request.query_params.get("search")
            condition = self.request.query_params.get("condition")
            min_price = self.request.query_params.get("min_price")
            max_price = self.request.query_params.get("max_price")
            city = self.request.query_params.get("city")

            if store:
                queryset = queryset.filter(store_id=store)
            if category:
                queryset = queryset.filter(category_id=category)
            if search:
                queryset = queryset.filter(name__icontains=search.strip())
            if condition in {Product.Condition.NEW, Product.Condition.USED}:
                queryset = queryset.filter(condition=condition)
            if min_price:
                queryset = queryset.filter(price__gte=min_price)
            if max_price:
                queryset = queryset.filter(price__lte=max_price)
            if city:
                queryset = queryset.filter(store__city__iexact=city.strip())

            return queryset.order_by("-is_featured", "-created_at")

        if self.action in {"update", "partial_update", "destroy"}:
            return queryset.filter(store__owner=self.request.user).order_by("-created_at")

        return queryset.order_by("-created_at")

    def get_serializer_class(self):
        if self.action == "list":
            return ProductListSerializer
        if self.action in {"retrieve", "my_products"}:
            return ProductDetailSerializer
        if self.action in {"create", "update", "partial_update"}:
            return ProductCreateUpdateSerializer
        return ProductDetailSerializer

    def _get_owner_store(self, user):
        return Store.objects.filter(owner=user).order_by("-created_at").first()

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Products fetched successfully.")

    def retrieve(self, request, *args, **kwargs):
        product = self.get_object()
        is_owner = bool(request.user.is_authenticated and product.store.owner_id == request.user.id)

        if not product.is_available and not is_owner:
            return self.error_response(
                data={},
                message="Product not found.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        serializer = self.get_serializer(product)
        return self.success_response(data=serializer.data, message="Product fetched successfully.")

    def create(self, request, *args, **kwargs):
        owner_store = self._get_owner_store(request.user)
        if owner_store is None:
            raise ValidationError({"store": "No store found for authenticated owner."})

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        images = request.FILES.getlist("images") or serializer.validated_data.pop("images", [])
        product = serializer.save(store=owner_store, is_available=True)

        for index, image in enumerate(images):
            ProductImage.objects.create(product=product, image=image, order=index)

        output = ProductDetailSerializer(product, context={"request": request})
        return self.success_response(
            data=output.data,
            message="Product created successfully.",
            status_code=status.HTTP_201_CREATED,
        )

    def partial_update(self, request, *args, **kwargs):
        product = self.get_object()
        if product.store.owner_id != request.user.id:
            raise PermissionDenied("You can only update your own products.")

        serializer = self.get_serializer(product, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        images = request.FILES.getlist("images") or serializer.validated_data.pop("images", [])
        product = serializer.save()

        if images:
            start_order = product.images.aggregate(max_order=Max("order"))["max_order"]
            start_order = -1 if start_order is None else start_order
            for index, image in enumerate(images):
                ProductImage.objects.create(product=product, image=image, order=start_order + index + 1)

        output = ProductDetailSerializer(product, context={"request": request})
        return self.success_response(data=output.data, message="Product updated successfully.")

    def update(self, request, *args, **kwargs):
        product = self.get_object()
        if product.store.owner_id != request.user.id:
            raise PermissionDenied("You can only update your own products.")

        serializer = self.get_serializer(product, data=request.data)
        serializer.is_valid(raise_exception=True)

        images = request.FILES.getlist("images") or serializer.validated_data.pop("images", [])
        product = serializer.save()

        if images:
            product.images.all().delete()
            for index, image in enumerate(images):
                ProductImage.objects.create(product=product, image=image, order=index)

        output = ProductDetailSerializer(product, context={"request": request})
        return self.success_response(data=output.data, message="Product updated successfully.")

    def destroy(self, request, *args, **kwargs):
        product = self.get_object()
        if product.store.owner_id != request.user.id:
            raise PermissionDenied("You can only remove your own products.")

        product.is_available = False
        product.save(update_fields=["is_available", "updated_at"])

        return self.success_response(
            data={"id": product.id, "is_available": product.is_available},
            message="Product removed successfully.",
        )

    @action(detail=False, methods=["get"], url_path="my-products")
    def my_products(self, request):
        owner_store = self._get_owner_store(request.user)
        if owner_store is None:
            return self.error_response(
                data={},
                message="No store found for authenticated owner.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        queryset = (
            Product.objects.select_related("store", "category")
            .prefetch_related("images")
            .filter(store=owner_store)
            .order_by("-created_at")
        )

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = ProductDetailSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = ProductDetailSerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Products fetched successfully.")

    @action(detail=False, methods=["get"], url_path="categories", permission_classes=[permissions.AllowAny])
    def categories(self, request):
        queryset = Category.objects.filter(parent__isnull=True).order_by("-created_at")

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = CategoryTreeSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = CategoryTreeSerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Categories fetched successfully.")
