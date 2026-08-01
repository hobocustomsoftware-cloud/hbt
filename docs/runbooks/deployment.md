# Deployment Runbook — HBT Backend

**Applies to:** Production and Staging environments
**Prerequisites:** SSH access, database credentials, Docker installed

---

## Pre-Deploy Checklist

- [ ] CI pipeline passing (all tests, linting, security scans)
- [ ] OpenAPI schema validated (`spectacular --validate`)
- [ ] Database migrations reviewed (no destructive operations)
- [ ] Backup taken (run `scripts/backup-postgres.sh`)
- [ ] Changelog updated
- [ ] Version bumped
- [ ] Release branch created (`release/vX.Y.Z`)
- [ ] Sentry release created (`sentry-cli releases new vX.Y.Z`)

---

## Step-by-Step Deployment

### 1. Pull latest images

```bash
ssh deploy@production-server
cd /opt/hobosaas
docker compose -f compose.production.yml pull
```

### 2. Apply database migrations

```bash
docker compose -f compose.production.yml run --rm backend python manage.py migrate
```

**If migration fails:** stop and roll back (see Rollback section below).

### 3. Start new containers

```bash
docker compose -f compose.production.yml up -d
```

### 4. Verify health

```bash
# Wait for readiness
sleep 10
curl -f http://localhost:8000/api/v1/health/ready/
# Expected: {"status": "ok", "database": "ok"}

# Check liveness
curl -f http://localhost:8000/api/v1/health/live/
# Expected: {"status": "alive"}

# Verify API responds
curl -f http://localhost:8000/api/v1/health/
```

### 5. Check logs

```bash
docker compose -f compose.production.yml logs --tail=50 backend
# Look for: no 5xx errors, no connection errors, migrations applied successfully
```

### 6. Smoke test

- [ ] Health endpoint returns 200
- [ ] Admin login works
- [ ] API returns data for authenticated requests
- [ ] Flutter app can connect and display data
- [ ] New bookings can be created

### 7. Monitor

- [ ] Sentry: no new errors after deploy
- [ ] Prometheus: no spike in error rate
- [ ] Logs: no unexpected warnings

### 8. Tag release

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
sentry-cli releases set-commits vX.Y.Z --auto
sentry-cli releases finalize vX.Y.Z
```

---

## Rollback Procedure

### Rollback database

```bash
# List available migrations
docker compose -f compose.production.yml run --rm backend python manage.py showmigrations

# Roll back to previous migration
docker compose -f compose.production.yml run --rm backend python manage.py migrate <app_name> <previous_migration_number>

# Example: python manage.py migrate bookings 0005
```

### Rollback application

```bash
# Deploy previous tagged version
git checkout vX.Y.Z-1
docker compose -f compose.production.yml build backend
docker compose -f compose.production.yml up -d backend

# Verify health (same as step 4)
```

---

## Environment Inventory

| Environment | URL | Server | Database |
|-------------|-----|--------|----------|
| Local | http://localhost:8000 | Docker Desktop | postgres:17 |
| Staging | https://staging.hoboplatform.com | staging-01 | staging-db |
| Production | https://api.hoboplatform.com | prod-01, prod-02 | prod-db (primary + replica) |

---

## Emergency Contacts

| Role | Contact |
|------|---------|
| Lead Engineer | internal |
| DBA | internal |
| Security | internal |
