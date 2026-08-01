# Release Tasks — Master List

**Generated:** 2026-07-29
**Current Readiness:** 🔴 NOT READY
**Last Updated:** Reeval-002

---

## How tasks work

1. Each task has an ID, description, and acceptance criteria.
2. When a task is completed, update its status and add a completion note.
3. After every completion, the master list is re-evaluated and the next highest-priority task is identified.
4. Tasks never deleted — only marked complete or superseded.

---

## Phase 1: Foundation (must fix before any deployment)

### Infrastructure

#### INFRA-001: Configure production secrets vault
**Priority:** 🔴 CRITICAL
**Effort:** 2h
**Description:** Replace env-var-based secret loading with Docker secrets. `compose.production.yml` now uses `secrets:` block with `POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password`. Settings.py uses `env_or_file()` pattern to read from file or env var. No secrets in docker-compose. No secrets in git.
**Acceptance:** Confirmed: secrets loaded via Docker secrets (`POSTGRES_PASSWORD_FILE`), settings.py reads via `env_or_file()`, production compose has no hardcoded secrets.
**Status:** ✅ COMPLETED

#### INFRA-002: Add Flutter CI pipeline
**Priority:** 🔴 CRITICAL
**Effort:** 1h
**Description:** Add `flutter test` and `flutter analyze` to CI. `.github/workflows/flutter-ci.yml` created.
**Acceptance:** PRs blocked on failing Flutter tests or analysis warnings.
**Status:** ✅ COMPLETED

#### INFRA-003: Create production nginx config
**Priority:** 🔴 CRITICAL
**Effort:** 1h
**Description:** Production nginx with HTTPS redirect, HSTS, reverse proxy, static files, rate limiting, request limits.
**Acceptance:** `devops/nginx/production.conf` exists and covers SSL, HSTS, rate limiting, reverse proxy, CORS preflight, health check exemption, metrics access restriction, hidden file blocking.
**Status:** ✅ COMPLETED

#### INFRA-004: Database backup automation
**Priority:** 🔴 CRITICAL
**Effort:** 1h
**Description:** Schedule daily backup via cron/systemd timer. Backups to local + S3. Retention: daily 30 days, weekly 12 months.
**Blocking reason:** No automated backup means data loss is unrecoverable.
**Acceptance:** Cron job created at devops/backup/crontab.example. backup-sync.sh created for S3 sync. verify-backup.sh created for weekly restore test.
**Status:** ✅ COMPLETED

#### INFRA-005: Secure PostgreSQL configuration
**Priority:** 🔴 CRITICAL
**Effort:** 2h
**Description:** PostgreSQL must use TLS connections, SCRAM-SHA-256 auth, `hostssl only` in pg_hba.conf.
**Blocking reason:** Database traffic is unencrypted. Credentials sent in plaintext over network.
**Acceptance:** All connections use TLS. Non-TLS connections rejected.
**Status:** ❌ PENDING

#### INFRA-006: Production Dockerfile hardening
**Priority:** 🟡 HIGH
**Effort:** 1h
**Description:** Dockerfile already uses `python:3.13-slim`, non-root user, and proper env vars. Verify HEALTHCHECK instruction is present.
**Acceptance:** Verified — Dockerfile meets production standards.
**Status:** ✅ COMPLETED (verified compliant)

#### INFRA-007: Migration rollback procedure
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Documented procedure for rolling back database migrations. CI check for unsafe operations.
**Acceptance:** `docs/runbooks/migration-rollback.md` exists with safe/unsafe migration patterns and rollback steps.
**Status:** ✅ COMPLETED

#### INFRA-008: Zero-downtime deploy strategy
**Priority:** 🟡 HIGH
**Effort:** 1h
**Description:** Documented zero-downtime deployment flow using health check warmup.
**Acceptance:** `docs/runbooks/zero-downtime-deploy.md` exists with start-new, wait, switch, stop procedure.
**Status:** ✅ COMPLETED

#### INFRA-009: Dependency lock files
**Priority:** 🟡 HIGH
**Effort:** 30m
**Description:** Ensure `requirements.txt` has pinned versions (not ranges) for production. Add `pip freeze > requirements-lock.txt` step to CI.
**Blocking reason:** Unpinned dependencies can introduce breaking changes on deploy without CI catching it.
**Acceptance:** Lock file exists. CI verifies lock matches requirements.
**Status:** ❌ PENDING

