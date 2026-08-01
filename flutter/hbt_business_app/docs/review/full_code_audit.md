# Full Code Audit — HBT Platform

**Audit date:** 2026-07-30
**Scope:** Flutter frontend (`hbt_business_app`, 74 Dart files, ~16K LOC) + Django backend (`backend/`, 17 apps, ~15K LOC)
**Method:** Static analysis of all source files, folder structure, migrations, tests, and configuration.

---

## Executive Summary

The HBT platform is a Myanmar-first intercity express bus SaaS with two frontends (passenger + business) and a Django backend. The codebase is well-structured, follows modern Django/Flutter conventions, and has strong security foundations (encrypted fields, JWT auth, CSP headers). However, significant gaps exist in testing coverage, offline resilience, operational readiness, and frontend-backend contract alignment.

| Metric | Flutter | Django Backend | Overall |
|--------|---------|----------------|---------|
| **Source files** | 74 | 170+ | ~250 |
| **Total LOC** | ~16,000 | ~15,000 | ~31,000 |
| **Test files** | 11 | 20+ | ~31 |
| **Test pass rate** | 57/57 (100%) | Unknown | ⚠️ |
| **Migrations** | — | 80+ | Mature schema evolution |
| **Architecture Score** | 55/100 | 70/100 | 62/100 |
| **Security Score** | 50/100 | 75/100 | 62/100 |
| **Performance Score** | 60/100 | 65/100 | 62/100 |
| **Offline Score** | 18/100 | 70/100 | 44/100 |
| **Maintainability** | 55/100 | 65/100 | 60/100 |
| **Testing Score** | 40/100 | 50/100 | 45/100 |
| **Overall** | **50/100** | **68/100** | **58/100** |

---

## Architecture Score: 62/100

### Flutter Frontend — 55/100

**Strengths:**
- Clean 4-layer separation: `app/`, `core/`, `shared/`, `features/` + `infrastructure/`
- Material 3 design system with 14+ shared widgets, barrel export
- No circular dependencies (verified DAG)
- Feature isolation: each feature has its own `screens/` directory
- `AsyncState` base class eliminates repeated loading/error patterns

**Weaknesses:**
- ❌ **No repository layer** — All 16+ screens call `api.get()` / `api.post()` directly
- ❌ **No dependency injection** — `SessionController` created in `app.dart`, passed via constructors through 16 files
- ❌ **No service layer** — Only `RefundService` exists; ticket sales, cargo, trip, routes use inline HTTP calls
- ❌ **`features/business/` is misnamed** — It's the app shell, not a feature
- 🟡 State management: 1 `ChangeNotifier` controller (ShiftController); 6 of 7 features manage state inline in `StatefulWidget`
- 🟡 `business_home.dart` imports from 7 feature screen files — coupling shell to every feature
- 🟡 `routing/routes.dart` exists but unused — all navigation via `Navigator.push(MaterialPageRoute(...))`

### Django Backend — 70/100

**Strengths:**
- ✅ Well-organized domain-driven app structure: 17 apps (tenancy, identity, scheduling, ticketing, etc.)
- ✅ Clean `config/` + `apps/` split
- ✅ Versioned API (`/api/v1/...`)
- ✅ Proper DRF viewset + serializer pattern
- ✅ Background task management (`management/commands/`)
- ✅ Proper migration strategy with 80+ sequentially numbered migrations
- ✅ `SIMPLE_JWT` with 15-min access + 7-day refresh, rotation, blacklisting
- ✅ Custom exception handler (`audit_exception_handler`)
- ✅ Rate limiting (120/min anon, 1200/min user)
- ✅ OpenAPI schema via `drf_spectacular` with Swagger UI + Redoc
- ✅ Encrypted fields for NRC, payment credentials, push tokens

**Weaknesses:**
- 🟡 No visible repository/service layer separation in most apps
- 🟡 No task queue (Celery/RQ) — long-running operations are synchronous
- 🟡 No GraphQL — REST-only (acceptable for MVP)
- 🟡 Some apps have no test files

---

## Flutter Score: 50/100

