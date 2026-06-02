from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework_simplejwt.authentication import JWTAuthentication

from core.api import ApiResponseMixin
from users.permissions import IsStoreOwner

from .models import Store, StoreCategory
from .serializers import (
    StoreCategorySerializer,
    StoreCreateUpdateSerializer,
    StoreDetailSerializer,
    StoreListSerializer,
)


class StoreViewSet(
    ApiResponseMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    authentication_classes = [JWTAuthentication]

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "my_store"}:
            permission_classes = [permissions.IsAuthenticated, IsStoreOwner]
        else:
            permission_classes = [permissions.AllowAny]
        return [permission() for permission in permission_classes]

    def get_queryset(self):
        queryset = Store.objects.select_related("owner").prefetch_related("category_relations__category")

        if self.action in {"list", "retrieve"}:
            queryset = queryset.filter(is_active=True, is_verified=True)

        if self.action == "list":
            city = self.request.query_params.get("city")
            state = self.request.query_params.get("state")
            category = self.request.query_params.get("category")
            search = self.request.query_params.get("search")

            if city:
                queryset = queryset.filter(city__iexact=city.strip())
            if state:
                queryset = queryset.filter(state__iexact=state.strip())
            if category:
                queryset = queryset.filter(category_relations__category_id=category)
            if search:
                queryset = queryset.filter(name__icontains=search.strip())

            queryset = queryset.distinct().order_by("-created_at")

        return queryset

    def get_serializer_class(self):
        if self.action == "list":
            return StoreListSerializer
        if self.action in {"retrieve", "my_store"}:
            return StoreDetailSerializer
        if self.action in {"create", "update", "partial_update"}:
            return StoreCreateUpdateSerializer
        if self.action == "categories":
            return StoreCategorySerializer
        return StoreDetailSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Stores fetched successfully.")

    def retrieve(self, request, *args, **kwargs):
        store = self.get_object()
        serializer = self.get_serializer(store)
        return self.success_response(data=serializer.data, message="Store fetched successfully.")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        store = serializer.save(owner=request.user)

        output = StoreDetailSerializer(store, context={"request": request})
        return self.success_response(
            data=output.data,
            message="Store created successfully.",
            status_code=status.HTTP_201_CREATED,
        )

    def partial_update(self, request, *args, **kwargs):
        store = self.get_object()
        if store.owner_id != request.user.id:
            raise PermissionDenied("You can only update your own store.")

        serializer = self.get_serializer(store, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        store = serializer.save()

        output = StoreDetailSerializer(store, context={"request": request})
        return self.success_response(data=output.data, message="Store updated successfully.")

    def update(self, request, *args, **kwargs):
        store = self.get_object()
        if store.owner_id != request.user.id:
            raise PermissionDenied("You can only update your own store.")

        serializer = self.get_serializer(store, data=request.data)
        serializer.is_valid(raise_exception=True)
        store = serializer.save()

        output = StoreDetailSerializer(store, context={"request": request})
        return self.success_response(data=output.data, message="Store updated successfully.")

    @action(detail=False, methods=["get"], url_path="my-store")
    def my_store(self, request):
        store = (
            Store.objects.select_related("owner")
            .prefetch_related("category_relations__category")
            .filter(owner=request.user)
            .order_by("-created_at")
            .first()
        )

        if store is None:
            return self.error_response(
                data={},
                message="Store not found for authenticated owner.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        serializer = self.get_serializer(store)
        return self.success_response(data=serializer.data, message="Store fetched successfully.")

    @action(detail=False, methods=["get"], url_path="categories", permission_classes=[permissions.AllowAny])
    def categories(self, request):
        queryset = StoreCategory.objects.all().order_by("-created_at")
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = StoreCategorySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = StoreCategorySerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Store categories fetched successfully.")
