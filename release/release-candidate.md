# Release Readiness Audit — HBT MVP Release Candidate

**Generated:** 2026-07-29  
**Auditor:** Release Readiness Review  
**Scope:** `F:\hbt` — Django Backend (24 apps) + Flutter Mobile (business + passenger)  
**Status:** 🟡 **RISKY — Not production-ready**

---

## Executive Summary

The HBT MVP has delivered substantial functionality across the Counter, Passenger, and Cargo flows. The backend is feature-complete for the MVP scope. The Flutter apps cover the critical paths with clean widget patterns post-refactor. However, **several blockers prevent production release** in the following domains (ordered by severity):

| Domain | Score | Blocker Summary |
|--------|-------|-----------------|
| Security | 🟡 6/10 | No MFA, no TLS between services, no certificate pinning, no app obfuscation |
| Testing | 🟡 5/10 | Flutter near-zero test coverage, no integration/E2E/load tests |
| Deployment | 🟠 4/10 | No staging env, no CD pipeline, empty docker-compose.yml, no HEALTHCHECK |
| Offline Sync | 🟡 6/10 | Infrastructure built but unused — screens call API directly |
| API Contracts | 🟠 4/10 | 7 critical Flutter↔OpenAPI mismatches still present in production code |
| Documentation | 🟡 6/10 | Draft status, missing user/admin guides |
| Architecture | ✅ 8/10 | Solid modular monolith, shared widgets complete, repo layer missing |
| Performance | 🟢 7/10 | No baseline data, but no obvious bottlenecks found |

**Overall: 🟡 RISKY** — Could deploy for a supervised pilot with these gaps, but not for production.

---

## Domain 1: Architecture

### Backend ✅

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Modular monolith with clear boundaries | ✅ | 24 Django apps with feature-first layout |
| URL routing | ✅ | `config/urls.py` includes all 22 app route files with version prefix |
| Middleware pipeline | ✅ | CORS, auth, audit, tenancy middleware chain |
| Error handling | ✅ | Exception handlers, DRF validation, custom error responses |
| Migration management | ✅ | `makemigrations --check --dry-run` in CI |
| Multi-tenancy | ✅ | Membership + Organization model with effective permission codes |
| Offline sync backend | ✅ | `SyncChange`, `SyncOperation`, `Device` models + push/pull/authorization endpoints |

### Flutter 🟡

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Feature-first folder structure | ✅ | `features/<name>/{presentation,application,domain}/` |
| Shared widgets migrated | ✅ | CQ-026→039: 14 screens use AsyncState + shared views |
| API client | ⚠️ | Single `api_client.dart` (600+ lines) — monolithic, no separation of concerns |
| Data/repository layer | ❌ | **Missing entirely** — no DAO, no data models used in production code. Screens call `api.post(...)` directly from presentation layer |
| State management | ⚠️ | `StatefulWidget` + `setState`. Works correctly but won't scale beyond ~20 screens |
| Domain models | ⚠️ | `hbt_models.dart` (14 typed DTO classes) exists but **not used** — production code uses raw `Map<String, dynamic>` |
| Offline data access | ❌ | `AppDatabase` exists but no screen reads from it. All UI screens are online-only |
| DTO-map consistency | ❌ | 7 critical field mismatches found between Flutter ↔ OpenAPI ↔ Serializer (see Contracts section) |

**Architecture Verdict:** ✅ Solid backend. 🟡 Flutter needs a repository layer and DTO adoption before it can be considered well-architected. Not a release blocker if documented as known debt.

---

## Domain 2: Security

