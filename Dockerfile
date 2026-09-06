FROM python:3.14-slim AS builder

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# install uv
COPY --from=ghcr.io/astral-sh/uv:0.12.5 /uv /uvx /bin/

COPY pyproject.toml uv.lock /_lock/

# Synchronize dependencies
RUN --mount=type=cache,target=/root/.cache \
    cd /_lock && \
    uv sync \
    --frozen \
    --no-install-project \
    --no-dev \
    --group prod

FROM python:3.14-slim

RUN useradd -m -r appuser && \
    mkdir /app && \
    chown -R appuser /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
WORKDIR /app

COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8000

# Placeholders only - settings.py needs both at import time.
# collectstatic never opens a DB connection, so these are never used.
RUN SECRET_KEY=build-placeholder \
      DATABASE_URL=postgres://build:build@localhost:5432/build \
      python manage.py collectstatic --noinput

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "fitness_booking.wsgi:application"]
