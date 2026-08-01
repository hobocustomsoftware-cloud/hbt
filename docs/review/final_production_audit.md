# HBT Platform — Final Production Audit

**Audit date:** 2026-08-01
**Auditor:** Lead Engineer (OpenClaw Manager) — automated + static verification
**Baseline:** full_code_audit (58/100), production_audit (32/100), passenger_review (38/100) — 2026-07-30
**Method:** re-verify every roadmap finding (F-01…F-26) against current code + test suites; estimate scores per original audit dimensions.

---

## 1. Verdict

| Metric | 2026-07-30 (worst) | 2026-08-01 | Delta |
|--------|---------------------|------------|-------|
| **Overall readiness** | **32/100** | **~73/100** | **+41** |
| Booking integrity | 0/100 (no seat lock) | **75** | +75 |
| Security | 40 | **72** | +32 |
| Offline | 15 | **68** | +53 |
| Ops/Deployment | 10 | **78** | +68 |
| Architecture | 45 | **55** | +10 |
| Testing | 40 | **55** | +15 |
| Maintainability | 40 | **58** | +18 |
| Release Readiness | 15 | **65** | +50 |

**Status: PILOT-READY with 2 external blockers.** All audit-critical issues
(booking integrity, offline death, security fundamentals, white-screen
crashes, unbounded lists) are resolved and test-verified. Remaining gaps are
externally blocked (crash SDK DSN, cert pinning bundle) or product-scoped
(localization).

---

## 2. Finding-by-finding status (F-01…F-26)

### Priority A — Booking integrity ✅ ALL RESOLVED

| ID | Finding | Status | Evidence |
|----|---------|--------|----------|
| F-01 | No seat-lock endpoints (counter + passenger) | ✅ | `SeatLock` model + migration 0005; acquire/release/extend/list endpoints (org + passenger); `sweep_expired_seat_locks` command |
| F-02 | Passenger booking zero lock protocol | ✅ | Booking screen acquires/releases locks, hold countdown, conflict→grid refresh |
| F-03 | Scanner never validates ticket state | ✅ | `TicketValidateActionView` (idempotent, audited); scanner "Mark as Validated" |
| F-04 | No `active_lock` in availability | ✅ | Seat APIs return `active_lock`; `SeatInfo` renders held seats |
| F-05 | No TTL sweep for holds | ✅ | `SeatLock` TTL 300s + sweep command + on-access expiry |

### Priority B — Security ✅ RESOLVED (1 external blocker)

| ID | Finding | Status | Evidence |
|----|---------|--------|----------|
| F-06 | Passenger no 401 token refresh | ✅ | `api.onRefreshToken` + 401-retry wired (tests green) |
| F-07 | No input validation | ✅ | `validators.dart` (Myanmar phone regex) on login/register |
| F-08 | No error boundary | ✅ | `configureFriendlyErrorWidget()` + `runZonedGuarded` both apps |
| F-09 | No pinning / no idle timeout | 🟡 HALF | Idle timeout ✅ (15-min lock overlay both apps); **cert pinning ⛔ blocked** (needs bundle + rotation policy — blocker-report B-2) |
| F-10 | Unsafe `substring(0,8)` crash | ✅ | Safe `shortId` truncation + tests |

### Priority C — Offline ✅ RESOLVED

| ID | Finding | Status | Evidence |
|----|---------|--------|----------|
| F-11 | Offline infra 100% dead code | ✅ | `DeviceRegistry.initialize()` + `AppDatabase` + `SyncManager` at startup |
| F-12 | No connectivity monitoring / sync UI | ✅ | 15s `/health/` ping, offline banner, real sync tab |
| F-13 | Passenger zero offline | ✅ | `AppCacheDatabase` + stale-flagged fallback (search/detail/seats/tickets/discovery) |

### Priority D — Ops ✅ RESOLVED