| Criterion | Status | Risk |
|-----------|--------|------|
| HTTPS enforced | ✅ | nginx config redirects HTTP→HTTPS, HSTS preload |
| Security headers | ✅ | `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `X-XSS-Protection`, `Referrer-Policy`, `Permissions-Policy` |
| Rate limiting | ✅ | nginx: 100r/s API, 5r/m login |
| JWT auth | ✅ | SimpleJWT with token refresh + blacklist |
| CI security scanning | ✅ | bandit + semgrep + pip-audit all pass |
| Encrypted local storage | ✅ | Flutter: `flutter_secure_storage` + `sqflite_sqlcipher` |
| Encrypted sensitive fields | ✅ | NRC, push tokens, payment credentials encrypted at rest |
| Permission enforcement | ✅ | Server-authorizes every request independently |
| CORS | ✅ | Explicit origins, credentials disabled, dev regex fallback |
| Production secret key enforcement | ✅ | `ImproperlyConfigured` raised if default key used in production |
| SQL injection prevention | ✅ | semgrep rule prohibits raw SQL string formatting |
| `shell=True` prohibited | ✅ | semgrep rule prevents subprocess shell injection |

### Security Gaps 🔴

| Gap | Severity | Impact | Fix Effort |
|-----|----------|--------|------------|
| No MFA | 🔴 HIGH | Single-factor auth for all users | 1-2 weeks (add TOTP) |
| No PostgreSQL TLS | 🔴 HIGH | DB credentials/ data in transit unencrypted between app server and database | 1 hour (configure) |
| No certificate pinning | 🟡 MEDIUM | Mobile app vulnerable to MitM via forged CA | 1-2 days (add pinning) |
| No app obfuscation | 🟡 MEDIUM | Flutter binary reverse-engineerable | 1 day (configure) |
| No secrets vault | 🟡 MEDIUM | Secrets in env vars, not a vault (HashiCorp Vault, AWS Secrets Manager) | 1-2 weeks |
| No container image scanning | 🟡 MEDIUM | Vulnerable base images undetected | 1-2 days (add Trivy to CI) |
| No idle session timeout | 🟡 MEDIUM | Stale sessions never expire on mobile | 1 day (add background timeout) |
| No pen testing conducted | 🟢 LOW | Unknown attack surface | 2-4 weeks (third-party) |

**Security Verdict:** 🟡 Passes basic checks. Needs MFA, DB TLS, and certificate pinning before production. Can proceed to supervised pilot with the gaps documented.

---

## Domain 3: Performance

| Criterion | Status | Details |
|-----------|--------|---------|
| Database indexes | ✅ | Key columns indexed (organization_id, status, user, installation_id) |
| Nginx rate limiting | ✅ | API: 100r/s, login: 5r/m |
| Gunicorn workers | ✅ | 3 workers × 2 threads = 6 concurrent capacity |
| Request size limits | ✅ | 10MB client max body |
| Static file caching | ✅ | 30d immutable for static, 7d for media |
| Load testing | ❌ | No baseline established |
| Performance monitoring | ❌ | No APM, no query profiling in staging |
| N+1 query audit | ❌ | Not reviewed. Cargo contact picker and trip status transitions are potential N+1 risks |
| Flutter build size | ❌ | Not measured. No obfuscation/release build analysis |
| API latency baseline | ❌ | No p50/p95/p99 metrics available |

**Performance Verdict:** 🟢 No obvious bottlenecks. Adequate for pilot-scale traffic (est. < 100 concurrent users). Load testing is a pre-production requirement before scale.

---

## Domain 4: Offline Sync

### Backend (Feature Complete ✅)

| Component | Status | File |
|-----------|--------|------|
| Device registration | ✅ | `MyDeviceListCreateView` — register/update device with installation_id |
| Device revocation | ✅ | `MyDeviceRevokeView` — revoke device access |
| Sync pull (cursor-delta) | ✅ | `SyncPullView` — returns changes since cursor, paginated |
| Sync push (batch) | ✅ | `SyncPushView` — accepts batch of operations, idempotent via `clientOperationId` |
| Authorization snapshots | ✅ | `AuthorizationSnapshotView` — permission cache for offline enforcement |
| Sync capabilities | ✅ | `SyncCapabilitiesView` — reports supported operations |
| Conflict handling | ✅ | `SyncOperation.conflict` status + `response_payload` for resolution |
| Operation handlers | ✅ | 23 operation types covering bookings, tickets, cargo, passengers, payments |

### Flutter (Infrastructure Built, Screens Unused 🟡)

| Component | Status | File |
|-----------|--------|------|
| Encrypted SQLite database | ✅ | `AppDatabase` — sqflite_sqlcipher, 8 tables, WAL mode, migration support |
| Device registry | ✅ | `DeviceRegistry` — installation_id, backend registration, sync cursor |
| Sync manager | ✅ | `SyncManager` — syncAll() orchestrates push → pull |
| Upload queue | ✅ | `SyncUploadQueue` — enqueue, pushAll (batch 50), retry, retryAll, clean, conflicts |
| **Screen-level offline usage** | ❌ | **No screen reads from local database. All screens call API directly** |

**Critical Gap:** The entire offline infrastructure exists but is **disconnected from the UI**. When the network is unavailable:
- Login fails immediately (no cached session for offline auth)
- Trip list shows error state (no local data fallback)
- Bookings can be queued via `enqueue()` but no screen calls it
- The Sync tab (Tab 3 in BusinessHome) shows a static placeholder

**Offline Sync Verdict:** 🟡 Infrastructure is well-designed and correct, but the 0→1 effort to connect it to screens remains. For MVP launch with "online-only" caveat, this is acceptable. For an offline-first product, this is a blocker.

**Recommendation:** Ship v1 as online-only with offline infrastructure ready for Phase 2. Document the limitation prominently.

---

## Domain 5: API Contracts

### Backend API Layer ✅

| Criterion | Status | Evidence |
|-----------|--------|----------|
| OpenAPI schema | ✅ | 333 schemas auto-generated via `drf-spectacular` |
| Schema validation in CI | ✅ | `spectacular --validate --fail-on-warn` passes |
| Swagger UI | ✅ | Available at `/api/docs/` |
| ReDoc | ✅ | Available at `/api/redoc/` |
| API versioning | ✅ | URL-based: `/api/{version}/` |
| Endpoint coverage | ✅ | 22 app route files covering all MVP features |

### Flutter ↔ OpenAPI Mismatches 🔴

From `flutter/reviews/dto-openapi-serializer-compare.md` — **7 critical mismatches still present in production code:**

| ID | Issue | Flutter Code | Correct | Risk |
|----|-------|-------------|---------|------|
| M-001 | Wrong field name | `booking['booking_reference']` | `booking['authorization_reference']` | 🔴 Runtime error |
| M-002 | Wrong parent object | Monetary fields read from Booking | Read from FareQuote | 🔴 Null values |
| M-003 | Non-existent field | `trip['organization_name']` | Only on `PublicTripSearch` results | 🔴 Null crash |
| M-004 | Wrong field names | `passenger['first_name']`, `['last_name']`, `['email']`, `['code']` | `passenger_code`, no first/last/email | 🔴 Always null |
| M-005 | Wrong field name | `passenger['phone']` | `phone_number` | 🔴 Always null |
| M-006 | Wrong field | `ticket['status']` as String | Ticket has `.is_valid`, `.is_used`, `.is_cancelled` booleans | 🔴 Wrong logic |
| M-007 | Wrong structure | `ticket['passenger_name']` flat on ticket | Nested under `passenger.name` | 🔴 Always null |

**Impact:** These mismatches affect:
- **Booking screen** (counter + passenger): monetary fields null → fare display broken
- **Trip list/detail**: organization_name always null on Trip objects
- **Passenger creation/search**: fields always never match backend → create crashes, search returns nothing
- **Ticket display**: status logic wrong, passenger name empty

These are **not theoretical** — they will cause runtime errors on any API response with data.

**API Contracts Verdict:** 🔴 **Blocker for release.** The 7 field mismatches will cause functional failures in booking, trip display, passenger management, and ticket views. Fixing these requires modifying Flutter production code (not just DTO models).

---

## Domain 6: Permissions

| Criterion | Status | Details |
|-----------|--------|---------|
| Server-enforced | ✅ | Every endpoint authorizes via `require_permission()` or `active_membership_for()` |
| UI gating | ✅ | `hasPermission()` checks in all screens — cargo, refund, booking, etc. |
| Effective permissions | ✅ | Backend computes effective permission codes from role assignments |
| Offline authorization | ✅ | `AuthorizationSnapshot` issued per device for offline permission enforcement |
| Role-based scoping | ✅ | Roles can be scoped by organization, branch, or specific resources |
| Granularity | ✅ | Feature-level + action-level (e.g., `cargo.view`, `cargo.manage`, `cargo.accept`) |
| Permission check | ⚠️ | `SignInScreen` does not gate UI by permission (no `BusinessHome` permission redirect) |

**Permissions Verdict:** ✅ Solid. Server-authorizes independently of client. UI gating is convenience-only. The one gap (no post-login permission redirect) is minor.

---

## Domain 7: Documentation

| Document | Status | Notes |
|----------|--------|-------|
| Product vision / MVP scope | ✅ | `01-mvp-scope.md`, `01-product-vision.md` |
| System architecture | ✅ | `05-system-architecture.md` |
| Technology stack | ✅ | `10-technology-stack.md` |
| Engineering standards (10 docs) | ✅ | `standards/01`–`10` complete |
| AI workflow / roles / DoD | ✅ | `03-`, `04-`, `05-` in standards |
| Security architecture | ✅ | `11-security-architecture.md` |
| Implementation blueprint | ✅ | `01-implementation-blueprint.md` |
| API completion matrix | ✅ | `06-mvp-api-completion-matrix.md` |
| API quality & security report | ✅ | `08-mvp-api-quality-security-report.md` |
| Flutter delivery record | ✅ | `13-flutter-business-delivery.md` |
| Backup strategy | ✅ | `backup_strategy.md` |
| Deployment runbooks (3) | ✅ | deployment, migration-rollback, zero-downtime-deploy |
| Release checklist | ✅ | `release/checklist.md` — template with pre/post-deploy steps |
| OpenAPI spec | ✅ | Auto-generated, docs serving at `/api/docs/` and `/api/redoc/` |
| API README | ⚠️ | Draft status — defines governance but lacks quickstart |
| User manual | ❌ | Not written |
| Admin guide | ❌ | Not written |
| Troubleshooting guide | ❌ | Not written |
| Onboarding guide | ❌ | Not written |
| Root README.md | ❌ | 0 bytes — empty file |

**Documentation Verdict:** 🟡 Technical documentation is strong (architecture, API, standards). User-facing documentation is missing entirely. Acceptable for pilot with trainer-led onboarding; not acceptable for self-service production launch.

---

## Domain 8: Testing

### Backend ✅

| Area | Result | Details |
|------|--------|---------|
| Test count | ✅ | ~1,047 test functions across 250 test files |
| CI test execution | ✅ | `python manage.py test --noinput` in CI |
| Migration check | ✅ | `makemigrations --check --dry-run` ensures no unapplied migrations |
| Schema validation | ✅ | `spectacular --validate --fail-on-warn` ensures OpenAPI validity |
| Dependency consistency | ✅ | `pip check` passes |
| Security scanning | ✅ | `bandit` + `semgrep` + `pip-audit` all pass in CI |
| Coverage report | ❌ | Not generated. No coverage threshold enforced |
| Flake8/linting | ❌ | Not in CI |

### Flutter ❌

| Area | Result | Details |
|------|--------|---------|
| Unit tests | ⚠️ | 11 tests (10 refund service + 1 widget smoke) |
| Widget tests | ❌ | Zero — no widget tests for any of the 14+ screens |
| Integration tests | ❌ | Zero — no driver tests |
| E2E tests | ❌ | Zero — no integration test harness |
| CI analysis | ✅ | `dart analyze` — 0 errors in both apps |
| CI formatting | ✅ | `dart format --set-if-changed` in CI |
| CI test execution | ✅ | `flutter test` runs 11 tests |
| CI dependency check | ✅ | `dart pub deps` verifies consistency |
| Coverage report | ❌ | No coverage tooling configured |

### Critical Testing Gaps 🔴

1. **Flutter widget coverage is near-zero.** 11 tests for an app with 14 screens. No loading/error/empty state tests, no navigation tests, no form validation tests.
2. **No integration tests.** The booking → payment → ticket issuance flow has zero automated test coverage.
3. **No coverage baseline.** Backend coverage is unknown; Flutter coverage is effectively 0%.
4. **No load tests.** No Locust/k6 scripts for any API endpoint.

**Testing Verdict:** 🔴 **Blocker for production release.** Backend testing is adequate. Flutter testing is critically deficient — with 7 field mismatches in production code, the absence of tests means regressions will go undetected. Minimum requirements before production:
- Widget tests for all 5 primary screens (Trip, Booking, Payment, Cargo, Ticket)
- Integration test for the core booking → payment flow
- Coverage report with ≥60% target

---

## Domain 9: Deployment

| Criterion | Status | Details |
|-----------|--------|---------|
| Dockerfile | ✅ | Multi-stage, python:3.13-slim, non-root user |
| Docker compose (production) | ✅ | `compose.production.yml` (2,982 bytes) |
| Docker compose (root) | ❌ | `docker-compose.yml` is **0 bytes** — empty placeholder |
| Nginx config | ✅ | SSL, HSTS, rate limiting, security headers, static/media serving |
| HEALTHCHECK | ❌ | Dockerfile missing `HEALTHCHECK` — container health undetectable |
| Restart policy | ❌ | Compose missing `restart: unless-stopped` — containers won't auto-recover |
| CI backend | ✅ | Tests, scanning, migration check, schema validation |
| CI Flutter | ✅ | Analyze, test, format, deps check |
| CD pipeline | ❌ | No deploy-to-staging or deploy-to-production workflow |
| Staging environment | ❌ | Not provisioned — no pre-production validation |
| Container registry | ❌ | No registry configured — no image tagging/pushing |
| Backup automation | ✅ | `backup-postgres.sh` + cron example + verify-backup.sh |
| Rollback procedure | ✅ | Documented in release checklist |
| Monitoring | ❌ | Sentry configured? No evidence. No Prometheus/Grafana stack |
| Secrets management | ❌ | No secrets vault — Docker secrets or env file only |
| Zero-downtime deploy | ⚠️ | `zero-downtime-deploy.md` exists as a runbook, not implemented in CI |

### Deployment Blocker Summary

| # | Issue | Severity | Fix Time |
|---|-------|----------|----------|
| 1 | Empty docker-compose.yml | 🔴 HIGH | 5 min (copy from production compose) |
| 2 | Missing HEALTHCHECK | 🟡 MEDIUM | 5 min |
| 3 | Missing restart policy | 🟡 MEDIUM | 2 min |
| 4 | No CD pipeline | 🟡 MEDIUM | 2 hours |
| 5 | No staging environment | 🟡 MEDIUM | 1 day (provision) |
| 6 | No container registry | 🟢 LOW | 30 min |

**Deployment Verdict:** 🟠 Manual deployment is possible (Dockerfile + nginx config are ready) but **risky**. The missing HEALTHCHECK and restart policy mean container failures go undetected until users report issues. No CD means manual SSH-and-run deployments. Acceptable for pilot deployment with on-call engineer present; not acceptable for unattended production.

---

## Verdict by Release Gate

### 🚫 Gate 1: Can we ship to production?

**NO.** The following are 🔴 blockers:

| # | Blocker | Domain | Fix |
|---|---------|--------|-----|
| 1 | 7 API field mismatches cause runtime errors | API Contracts | Fix field names in Flutter production code |
| 2 | Near-zero Flutter test coverage | Testing | Add widget tests for primary screens + coverage threshold |
| 3 | No Flutter integration tests for core flow | Testing | Add booking→payment flow integration test |
| 4 | Empty docker-compose.yml | Deployment | Populate from production compose |

### 🟡 Gate 2: Can we ship to a supervised pilot?

**YES, with conditions.** Address these before pilot kickoff:

| # | Requirement | Owner | ETA |
|---|-------------|-------|-----|
| 1 | Fix M-001→M-007 field mismatches in Flutter | Flutter | 2-3 days |
| 2 | Add widget tests for Trip, Booking, Payment, Cargo, Ticket screens | Flutter | 3-5 days |
| 3 | Add HEALTHCHECK to Dockerfile + restart policy to compose | DevOps | 1 hour |
| 4 | Populate root docker-compose.yml | DevOps | 30 min |
| 5 | Deploy staging environment with production compose | DevOps | 1 day |
| 6 | Document the "online-only" caveat for MVP | Product | 1 hour |
| 7 | Configure Sentry for error tracking | DevOps | 1 hour |

### ✅ Gate 3: What's needed for full production readiness?

After pilot, before full production:

| # | Requirement | Domain |
|---|-------------|--------|
| 1 | Load testing with baseline p50/p95/p99 | Performance |
| 2 | MFA for all staff accounts | Security |
| 3 | PostgreSQL TLS | Security |
| 4 | Certificate pinning in Flutter | Security |
| 5 | App obfuscation + Release build optimization | Security |
| 6 | CI/CD deployment pipeline | Deployment |
| 7 | Secrets vault (env → vault migration) | Security |
| 8 | Coverage report with ≥60% target | Testing |
| 9 | User manual + admin guide | Documentation |
| 10 | Monitoring stack (health, error tracking, uptime) | Deployment |

---

## Appendices

### A: BLOCKER Details — 7 API Field Mismatches

From `flutter/reviews/dto-openapi-serializer-compare.md`:

```
M-001: booking['booking_reference']      → booking['authorization_reference']
M-002: booking['base_fare'] etc.         → fare_quote['total_amount'] etc.
M-003: trip['organization_name']         → Only on PublicTripSearch, not Trip
M-004: passenger['first_name'] etc.      → passenger['passenger_code']
M-005: passenger['phone']                → passenger['phone_number']
M-006: ticket['status'] String           → ticket['is_valid'] boolean
M-007: ticket['passenger_name'] flat     → ticket['passenger']['name'] nested
```

Affected screens: `counter_booking_page.dart`, `payment_decision_page.dart`, `trip_list_page.dart`, `trip_detail_page.dart`, `ticket_sales_page.dart`, `booking_screen.dart`, `ticket_list_screen.dart`, `trip_search_screen.dart`.

### B: Test Coverage Gap Detail

| Screen | Widget Tests | Loading | Error | Empty | Form Validation |
|--------|--------------|---------|-------|-------|-----------------|
| SignInScreen | ❌ | ❌ | ❌ | N/A | ❌ |
| TripListPage | ❌ | ❌ | ❌ | ❌ | N/A |
| TripDetailPage | ❌ | ❌ | ❌ | N/A | ❌ |
| CounterBookingPage | ❌ | ❌ | ❌ | N/A | ❌ |
| PaymentDecisionPage | ❌ | ❌ | ❌ | ❌ | ❌ |
| TicketSalesPage | ❌ | ❌ | ❌ | ❌ | N/A |
| CargoWorklistPage | ❌ | ❌ | ❌ | ❌ | N/A |
| CargoAcceptancePage | ❌ | ❌ | ❌ | N/A | ❌ |
| RefundListPage | ❌ | ❌ | ❌ | ❌ | N/A |
| RefundDetailPage | ❌ | ❌ | ❌ | N/A | ❌ |
| RefundCreatePage | ❌ | ❌ | ❌ | N/A | ❌ |
| BookingScreen (passenger) | ❌ | ❌ | ❌ | N/A | ❌ |
| TripSearchScreen | ❌ | ❌ | ❌ | ❌ | N/A |
| TicketListScreen | ❌ | ❌ | ❌ | ❌ | N/A |
| LoginScreen | ❌ | ❌ | ❌ | N/A | ❌ |
| RegistrationScreen | ❌ | ❌ | ❌ | N/A | ❌ |
| HomeScreen | ❌ | ❌ | ❌ | N/A | N/A |

### C: Flutter `dart analyze` Results (current)

**Business app:** `No issues found!` ✅  
**Passenger app:** 5 info-level hints (3 doc comment, 2 unnecessary braces) — 0 errors/warnings ✅

### D: Backend CI Pipeline Steps

```
1. pip install requirements.txt + requirements-security.txt
2. python manage.py makemigrations --check --dry-run
3. python manage.py spectacular --file openapi.yaml --validate --fail-on-warn
4. python manage.py test --noinput
5. pip check
6. pip-audit -r requirements.txt
7. bandit -r backend/apps backend/config
8. semgrep --config security/.semgrep.yml backend/apps backend/config
```

All currently pass ✅

### E: Flutter CI Pipeline Steps

```
1. flutter pub get
2. flutter analyze
3. flutter test --no-pub
4. dart format --set-exit-if-changed .
5. dart pub deps
```

All currently pass ✅

---

*End of Release Readiness Audit*
