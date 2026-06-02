from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .serializers import (
    ChangePasswordSerializer,
    LoginSerializer,
    RegisterSerializer,
    UserAuthSerializer,
    UserProfileSerializer,
)


def json_response(*, success: bool, data: dict | None = None, message: str = "", status_code: int = 200) -> Response:
    return Response(
        {
            "success": success,
            "data": data or {},
            "message": message,
        },
        status=status_code,
    )


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return json_response(
                success=False,
                data=serializer.errors,
                message="Validation failed.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        user = serializer.save()
        refresh = RefreshToken.for_user(user)

        return json_response(
            success=True,
            data={
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserAuthSerializer(user).data,
            },
            message="User registered successfully.",
            status_code=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return json_response(
                success=False,
                data=serializer.errors,
                message="Invalid credentials.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        user = serializer.validated_data["user"]
        return json_response(
            success=True,
            data={
                "access": serializer.validated_data["access"],
                "refresh": serializer.validated_data["refresh"],
                "user": UserAuthSerializer(user).data,
            },
            message="Login successful.",
            status_code=status.HTTP_200_OK,
        )


class TokenRefreshAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = TokenRefreshSerializer(data=request.data)
        if not serializer.is_valid():
            return json_response(
                success=False,
                data=serializer.errors,
                message="Token refresh failed.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        return json_response(
            success=True,
            data=serializer.validated_data,
            message="Token refreshed successfully.",
            status_code=status.HTTP_200_OK,
        )


class LogoutView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return json_response(
                success=False,
                data={"refresh": ["This field is required."]},
                message="Refresh token is required.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            return json_response(
                success=False,
                data={"refresh": ["Invalid or expired refresh token."]},
                message="Logout failed.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        return json_response(
            success=True,
            data={},
            message="Logout successful.",
            status_code=status.HTTP_200_OK,
        )


class MeView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return json_response(
            success=True,
            data=serializer.data,
            message="Profile fetched successfully.",
            status_code=status.HTTP_200_OK,
        )

    def patch(self, request):
        serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
        if not serializer.is_valid():
            return json_response(
                success=False,
                data=serializer.errors,
                message="Profile update failed.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        serializer.save()
        return json_response(
            success=True,
            data=serializer.data,
            message="Profile updated successfully.",
            status_code=status.HTTP_200_OK,
        )


class ChangePasswordView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={"request": request})
        if not serializer.is_valid():
            return json_response(
                success=False,
                data=serializer.errors,
                message="Password change failed.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        request.user.set_password(serializer.validated_data["new_password"])
        request.user.save(update_fields=["password"])

        return json_response(
            success=True,
            data={},
            message="Password changed successfully.",
            status_code=status.HTTP_200_OK,
        )
