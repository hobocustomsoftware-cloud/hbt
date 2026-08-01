# Database Migration Rollback Procedure

**Scope:** All Django apps in `backend/apps/*`

---

## Before Running Any Migration

Every migration MUST have a documented reverse operation. Run this check before deployment:

```bash
# Check for migrations without clear reverse paths
python manage.py showmigrations --plan
```

**Blocking patterns** (migration must be reviewed before deploy):
- `RemoveField` without corresponding `AddField` in the reverse
- `DeleteModel` without data preservation strategy
- `AlterField` with data loss risk (narrowing field type, removing nullability)
- `RunPython` without reverse Python function
- Data backfill operations

---

## Safe Migrations (auto-reversible)

These can be rolled back automatically with `migrate <app> <previous>`:

| Operation | Reverse |
|-----------|---------|
| `CreateModel` | `DeleteModel` |
| `AddField` | `RemoveField` |
| `AddIndex` | `RemoveIndex` |
| `AddConstraint` | `RemoveConstraint` |
| `CreateIndex` | `DropIndex` (PostgreSQL) |

## Unsafe Migrations (require manual reverse)

| Operation | Risk | Reverse Strategy |
|-----------|------|------------------|
| `RemoveField` | Data loss | Backup data before removal, restore on rollback |
| `AlterField` | Data corruption | Test forward+reverse on staging first |
| `DeleteModel` | Data loss | Export data before deletion, restore on rollback |
| `RunPython` | Unknown | Must provide `reverse_code` in migration |
| Data backfill | Duplicate or lost data | Must be idempotent — always check for existing data |

---

## Rollback Steps

### 1. Identify the target migration

```bash
# List all migrations with their applied status
python manage.py showmigrations

# Example output:
# bookings
#  [X] 0001_initial
#  [X] 0002_add_seat_reservation
#  [X] 0003_remove_seat_limit
#  [ ] 0004_add_booking_fees    <-- this is the one to revert
```

### 2. Roll back one migration

```bash
python manage.py migrate bookings 0003
```

### 3. Verify rollback

```bash
# Check that the migration is now unapplied
python manage.py showmigrations bookings
# Expected: 0004 shows [ ] (not applied)

# Run health check
python manage.py check --deploy

# Test critical paths
python manage.py test bookings.tests.test_rollback
```

### 4. Deploy the rollback

```bash
# Deploy the previous application version
git checkout vX.Y.Z-1
docker compose -f compose.production.yml up -d backend
```

### 5. Document the rollback

Record in the release notes:
- Why the rollback occurred
- Which migration was reversed
- Data state after rollback (any data loss? any manual fixes?)
- What needs to change before re-deploying

---

## Emergency Rollback (data loss risk)

If a migration is actively corrupting data:

```bash
# 1. Stop the application immediately
docker compose -f compose.production.yml stop backend

# 2. Restore from the pre-deploy backup
gunzip -c /var/backups/hobosaas/backup_$(date +%Y%m%d).dump.gz | \
    docker exec -i hobosaas_db pg_restore -U saas_admin -d hobosaas_db

# 3. Deploy the previous version
git checkout vX.Y.Z-1
docker compose -f compose.production.yml up -d backend

# 4. Verify data integrity
python manage.py check
python manage.py test
```

---

## CI Gate (automated)

The CI pipeline at `.github/workflows/backend-ci.yml` runs:

```yaml
- run: python manage.py makemigrations --check --dry-run
```

**This blocks PRs with unapplied migrations.** It does NOT check for rollback safety. Add a manual review step for any migration that contains unsafe operations.