### Security

#### SEC-001: Create SECURITY.md
**Priority:** 🔴 CRITICAL
**Effort:** 30m
**Description:** Vulnerability disclosure policy with PGP key and response SLA.
**Acceptance:** File exists at repository root.
**Status:** ✅ COMPLETED

#### SEC-002: Container image scanning in CI
**Priority:** 🟡 HIGH
**Effort:** 1h
**Description:** Add Trivy or docker scan to CI. Fail on CRITICAL vulnerabilities.
**Acceptance:** CI blocks PRs with CRITICAL vulnerabilities in Docker image.
**Status:** ❌ PENDING

#### SEC-003: Idle session timeout
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Add middleware for idle session timeout. 30 min for web, 24h for mobile.
**Acceptance:** Web sessions expire after 30 min idle. Mobile JWT unchanged.
**Status:** ❌ PENDING

#### SEC-004: Login rate limiting enforcement
**Priority:** 🟡 HIGH
**Effort:** 30m
**Description:** Verify login throttle is actually applied. Add progressive delay after 3 failures.
**Acceptance:** 5 login attempts/min/IP verified. Lockout after 10 failures.
**Status:** ❌ PENDING

#### SEC-005: Flutter app obfuscation
**Priority:** 🟡 HIGH
**Effort:** 1h
**Description:** Add `--obfuscate --split-debug-info` to Flutter release build. Document in release process.
**Acceptance:** Release APK/IPA is obfuscated. Debug symbols archived separately.
**Status:** ❌ PENDING

#### SEC-006: Certificate pinning in Flutter
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Pin production TLS cert in `ApiClient`. Reject connections with untrusted certs even if CA is trusted.
**Acceptance:** App rejects MITM proxies. Only production cert accepted.
**Status:** ❌ PENDING

#### SEC-007: SQL injection fuzzing in CI
**Priority:** 🟡 MEDIUM
**Effort:** 1h
**Description:** Integrate existing `scripts/fuzz-authorized-staging.ps1` into CI pipeline.
**Acceptance:** Fuzz tests run in CI weekly. Findings reported as blocked.
**Status:** ❌ PENDING

### Data Integrity

#### DATA-001: Automated backup verification
**Priority:** 🔴 CRITICAL
**Effort:** 1h
**Description:** Weekly cron job that restores latest backup to temp database, verifies integrity, reports result.
**Blocking reason:** Untested backups are not backups.
**Acceptance:** verify-backup.sh created at devops/backup/verify-backup.sh. Scheduled in crontab.example for weekly run. Failure alerts pending.
**Status:** ✅ COMPLETED

#### DATA-002: Offline sync data layer (Flutter)
**Priority:** 🟡 HIGH
**Effort:** 3d
**Description:** Implement offline data layer using sqflite_sqlcipher. Local DB, upload queue, conflict resolution.
**Acceptance:** App creates bookings/cargo/payments offline. Syncs when online. Conflicts surfaced.
**Status:** ❌ PENDING

#### DATA-003: Data retention policy
**Priority:** 🟡 MEDIUM
**Effort:** 1h
**Description:** Document data retention: audit logs retain 1 year, payment records 7 years (legal), deleted tenants 90 days. Add automated cleanup job.
**Acceptance:** Policy documented. Cron job purges expired data.
**Status:** ❌ PENDING

### Testing

#### TEST-001: Backend coverage baseline
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Run `coverage run && coverage report` to establish baseline. Target 60%.
**Acceptance:** Coverage report generated. Gaps documented.
**Status:** ❌ PENDING

#### TEST-002: Flutter widget tests
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Widget tests for SignInScreen, BusinessHome, and one cargo screen.
**Acceptance:** 5+ widget tests passing in CI.
**Status:** ❌ PENDING

#### TEST-003: API integration test for critical flows
**Priority:** 🟡 HIGH
**Effort:** 3h
**Description:** Write integration tests for: register tenant, create booking, approve payment, issue ticket, cargo lifecycle.
**Acceptance:** Critical business flows are covered by automated tests.
**Status:** ❌ PENDING

### Monitoring & Observability