### 2. Folder Structure — 65/100
```
lib/
├── main.dart
├── app/              ✅ App entry + config
├── core/theme/       ✅ Design tokens
├── core/widgets/     ✅ 22 shared widgets (12 unused = -5)
├── shared/models/    ✅ 9 DTO files
├── shared/services/  ✅ 5 service files
├── features/         ✅ 10 feature directories
├── infrastructure/   ✅ DB + offline (disconnected)
└── routing/          ⚠️ routes.dart exists, unused
```

### 3. Clean Architecture — 40/100
- Domain layer: ❌ None — models are `Map<String, dynamic>` bags of data, not domain objects
- Repository layer: ❌ None — every screen calls HTTP directly
- Use case layer: ❌ None — business logic in `StatefulWidget` methods
- Dependency flow: ✅ Clean outward, but no abstraction boundaries
- DDD: 🟡 Domain concepts are present (Booking, Ticket, Trip) but not modeled as value objects

### 4. State Management — 30/100
- Auth: `ChangeNotifier` + `AnimatedBuilder` — works for MVP but rebuilds entire `MaterialApp` on auth change
- Features: `StatefulWidget` + inline booleans (`_loading`, `_error`, `_data`) — state disappears on rebuild
- No Riverpod, BLoC, or any state persistence across widget rebuilds
- `SessionController` is still a god class (auth + org + counter + audit) despite split effort

### 5. Dependency Injection — 20/100
- Zero DI framework (no GetIt, no Provider, no Riverpod)
- `SessionController` created in `app.dart`, threaded through all 16+ constructors
- Changing `SessionController` type requires updating 16+ screen files

### 6. Dead Code — 65/100
- 12 of 22 core widgets (54%) have zero consumers
- `routing/routes.dart` exists but is never imported
- `infrastructure/offline/` (3 files, ~700 LOC) completely disconnected from lib/
- `assets/` directory doesn't exist yet
- Offline database (4 tables + sync_operations) never queried

### 7. Naming — 80/100
- ✅ Consistent snake_case file names
- ✅ Descriptive class names (`TripListPage`, `SeatLockController`)
- 🟡 `features/business/` is a shell, not a business feature
- 🟡 `shared/services/api_client.dart` mixes HTTP client and exception class

---

## Backend Score: 68/100

### 8. API Design — 75/100
- ✅ Consistent `/api/v1/{resource}/` URL structure
- ✅ DRF ViewSets with `list`, `create`, `retrieve`, `update`, `destroy`
- ✅ Versioned via URL path (`DEFAULT_VERSIONING_CLASS`)
- ✅ Proper HTTP methods (GET/POST/PATCH/DELETE)
- ✅ OpenAPI schema generation
- 🟡 No HATEOAS or API discovery
- 🟡 No API versioning in URL patterns visible from views
- 🟡 Pagination settings not visible in settings.py

### 9. Authentication — 85/100
- ✅ JWT with `rest_framework_simplejwt`
- ✅ 15-min access token, 7-day refresh token
- ✅ Token rotation + blacklisting
- ✅ `UPDATE_LAST_LOGIN`
- ✅ Flutter `AuthController` stores both tokens in `FlutterSecureStorage`
- ✅ Token refresh callback wired in `ApiClient`
- ❌ No MFA
- ❌ No device-level trust

### 10. Authorization — 70/100
- ✅ Permission-based via DRF `IsAuthenticated` default
- ✅ Granular permissions seeded via migrations (19 seed migrations)
- ✅ Multi-tenant isolation via `Organization` context
- 🟡 No permission checking in Flutter API client beyond `hasPermission()` string matching
- 🟡 No visible row-level permission enforcement in backend views
- ❌ No ABAC or RBAC framework beyond DRF permissions

### 11. Database Design — 75/100
- ✅ PostgreSQL with SQLite fallback for development
- ✅ Connection pooling (`CONN_MAX_AGE: 60`, health checks)
- ✅ Proper migration strategy with sequenced files
- ✅ Encrypted field support (NRC, payment credentials, push tokens)
- ✅ Partial unique indexes concept designed for seat lock
- 🟡 No visible `select_related`/`prefetch_related` usage check
- 🟡 Migration count (80+) suggests schema churn

### 12. ORM Usage — 70/100
- ✅ Standard Django ORM patterns
- ✅ Custom managers (identity `managers.py`)
- ✅ Service layer in some apps
- 🟡 No query analysis visible — potential N+1 in nested serializers
- 🟡 No `db_index` review done

