# HBT Passenger App — Full Code Review

**Review date:** 2026-07-30
**Scope:** `hbt_passenger_app` (18 Dart files, ~2,951 LOC)
**Analysis:** Static audit of all source files, architecture, state management, API, widgets, offline readiness, performance, security, and testing.

---

## Executive Summary

The HBT Passenger App is a self-service mobile ticketing application for bus passengers. It has 7 screens covering the core booking flow (splash → login/register → trip search → trip detail → seat selection → booking confirmation → my tickets). The codebase is lightweight and functional for an MVP but has significant architectural gaps, security concerns, and zero test coverage.

| Metric | Score | Assessment |
|--------|-------|------------|
| **Architecture** | 45/100 | No DI, no repository, no state management |
| **Code Quality** | 55/100 | Clean structure, mixed practices |
| **Security** | 35/100 | Token refresh but no pinning, no idle timeout |
| **Performance** | 50/100 | N+1 mitigated but no caching |
| **UX** | 60/100 | Good loading/error states, empty states missing |
| **Testing** | 0/100 | Zero tests |
| **Overall** | **38/100** | 🛑 Pre-alpha quality |

### Key Findings

| Type | Count |
|------|-------|
| 🔴 Critical | 4 |
| 🟡 High | 7 |
| 🔵 Medium | 8 |
| 🟢 Low | 6 |

---

## 1. Architecture — 45/100

### Folder Structure — 60/100

```
lib/
├── main.dart                     ✅ Entry point
├── app/passenger_app.dart        ✅ App shell with routing
├── core/
│   ├── auth/auth_controller.dart  ✅ Auth state management
│   ├── config/app_config.dart     ✅ Environment config
│   ├── network/api_client.dart    ✅ HTTP client (duplicate of business app)
│   ├── theme/app_theme.dart       ✅ M3 theme
│   └── widgets/                   ✅ Reusable widgets (app_button, async_views, etc.)
└── features/
    ├── auth/presentation/         ✅ Login + Registration screens
    ├── booking/presentation/      ✅ Seat selection + confirmation
    ├── home/presentation/         ✅ Tab shell
    ├── splash/presentation/       ✅ Splash screen
    ├── ticket/presentation/       ✅ Ticket list
    └── trip/presentation/         ✅ Search + Detail screens
```

**Issues:**
- 🔴 No `shared/` or `infrastructure/` directories (duplicated code with business app)
- 🟡 `features/` uses `presentation/` instead of `screens/` (inconsistent with business app)
- 🟡 No `models/` directory — all data is `Map<String, dynamic>` with no typed DTOs
- 🟡 No `services/` directory — feature screens call `api.get()` directly
- 🟢 No `routing/` — routes defined inline in `passenger_app.dart`

### Clean Architecture — 30/100

| Layer | Status | Detail |
|-------|--------|--------|
| **Presentation** | ✅ | Screens with `StatefulWidget` + `AsyncState` |
| **Application** | ❌ | No use-case / service layer |
| **Domain** | ❌ | No entities, no models, no value objects |
| **Repository** | ❌ | Screens call HTTP directly |

### Dependency Injection — 10/100
- Zero DI — `AuthController` created in `main.dart`, passed through constructors
- No `GetIt`, `Provider`, or `Riverpod`
- Changing `AuthController` signature requires updating 7+ screen constructors

---

## 2. API Client — 40/100

**File:** `core/network/api_client.dart`

**Issues:**
- 🔴 **No token refresh mechanism** — Business app has `onRefreshToken` callback; passenger app has none. Expired token = permanent error.
- 🔴 **No 401 retry** — Unlike business app, passenger API client doesn't intercept 401 for refresh
- 🟡 **Duplicate code** — Essentially identical to business app's `api_client.dart` (both ~200 lines)
- 🟡 **No timeout for multipart** — Only 15s default for all requests
- 🟢 **Error messages are in English** — Business app uses Burmese

### AuthController — 35/100

**File:** `core/auth/auth_controller.dart`

| Feature | Status | Detail |
|---------|--------|--------|
| Login/Register | ✅ | Works with phone + password |
| Token storage | ✅ | Uses `FlutterSecureStorage` |
| Session restore | ✅ | `tryRestore()` with refresh fallback |
| Token refresh | 🟡 | Manual — only in `tryRestore()`, not in API client |
| Sign-out | ✅ | `signOut()` with server notification |
| MFA | ❌ | Not implemented |
| Device binding | ❌ | Not implemented |

