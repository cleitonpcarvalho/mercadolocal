# Mercado Local Backend

Backend API built with Django + DRF + JWT authentication.

## Poetry workflow

Install dependencies:

```bash
poetry install
```

Add a new runtime dependency:

```bash
poetry add {package}
```

Add a new development dependency:

```bash
poetry add --group dev {package}
```

Activate virtual environment shell:

```bash
poetry shell
```

Run development server:

```bash
poetry run python manage.py runserver 0.0.0.0:8001
```

Run migrations:

```bash
poetry run python manage.py migrate
```

Create a superuser (example):

```bash
poetry run python manage.py createsuperuser
```
