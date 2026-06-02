from rest_framework import serializers

from stores.models import Store

from .models import Category, Product, ProductImage


class CategoryTreeSerializer(serializers.ModelSerializer):
    children = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ("id", "name", "icon", "parent", "created_at", "children")

    def get_children(self, obj):
        children = obj.children.all().order_by("-created_at")
        return CategoryTreeSerializer(children, many=True, context=self.context).data


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "icon", "parent", "created_at")


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ("id", "image", "order", "created_at")


class ProductStoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Store
        fields = ("id", "name", "city", "address", "latitude", "longitude")


class ProductListSerializer(serializers.ModelSerializer):
    store = ProductStoreSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    first_image = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = (
            "id",
            "name",
            "description",
            "price",
            "condition",
            "weight_kg",
            "is_featured",
            "pickup_only",
            "store",
            "category",
            "first_image",
            "created_at",
        )

    def get_first_image(self, obj):
        image = obj.images.order_by("order", "id").first()
        return image.image if image else None


class ProductDetailSerializer(serializers.ModelSerializer):
    store = ProductStoreSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    images = ProductImageSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = (
            "id",
            "store",
            "category",
            "name",
            "description",
            "price",
            "stock",
            "condition",
            "weight_kg",
            "is_available",
            "is_featured",
            "pickup_only",
            "images",
            "created_at",
            "updated_at",
        )


class ProductSerializer(ProductDetailSerializer):
    pass


class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(queryset=Category.objects.all())
    images = serializers.ListField(child=serializers.URLField(), write_only=True, required=False)

    class Meta:
        model = Product
        fields = (
            "id",
            "category",
            "name",
            "description",
            "price",
            "stock",
            "condition",
            "weight_kg",
            "pickup_only",
            "is_featured",
            "images",
            "is_available",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "is_available", "created_at", "updated_at")

    def validate_stock(self, value):
        if value < 0:
            raise serializers.ValidationError("Stock cannot be negative.")
        return value

    def validate_weight_kg(self, value):
        if value <= 0:
            raise serializers.ValidationError("Weight must be greater than zero.")
        return value
