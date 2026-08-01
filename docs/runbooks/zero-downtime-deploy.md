# Zero-Downtime Deployment Strategy

**Prerequisites:** nginx reverse proxy, 2x backend instances, shared database

---

## Architecture

```
                         ┌──────────────┐
                         │    nginx     │
                         │  (reverse    │
                         │   proxy)     │
                         └──────┬───────┘
                                │
                 ┌──────────────┼──────────────┐
                 ▼              ▼              ▼
         ┌────────────┐ ┌────────────┐ ┌────────────┐
         │ Backend    │ │ Backend    │ │ Backend    │
         │ v1.0.0     │ │ v1.1.0     │ │ v1.1.0     │
         │ (old)      │ │ (new)      │ │ (new)      │
         └──────┬─────┘ └──────┬─────┘ └──────┬─────┘
                │              │              │
                └──────────────┼──────────────┘
                               ▼
                       ┌──────────────┐
                       │  PostgreSQL  │
                       │  (shared)    │
                       └──────────────┘
```

---

## Deployment Steps

### Phase 1: Start new instances

```bash
# Scale up — add new instances with new image
docker compose -f compose.production.yml up -d --scale backend=4 --no-deps

# Wait for new instances to pass health check
for i in {1..10}; do
  if curl -sf http://backend-new:8000/api/v1/health/ready/; then
    echo "New instance ready"
    break
  fi
  sleep 3
done
```

### Phase 2: Drain old instances

```bash
# In nginx config, mark old instances as "down" (maintenance)
# This allows in-flight requests to complete but stops new traffic
docker compose -f compose.production.yml stop backend-v1
```

### Phase 3: Verify

```bash
# Verify all requests go to new instances
curl -H "Host: api.hoboplatform.com" https://localhost/api/v1/health/

# Check logs for errors
docker compose logs --tail=50 backend
```

### Phase 4: Cleanup

```bash
# Remove old images
docker image prune -a --filter "until=24h"

# Remove old containers (keep last 2 versions)
docker compose -f compose.production.yml rm -s -v backend-v1
```

---

## Rollback (during deployment)

If the new instance fails health check:

```bash
# Stop new instances
docker compose -f compose.production.yml stop backend-new

# Restore old instances
docker compose -f compose.production.yml up -d --scale backend=3 backend-v1

# Revert nginx config
# Remove new instances from upstream block
# Reload nginx: docker exec nginx nginx -s reload
```

---

## Database Migration Considerations

- **Non-locking migrations only** during zero-downtime deploy
- `AddField` with `default=X` locks the table on PostgreSQL < 11. Use `AddField(null=True)` then backfill in a separate deploy.
- `CreateIndex CONCURRENTLY` must be done manually outside of Django migrations
- Never use `RunPython` that reads/writes large tables during deployment window

---

## Health Check Requirements

```python
# /api/v1/health/ready/ must check:
# - Database connectivity
# - Redis connectivity
# - Pending migrations (fail if unapplied)
# - Minimum instance count in load balancer pool

# /api/v1/health/live/ must:
# - Return immediately (no DB query)
# - Check only process liveness
```
