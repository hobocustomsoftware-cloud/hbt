# Flutter Architecture Audit — HBT Business App

**Audit date:** 2026-07-30
**Scope:** `lib/` (44 Dart source files)
**Analysis:** Folder structure, dependency flow, state management, offline readiness, testability, scalability

---

## 1. Folder Structure & Separation of Concerns

### Current layout

```
lib/
├── main.dart
├── app/                          ← App entry + config
├── core/theme/                   ← Design tokens
├── core/widgets/                 ← Reusable UI components (barrel exported)
├── shared/models/                ← Domain DTOs (Trip, Booking, Ticket, etc.)
├── shared/services/              ← HTTP client + refund service
├── infrastructure/database/      ← SQLCipher encrypted DB
├── infrastructure/offline/       ← Device registry, sync manager, upload queue
├── routing/                      ← Route path constants
└── features/
    ├── auth/controllers/         ← SessionController (auth + org + permissions)
    ├── auth/screens/
    ├── business/screens/         ← Shell with NavigationBar
    ├── cargo/screens/
    ├── ticket_sales/screens/
    ├── trip/screens/
    ├── routes/screens/
    └── refund/screens/
```

### Strengths

| Aspect | Score | Notes |
|--------|-------|-------|
| **Layer separation** | 8/10 | Four clear layers: `app/`, `core/`, `shared/`, `features/`. `infrastructure/` correctly separates DB and sync plumbing from UI and business logic. |
| **Feature isolation** | 7/10 | Each feature has its own `screens/` directory. No cross-feature imports from screen files (they only import `core/`, `shared/`, or intra-feature files). |
| **Naming consistency** | 9/10 | Every screen file uses `*_page.dart` or `*_screen.dart`. Controllers use `*_controller.dart`. All snake_case files. |
| **Barrel export** | 7/10 | `core/widgets/widgets.dart` exists but no feature-level barrel files. Each screen file imports widgets individually. |

### Weaknesses

1. **Mixed concerns in `core/`** — `core/theme/` and `core/widgets/` are pure UI, which is correct. But the original `core/config/`, `core/network/`, `core/database/` etc. (already moved to `app/`, `shared/`, `infrastructure/`) had UI and infrastructure mixed. The restructure fixed this but leaves `core/` as a "UI-only" layer — worth making explicit.

2. **`business/` is not a feature** — It's the app shell (NavigationBar + route dispatch). Housing it as `features/business/screens/` is misleading. It should be `features/shell/` or live at `app/shell/`.

3. **`features/organization/` was deleted** — Its only file (`organization_context.dart`) was moved to `shared/models/`. This is fine for a single-domain model, but if org logic grows (org management screens, org picker), it needs a feature folder back.

4. **No `assets/` directory** — The app uses Material icons only. If custom icons, fonts, or images are added later, an `assets/` folder needs integration into `pubspec.yaml`.

### Recommended improvements

- Rename `features/business/screens/` → `features/shell/screens/`
- Create a `features/organization/screens/` directory for future org management UI
- Add explicit doc comments at the top of each layer directory (e.g. a `README.md` in `lib/core/` stating "pure UI only — no business logic")
- Move `core/theme/` one level up to `lib/theme/` if the design system grows beyond Material 3 wrappers

---

## 2. Feature Boundaries

### Current feature map

| Feature | Screens | Controllers | Services | Models |
|---------|---------|-------------|----------|--------|
| Auth | 1 | 1 | (inline in controller) | — |
| Business/Shell | 1 | — | — | — |
| Cargo | 2 | — | — | — |
| Ticket Sales | 4 | — | — | — |
| Trip | 2 | — | — | — |
| Routes | 2 | — | — | — |
| Refund | 3 | — | 1 | — |

### Strengths

- **One feature = one directory** — every feature has a `screens/` folder with clear ownership
- **No cyclic dependencies** — features only import `core/` and `shared/`, never each other (business_home is the exception — it aggregates all screens, which is correct for a shell)
- **Refund has a service layer** — the only feature with a proper `Service` class (`refund_service.dart`), making it the most testable feature