### 13. N+1 Queries — 50/100
- 🟡 Booking → FareQuote → FareQuoteLine chain: potential 3-deep N+1
- 🟡 Trip → Schedule → Route → Stops: potential 4-deep N+1
- 🟡 Ticket → Booking → Passenger: potential 3-deep N+1
- 🟡 No `select_related` or `prefetch_related` visible in serializers
- ✅ Flutter `Future.wait` parallel fetching mitigates frontend N+1

### 14. Indexes — 60/100
- ✅ Foreign keys indexed by Django defaults
- ✅ `sync_operations` has status index
- ✅ Seat lock partial unique index designed
- 🟡 No composite indexes for common query patterns (org + status + date)
- 🟡 No full-text search indexes (PostgreSQL tsvector)

### 15. Transaction Safety — 65/100
- ✅ `atomic()` blocks in migration data migrations
- ✅ Seat lock partial unique index prevents race condition
- 🟡 Booking creation (booking + fare quote + lock) not wrapped in atomic transaction
- 🟡 Payment recording (payment + evidence upload) not transactional
- ❌ No distributed transaction support (Saga pattern)

---

## Security Score: 62/100

### 16. General Security — 70/100
- ✅ HTTPS via `SECURE_SSL_REDIRECT`
- ✅ HSTS headers configurable
- ✅ `X_FRAME_OPTIONS = DENY`
- ✅ `SECURE_CONTENT_TYPE_NOSNIFF`
- ✅ `SECURE_REFERRER_POLICY`
- ✅ `SECURE_CROSS_ORIGIN_OPENER_POLICY`
- ✅ CORS restricted to explicit origins
- ✅ JWT tokens stored in `FlutterSecureStorage`
- ✅ Encrypted fields for NRC, payment credentials, push tokens
- ✅ Malware scanning for file uploads (configurable)
- ❌ No certificate pinning
- ❌ No security event logging
- ❌ No audit trail for admin actions

### 17. Flutter Security — 50/100
- ✅ Token in secure storage
- ✅ No hardcoded secrets
- 🟡 API base URL from compile-time env var — can't rotate without rebuild
- ❌ No idle session timeout
- ❌ No screen lock
- ❌ No certificate pinning
- ❌ No input sanitization

### 18. Logging — 40/100
- ✅ Custom exception handler logs audit events
- 🟡 No structured logging (JSON)
- 🟡 No log levels visible (DEBUG/INFO/WARNING/ERROR)
- ❌ No centralized log aggregation
- ❌ No audit trail for non-API operations
- ❌ Flutter has zero logging — no `debugPrint` or `log` usage

### 19. Error Handling — 55/100
- ✅ Django: custom exception handler with audit logging
- ✅ Flutter: error cards with retry on most screens
- ✅ API client: specific Burmese error messages per error type
- 🟡 Flutter: no global error boundary (`FlutterError.onError` not configured)
- 🟡 Flutter: no `runZonedGuarded` for async errors
- ❌ Flutter: no crash reporting (Sentry/Crashlytics)
- ❌ Backend: no structured error response format beyond DRF defaults

---

## Performance Score: 62/100

### 20. Flutter Performance — 60/100
- ✅ Parallel `Future.wait` in initial data loads
- ✅ Pagination on trip list
- ✅ 15s API timeouts
- 🟡 No client-side caching — every tab switch re-fetches
- 🟡 `AnimatedBuilder` rebuilds entire `MaterialApp` on auth change
- 🟡 No image optimization (not applicable — Material icons only)
- ❌ No list virtualization (all lists use `ListView` with all items built at once)

### 21. Backend Performance — 65/100
- ✅ Connection pooling with health checks
- ✅ Rate limiting configured
- ✅ JWT (stateless) — no DB session lookup
- 🟡 No Redis cache for frequently accessed data (routes, stops)
- 🟡 No database query profiling tools configured
- 🟡 No async views for I/O-heavy operations
- ❌ No Celery/RQ for background tasks

### 22. Memory — 60/100
- 🟡 Flutter: all lists load entire dataset into memory at once
- 🟡 No pagination on cargo, route, or refund lists
- 🟡 Backend: no streaming responses for large datasets

---

## Offline Score: 44/100