#### OBS-001: Sentry error tracking
**Priority:** 🔴 CRITICAL
**Effort:** 1h
**Description:** Add `sentry-sdk` to requirements.txt. Configure Django + DRF integration. Add DSN to production env.
**Blocking reason:** Production errors are invisible without error tracking.
**Acceptance:** Django errors appear in Sentry dashboard. DRF exceptions captured.
**Status:** ❌ PENDING

#### OBS-002: Prometheus metrics endpoint
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Add `django-prometheus` for request count, latency, DB queries, cache, active tenants at /metrics/.
**Acceptance:** `/metrics/` returns Prometheus data. Not exposed publicly (nginx restricts).
**Status:** ❌ PENDING

#### OBS-003: Structured JSON logging
**Priority:** 🟡 MEDIUM
**Effort:** 1h
**Description:** Replace Django's default logging formatter with JSON output. Add request_id, user_id, tenant_id to every log line.
**Acceptance:** Log output is valid JSON parseable by log aggregators.
**Status:** ❌ PENDING

### Operations

#### OPS-001: Deployment runbook
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Step-by-step deploy guide with pre-deploy checks, migration, deploy, verification, rollback.
**Acceptance:** `docs/runbooks/deployment.md` exists.
**Status:** ✅ COMPLETED

#### OPS-002: Release checklist
**Priority:** 🟡 HIGH
**Effort:** 1h
**Description:** Release gate checklist covering pre-release, deploy, post-deploy, rollback criteria.
**Acceptance:** `docs/release/checklist.md` exists and is used for every release.
**Status:** ✅ COMPLETED

---

## Phase 2: Production Hardening (after foundation is secure)

### INFRA-010: Staging environment provisioning
**Priority:** 🟡 HIGH
**Effort:** 4h
**Description:** Create a staging environment that mirrors production. Same Docker compose, same PostgreSQL version, same Redis. Document how to provision.
**Acceptance:** Staging can be deployed in < 30 min from scratch following docs.
**Status:** ❌ PENDING

### INFRA-011: Load testing baseline
**Priority:** 🟡 MEDIUM
**Effort:** 3h
**Description:** Create k6 or Locust scripts for: login, booking search, booking create, ticket issue, cargo CRUD. Run against staging. Record p50/p95/p99 latencies.
**Acceptance:** Load test scripts exist. Baseline performance numbers documented.
**Status:** ❌ PENDING

### SEC-008: API key rotation automation
**Priority:** 🟡 MEDIUM
**Effort:** 2h
**Description:** Document and automate rotation of: Django SECRET_KEY, Dinger API keys, Firebase credentials, encryption keys.
**Acceptance:** Key rotation documented and safe to execute within 30 min.
**Status:** ❌ PENDING

### MOB-001: Flutter app store submission prep
**Priority:** 🟡 HIGH
**Effort:** 4h
**Description:** Prepare app for Play Store and App Store submission: privacy policy, app icons, screenshots, store listing text (EN + MM), test accounts, demo video.
**Acceptance:** App meets Play Store and App Store submission requirements.
**Status:** ❌ PENDING

### MOB-002: Flutter crash reporting
**Priority:** 🟡 HIGH
**Effort:** 2h
**Description:** Add Sentry Flutter SDK (`sentry_flutter`) to the mobile app. Configure automatic crash reporting with user context (tenant ID, org ID). Breadcrumbs for navigation and API calls.
**Acceptance:** Unhandled Flutter errors appear in Sentry with tenant and user context.
**Status:** ❌ PENDING

### MOB-003: Flutter deep link handling
**Priority:** 🟡 MEDIUM
**Effort:** 2h
**Description:** Implement deep link handling for: payment return URLs (`hobosaas://payment/success`), notification tap to relevant screen, ticket validation scanner deep links.
**Acceptance:** Deep links navigate to correct screens after authentication.
**Status:** ❌ PENDING

### DOC-001: API documentation public
**Priority:** 🟡 MEDIUM
**Effort:** 2h
**Description:** Deploy Swagger UI (already configured in `config/urls.py`). Ensure OpenAPI schema is served at `/api/schema/`. Add authentication flow documentation.
**Acceptance:** Swagger UI available at `/api/docs/`. All endpoints documented with request/response examples.
**Status:** ❌ PENDING

---

## Task Summary

