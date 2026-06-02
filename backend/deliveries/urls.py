from rest_framework.routers import DefaultRouter

from .views import DeliveryViewSet

router = DefaultRouter()
router.register("deliveries", DeliveryViewSet, basename="deliveries")

urlpatterns = router.urls
