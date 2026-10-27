# syntax=docker/dockerfile:1
#
# Multi-stage build:
#   base    -> Python + runtime dependencies (shared by the other two stages)
#   test    -> base + pytest + tests; the build FAILS if any test fails
#   runtime -> base + app code only; small, non-root, served by gunicorn
#
# Usage:
#   docker build --target test .                                         # run tests
#   docker build --target runtime --build-arg APP_VERSION=abc123 -t hello-world-flask:abc123 .

# ---------- base ----------
FROM python:3.13-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Copy requirements first so this layer is cached until requirements.txt changes,
# instead of reinstalling dependencies on every code edit.
COPY requirements.txt .
RUN pip install -r requirements.txt

# ---------- test ----------
FROM base AS test

COPY requirements-dev.txt .
RUN pip install -r requirements-dev.txt
COPY app/ app/
COPY tests/ tests/
RUN pytest -q

# ---------- runtime ----------
FROM base AS runtime

# CI passes the git commit SHA here; the app reports it at "/".
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

# Run as an unprivileged user. A numeric UID lets Kubernetes verify runAsNonRoot.
RUN useradd --create-home --uid 10001 appuser
COPY app/ app/
USER 10001

EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--access-logfile", "-", "app.main:app"]
