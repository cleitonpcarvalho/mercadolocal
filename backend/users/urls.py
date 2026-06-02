from django.urls import path

from .views import ChangePasswordView, LoginView, LogoutView, MeView, RegisterView, TokenRefreshAPIView

urlpatterns = [
    path("users/register/", RegisterView.as_view(), name="users-register"),
    path("users/login/", LoginView.as_view(), name="users-login"),
    path("users/token/refresh/", TokenRefreshAPIView.as_view(), name="users-token-refresh"),
    path("users/logout/", LogoutView.as_view(), name="users-logout"),
    path("users/me/", MeView.as_view(), name="users-me"),
    path("users/change-password/", ChangePasswordView.as_view(), name="users-change-password"),
]
