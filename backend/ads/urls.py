from rest_framework.routers import DefaultRouter

from .views import AdViewSet

router = DefaultRouter()
router.register("ads", AdViewSet, basename="ads")

urlpatterns = router.urls
