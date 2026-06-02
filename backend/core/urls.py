from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("users.urls")),
    path("api/", include("stores.urls")),
    path("api/", include("products.urls")),
    path("api/", include("orders.urls")),
    path("api/", include("deliveries.urls")),
    path("api/", include("ads.urls")),
    path("api/dashboard/", include("dashboard.urls")),
]