| ID | Finding | Status | Evidence |
|----|---------|--------|----------|
| F-14 | No health endpoint | ✅ | `/health/`, `/health/live/`, `/health/ready/` |
| F-15 | No structured logging | ✅ | Django JSON LOGGING config |
| F-16 | No CI/CD | ✅ | `backend-ci.yml` + `flutter-ci.yml` (matrix both apps) |
| F-17 | No pagination default | ✅ | DRF `PageNumberPagination` page size 100 |
| F-18 | No crash reporting | 🟡 HOOK DONE | `CrashReporter` env-gated in both apps; **vendor SDK ⛔ blocked** (needs DSN — blocker-report B-1) |
| F-19 | No composite indexes; cargo/route/refund pagination | ✅ | 4+ composite indexes incl. Ticket + PaymentRecord; `getAllPages()` on all 3 lists |

### Priority E — Architecture/quality ✅ MOSTLY RESOLVED (cleanup-class remaining)

| ID | Finding | Status |
|----|---------|--------|
| F-20 | No repository layer | ✅ Passenger repo layer (Result<T>, Trip/Booking/Ticket repos, screens migrated) |
| F-21 | ~800 LOC duplicated | 🟡 Deferred (M4d) — documented; no user impact |
| F-22 | No DI; god SessionController | 🟡 Deferred — constructor injection proven sufficient |
| F-23 | Dead widgets/routes/misnamed | ✅ Dead code removed (918 LOC); F-23b rename deferred (style-only) |
| F-24 | Zero passenger tests; low business coverage | ✅ Passenger 0→56 tests; business 57→82; auth/org/session covered; screen-level tests remain |
| F-25 | No localization | 🟡 Open (M5c-003) — product decision needed |
| F-26 | N+1 trip search, no caching | ✅ Discovery caching (TTL) + result caching |

---

## 3. Verification evidence (2026-08-01)

| Suite | Result |
|-------|--------|
| Backend `manage.py test` | **124/124 OK** (was 118) |
| Business `flutter analyze` / `flutter test` | **No issues / 82/82** (was 57) |
| Passenger `flutter analyze` / `flutter test` | **No issues / 56/56** (was 9) |
| Security config | `ImproperlyConfigured` guard on dev SECRET_KEY; AnonRateThrottle 120/min + UserRateThrottle 1200/min |
| Indexes in DB | ticket_org_status_issued_idx, payment_org_status_date_idx, booking_org_status_date_idx, trip_org_date_status_idx verified |

---

## 4. What would still fail a strict production review

1. **Certificate pinning absent** (blocked — B-2) — MITM risk on hostile networks remains.
2. **Crash SDK not wired** (blocked — B-1) — crashes logged locally only.
3. **No load/stress tests, no E2E integration test runner** (out of original scope; CI covers unit/widget).
4. **Localization absent** (F-25) — Myanmar users see English UI.
5. **No MFA / biometrics** — phone+password only (product decision).
6. **Business-app screens still call API directly** (F-20 business side not migrated) — works, but offline caching limited to what M2/M4 provide.
7. **`chkdsk H: /f` + repo backup to C:/D: still recommended** — operational hygiene from the 7/31 disconnect.

---

## 5. Recommended next actions (priority order)

1. **Unblock B-1**: provision Sentry DSN → wire SDK (~1–2h, one file per app).
2. **Unblock B-2**: cert bundle + rotation policy next release cycle.
3. F-25 localization (EN baseline extraction first — no product decision needed to start).
4. F-24 part 2: cargo/trip/routes widget tests.
5. F-23b rename + F-21 shared-package extraction (mechanical, low risk).

---

## 6. Score methodology note

Scores are engineering estimates derived from: (a) each F-item's resolution
state above, (b) the original audits' dimension weightings, (c) actual suite
counts. They are directional, not the output of a third-party audit. The
**deployment-day failure scenarios** from the original production audit
(double-booking, offline death, white screen, forced re-login, truncated
lists) are all verifiably eliminated.
