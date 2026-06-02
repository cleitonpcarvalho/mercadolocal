from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import StoreViewSet

router = DefaultRouter()
router.register("stores", StoreViewSet, basename="stores")

urlpatterns = router.urls + [
    path("store-categories/", StoreViewSet.as_view({"get": "categories"}), name="store-categories-legacy"),
]