### 23. Flutter Offline — 18/100
- ✅ DeviceRegistry with UUID installation ID
- ✅ AppDatabase with 6 tables + sync_operations (SQLCipher encrypted)
- ✅ SyncUploadQueue with batch push + idempotency UUIDs
- ✅ SyncManager with cursor-based pull
- ❌ DeviceRegistry never initialized (dead code)
- ❌ No screen uses local database
- ❌ No connectivity monitoring
- ❌ Sync tab is placeholder text
- ❌ No conflict resolution UI

### 24. Backend Offline — 70/100
- ✅ Dedicated `apps/offline` with full sync infrastructure
- ✅ Device registration endpoint
- ✅ Cursor-based sync pull endpoint
- ✅ Idempotency key support
- ✅ Conflict detection in sync operations
- 🟡 No WebSocket for real-time sync push
- 🟡 No TTL-based cursor expiry

---

## Maintainability: 60/100

### 25. Code Duplication — 60/100
- 🟡 `_loading` / `_error` / try/catch/finally repeated in 10+ Flutter screens
- 🟡 `TextField(...)` repeated in 8+ screens instead of using `FormTextField`
- 🟡 `DropdownButtonFormField` repeated in 6+ screens instead of `FormDropdown`
- 🟡 `showDialog(AlertDialog(...))` in 3 screens instead of `AppDialog`
- ✅ Backend: clean DRY patterns via DRF ViewSets + Serializers

### 26. SOLID — 45/100
- **S** (Single Responsibility): Violated — `SessionController` still handles auth + org + counter + audit
- **O** (Open/Closed): 🟡 Flutter screens are closed for extension without modification
- **L** (Liskov Substitution): ✅ Not relevant — no deep inheritance hierarchies
- **I** (Interface Segregation): ❌ No interfaces/abstract classes in Flutter
- **D** (Dependency Inversion): ❌ Flutter screens depend on concrete `ApiClient`, not abstractions

### 27. Testing — 45/100
| Area | Flutter | Backend |
|------|---------|---------|
| Test files | 11 | 20+ |
| Total tests | 57 | Unknown |
| Test pass rate | 100% (57/57) | Unknown |
| Coverage estimate | ~10% | ~30% |
| CI integration | ❌ | ❌ |
| Widget tests | 3 screens | N/A |
| Integration tests | 3 flows | Some |
| Unit tests | 17 (QR validation) | Some |

**Gaps:**
- 🟡 No tests for: settings, auth controller (Flutter), cargo, trip, routes screens
- 🟡 No backend test runner visible in `manage.py`
- 🟡 `MockApiClient` throws on every un-mocked call — brittle test pattern
- ❌ No load/stress tests
- ❌ No E2E tests (no integration test runner)

---

## Technical Debt: Medium

| Category | Items | Effort |
|----------|-------|--------|
| **Critical** | Offline infra completely disconnected | 10-12 days |
| **High** | 12/22 dead widgets + no repository layer | 5-8 days |
| **High** | No crash reporting + no CI/CD | 3-5 days |
| **Medium** | Duplicate patterns (loading/error) in 10+ screens | 2-3 days |
| **Medium** | Unused `routing/routes.dart` | 0.5 days |
| **Low** | Mixed English/Burmese strings | 1-2 days |
| **Low** | `features/business/` misnamed | 0.5 days |

---

## Critical Issues

| # | Issue | Component | Impact |
|---|-------|-----------|--------|
| C1 | Offline architecture is 100% dead code — DeviceRegistry never initialized, SyncManager never called | Flutter | Any network loss = app completely unusable |
| C2 | No crash reporting (Sentry/Crashlytics) | Both | Cannot detect production crashes |
| C3 | No repository layer — screens depend on HTTP directly | Flutter | Cannot add offline cache, testing is painful |
| C4 | No CI/CD pipeline | Both | Regressions not caught, manual deploy only |
| C5 | 12 of 22 shared widgets (54%) are unused | Flutter | Dead code surface that must be maintained |

## High Issues

| # | Issue | Component | Effort |
|---|-------|-----------|--------|
| H1 | No auth route guard — any screen reachable without auth | Flutter | 1-2d |
| H2 | Scanner QR code still `?code=***` in some code paths | Flutter | Verify |
| H3 | No token refresh fallback — if both tokens expired, no graceful redirect | Flutter | 1d |
| H4 | N+1 risk in Booking → FareQuote → FareQuoteLine chain | Backend | 1d |
| H5 | No composite indexes for org+status+date queries | Backend | 1d |
| H6 | Payment recording not wrapped in atomic transaction | Backend | 1d |
| H7 | Flutter has zero error boundary — unhandled exception crashes app | Flutter | 0.5d |

