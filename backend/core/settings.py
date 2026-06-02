import os
from datetime import timedelta
from pathlib import Path
from urllib.parse import urlparse

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
DEBUG = os.getenv("DEBUG", "False").lower() == "true"
ALLOWED_HOSTS = [host.strip() for host in os.getenv("ALLOWED_HOSTS", "localhost,127.0.0.1").split(",") if host.strip()]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "rest_framework_simplejwt.token_blacklist",
    "storages",
    "core",
    "users",
    "stores",
    "products",
    "orders",
    "deliveries",
    "ads",
    "dashboard",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "core.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "core.wsgi.application"
ASGI_APPLICATION = "core.asgi.application"


def parse_database_url(url: str) -> dict:
    parsed = urlparse(url)
    password = parsed.password or ""
    return {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": (parsed.path or "/postgres").lstrip("/"),
        "USER": parsed.username or "postgres",
        "PASSWORD": password,
        "HOST": parsed.hostname or "localhost",
        "PORT": str(parsed.port or 5432),
    }


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/postgres")
DATABASES = {
    "default": parse_database_url(DATABASE_URL),
}

AUTH_USER_MODEL = "users.CustomUser"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "pt-br"
TIME_ZONE = "America/Fortaleza"
USE_I18N = True
USE_TZ = True

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_STORAGE_BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET", "")

if SUPABASE_URL and SUPABASE_STORAGE_BUCKET:
    endpoint_base = SUPABASE_URL.rstrip("/")
    AWS_S3_ENDPOINT_URL = f"{endpoint_base}/storage/v1/s3"
    AWS_STORAGE_BUCKET_NAME = SUPABASE_STORAGE_BUCKET
    AWS_S3_REGION_NAME = "us-east-1"
    AWS_QUERYSTRING_AUTH = False
    AWS_DEFAULT_ACL = None

    parsed_supabase = urlparse(SUPABASE_URL)
    project_ref = parsed_supabase.hostname.split(".")[0] if parsed_supabase.hostname else ""

    # Supabase S3-compatible credentials use project ref as key id and the service key as secret.
    AWS_ACCESS_KEY_ID = project_ref
    AWS_SECRET_ACCESS_KEY = os.getenv("SUPABASE_PUBLISHABLE_KEY", "")

    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
            "OPTIONS": {
                "bucket_name": AWS_STORAGE_BUCKET_NAME,
            },
        },
        "staticfiles": {
            "BACKEND": "storages.backends.s3boto3.S3StaticStorage",
            "OPTIONS": {
                "bucket_name": AWS_STORAGE_BUCKET_NAME,
                "location": "static",
            },
        },
    }

    static_location = "static"
    media_location = "media"
    STATIC_URL = f"{endpoint_base}/storage/v1/object/public/{AWS_STORAGE_BUCKET_NAME}/{static_location}/"
    MEDIA_URL = f"{endpoint_base}/storage/v1/object/public/{AWS_STORAGE_BUCKET_NAME}/{media_location}/"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PAGINATION_CLASS": "core.pagination.StandardPagination",
    "PAGE_SIZE": 20,
    "EXCEPTION_HANDLER": "core.exceptions.custom_exception_handler",
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}

def parse_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


CORS_ALLOW_ALL_ORIGINS = os.getenv("CORS_ALLOW_ALL_ORIGINS", "False").lower() == "true"
CORS_ALLOWED_ORIGINS = parse_csv(
    os.getenv(
        "CORS_ALLOWED_ORIGINS",
        ",".join(
            [
                "http://localhost:5173",
                "http://127.0.0.1:5173",
                "http://localhost:5180",
                "http://127.0.0.1:5180",
                "http://localhost:5181",
                "http://127.0.0.1:5181",
            ]
        ),
    )
)
CORS_ALLOW_CREDENTIALS = True

CSRF_TRUSTED_ORIGINS = parse_csv(
    os.getenv(
        "CSRF_TRUSTED_ORIGINS",
        ",".join(
            [
                "http://localhost:5173",
                "http://127.0.0.1:5173",
                "http://localhost:5180",
                "http://127.0.0.1:5180",
                "http://localhost:5181",
                "http://127.0.0.1:5181",
            ]
        ),
    )
)

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
