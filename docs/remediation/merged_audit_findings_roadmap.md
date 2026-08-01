# HBT Platform — Merged Audit Findings & Remediation Roadmap

**Created:** 2026-07-31
**Last verified:** 2026-08-01 (post-disconnect recovery; drive remounted F: → H:)

## Status summary (2026-08-01)

| Milestone | Status | Evidence |
|-----------|--------|----------|
| M0 Booking integrity | ✅ DONE | Backend suite 118/118 OK (incl. 8 seat-lock tests); seat-lock model/migration/services/endpoints verified in code; create_booking rejects foreign-held seats + consumes own locks; TicketValidateActionView idempotent + audited |
| M1 Security | ✅ DONE | Passenger 401-triggered refresh wired via `api.onRefreshToken`; validators (Myanmar phone regex) on login/register; error boundary `configureFriendlyErrorWidget()` + `runZonedGuarded` in both apps; unsafe `substring(0,8)` replaced |
| M2 Offline activation | ✅ DONE | `DeviceRegistry.initialize()` + `AppDatabase.initialize()` + SyncManager at startup; connectivity monitor 15s ping; offline banner; real sync tab |
| M3 Operational readiness | ✅ DONE | `/health/`, `/health/live/`, `/health/ready/`; JSON logging; DRF PageNumberPagination (page size 100); CI matrix over both Flutter apps + backend workflow |
| M4 Passenger offline + architecture | ⏳ Pending | Repository layer (F-20), shared package (F-21), DI (F-22), passenger offline (F-13) |
| M5 Quality & cleanup | ⏳ Pending | Dead widgets (F-23), tests (F-24), localization (F-25), search (F-26), cert pinning/idle timeout (F-09), crash reporting SDK (F-18), composite indexes (F-19) — **explicitly last** |

**Verification runs (2026-08-01):** backend `manage.py test` → 118 tests OK (493s). Business app `flutter analyze` → no issues; `flutter test` → 57/57. Passenger app `flutter analyze` → no issues; `flutter test` → 9/9.

**Recovery notes:** drive disconnected 2026-07-31 20:00 (Event 50/137/140, dirty volume). Remounted as H: on 2026-08-01. Git metadata (`.git/`) was empty — repo re-initialized and full working tree committed (1029 files). `chkdsk` was the original plan; files verified readable and all tests pass, so no data loss detected in the working tree. Recommend `chkdsk H: /f` at next idle window and copying repo to C:/D: to remove single-point-of-failure.

---

## 1. Verification note — stale audit claims (already fixed, no action)

**Source audits merged:**
1. `flutter/hbt_business_app/docs/review/full_code_audit.md` (2026-07-30, overall 58/100)
2. `flutter/hbt_passenger_app/docs/review/passenger_review.md` (2026-07-30, overall 38/100)
3. `flutter/hbt_business_app/docs/review/production_audit.md` (2026-07-30, overall 32/100)

**Method:** All findings from the three audits were collected, duplicates merged (3 audits × overlapping
criteria = ~40 unique findings), then each finding was **re-verified against the current code** (2026-07-31)
to separate live issues from stale audit claims. Prioritization = business impact × implementation dependency.

---

## 1. Verification note — stale audit claims (already fixed, no action)

Several audit claims did not match the code as of 2026-07-31. These were **verified as already implemented**
and are excluded from the roadmap:

| Audit claim | Verification result |
|---|---|
| CR-07: `SECRET_KEY` defaults to dev key | ✅ `settings.py:39-42` raises `ImproperlyConfigured` when `DEBUG=False` and key is default |
| CR-03: booking creation not atomic | ✅ `bookings/services.py:20` `create_booking` is `@transaction.atomic` with `select_for_update`, idempotency via `client_request_id`, seat conflict checks |
| CR-04: payment recording not transactional | ✅ `payments/services.py` — 13+ `@transaction.atomic` service functions incl. `create_payment` |
| HI-07: N+1 in Booking/FareQuote chain | ✅ `select_related`/`prefetch_related` present in bookings, ticketing, passengers, boarding views |
| CR-06: no auth throttling | ✅ DRF `AnonRateThrottle` (120/min) + `UserRateThrottle` (1200/min) configured |
| C1/CR-02 (partial): counter booking has no seat lock | ⚠️ **Partial** — UI lock flow exists (`SeatLockController`) but calls backend endpoints that **do not exist** (see F-01) |

---

## 2. Merged findings (unique, live)

### Priority A — Booking integrity & revenue protection (business-critical)