**Critical issue:** Token refresh only happens during `tryRestore()`. If a 401 occurs during normal API usage, there's no automatic refresh. The user gets an error and must re-login.

---

## 3. State Management — 25/100

| Screen | Pattern | State Type |
|--------|---------|------------|
| SplashScreen | `StatefulWidget` + `Navigator` | Success only |
| LoginScreen | `StatefulWidget` + `AuthController` | Loading/error via `AuthController` |
| RegistrationScreen | `StatefulWidget` + `AuthController` | Loading/error via `AuthController` |
| HomeScreen | `StatefulWidget` + `IndexedStack` | Tab index only |
| TripSearchScreen | `StatefulWidget` + `AsyncState` | 7 independent booleans |
| TripDetailScreen | `StatefulWidget` + `AsyncState` | Standard pattern |
| BookingScreen | `StatefulWidget` + `AsyncState` | Booking result state |
| TicketListScreen | `StatefulWidget` + `AsyncState` | Standard pattern |

**Issues:**
- 🔴 State disappears on widget rebuild — `StatefulWidget` state is ephemeral
- 🟡 `TripSearchScreen` has 7+ independent `_loading` style booleans (`_searching`, `_loadingRoutes`, etc.)
- 🟡 `AuthController` is a god class — login, register, restore, refresh, sign-out, token storage, user profile, error handling
- 🟡 No offline-aware state — no indication when app is offline

---

## 4. Performance — 50/100

### N+1 Query (Mitigated) — 55/100

The trip search screen had an N+1 problem that was **partially fixed** with `Future.wait` parallelization:

```dart
// Phase 1: Fetch all routes for all orgs in parallel ← ✅ Fixed
final orgRouteFutures = <Future>[...];
final allOrgRoutes = await Future.wait(orgRouteFutures);

// Phase 2: Fetch stops for every route across all orgs in parallel ← ✅ Fixed
final stopFutures = <Future>[...];
final allStops = await Future.wait(stopFutures);
```

**Before:** Sequential fetch — N orgs × M routes = ~34 sequential API calls
**After:** Parallel fetch — 2 phases = orgs + (orgs × routes) parallel calls

**Remaining issues:**
- 🟡 **No client-side caching** — Every trip search re-fetches all orgs, routes, and stops
- 🟡 **No pagination** — `/passenger/tickets/` returns all tickets at once
- 🟡 **No list virtualization** — All lists use standard `ListView` (acceptable for MVP with < 100 items)
- 🟢 Trip search fetches all routes/stops for ALL orgs — could be filtered server-side

### Memory — 60/100
- Seat grid builds all seat widgets upfront (no lazy building)
- Ticket list loads all tickets at once
- No images (Material icons only) — memory pressure is low

---

## 5. Security — 35/100

| Area | Score | Issues |
|------|-------|--------|
| Token storage | ✅ 80/100 | FlutterSecureStorage — correct |
| API authentication | ✅ 70/100 | Bearer JWT — correct |
| Token refresh | 🔴 20/100 | Only in `tryRestore()`, not in API client |
| Certificate pinning | ❌ 0/100 | Not implemented |
| Input validation | 🟡 40/100 | Basic existence checks only |
| Screen lock / idle timeout | ❌ 0/100 | Not implemented |
| Error message exposure | 🟡 50/100 | Shows raw API errors to user |

### 🟡 Input Validation Gaps

| Screen | Field | Validation |
|--------|-------|------------|
| Login | Phone | Only "Required" — no format check |
| Login | Password | Only "Required" — no length check |
| Register | Phone | Length ≥ 8 — but no format regex |
| Register | Password | Length ≥ 8 — correct |
| Register | First/Last name | None — optional |

No phone number format validation (Myanmar numbers: +95 9XXXXXXXXX pattern).

---

## 6. UX — 60/100

### Loading States — 70/100
- ✅ All screens show `LoadingView` or inline spinner on data fetch
- ✅ `BusyButton` on all action buttons
- ✅ Trip search has independent loading states for different phases

### Error States — 65/100
- ✅ Error messages displayed via `_state.fail()` or `AuthController.error`
- ✅ Error messages disappear on next successful action
- 🟡 No `ErrorCard` / `ErrorView` usage in passenger app (uses plain `Text` with red color)
- 🟡 No retry buttons on error — user must navigate away