### Weaknesses

1. **Only Refund has a service layer** — Ticket Sales, Cargo, Trip, and Routes make direct `widget.session.api.get/post(...)` calls from screen files. This couples presentation to HTTP transport.

2. **Cross-feature screen imports from business_home** — `business_home.dart` imports from 7 different feature screen files. This is acceptable for an app shell, but means changing any screen's constructor signature or import path cascades into the shell file.

3. **No feature-level state controllers** — Only Auth has `SessionController`. Every other feature manages all state inline in `StatefulWidget` with `_loading`, `_error`, `_data` booleans and lists.

4. **Private widget classes leak into screen files** — `_QuickAction`, `_PlaceholderPage`, `_BusinessContextBody` (business_home), `_StatusFilterBar`, `_RefundListItem` (refund_list_page), `_ResultOverlay`, `_FieldConfig`, `_InfoRow`, `_TimelineItem` (refund_detail_page) — these are private but some could be extracted as shared widgets. They aren't reusable across features because they're `_`-prefixed and defined inside screen files.

### Recommended improvements

- Extract service classes for **Ticket Sales** (`BookingService`, `TicketService`), **Cargo** (`CargoService`), **Trip** (`TripService`), **Routes** (`RouteService`) — these already exist as inline API calls
- Move `_BusinessContextBody` out of `business_home.dart` — it's used by one screen but logically separate (org context guard)
- Extract `_RefundListItem` and `_StatusFilterBar` into shared widgets or keep them feature-private in a `refund/screens/widgets/` directory
- Consider whether `business_home.dart` could be split into shell logic + dashboard page

---

## 3. Dependency Direction

### Current dependency graph (simplified)

```
main.dart
  └── app/app.dart
        ├── shared/services/api_client.dart
        ├── features/auth/controllers/session_controller.dart
        │     ├── shared/services/api_client.dart
        │     └── shared/models/organization_context.dart
        ├── features/auth/screens/sign_in_screen.dart
        │     ├── shared/services/api_client.dart
        │     ├── core/widgets/app_button.dart
        │     └── features/auth/controllers/session_controller.dart
        └── features/business/screens/business_home.dart
              ├── features/*/screens/*.dart              ← 7 feature screens
              └── features/auth/controllers/session_controller.dart

core/widgets/*.dart
  └── core/theme/app_theme.dart                          ← Pure UI, no dependencies

shared/services/api_client.dart                           ← dart:convert + http only
shared/services/refund_service.dart
  ├── shared/services/api_client.dart
  └── features/auth/controllers/session_controller.dart

infrastructure/database/app_database.dart                 ← sqflite_sqlcipher only
infrastructure/offline/*.dart
  ├── shared/services/api_client.dart
  └── infrastructure/database/app_database.dart
```

### Strengths