| ID | Finding | Sources | Live status (verified) |
|----|---------|---------|------------------------|
| **F-01** | **Backend has no seat-lock endpoints.** `SeatLockController` (counter) calls `POST/DELETE /organizations/{org}/seat-lock/…` which 404. Counter seat-selection lock flow is broken; passenger app has no lock at all. | CR-01, CR-02, CR-11(part), seat_lock.md | 🔴 LIVE |
| **F-02** | Passenger self-service booking has zero lock protocol: availability is a point-in-time snapshot, no held-seat visibility, no conflict handling/auto-refresh on double-book. Backend rejects the 2nd booking atomically, but UX is a hard error with no seat suggestion. | CR-01 | 🔴 LIVE |
| **F-03** | Scanner validates ticket via GET lookup only — ticket status never transitions to `validated`, no audit trail for check-in. | CR-05 | 🔴 LIVE |
| **F-04** | Seat availability APIs return `available` only — no `active_lock` payload; UI cannot render "held by another" states. | CR-02, seat_lock.md | 🔴 LIVE |
| **F-05** | No server-side TTL sweep for holds — no expiry job for HELD seats (partial-unique-index concept exists in docs only). | CR-02, offline_booking_strategy.md | 🔴 LIVE |

### Priority B — Security (credential & data protection)

| ID | Finding | Sources | Live status |
|----|---------|---------|-------------|
| **F-06** | Passenger `api_client.dart` has no 401-triggered token refresh — expired JWT = permanent error, forced re-login mid-session. Business app already has `onRefreshToken` (mirror it). | CR-09, C2, H3 | 🔴 LIVE |
| **F-07** | No input format validation on login/register (Myanmar phone format `^09\d{7,9}$` not enforced); passenger app shows raw API errors. | H7, CR-10(part) | 🟡 LIVE |
| **F-08** | No error boundary in either app — unhandled exception = white screen; no `runZonedGuarded`/`FlutterError.onError`. | CR-18, H6, H7(audit1) | 🔴 LIVE |
| **F-09** | No certificate pinning either app; no idle session timeout. | CR-08, HI-xx | 🟡 Deferred — needs release/build infra + product decision (M5) |
| **F-10** | Unsafe `substring(0, 8)` on booking ID in passenger success screen — crash on IDs < 8 chars. | C3, HI-21 | 🔴 LIVE (quick fix) |

### Priority C — Offline functionality (market-critical for Myanmar connectivity)

| ID | Finding | Sources | Live status |
|----|---------|---------|-------------|
| **F-11** | Offline infra is 100% dead code: `DeviceRegistry.initialize()` never called, `SyncManager` never instantiated, `AppDatabase` never opened. Any network loss = app unusable. | C1, CR-11 | 🔴 LIVE |
| **F-12** | No connectivity monitoring / offline indicator / sync-status UI. Sync tab is placeholder. | CR-11(part), HI-16, MI-07 | 🔴 LIVE |
| **F-13** | Passenger app has zero offline capability (no cache, no queue, no local DB). | H1(passenger review) | 🟡 Deferred to M4 (repo layer first) |

### Priority D — Operational readiness (deployment safety)

| ID | Finding | Sources | Live status |
|----|---------|---------|-------------|
| **F-14** | No health-check endpoint (`/health/`, liveness/readiness). | CR-20 | 🔴 LIVE (quick) |
| **F-15** | No structured logging (Django LOGGING config minimal; Flutter zero logging). | CR-19 | 🔴 LIVE |
| **F-16** | No CI/CD pipeline (repo has `.github/` but no workflows). | C4, CR-17 | 🔴 LIVE |
| **F-17** | DRF pagination not globally configured — list endpoints unbounded. | HI-12 | 🟡 LIVE (quick) |
| **F-18** | No crash reporting (Sentry/Crashlytics) — needs DSN; hook + env-gated init. | C2, CR-16, M6 | 🟡 Deferred (needs keys) — error boundary first (F-08) |
| **F-19** | No composite indexes for org+status+date queries; no pagination on cargo/route/refund lists. | H5, HI-15, M4 | 🟡 M5 |

### Priority E — Architecture & quality debt (do NOT start before A–D)

| ID | Finding | Sources |
|----|---------|---------|
| F-20 | No repository layer; screens call HTTP directly (blocks offline caching) | C3, CR-12, M4 |
| F-21 | ~800 LOC duplicated between the two Flutter apps (api_client, app_config, theme, widgets) | C4(passenger), CR-13 |
| F-22 | No dependency injection; `SessionController` god class | CR-14, M1 |
| F-23 | 12/22 shared widgets dead code; `routing/routes.dart` unused; `features/business/` misnamed | C5, HI-13, MI-03/04, L1/L2 |
| F-24 | Zero tests in passenger app; business app ~10% coverage | C1(passenger), HI-xx |
| F-25 | No localization (English-only UI, mixed MM/EN strings) | M7, M6(audit1) |
| F-26 | N+1 in public trip search (34 sequential calls, partially mitigated with `Future.wait`), no client-side caching | H3(passenger), HI-16 |

---

