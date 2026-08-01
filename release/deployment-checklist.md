# HBT Deployment Checklist

**Generated:** 2026-07-29  
**Target:** Supervised Pilot → Production  
**Status:** 🟡 3 critical fixes applied, 3 warnings remain

---

## Pre-Deployment Overview

This checklist validates every component required for a production deployment of the HBT platform (Django backend + Flutter apps). Each section shows ✅ verified OK, ⚠️ issues found and fixed this session, or 🔴 blockers.

---

## 1. Environment Variables

### Backend `.env` (required)

| Variable | Status | Notes |
|----------|--------|-------|
| `DJANGO_SECRET_KEY` | ✅ Set | Present in `.env`, placeholder in `.env.production` |
| `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | ✅ Set | Present in `.env` |
| `POSTGRES_HOST`, `POSTGRES_PORT` | ✅ Set | Dev: `localhost:5432` |
| `NRC_ENCRYPTION_KEY` | ✅ Set | Present in `.env` |
| `NRC_BLIND_INDEX_KEY` | ✅ Set | Present in `.env` |
| `PAYMENT_CREDENTIAL_ENCRYPTION_KEY` | ✅ Set | Present in `.env` |
| `PUSH_TOKEN_ENCRYPTION_KEY` | ✅ Set | Present in `.env` |
| `DJANGO_ALLOWED_HOSTS` | ✅ Set | Dev: `localhost,127.0.0.1` |
| `DJANGO_CORS_ALLOWED_ORIGINS` | ✅ Set | Dev defaults |
| `DJANGO_SECURE_SSL_REDIRECT` | ✅ Set | Dev: `false`, Prod: `true` |
| `DJANGO_SECURE_HSTS_SECONDS` | ✅ Set | Prod: `31536000` |
| `DJANGO_SECURE_HSTS_PRELOAD` | ✅ Set | Prod: `true` |
| `DJANGO_TRUST_PROXY_SSL_HEADER` | ✅ Set | Prod: `true` |

### Production `.env` Template

Exists at `backend/.env.production.example`. Missing for pilot:
- ⚠️ **Actual secret values** need injection (currently placeholder `inject-from-secret-store`)
- ⚠️ **Docker secrets** (`postgres_password` via file) need setup

**Action:** Copy `.env.production.example` → `.env.production`, populate with real secrets via secrets vault or env injection.

---

## 2. Database

| Check | Status | Evidence |
|-------|--------|----------|
| Migration files exist across all apps | ✅ | 24 Django apps with migration directories |
| CI validates migrations (`check --dry-run`) | ✅ | Pipeline step passes |
| No unapplied migrations | ⚠️ | Checked in CI only; full `migrate` run verified in entrypoint |
| Connection health checks | ✅ | `CONN_HEALTH_CHECKS: True` in settings |
| Readiness endpoint checks DB | ✅ | `/health/ready/` runs `SELECT 1` |
| Migration rollback runbook | ✅ | `docs/runbooks/migration-rollback.md` |

**Action:** On first deploy, run `python manage.py migrate` and verify all 24 apps apply cleanly.

---

## 3. Static Files

| Check | Status | Evidence |
|-------|--------|----------|
| `STATIC_URL` configured | ✅ | `static/` |
| `STATIC_ROOT` defined | ✅ **← FIXED** | Added `BASE_DIR / "staticfiles"` (was missing — would crash `collectstatic`) |
| `collectstatic` runs in entrypoint | ✅ | `HBT_RUN_BOOTSTRAP=true` triggers it |
| nginx serves static files | ✅ | `location /static/ { alias /srv/static/; }` |
| Static volume mounted in compose | ✅ | `static_data:/app/staticfiles` |

**No remaining issues.**

---

## 4. Media Files

| Check | Status | Evidence |
|-------|--------|----------|
| `MEDIA_ROOT` configured | ✅ | `BASE_DIR / "media"` |
| `MEDIA_URL` configured | ✅ | `media/` |
| `PRIVATE_MEDIA_ROOT` configured | ✅ | `BASE_DIR / "private_media"` |
| nginx serves public media | ⚠️ | `hbt.conf` returns 404 for `/media/` — intentional? |
| Production compose mounts media volume | ✅ | `media_data:/app/media` |
| Malware scan config | ✅ | `MALWARE_SCAN_REQUIRED`, `MALWARE_SCAN_COMMAND` configurable |

**Note:** `hbt.conf` (compose nginx) returns 404 for `/media/` — public media uploads (payment evidence, cargo photos) won't be accessible through nginx. The `production.conf` config does serve them. Verify which nginx config is used in your deployment.

---

## 5. HTTPS / TLS

| Check | Status | Evidence |
|-------|--------|----------|
| nginx SSL config (production.conf) | ✅ | TLS 1.2/1.3, HSTS, secure ciphers |
| nginx SSL config (compose hbt.conf) | ✅ | TLS 1.2/1.3, HSTS |
| HTTP → HTTPS redirect | ✅ | Both configs redirect port 80 |
| HSTS preload | ✅ | `production.conf`: `max-age=31536000; includeSubDomains; preload` |
| Security headers | ✅ | X-Frame-Options, X-Content-Type, X-XSS, Referrer-Policy, Permissions-Policy, CSP |
| TLS cert paths | ✅ | Configured, paths via env vars in compose |
| SSL redirect in Django | ✅ | `DJANGO_SECURE_SSL_REDIRECT` env var |
| Proxy SSL header | ✅ | `SECURE_PROXY_SSL_HEADER` when `DJANGO_TRUST_PROXY_SSL_HEADER=true` |

**Action needed:**
- ⚠️ Obtain and place TLS certificates at configured paths
- ⚠️ For `production.conf`: cert paths point to `/etc/ssl/certs/hoboplatform.crt` — update if different

---

## 6. Health Endpoints & HEALTHCHECK

| Check | Status | Evidence |
|-------|--------|----------|
| Liveness endpoint (`/health/live/`) | ✅ | Returns `{"status": "alive"}` |
| Readiness endpoint (`/health/ready/`) | ✅ | Checks DB, returns `{"status": "ready"}` or 503 |
| Health endpoint (`/health/`) | ✅ | Returns `{"status": "ok"}` |
| HEALTHCHECK in Dockerfile | ✅ **← FIXED** | Added (was missing — containers wouldn't be health-checked) |
| Compose healthcheck for API | ✅ | Overrides Dockerfile HEALTHCHECK with same check |
| Compose healthcheck for Postgres | ✅ | `pg_isready` |
| nginx health location (no rate limit) | ✅ | `location /api/v1/health/ { access_log off; }` |

**No remaining issues.**

---

## 7. Docker & Compose

| Check | Status | Evidence |
|-------|--------|----------|
| Root `docker-compose.yml` | ✅ **← FIXED** | Was empty (0 bytes), now populated with postgres + api services |
| Production compose | ✅ | `devops/compose.production.yml` — full multi-service config |
| Dockerfile | ✅ | HEALTHCHECK added, multi-stage, non-root user |
| Restart policy | ✅ | `unless-stopped` on all services |
| Read-only root filesystem | ✅ | `read_only: true` + `tmpfs: /tmp` |
| No-new-privileges security opt | ✅ | `security_opt: no-new-privileges:true` |
| Container entrypoint | ✅ | Runs migrate + collectstatic on bootstrap, then exec CMD |
| Gunicorn config | ✅ | 3 workers, 2 threads, 60s timeout, graceful 30s |

**No remaining issues.**

---

## 8. Rate Limiting

| Check | Status | Evidence |
|-------|--------|----------|
| nginx API rate limit | ✅ | 100 req/s (burst 200) |
| nginx login rate limit | ✅ | 5 req/min |
| Django anon throttle | ✅ | `API_ANON_RATE` env var (default 120/min) |
| Django user throttle | ✅ | `API_USER_RATE` env var (default 1200/min) |

**No issues.**

---

## 9. Backup & Recovery

| Check | Status | Evidence |
|-------|--------|----------|
| Backup script | ✅ | `scripts/backup-postgres.sh` — custom pg_dump with SHA256 |
| Restore script | ✅ | `scripts/restore-postgres.sh` — with confirmation guard |
| Cloud sync script | ✅ | `devops/backup/backup-sync.sh` — S3-compatible, retention policies |
| Backup verification script | ✅ | `devops/backup/verify-backup.sh` — restore to temp DB + integrity check |
| Crontab example | ✅ | `devops/backup/crontab.example` — daily backup, S3 sync, weekly verify |
| Backup docs | ✅ | `docs/deployment/06-backup.md` |

**Action:** Install crontab on the production server:
```bash
crontab -u hbt devops/backup/crontab.example
```

**Ensure these env vars are set on the server:**
- `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `HBT_BACKUP_DIR` (default: `/var/backups/hobosaas`)
- `HBT_S3_BUCKET`, `HBT_S3_ENDPOINT` (for cloud sync)