## Medium Issues

| # | Issue | Component | Effort |
|---|-------|-----------|--------|
| M1 | SessionController still handles 4+ concerns | Flutter | 2-3d |
| M2 | No empty states on 5 of 7 list screens | Flutter | 1d |
| M3 | FormTextField/Dropdown unused — 8+ screens hand-roll TextFields | Flutter | 1-2d |
| M4 | Pagination only on trip list — cargo/route/refund have none | Flutter | 1-2d |
| M5 | No pre-fetch optimization on backend | Backend | 2-3d |
| M6 | Mixed Myanmar/English error messages | Flutter | 1-2d |

## Low Issues

| # | Issue | Component | Effort |
|---|-------|-----------|--------|
| L1 | `features/business/` should be `features/shell/` | Flutter | 0.5d |
| L2 | `routing/routes.dart` exists unused | Flutter | 0.5d |
| L3 | No splash screen | Flutter | 0.5d |
| L4 | No structured logging | Backend | 1d |
| L5 | No `__init__.py` in Flutter directories (not required but inconsistent) | Flutter | 0.1d |

---

## Improvement Roadmap

### Phase 1: Production Stabilization (1-2 weeks)
| Priority | Effort | Items |
|----------|--------|-------|
| P0 | 2d | Configure Sentry/Crashlytics for both apps |
| P0 | 3d | Set up CI/CD (GitHub Actions: lint → test → build) |
| P1 | 1d | Add global error boundary + `runZonedGuarded` |
| P1 | 2d | Fix 3 scanner P1 issues (camera permission, error handling, status update) |

### Phase 2: Architecture Hardening (2-3 weeks)
| Priority | Effort | Items |
|----------|--------|-------|
| P0 | 10-12d | Activate offline infrastructure (repository layer, DeviceRegistry init) |
| P1 | 5-8d | Migrate to repository pattern (screens → repositories → ApiClient + AppDatabase) |
| P1 | 2-3d | Split SessionController into 3 distinct services |
| P2 | 1-2d | Activate unused shared widgets |

### Phase 3: Testing & Quality (2-3 weeks)
| Priority | Effort | Items |
|----------|--------|-------|
| P1 | 3-5d | Add tests for auth, cargo, trip, route screens |
| P1 | 2-3d | Add pagination to all list screens |
| P2 | 2-3d | Add N+1 query optimization (select_related/prefetch_related) |
| P2 | 1d | Add composite indexes for common queries |

### Phase 4: Feature Complete (3-4 weeks)
| Priority | Effort | Items |
|----------|--------|-------|
| P2 | 5-8d | Offline mode with SyncManager integration |
| P2 | 3-5d | GoRouter migration with deep linking |
| P2 | 2-3d | Booking detail, ticket detail, cargo detail screens |
| P3 | 1-2d | Splash screen + onboarding flow |

---

## Final Scores Summary

| Domain | Score | Verdict |
|--------|-------|---------|
| **Architecture** | 62/100 | Solid foundation, repository layer missing |
| **Security** | 62/100 | Good backend, weak Flutter |
| **Performance** | 62/100 | Adequate for MVP, no profiling done |
| **Offline** | 44/100 | Infra built, completely disconnected |
| **Testing** | 45/100 | Coverage too low for production |
| **Maintainability** | 60/100 | Clean but has technical debt |
| **Overall** | **58/100** | **Not production-ready** |

### Key Takeaway

The backend is mature and well-architected (70/100). The Flutter frontend is the bottleneck (50/100), held back by:
1. No repository layer / offline connectivity
2. No operational monitoring
3. 54% dead widget surface area
4. No CI/CD or error tracking

The architecture audit identified **5 critical, 7 high, and 6 medium issues**. The most impactful single fix is activating the offline infrastructure (10-12 days), which would simultaneously solve the offline problem, enable a proper repository pattern, and justify the 700+ LOC already written in `infrastructure/offline/`.

---

*No files were modified during this audit.*