### Empty States — 50/100
- ✅ Ticket list shows empty state with icon + guidance text
- ✅ Trip search shows "No trips found" with back button
- 🟡 Trip search shows no "No routes" empty state when routes API returns empty
- 🟢 Splash screen has no loading error state (expected — auth restore handled before navigation)

### Navigation — 65/100
- ✅ Named routes via `onGenerateRoute` with type-safe arguments
- ✅ Post-login → `/home` with pushReplacementNamed
- ✅ Post-booking → success view with "My Tickets" deep link
- 🟡 No deep link support for external booking links
- 🟡 No 404 route — `onUnknownRoute` returns to home
- 🟢 BackButton in results view works correctly

### Localization — 0/100
- ❌ All strings are hardcoded in English
- ❌ Myanmar business targets will need Burmese localization
- ❌ No `intl` or `flutter_localizations` dependency

---

## 7. Code Quality — 55/100

### Strengths
- ✅ Consistent use of `AsyncState` for loading/error patterns
- ✅ Safe `_extractTicketList()` with type checking prevents runtime crashes
- ✅ Safe `_toMapList()` and `_extractMaps()` helpers for API response parsing
- ✅ `_extractStops()` handles multiple response formats gracefully
- ✅ Consistent snake_case file naming
- ✅ Material 3 theme from same seed colour as business app

### Weaknesses

#### 🔴 Zero Tests — 0/100
- **0 test files** — not even a smoke test
- **0 test dependencies** beyond default `flutter_test`
- No `wrapInApp` helper (business app has it)
- No mock API client
- No test runner configured

#### 🟡 Code Duplication
- `api_client.dart` is essentially identical to business app's version (~200 lines duplicated)
- `app_config.dart` is identical to business app's version
- Core widgets (`app_button.dart`, `app_dialog.dart`, `async_state.dart`, `async_views.dart`, `status_chip.dart`) are duplicated from business app
- `AppTheme` is duplicated from business app's seed colour
- **Estimated 800+ lines of duplicated code** between the two apps

#### 🟡 Mixed Patterns
- Trip search uses `_state.fail()` for error, but booking screen uses `_state.fail()`
- Login uses `widget.auth.error` directly, but trip search uses `_state.error`
- No consistent error handling pattern across screens

#### 🟡 Hardcoded Values
| Location | Value |
|----------|-------|
| `SplashScreen` | `Future.delayed(const Duration(milliseconds: 600))` — magic number |
| `TripSearchScreen` | `lastDate: DateTime.now().add(const Duration(days: 60))` — magic number |
| `BookingScreen` | `booking['id']?.toString().substring(0, 8)` — unsafe: will crash if ID < 8 chars |
| `BookingScreen` | `'T${DateTime.now().millisecondsSinceEpoch}'` — fallback passenger code format |

#### 🟡 Unsafe Operations
```dart
// BookingScreen: unsafe substring — will crash if ID < 8 chars
'Booking #${_result!['id']?.toString().length != null ? _result!['id']?.toString().substring(0, 8) ?? '-' : '-'}'
                                                                                    ^^^^^^^^
```

### Naming — 75/100
- ✅ Consistent `_screen.dart` suffix
- ✅ Descriptive method names (`_loadInitialData`, `_bookSeat`)
- 🟡 `_fmtTs()` vs `_formatDate()` vs `_formatTs()` — three different date formatters
- 🟡 TripSearchScreen has `_extractList()` and `_toMapList()` — could be shared helpers

---

## 8. Offline Readiness — 10/100

| Component | Status | Notes |
|-----------|--------|-------|
| Local database | ❌ | Not implemented |
| Connectivity monitoring | ❌ | Not implemented |
| Offline queue | ❌ | Not implemented |
| Cached responses | ❌ | Not implemented |
| Error handling for offline | 🟡 | Shows "No internet connection. Please try again." |

The passenger app has **zero offline capability**. Any network loss at any point results in a hard error. Given that the target market is Myanmar (variable network quality), this is a significant limitation.

---

## 9. Business App Dependency Analysis