- **No circular dependencies** — The dependency graph is a DAG (directed acyclic graph)
- **core/widgets/ is leaf-level** — widgets only depend on `core/theme/`, which is correct
- **infrastructure/ depends on shared/, never on features/** — correct architectural layering
- **features/ depend on shared/, never on infrastructure/** — correct (except TicketSales screens import api_client directly)

### Weaknesses

1. **Presentation depends on HTTP directly** — Every screen imports `api_client.dart` and calls `api.get(...)`, `api.post(...)`. This violates the Dependency Inversion Principle. Screens should depend on repository abstractions, not concrete HTTP clients.

2. **`shared/services/refund_service.dart` imports from features/auth/controllers** — A shared service should not depend on a feature controller. `RefundService` needs `SessionController` only for `_orgId`. The org ID should be injected directly, making it a pure service.

3. **No repository layer** — `api_client.dart` is the sole data-access class. There are no feature-level repositories that could add caching, offline fallback, or mock injection for testing.

4. **Concrete classes everywhere** — No interfaces, no abstract classes, no dependency injection. Everything is `final Foo = Foo()`.

### Recommended improvements

| Current | Should be |
|---------|-----------|
| `widget.session.api.get(...)` | `bookingRepository.list(orgId)` |
| `SessionController` injected everywhere | Auth token service + org context provider (separate concerns) |
| `RefundService(session)` | `RefundService(api, orgId)` |
| `final _session = SessionController(api:, storage:)` | `GetIt.I<ApiClient>()` or `Provider<ApiClient>` |
| No repository classes | `CargoRepository`, `TripRepository`, `BookingRepository` |

**Priority:** High. This is the single biggest architectural risk.

---

## 4. Reusable Widgets

### Widget inventory

| Widget | Location | Usage count | Status |
|--------|----------|-------------|--------|
| `LoadingView` | `core/widgets/async_views.dart` | 7 screens | ✅ Good |
| `ErrorView` | `core/widgets/async_views.dart` | 5 screens | ✅ Good |
| `EmptyView` | `core/widgets/async_views.dart` | 2 screens | ✅ Good |
| `ErrorCard` | `core/widgets/async_views.dart` | 6 screens | ✅ Good |
| `EmptyListTileCard` | `core/widgets/async_views.dart` | 3 screens | ✅ Good |
| `BusyButton` | `core/widgets/app_button.dart` | 5 screens | ✅ Good |
| `ActionButtonRow` | `core/widgets/app_button.dart` | 2 screens | ✅ Good |
| `AppListTileCard` | `core/widgets/app_card.dart` | 6 screens | ✅ Good |
| `InfoCard` | `core/widgets/app_card.dart` | 1 screen | ⚠️ Underused |
| `StatusChip` | `core/widgets/status_chip.dart` | 4 screens | ✅ Good |
| `StatusAvatar` | `core/widgets/status_chip.dart` | 1 screen | ⚠️ Underused |
| `AppDialog.*` | `core/widgets/app_dialog.dart` | 2 screens | ⚠️ Underused |
| `AsyncState` | `core/widgets/async_state.dart` | 6 screens | ✅ Good |
| `PaginationBar` | `core/widgets/pagination.dart` | 0 screens | ❌ Unused |
| `SearchField` | `core/widgets/search_field.dart` | 0 screens | ❌ Unused |
| `FormTextField` | `core/widgets/app_form.dart` | 0 screens | ❌ Unused |
| `FormDropdown` | `core/widgets/app_form.dart` | 0 screens | ❌ Unused |
| `SectionHeader` | `core/widgets/app_form.dart` | 0 screens | ❌ Unused |
| `ResponsiveDataTable` | `core/widgets/data_table.dart` | 0 screens | ❌ Unused |
| `SkeletonLoader` | `core/widgets/loading.dart` | 0 screens | ❌ Unused |
| `Toast` | `core/widgets/error_states.dart` | 0 screens | ❌ Unused |
| `PermissionGuard` | `core/widgets/permission_guard.dart` | 0 screens | ❌ Unused |
| `MetricCard` | `core/widgets/app_card.dart` | 0 screens | ❌ Unused |
| `TimelineEventCard` | `core/widgets/app_card.dart` | 0 screens | ❌ Unused |

### Strengths

- **14 reusable widgets** exist in `core/widgets/` with a barrel export
- **Async base class** (`AsyncState`) eliminates the `_loading`/`_error`/try/catch/finally pattern in 6 screens — big win
- **Design tokens** in `AppTheme` standardise spacing, radius, typography across the app
- **`AppTheme.buildTheme()`** produces a full Material 3 theme with component defaults

### Weaknesses

1. **12 of 22 shared widgets are unused** — They were recently added (in the design system build) but no screen imports them yet. These are technically dead code until screens migrate to use them.

2. **`PaginationBar` has zero consumers** — No screen implements pagination yet, despite DRF backend pagination being available.

3. **`SearchField` has zero consumers** — No client-side or server-side search is implemented in any screen.

4. **`AppDialog.showForm` is underused** — Only `cargo_worklist_page` uses `AppDialog.showPicker`, and `counter_booking_page` + `cargo_acceptance_page` still use inline `showDialog(AlertDialog(...))`.

5. **`InfoCard` is underused** — Only `trip_detail_page` uses it. Payment, refund detail, and route detail pages build their own info layouts manually.

### Recommended improvements

| Unused widget | Should be used in |
|---------------|-------------------|
| `FormTextField` | All screen `TextField(...)` calls — dozens of instances |
| `FormDropdown<T>` | All `DropdownButtonFormField<Map<String, dynamic>>(...)` — 8+ instances |
| `SectionHeader` | All `Text('...', style: textTheme.titleMedium)` — 5+ instances |
| `Toast` | All `ScaffoldMessenger.of(context).showSnackBar(...)` — 4+ instances |
| `PermissionGuard` | All `if (hasPermission(...)) widget else null` — 8+ instances |
| `PaginationBar` | Trip list, route list (backend already returns paginated `{results, next}`) |
| `SkeletonLoader` | List loading states (trip list, route list, cargo worklist) |
| `AppDialog.showForm` / `.showTextField` / `.showMultiField` | Entity creation dialogs (passenger, contact, handover) — 3 instances |

**Migration effort estimate:** Medium (1-2 days). Each replacement is mechanical (cut old pattern, paste new widget). No business logic changes required.

---

## 5. State Management Readiness

### Current approach

```
SessionController extends ChangeNotifier
  ↓
  AnimatedBuilder in app.dart
  ↓
  Screen state via StatefulWidget
```

### Strengths

- `SessionController` handles auth lifecycle (login, restore, refresh, logout) adequately for MVP
- `AnimatedBuilder` keeps the app tree reactive to auth changes without a third-party package
- `AsyncState` provides a reusable loading/error/data base class used across 6 screens

### Weaknesses

1. **One controller to rule them all** — `SessionController` manages:

   - Auth status (`authenticated`, `user`, `restore()`, `signIn()`, `signOut()`)
   - Organization list and switching (`organizations`, `activeOrganization`, `loadOrganizationContext()`)
   - Permission checking (`hasPermission()`)
   - Token persistence (via `FlutterSecureStorage`)

   This violates the **Single Responsibility Principle**. Three distinct domains in one class.

2. **No feature-level state management** — 6 out of 7 features manage state inline in widget `State` objects. This means:

   - State disappears on widget rebuild
   - State cannot be tested in isolation
   - State cannot be shared between screens
   - The `_loading` / `_error` / try / catch / finally pattern is repeated ~15 times across the codebase

3. **`AnimatedBuilder` is not a state management solution** — It rebuilds the entire `MaterialApp` widget tree every time auth state changes. For MVP this is fine, but as the app grows, switching organization triggers a full theme rebuild and re-mounts all screens.

4. **No offline-aware state** — `SessionController`'s `loading`/`contextLoading` booleans don't distinguish between "first time loading" and "offline with cached data." The app has an offline database but no state management layer uses it.

### State Management Options

| Approach | Alignment | Effort | Notes |
|----------|-----------|--------|-------|
| **Keep ChangeNotifier + split into services** | Good | Low | Split `SessionController` into `AuthService`, `OrgService`, `PermissionService`. Each remains a `ChangeNotifier`. No new package. |
| **Riverpod** | Excellent | Medium | Aligns with Clean Architecture. `AsyncNotifier<T>` eliminates the `_loading`/`_error`/try/catch pattern. Auto-disposal. `Provider.family` for parameterised queries. |
| **BLoC** | Good | Medium-High | Event-driven, more boilerplate. Good for complex form flows (counter booking pipeline). |
| **Keep as-is** | Fragile | None | Will break when adding offline state, cross-screen data, or complex form interactions. |

**Recommendation:** Split `SessionController` now (no new package, low effort). Evaluate Riverpod for feature-level state when the next feature is added.

---

## 6. Offline Readiness

### Current infrastructure

| Component | Status | Location |
|-----------|--------|----------|
| Encrypted local database (`sqflite_sqlcipher`) | ✅ Built | `infrastructure/database/app_database.dart` |
| Device registration | ✅ Built | `infrastructure/offline/device_registry.dart` |
| Sync upload queue | ✅ Built | `infrastructure/offline/sync_upload_queue.dart` |
| Full sync manager (push + pull) | ✅ Built | `infrastructure/offline/sync_manager.dart` |
| Idempotency UUIDs | ✅ Built | `sync_upload_queue.dart` uses `uuid.v4()` |
| Offline-first state management | ❌ Missing | — |
| Local-first repository layer | ❌ Missing | — |
| Conflict resolution UI | ❌ Missing | — |
| Offline auth cache | ✅ Partial | Token in `flutter_secure_storage`. No user profile cache. |
| Sync status indicator in UI | ❌ Missing | Tab exists but shows placeholder |
| Manual retry UI | ❌ Missing | — |

### Strengths

- The **entire offline infrastructure is built** — database, device registry, upload queue with batching, sync manager with push/pull
- **Idempotency is solved** — every operation has a `client_operation_id` (UUID v4)
- **Schema migration** is implemented (`_onUpgrade` with versioning)
- **WAL journal mode** and **foreign keys** enabled in SQLite

### Weaknesses

1. **Offline code is completely disconnected from the UI** — Screens call `widget.session.api.get(...)` which hits HTTP directly. The `AppDatabase`, `SyncManager`, and `SyncUploadQueue` are never invoked by any screen. They exist in the codebase but are dead code until a repository layer is added.

2. **No local-first read path** — `AppDatabase.query()` exists but nothing calls it. Every screen goes to the server on every render.

3. **No conflict resolution UI** — `SyncUploadQueue` tracks `conflict` status but no screen handles it.

4. **`device_registry.dart` is never imported** — device registration never runs, so `SyncManager` will always get `-1` from `uploadQueue.pushAll()` (prerequisite: `_device.registered` must be true).

5. **`sqflite_sqlcipher` + `path` + `uuid` are declared dependencies but practically unused** — They're imported in the offline files, but since those files are dead code, the dependencies add ~3MB to the APK for no benefit.

### Recommended improvements

| Priority | Action |
|----------|--------|
| **High** | Create feature repository classes that wrap `ApiClient` and fall back to `AppDatabase` |
| **High** | Initialize `DeviceRegistry.initialize()` in `main()` before `HbtBusinessApp.start()` |
| **Medium** | Build the sync tab UI (progress indicator, pending count, manual retry, conflict list) |
| **Medium** | Add `SyncManager.syncAll()` trigger on app resume and periodic timer |
| **Low** | Add conflict resolution screens for rejected/conflict operations |

**Risk:** Offline mode is the project's stated architectural goal (see `README.md`), but the current app is fully online-only. Building the offline layer on top of the current direct-HTTP screens requires a repository layer that touches every screen.

---

## 7. Routing Scalability

### Current approach

```dart
// business_home.dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => TripListPage(session: widget.session),
  ),
);
```

Every screen navigates to another screen via `Navigator.push(MaterialPageRoute(...))`. No named routes, no GoRouter, no Navigator 2.0.

### Strengths

- Simple and direct — no indirection, no route configuration files to maintain
- Type-safe — constructors are called directly, no string parsing
- Works for an MVP with ~16 screens
- `routing/routes.dart` exists with route path constants (not yet used)

### Weaknesses

1. **`Navigator.push` everywhere** — 40+ `Navigator.push(MaterialPageRoute(...))` calls across 9 screen files. Adding deep linking, path-based routing, or `Router` widget support requires touching every call site.

2. **No deep linking support** — Can't generate shareable links (`/trips/trip-123`), no web URL support.

3. **No transition animations control** — Every push uses default slide-from-right. Cannot easily switch to custom transitions (e.g., bottom sheet for modals, fade for dialogs).

4. **Session object passed manually** — Every screen takes `required this.session` in its constructor. This is:
   - Boilerplate: 16 screens, each with `session` parameter
   - Brittle: changing `session` type requires updating all constructors
   - Opaque: no way to derive `session` from context without passing it down

5. **`routing/routes.dart` is unused** — The file exists but no screen imports it.

### Recommended improvements

| Phase | Change | Effort | Benefit |
|-------|--------|--------|---------|
| **Now** | Use `Routes.counterBooking` etc. in navigation calls | 30 min | Removes magic strings |
| **Soon** | Switch to `go_router` or `route_map` for named routes | 1 day | Deep linking, URL bar, transition control |
| **Future** | Pass `session` via `Provider` / `InheritedWidget` instead of constructors | 1 day | Eliminates constructor boilerplate in 16 files |

---

## 8. Testability

### Test inventory

| Test file | Type | Status after restructure |
|-----------|------|-------------------------|
| `test/widget_test.dart` | Smoke | Compiles (no imports) |
| `test/helpers/test_helpers.dart` | Shared helpers | **Broken** — imports old paths |
| `test/features/auth/sign_in_widget_test.dart` | Widget | **Broken** — imports old paths |
| `test/features/booking/counter_booking_widget_test.dart` | Widget | **Broken** — imports old paths |
| `test/features/booking/booking_integration_test.dart` | Integration | **Broken** — imports old paths |
| `test/features/payment/payment_integration_test.dart` | Integration | **Broken** — imports old paths |
| `test/features/refund/refund_full_flow_test.dart` | Integration | **Broken** — imports old paths |
| `test/features/refund/refund_list_widget_test.dart` | Widget | **Broken** — imports old paths |
| `test/features/refund/refund_service_test.dart` | Unit | **Broken** — imports old paths |
| `test/features/trip/trip_list_widget_test.dart` | Widget | **Broken** — imports old paths |

### Strengths

- **Tests exist** — 9 test files including widget, unit, and integration tests
- **Test helpers exist** — `MockStorage`, `MockApiClient`, `createMockSession()` provide a solid foundation
- **RefundService has its own unit test** — the only feature service with proper test coverage
- **Integration tests exist** — booking and payment flows have end-to-end tests

### Weaknesses

1. **All 9 test files are broken** — The folder restructure moved source files but didn't update test imports. Tests reference:

   - `package:hbt_business_app/core/network/api_client.dart` → moved to `shared/services/`
   - `package:hbt_business_app/features/auth/application/session_controller.dart` → moved to `features/auth/controllers/`
   - `package:hbt_business_app/features/auth/presentation/sign_in_screen.dart` → moved to `features/auth/screens/`
   - `package:hbt_business_app/features/ticket_sales/presentation/counter_booking_page.dart` → moved to `ticket_sales/screens/`
   - `package:hbt_business_app/features/refund/presentation/refund_list_page.dart` → moved to `refund/screens/`
   - `package:hbt_business_app/features/refund/application/refund_service.dart` → moved to `shared/services/`
   - `package:hbt_business_app/features/trip/presentation/trip_list_page.dart` → moved to `trip/screens/`
   - `package:hbt_business_app/features/organization/domain/organization_context.dart` → moved to `shared/models/`

2. **No test coverage for core widgets** — `core/widgets/` has 22 widgets but zero test files.

3. **No test coverage for offline infra** — `infrastructure/offline/` sync queue, sync manager, and device registry have no tests.

4. **No test coverage for API client** — `shared/services/api_client.dart` (300 lines) has no dedicated unit tests. Error parsing, status code handling, and multipart uploads are untested.

5. **MockApiClient throws on every call** — The `MockApiClient` in `test_helpers.dart` throws `ApiException('Unmocked GET ...')` for every method. Tests must override each method individually, leading to per-file subclasses (`_HangingApi`, `_FailingApi`, `_LoadedBookingApi`, etc.).

### Recommended improvements

| Priority | Action |
|----------|--------|
| **Urgent** | Fix test imports to match the new folder structure |
| **High** | Replace `MockApiClient` with a proper `FakeApiClient` (returns default data instead of throwing) |
| **Medium** | Add widget tests for `core/widgets/` — `BusyButton`, `ErrorCard`, `StatusChip`, `AppListTileCard`, `AppDialog` |
| **Medium** | Add unit tests for `sync_upload_queue.dart` (enqueue, push, retry, cleanup) |
| **Low** | Add unit test for `api_client.dart` error handling edge cases |

---

## 9. Dependency Audit (pubspec.yaml)

| Package | Declared | Used in code | Status |
|---------|----------|-------------|--------|
| `flutter` | ✅ | ✅ | Required |
| `cupertino_icons` | ✅ | ❌ (never imported) | Remove |
| `flutter_secure_storage` | ✅ | ✅ (session, database, device) | Keep |
| `http` | ✅ | ✅ (api_client) | Keep |
| `file_picker` | ✅ | ✅ (payment_decision_page) | Keep |
| `mobile_scanner` | ✅ | ✅ (ticket_scanner_screen) | Keep |
| `path` | ✅ | ✅ (app_database) | Keep |
| `sqflite_sqlcipher` | ✅ | ✅ (app_database) | Keep |
| `uuid` | ✅ | ✅ (device_registry, sync_upload_queue) | Keep |

All declared dependencies are used in source files. No dead dependencies.

---

## 10. Summary

### Scores by dimension

| Dimension | Score | Key strength | Key weakness |
|-----------|-------|-------------|--------------|
| **Separation of concerns** | 7/10 | 4 clear layers | `features/business/` misnamed |
| **Feature boundaries** | 6/10 | Clear directory per feature | Only 1 feature has a service layer |
| **Dependency direction** | 4/10 | No circular deps | Every screen depends on HTTP directly |
| **Reusable widgets** | 6/10 | 14 shared widgets exist | 12 are unused (newly added) |
| **State management** | 3/10 | AsyncState base class works | 1 controller does auth + org + permissions |
| **Offline readiness** | 4/10 | Full infra built (DB, sync, queue) | Completely disconnected from UI |
| **Routing scalability** | 5/10 | routes.dart exists | 0 screens use it; no named routes |
| **Testability** | 3/10 | Test helpers + 9 test files | All 9 broken; poor mock pattern |

**Overall:** 4.75 / 10

### Risks

1. **🔴 CRITICAL: Offline infrastructure is dead code** — The architectural mandate is "offline first" but the app is fully online. `DeviceRegistry` is never initialized. `SyncManager` is never called. If production users go offline, all screens crash or show network errors.

2. **🔴 HIGH: Tests are broken** — The folder restructure invalidated all 9 test files. CI/CD will not catch regressions until import paths are updated.

3. **🟡 MEDIUM: SessionController is a god class** — Auth + org + permissions + token in one file. As permissions grow (HBT has ~60 permissions), this file becomes unmaintainable.

4. **🟡 MEDIUM: No dependency injection** — `SessionController` is created in `app.dart` and passed manually through the widget tree. Adding a `SyncManager` or `AppDatabase` requires modifying constructors across 16+ files.

5. **🟢 LOW: Routing is ad-hoc** — Fine for 16 screens, but adding deep linking, redirect guards, or web support requires a full rewrite of every navigation call.

### Recommended improvement roadmap

| Timeline | Changes |
|----------|---------|
| **Immediate** | Fix test import paths to match new folder structure |
| **Immediate** | Update `test_helpers.dart` to point to new file locations |
| **Sprint 1** | Split `SessionController` into `AuthService`, `OrgService`, `PermissionService` |
| **Sprint 1** | Initialize `DeviceRegistry.initialize()` in `main()` |
| **Sprint 2** | Create repository layer: `TripRepository`, `BookingRepository`, `CargoRepository` wrapping `ApiClient` |
| **Sprint 2** | Migrate `refund_service.dart` to inject `orgId` directly instead of `SessionController` |
| **Sprint 2** | Migrate screen `TextField`/`DropdownButtonFormField` calls to `FormTextField`/`FormDropdown` |
| **Sprint 3** | Migrate navigation to `go_router` with `routing/routes.dart` constants |
| **Sprint 3** | Add sync tab UI (progress, pending count, retry) |
| **Sprint 4** | Add offline read path (repository falls back to `AppDatabase`) |
| **Sprint 4** | Add widget tests for core widgets |
| **Future** | Evaluate Riverpod for feature-level state management |

---

*End of audit. No files were modified during review.*