## 3. Prioritization rationale

**Business impact:**
- Booking integrity (F-01…F-05) → direct revenue loss + double-booking incidents on day 1 of any pilot.
- Security (F-06…F-10) → credential theft / forced logouts erode trust; F-10 is a guaranteed crash path.
- Offline (F-11…F-12) → product-killer in target market (variable connectivity) — every network drop stops sales.
- Ops (F-14…F-17) → invisible failures; blocks safe deployment, not the pilot itself.
- Cleanup (F-20…F-26) → maintainability only; zero user-visible impact. **Explicitly last.**

**Implementation dependency:**
- F-01 must precede F-02/F-04 (backend contract first).
- F-08 (error boundary) precedes F-18 (crash reporting).
- F-11 (offline init) is independent of F-13 (passenger offline) but F-20 (repo layer) unblocks F-13.
- F-06 mirrors an existing pattern (business app) — low risk, do early.

---

## 4. Remediation roadmap — milestones

### M0 — Booking integrity & revenue protection (Days 1–2) ⛔ gate: no deployment without this
| Item | Finding | Deliverable |
|------|---------|-------------|
| Seat-lock backend | F-01, F-05 | `SeatLock` model + partial-unique active-lock constraint + migration; acquire/release/extend/list endpoints (org + passenger); TTL sweep (on-access + management command); idempotency key |
| Lock enforcement in booking | F-01 | `create_booking` rejects seats with active locks not owned by actor; consumes own locks on success |
| Availability lock status | F-04 | Counter + passenger seat APIs return `active_lock` per seat |
| Passenger booking lock flow | F-02 | Booking screen: acquire on select, hold countdown, conflict handling, release on back/cancel/expiry |
| Scanner state update | F-03 | `POST /tickets/{id}/validate/` marks ticket `validated` (idempotent, audit); scanner offers "Mark validated" after successful lookup |

**Exit criteria:** two counters cannot hold/sell the same seat simultaneously; passenger double-tap cannot double-book; validation leaves an audit trail; all 57 business + backend tests pass.

### M1 — Security hardening (Days 2–3)
| Item | Finding | Deliverable |
|------|---------|-------------|
| Passenger token refresh | F-06 | Mirror business `onRefreshToken` + 401-retry in passenger `api_client.dart`; wire `AuthController` |
| Crash-safe success screen | F-10 | Fix `substring(0,8)` → safe truncation helper |
| Input validation | F-07 | Myanmar phone regex on login/register; trim/sanitize text inputs before send |
| Error boundary | F-08 | `runZonedGuarded` + `FlutterError.onError` + error screen in both apps |

**Exit criteria:** expired-token mid-session = silent refresh, not re-login; no crash path on short IDs; invalid phone rejected client-side; unhandled errors show recoverable screen.

### M2 — Offline activation (Days 3–5)
| Item | Finding | Deliverable |
|------|---------|-------------|
| Device bootstrap | F-11 | `DeviceRegistry.initialize()` at app start; register device with backend; persist installation ID |
| Connectivity monitoring | F-12 | Connectivity stream (online/offline) + UI banner; gate network calls |
| Sync wiring | F-12 | Sync tab shows device/sync status; manual "Sync now" triggers `SyncManager` pull |
| Startup resilience | F-11 | App boots offline with cached session; graceful degraded mode |

**Exit criteria:** app registers device on first run; network loss shows banner and does not crash; sync tab reflects real state.

### M3 — Operational readiness (Days 5–7)
| Item | Finding | Deliverable |
|------|---------|-------------|
| Health endpoint | F-14 | `/health/` + `/health/ready/` (DB check) |
| Structured logging | F-15 | Django `LOGGING` JSON-ish config; Flutter `debugPrint`/log in API client, auth, booking paths |
| CI/CD | F-16 | GitHub Actions: backend `check` + tests, Flutter `analyze` + tests on PR |
| Pagination default | F-17 | DRF `PageNumberPagination` default page size |

**Exit criteria:** health endpoint 200; logs on key paths; PRs run green CI; list endpoints paginated.

### M4 — Passenger offline + architecture (Week 2) — after M0–M3
Repository layer (F-20), shared `hbt_shared` package (F-21), DI (F-22), passenger offline cache/queue (F-13).

### M5 — Quality & cleanup (Week 3+) — explicitly last
Dead widgets (F-23), tests (F-24), localization (F-25), search optimization (F-26), cert pinning + idle timeout (F-09), crash reporting SDK (F-18), composite indexes (F-19).

---

## 5. Non-negotiables (user directive)

- **Do not start M5 cleanup while M0–M3 are unresolved.** Low-impact items (dead widgets, rename, routes.dart,
  magic numbers) are scheduled only after booking integrity, offline, and security gates are green.
- Each milestone keeps the full test suite green before moving on.