| Item | Passenger App | Business App | Deduplicated? |
|------|---------------|--------------|---------------|
| `api_client.dart` | ✅ ~140 lines | ✅ ~300 lines | ❌ Duplicated |
| `auth_controller.dart` | ✅ ~180 lines | ✅ ~100 lines (`AuthController`) | ✅ Different (passenger has register) |
| `app_config.dart` | ✅ ~8 lines | ✅ ~8 lines | ❌ Identical |
| `app_theme.dart` | ✅ ~80 lines | ✅ ~80 lines + widgets | ❌ Duplicated seed colour |
| `app_button.dart` | ✅ ~60 lines | ✅ ~60 lines | ❌ Identical |
| `app_dialog.dart` | ✅ ~100 lines | ✅ ~100 lines | ❌ Identical |
| `async_state.dart` | ✅ ~50 lines | ✅ ~50 lines | ❌ Identical |
| `async_views.dart` | ✅ ~80 lines | ✅ ~120 lines | ❌ Similar |
| `status_chip.dart` | ✅ ~60 lines | ✅ ~60 lines | ❌ Identical |
| Models (DTOs) | ❌ None | ✅ 9 files | ❌ Passenger has zero models |

**Estimated duplicated code: ~800+ lines across 8 files**

Recommendation: Extract shared code into a `hbt_shared` package or create a monorepo with library paths.

---

## 10. Critical Issues (4)

| # | Issue | File | Impact |
|---|-------|------|--------|
| **C1** | **Zero tests** | (entire app) | No confidence in any behaviour; regressions undetectable |
| **C2** | **No token refresh in API client** | `core/network/api_client.dart` | Any expired JWT during normal usage = permanent error, user must re-login |
| **C3** | **Unsafe substring on booking ID** | `booking_screen.dart` line ~450 | Crashes if API returns booking ID < 8 characters |
| **C4** | **~800 lines of duplicated code** | Multiple files | Code rot: fixes in business app must be manually ported |

---

## 11. High Issues (7)

| # | Issue | File | Impact |
|---|-------|------|--------|
| **H1** | **No offline capability** | (entire app) | App unusable in areas with poor connectivity |
| **H2** | **No empty states on trip search** | `trip_search_screen.dart` | Search returns no results with no error shown |
| **H3** | **No client-side caching** | (entire app) | Every tab switch re-fetches all data |
| **H4** | **3 different date formatters** | Multiple files | Inconsistent display, harder to maintain |
| **H5** | **No retry on error** | All screens | Errors shown with no retry action |
| **H6** | **No error boundary** | `main.dart` | Unhandled exception crashes entire app |
| **H7** | **No input format validation** | `login_screen.dart` | Users can enter invalid Myanmar phone numbers |

---

## 12. Medium Issues (8)

| # | Issue | File | Impact |
|---|-------|------|--------|
| M1 | No `models/` directory — all data is `Map<String, dynamic>` | (entire app) | Type safety, autocomplete, refactoring all worse |
| M2 | `presentation/` instead of `screens/` (inconsistent with business app) | (features/) | Developer confusion |
| M3 | `AuthController` is a god class | `auth_controller.dart` | Single responsibility violated |
| M4 | No service/repository layer | (entire app) | Cannot add offline cache, testing is painful |
| M5 | No dependency injection | (entire app) | Brittle constructor threading |
| M6 | No crash reporting | (entire app) | Cannot detect production issues |
| M7 | No localization | (entire app) | Myanmar users see English-only UI |
| M8 | No splash screen error state | `splash_screen.dart` | On failure, stays on splash forever |

---

## 13. Low Issues (6)

| # | Issue | File | Impact |
|---|-------|------|--------|
| L1 | Magic numbers (`600ms`, `60 days`) | Multiple files | Hard to configure |
| L2 | No `routing/` directory — routes in `passenger_app.dart` | `app/passenger_app.dart` | Route discovery harder |
| L3 | No `SkeletonLoader` widget | (not used) | Spinner only, no shimmer |
| L4 | No `PaginationBar` widget | (not used) | No pagination on ticket list |
| L5 | No `SectionHeader` usage | (not used) | Inconsistent title styling |
| L6 | No `AppTheme.cardPadding` / `AppTheme.pagePadding` usage | (not used) | Inconsistent spacing |

---

## 14. File-by-File Summary