---

## 10. CI/CD

| Check | Status | Evidence |
|-------|--------|----------|
| Backend CI | ✅ | `.github/workflows/backend-ci.yml` — lint, test, security scan |
| Flutter CI | ✅ | `.github/workflows/flutter-ci.yml` — analyze, test, format |
| OpenAPI validation in CI | ✅ | `spectacular --validate` |
| Migration check in CI | ✅ | `makemigrations --check --dry-run` |
| Security scanning in CI | ✅ | bandit + semgrep + pip-audit |
| CD pipeline | ❌ | **Not configured** — manual deploy via SSH |
| Container registry | ❌ | **Not configured** — images built on deploy server |

**Action:** Set up:
- Container registry (Docker Hub / GitHub Container Registry)
- CD workflow (GitHub Actions deploy to staging → production)
- Or script the manual deploy process documented in runbook

---

## 11. Monitoring & Observability

| Check | Status | Evidence |
|-------|--------|----------|
| Health endpoints | ✅ | live, ready, health |
| Sentry configured | ❌ | **Not configured** — no credentials in env |
| Prometheus metrics | ⚠️ | nginx config has `/metrics/` location, but no metrics endpoint on backend |
| Centralized logging | ❌ | Not configured |
| Uptime monitoring | ❌ | Not configured |

