FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN groupadd --system hbt && useradd --system --gid hbt --home-dir /app hbt
WORKDIR /app

COPY requirements.txt .
RUN pip install --requirement requirements.txt

COPY . .
RUN chmod +x /app/scripts/container-entrypoint.sh \
    && chown -R hbt:hbt /app

USER hbt
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live/', timeout=3)"
ENTRYPOINT ["/app/scripts/container-entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", "--bind=0.0.0.0:8000", "--workers=3", "--threads=2", "--timeout=60", "--graceful-timeout=30", "--access-logfile=-", "--error-logfile=-"]