| File | LOC | Quality | Issues |
|------|-----|---------|--------|
| `main.dart` | 12 | 🟢 Clean | No error boundary |
| `app/passenger_app.dart` | 120 | 🟡 Mixed | Routes inline, no 404 handler |
| `core/auth/auth_controller.dart` | 180 | 🟡 Mixed | God class, no API client refresh |
| `core/config/app_config.dart` | 8 | ✅ Good | Identical to business app |
| `core/network/api_client.dart` | 140 | 🟡 Mixed | No token refresh, duplicate |
| `core/theme/app_theme.dart` | 80 | ✅ Good | Shared M3 seed colour |
| `widgets/app_button.dart` | 60 | ✅ Good | Identical to business app |
| `widgets/app_dialog.dart` | 100 | ✅ Good | Identical to business app |
| `widgets/async_state.dart` | 50 | ✅ Good | Identical to business app |
| `widgets/async_views.dart` | 80 | ✅ Good | Similar to business app |
| `widgets/status_chip.dart` | 60 | ✅ Good | Identical to business app |
| `splash_screen.dart` | 85 | 🟡 Mixed | Magic delay, no error handling |
| `login_screen.dart` | 100 | 🟡 Mixed | No format validation |
| `registration_screen.dart` | 130 | 🟡 Mixed | No phone regex |
| `home_screen.dart` | 75 | ✅ Good | Clean tab shell |
| `trip_search_screen.dart` | 380 | 🟡 Mixed | Complex state, no empty states |
| `trip_detail_screen.dart` | 220 | ✅ Good | Cleaner pattern |
| `booking_screen.dart` | 450 | ⚠️ Complex | Unsafe substring, complex state |
| `ticket_list_screen.dart` | 130 | ✅ Good | Safe list extraction |

---

## 15. Improvement Roadmap

### Phase 1: Critical Fixes (1-2 days)
| Priority | Effort | Item |
|----------|--------|------|
| C2 | 1d | Add token refresh to API client (passenger `api_client.dart`) |
| C3 | 0.5h | Fix unsafe `substring(0, 8)` in booking_screen.dart |
| C1 | 2-3d | Add basic test suite (smoke test + login widget test + search unit test) |

### Phase 2: Quality Improvements (1 week)
| Priority | Effort | Item |
|----------|--------|------|
| H7 | 1d | Add Myanmar phone number validation (`^09\\d{7,9}$`) |
| H5 | 1d | Add retry buttons to error states |
| H4 | 1d | Consolidate date formatting into shared helper |
| H6 | 0.5d | Add `runZonedGuarded` + FlutterError.onError |
| H2 | 0.5d | Add empty states for all list/search screens |

### Phase 3: Architecture (2-3 weeks)
| Priority | Effort | Item |
|----------|--------|------|
| C4 | 3-5d | Extract shared code into `hbt_shared` package or monorepo |
| M4+M5 | 2-3d | Add repository layer + lightweight DI |
| M1 | 1-2d | Add typed DTOs for Trip, Booking, Ticket, Seat |
| M3 | 1d | Split `AuthController` into smaller services |
| H1 | 5-8d | Add offline support (cached trips, pending bookings) |

### Phase 4: Production Readiness (3-4 weeks)
| Priority | Effort | Item |
|----------|--------|------|
| M6 | 1d | Configure Sentry/Crashlytics |
| M7 | 2-3d | Add localization (Burmese + English) |
| L1 | 0.5d | Extract magic numbers into constants |
| L3-L6 | 1-2d | Use shared design system widgets (skeleton, pagination, section header) |

---

## 16. Conclusion

**Overall Score: 38/100 — Pre-alpha quality**

The passenger app is a functional MVP that covers the core booking flow, but it has **4 critical issues** (zero tests, no API-level token refresh, unsafe booking ID display, ~800 lines duplicated code) that make it unsuitable for production without significant remediation.

### What's good
- ✅ Working booking flow end-to-end (search → select → book → confirm → view tickets)
- ✅ Safe API response parsing with type guards (`_extractMaps`, `_toMapList`)
- ✅ Named routes with argument passing
- ✅ Material 3 theme matching business app
- ✅ No circular dependencies

### What needs fixing
- 🔴 Zero test coverage
- 🔴 No API-level token refresh (passenger will hit 401 errors mid-session)
- 🔴 Unsafe substring that crashes on short IDs
- 🔴 ~800 lines duplicated from business app
- 🟡 No empty states, no retry, no caching, no offline
- 🟡 Complex state management in TripSearchScreen (7+ booleans)
- 🟡 No crash reporting or error boundary

The app is **not remotely production-ready** in its current state. The foundational issues (no tests, no token refresh, duplicated code) must be addressed before any production deployment. A focused 1-week sprint on critical and high issues could bring it to **~55/100** — adequate for a supervised pilot.

---

*No files were modified during this review.*