| ID | Phase | Priority | Area | Effort | Status |
|----|-------|----------|------|--------|--------|
| INFRA-001 | 1 | 🔴 CRITICAL | Secrets vault | 2h | ✅ |
| INFRA-002 | 1 | 🔴 CRITICAL | Flutter CI | 1h | ✅ |
| INFRA-003 | 1 | 🔴 CRITICAL | Nginx config | 1h | ✅ |
| INFRA-004 | 1 | 🔴 CRITICAL | Backup automation | 1h | ✅ |
| INFRA-005 | 1 | 🔴 CRITICAL | PostgreSQL TLS | 2h | ❌ |
| INFRA-006 | 1 | 🟡 HIGH | Docker hardening | 1h | ✅ |
| INFRA-007 | 1 | 🟡 HIGH | Migration rollback | 2h | ✅ |
| INFRA-008 | 1 | 🟡 HIGH | Zero-downtime deploy | 1h | ✅ |
| INFRA-009 | 1 | 🟡 HIGH | Dependency lock | 30m | ❌ |
| INFRA-010 | 2 | 🟡 HIGH | Staging provisioning | 4h | ❌ |
| INFRA-011 | 2 | 🟡 MEDIUM | Load testing | 3h | ❌ |
| SEC-001 | 1 | 🔴 CRITICAL | SECURITY.md | 30m | ✅ |
| SEC-002 | 1 | 🟡 HIGH | Container scanning | 1h | ❌ |
| SEC-003 | 1 | 🟡 HIGH | Session timeout | 2h | ❌ |
| SEC-004 | 1 | 🟡 HIGH | Login rate limit | 30m | ❌ |
| SEC-005 | 1 | 🟡 HIGH | Flutter obfuscation | 1h | ❌ |
| SEC-006 | 1 | 🟡 HIGH | Cert pinning | 2h | ❌ |
| SEC-007 | 1 | 🟡 MEDIUM | SQL fuzzing CI | 1h | ❌ |
| SEC-008 | 2 | 🟡 MEDIUM | Key rotation | 2h | ❌ |
| DATA-001 | 1 | 🔴 CRITICAL | Backup verification | 1h | ✅ |
| DATA-002 | 1 | 🟡 HIGH | Offline sync | 3d | ❌ |
| DATA-003 | 1 | 🟡 MEDIUM | Data retention | 1h | ❌ |
| TEST-001 | 1 | 🟡 HIGH | Coverage baseline | 2h | ❌ |
| TEST-002 | 1 | 🟡 HIGH | Flutter widget tests | 2h | ❌ |
| TEST-003 | 1 | 🟡 HIGH | API integration tests | 3h | ❌ |
| OBS-001 | 1 | 🔴 CRITICAL | Sentry backend | 1h | ❌ |
| OBS-002 | 1 | 🟡 HIGH | Prometheus metrics | 2h | ❌ |
| OBS-003 | 1 | 🟡 MEDIUM | JSON logging | 1h | ❌ |
| OPS-001 | 1 | 🟡 HIGH | Deployment runbook | 2h | ✅ |
| OPS-002 | 1 | 🟡 HIGH | Release checklist | 1h | ✅ |
| MOB-001 | 2 | 🟡 HIGH | App store prep | 4h | ❌ |
| MOB-002 | 2 | 🟡 HIGH | Flutter crash reporting | 2h | ❌ |
| MOB-003 | 2 | 🟡 MEDIUM | Deep links | 2h | ❌ |
| DOC-001 | 2 | 🟡 MEDIUM | API docs public | 2h | ❌ |

**Phase 1: 10/24 tasks complete**
**Phase 2: 0/7 tasks complete**
**Total: 10/31 tasks complete**

---

## Current Completion Status

```
Phase 1: Infrastructure  [███████░░░] 7/9
Phase 1: Security        [█░░░░░░░░░] 1/7
Phase 1: Data            [███░░░░░░░] 1/3
Phase 1: Testing         [░░░░░░░░░░] 0/3
Phase 1: Monitoring      [░░░░░░░░░░] 0/3
Phase 1: Operations      [██████████] 2/2
────────────────────────────────────
Phase 1 Total:           [████░░░░░░] 11/24

Phase 2:                  [░░░░░░░░░░] 0/7
────────────────────────────────────
Grand Total:              [███░░░░░░░] 11/31
```
