from rest_framework.permissions import BasePermission

from .models import CustomUser


class IsCustomer(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == CustomUser.Role.CUSTOMER)


class IsStoreOwner(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == CustomUser.Role.STORE_OWNER)


class IsDeliveryDriver(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == CustomUser.Role.DELIVERY_DRIVER)


class IsAdminUser(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == CustomUser.Role.ADMIN)
