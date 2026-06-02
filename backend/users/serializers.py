from django.contrib.auth import password_validation
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import CustomUser


class UserAuthSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="first_name")

    class Meta:
        model = CustomUser
        fields = ("id", "name", "email", "role", "city")


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    role = serializers.ChoiceField(
        choices=[
            CustomUser.Role.CUSTOMER,
            CustomUser.Role.STORE_OWNER,
            CustomUser.Role.DELIVERY_DRIVER,
        ]
    )
    city = serializers.CharField(max_length=120, required=False, allow_blank=True)
    state = serializers.CharField(max_length=120, required=False, allow_blank=True)

    def validate_email(self, value: str) -> str:
        email = value.lower().strip()
        if CustomUser.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("This email is already registered.")
        return email

    def validate_password(self, value: str) -> str:
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long.")
        password_validation.validate_password(value)
        return value

    def create(self, validated_data: dict) -> CustomUser:
        email = validated_data["email"].lower().strip()
        password = validated_data.pop("password")
        name = validated_data.pop("name")

        user = CustomUser(
            username=email,
            email=email,
            first_name=name,
            is_active=True,
            is_verified=False,
            **validated_data,
        )
        user.set_password(password)
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs: dict) -> dict:
        email = attrs.get("email", "").lower().strip()
        password = attrs.get("password", "")

        user = CustomUser.objects.filter(email__iexact=email).first()
        if user is None or not user.check_password(password):
            raise serializers.ValidationError("Invalid email or password.")

        if not user.is_active:
            raise serializers.ValidationError("This account is inactive.")

        refresh = RefreshToken.for_user(user)

        attrs["user"] = user
        attrs["access"] = str(refresh.access_token)
        attrs["refresh"] = str(refresh)
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="first_name", required=False, allow_blank=True)

    class Meta:
        model = CustomUser
        fields = (
            "id",
            "name",
            "email",
            "role",
            "phone",
            "avatar",
            "city",
            "state",
            "latitude",
            "longitude",
            "is_verified",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "email",
            "role",
            "is_verified",
            "created_at",
            "updated_at",
        )


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=8)

    def validate(self, attrs: dict) -> dict:
        request = self.context.get("request")
        user = getattr(request, "user", None)

        if user is None or not user.is_authenticated:
            raise serializers.ValidationError("Authentication is required.")

        if not user.check_password(attrs["old_password"]):
            raise serializers.ValidationError({"old_password": "Old password is incorrect."})

        if attrs["old_password"] == attrs["new_password"]:
            raise serializers.ValidationError({"new_password": "New password must be different from old password."})

        password_validation.validate_password(attrs["new_password"], user=user)
        return attrs