**Action:** Before pilot:
- [ ] Configure Sentry (set `SENTRY_DSN` in env, add `sentry-sdk` to requirements)
- [ ] Add `django-prometheus` for metrics
- [ ] Set up basic uptime monitoring (e.g., UptimeRobot, Healthchecks.io)

---

## 12. Runbooks & Documentation

| Check | Status | Evidence |
|-------|--------|----------|
| Deployment runbook | ✅ | `docs/runbooks/deployment.md` |
| Rollback runbook | ✅ | `docs/runbooks/migration-rollback.md` |
| Zero-downtime deploy guide | ✅ | `docs/runbooks/zero-downtime-deploy.md` |
| Backup docs | ✅ | `docs/deployment/06-backup.md` |
| Recovery docs | ✅ | `docs/deployment/07-recovery.md` |
| Release checklist | ✅ | `docs/release/checklist.md` |

**No issues.**

---

## Summary: Blocker Status

### ❌ Fixed This Session (3 items)

| Item | Fix |
|------|-----|
| `STATIC_ROOT` missing in settings.py | ✅ Added `STATIC_ROOT = BASE_DIR / "staticfiles"` |
| Empty `docker-compose.yml` | ✅ Populated with postgres + api services |
| Missing HEALTHCHECK in Dockerfile | ✅ Added container health check |

### ⚠️ Still Needs Attention (6 items)

| Priority | Item | Action |
|----------|------|--------|
| 🔴 HIGH | Production `.env` secrets | Populate `.env.production` with real values |
| 🔴 HIGH | TLS certificates | Obtain and deploy at configured paths |
| 🟡 MEDIUM | Sentry DSN | Configure error tracking before pilot |
| 🟡 MEDIUM | CD pipeline | Set up automated deployment |
| 🟡 MEDIUM | Container registry | Push images to registry |
| 🟢 LOW | Monitoring stack | Uptime + metrics + logging |

---

*End of Deployment Checklist*
