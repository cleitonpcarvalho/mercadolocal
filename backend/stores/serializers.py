from django.db.models import Avg
from rest_framework import serializers

from .models import Store, StoreCategory, StoreCategoryRelation


class StoreCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreCategory
        fields = ("id", "name", "icon", "created_at")
        read_only_fields = ("id", "created_at")


class StoreListSerializer(serializers.ModelSerializer):
    categories = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = (
            "id",
            "name",
            "description",
            "logo",
            "city",
            "address",
            "latitude",
            "longitude",
            "categories",
        )

    def get_categories(self, obj):
        categories = [relation.category for relation in obj.category_relations.all()]
        return StoreCategorySerializer(categories, many=True).data


class StoreDetailSerializer(serializers.ModelSerializer):
    categories = serializers.SerializerMethodField()
    average_rating = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = (
            "id",
            "name",
            "description",
            "logo",
            "phone",
            "city",
            "state",
            "address",
            "latitude",
            "longitude",
            "is_active",
            "is_verified",
            "commission_rate",
            "average_rating",
            "categories",
            "created_at",
            "updated_at",
        )

    def get_categories(self, obj):
        categories = [relation.category for relation in obj.category_relations.all()]
        return StoreCategorySerializer(categories, many=True).data

    def get_average_rating(self, obj):
        average_rating = obj.orders.aggregate(avg=Avg("delivery__ratings__rating"))["avg"]
        if average_rating is None:
            return None
        return round(float(average_rating), 2)


class StoreCreateUpdateSerializer(serializers.ModelSerializer):
    categories = serializers.ListField(
        child=serializers.IntegerField(min_value=1), write_only=True, required=False
    )

    class Meta:
        model = Store
        fields = (
            "id",
            "name",
            "description",
            "logo",
            "phone",
            "city",
            "state",
            "address",
            "latitude",
            "longitude",
            "is_active",
            "categories",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_categories(self, value):
        if not value:
            return value

        found_categories = StoreCategory.objects.filter(id__in=value)
        if found_categories.count() != len(set(value)):
            raise serializers.ValidationError("One or more categories are invalid.")
        return value

    def create(self, validated_data):
        categories = validated_data.pop("categories", [])
        store = Store.objects.create(**validated_data)
        self._replace_categories(store=store, category_ids=categories)
        return store

    def update(self, instance, validated_data):
        categories = validated_data.pop("categories", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if categories is not None:
            self._replace_categories(store=instance, category_ids=categories)

        return instance

    def _replace_categories(self, *, store, category_ids):
        StoreCategoryRelation.objects.filter(store=store).delete()
        relations = [StoreCategoryRelation(store=store, category_id=category_id) for category_id in set(category_ids)]
        if relations:
            StoreCategoryRelation.objects.bulk_create(relations)
