from django.db.models import F
from django.utils import timezone
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.authentication import JWTAuthentication

from core.api import ApiResponseMixin
from stores.models import Store
from users.permissions import IsStoreOwner

from .models import Ad
from .serializers import AdCreateSerializer, AdSerializer


class AdViewSet(ApiResponseMixin, mixins.CreateModelMixin, viewsets.GenericViewSet):
    authentication_classes = [JWTAuthentication]
    queryset = Ad.objects.select_related("store", "product").order_by("-created_at")

    def get_permissions(self):
        if self.action in {"active", "click"}:
            permission_classes = [permissions.AllowAny]
        elif self.action in {"create", "my_ads"}:
            permission_classes = [permissions.IsAuthenticated, IsStoreOwner]
        else:
            permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in permission_classes]

    def get_serializer_class(self):
        if self.action == "create":
            return AdCreateSerializer
        return AdSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        provided_store = serializer.validated_data.get("store")
        owner_stores = Store.objects.filter(owner=request.user).order_by("-created_at")

        if provided_store is not None:
            if provided_store.owner_id != request.user.id:
                raise ValidationError({"store": "You can only create ads for your own store."})
            store = provided_store
        else:
            store = owner_stores.first()
            if store is None:
                raise ValidationError({"store": "No store found for authenticated owner."})

        product = serializer.validated_data.get("product")
        if product is not None and product.store_id != store.id:
            raise ValidationError({"product": "Product must belong to the selected store."})

        ad = serializer.save(store=store)
        output = AdSerializer(ad, context={"request": request})

        return self.success_response(
            data=output.data,
            message="Ad created successfully.",
            status_code=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=["get"], url_path="active", permission_classes=[permissions.AllowAny])
    def active(self, request):
        now = timezone.now()
        queryset = Ad.objects.select_related("store", "product").filter(
            is_active=True,
            starts_at__lte=now,
            ends_at__gte=now,
        )

        ad_type = request.query_params.get("ad_type")
        if ad_type in {Ad.AdType.BANNER, Ad.AdType.FEATURED_PRODUCT, Ad.AdType.SPONSORED_STORE}:
            queryset = queryset.filter(ad_type=ad_type)

        queryset = queryset.order_by("-created_at")

        page = self.paginate_queryset(queryset)
        if page is not None:
            ad_ids = [ad.id for ad in page]
            if ad_ids:
                Ad.objects.filter(id__in=ad_ids).update(impressions=F("impressions") + 1)
                for ad in page:
                    ad.impressions += 1

            serializer = AdSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        ad_ids = list(queryset.values_list("id", flat=True))
        if ad_ids:
            Ad.objects.filter(id__in=ad_ids).update(impressions=F("impressions") + 1)

        serializer = AdSerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="Active ads fetched successfully.")

    @action(detail=True, methods=["post"], url_path="click", permission_classes=[permissions.AllowAny])
    def click(self, request, pk=None):
        ad = self.get_object()
        Ad.objects.filter(id=ad.id).update(clicks=F("clicks") + 1)
        ad.refresh_from_db(fields=["clicks"])

        return self.success_response(
            data={"id": ad.id, "clicks": ad.clicks},
            message="Ad click registered successfully.",
        )

    @action(detail=False, methods=["get"], url_path="my-ads")
    def my_ads(self, request):
        queryset = Ad.objects.select_related("store", "product").filter(store__owner=request.user).order_by("-created_at")

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = AdSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = AdSerializer(queryset, many=True)
        return self.success_response(data=serializer.data, message="My ads fetched successfully.")
