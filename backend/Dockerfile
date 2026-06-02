FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV POETRY_NO_INTERACTION=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://install.python-poetry.org | python3 - \
    && ln -s /root/.local/bin/poetry /usr/local/bin/poetry

COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

COPY . .

EXPOSE 8001

CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8001", "--workers", "3"]
