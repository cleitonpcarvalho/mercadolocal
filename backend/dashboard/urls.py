from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    DashboardAdViewSet,
    DashboardDeliveryViewSet,
    DashboardOrderViewSet,
    DashboardProductViewSet,
    DashboardStatsAPIView,
    DashboardStoreViewSet,
    DashboardUserViewSet,
)

router = DefaultRouter()
router.register("users", DashboardUserViewSet, basename="dashboard-users")
router.register("stores", DashboardStoreViewSet, basename="dashboard-stores")
router.register("orders", DashboardOrderViewSet, basename="dashboard-orders")
router.register("products", DashboardProductViewSet, basename="dashboard-products")
router.register("deliveries", DashboardDeliveryViewSet, basename="dashboard-deliveries")
router.register("ads", DashboardAdViewSet, basename="dashboard-ads")

urlpatterns = [
    path("stats/", DashboardStatsAPIView.as_view(), name="dashboard-stats"),
    path("", include(router.urls)),
]
