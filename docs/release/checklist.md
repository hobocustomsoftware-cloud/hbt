# Release Checklist

**Release:** `vX.Y.Z`
**Date:** YYYY-MM-DD
**Release Manager:** [Name]
**Approved by:** [Name]

---

## Pre-Release (72 hours before)

- [ ] Feature freeze announced
- [ ] All PRs targeting this release merged
- [ ] Changelog drafted for this release
- [ ] Version bumped in `backend/config/settings.py` and `pubspec.yaml`
- [ ] Release branch created: `release/vX.Y.Z`
- [ ] Release candidate tagged: `vX.Y.Z-rc1`

---

## Pre-Deploy (12 hours before)

- [ ] CI pipeline green on release branch
  - [ ] `python manage.py test` — backend tests pass
  - [ ] `flutter test` — mobile tests pass
  - [ ] `pip check` — dependencies consistent
  - [ ] `pip-audit` — no known vulnerabilities
  - [ ] `bandit` — no security findings
  - [ ] `semgrep` — no rule violations
  - [ ] `spectacular --validate` — OpenAPI schema valid
  - [ ] `makemigrations --check --dry-run` — no unapplied migrations
- [ ] Coverage report reviewed (≥60%)
- [ ] Database migration plan reviewed
  - [ ] All migrations have reverse operations
  - [ ] No destructive migrations (DELETE, DROP, ALTER without backup)
- [ ] Sentry release created: `sentry-cli releases new vX.Y.Z`

---

## Deploy Window

- [ ] Backup taken: `scripts/backup-postgres.sh`
- [ ] Backup verified (file size > 0, checksum matches)
- [ ] Maintenance page enabled (if migration is locking tables)
- [ ] Database migration applied
- [ ] New containers deployed
- [ ] Health check passed (`/api/v1/health/ready/`)
- [ ] Smoke test passed:
  - [ ] Health endpoints respond 200
  - [ ] Auth: login succeeds, tokens refresh
  - [ ] Core API: bookings, tickets, cargo, payments return data
  - [ ] Flutter app connects and renders data
  - [ ] Admin panel loads
- [ ] Monitoring checked (Sentry: 0 new errors, Prometheus: normal)
- [ ] Maintenance page disabled (if enabled)
- [ ] Git tag pushed: `git push origin vX.Y.Z`

---

## Post-Deploy (24 hours)

- [ ] Sentry errors reviewed — no unexpected issues
- [ ] Database connections stable (check `pg_stat_activity`)
- [ ] API latency baseline compared (p50/p95/p99)
- [ ] Users report no issues
- [ ] Changelog published
- [ ] Release documented in internal wiki
- [ ] Rollback procedure verified (can revert if needed)

---

## Rollback Criteria

Roll back immediately if ANY of the following occurs:

- [ ] API returns 5xx for critical endpoints (auth, bookings, payments)
- [ ] Database query performance degrades by >50% (p95 latency)
- [ ] Data integrity issue detected (missing records, incorrect amounts)
- [ ] Security vulnerability introduced (authentication bypass, data leak)
- [ ] Mobile app cannot connect or crashes on launch

---

## Previous Release History

| Version | Date | Deployed By | Outcome | Notes |
|---------|------|-------------|---------|-------|
| — | — | — | — | First tracked release |
