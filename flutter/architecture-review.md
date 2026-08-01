# Flutter Project — Architecture Review

**Reviewed:** `F:\hbt\flutter\hbt_business_app`
**Platform:** Flutter 3.x / Dart SDK ^3.10.4
**Scope:** All 18 Dart source files

---

## 1. Architecture Layer Audit

The project attempts a Clean Architecture-inspired layout but the layers are incomplete and partially misaligned.

### Current Structure

```
lib/
  main.dart
  app/
    hbt_business_app.dart         ← App entry, wire-up
  core/
    config/
      app_config.dart             ← Environment config
    network/
      api_client.dart             ← HTTP client
  features/
    auth/
      application/
        session_controller.dart   ← Auth + org state
      presentation/
        sign_in_screen.dart       ← Login UI
    business/
      presentation/
        business_home.dart        ← Main shell with nav
    cargo/
      presentation/
        cargo_acceptance_page.dart
        cargo_worklist_page.dart
    organization/
      domain/
        organization_context.dart ← Domain models
    ticket_sales/
      presentation/
        counter_booking_page.dart
        payment_decision_page.dart
        ticket_sales_page.dart
```

### What Exists vs. What's Missing

| Layer | Status | Files | Notes |
|-------|--------|-------|-------|
| **App Entry** | ✅ | `main.dart`, `hbt_business_app.dart` | Clean. Minimal. |
| **Core** | ✅ Partial | `api_client.dart`, `app_config.dart` | `api_client.dart` is monolithic (600+ lines). `app_config.dart` is only 3 lines. |
| **Data / Repository** | ❌ Missing | — | No repository layer. No DAO. No data models. API calls are made directly from presentation widgets. |
| **Domain / Models** | ⚠️ Minimal | `organization_context.dart` (only 2 model classes) | Only one domain file exists. No entity layer for booking, ticket, cargo, payment, passenger, trip. |
| **Application / State** | ⚠️ Partial | `session_controller.dart` | Only auth + org context state is managed. Feature-level state is all inline in widgets. |
| **Presentation** | ✅ | 7 screen files | Functional. Myanmar UI. Permission-checked. |

---

## 2. Folder Structure & Feature-First Organization

**Intention is correct.** The project uses `features/<feature_name>/` with sub-layers (`application/`, `presentation/`, `domain/`). This is the right approach for a feature-first architecture.

**Inconsistencies:**

| Issue | Affected |
|-------|----------|
| `business/` is not really a feature — it's a shell/navigation | `business_home.dart` contains `BusinessHome`, `_BusinessContextBody`, `_DashboardPage`, `_QuickAction`, `_PlaceholderPage` — 5 classes in one file |
| `organization/` has only `domain/` — missing `application/` and `presentation/` | No organization picker screen, no org management flow. The org switch is a `PopupMenuButton` inside `BusinessHome` |
| No `data/` or `repository/` sub-layer in any feature | Data access is direct HTTP from widgets. No caching. No offline storage abstraction. |
| No `shared/` or `common/` directory | Reusable patterns (dropdown, contact picker, error card) are duplicated across widgets. E.g., `_contactPicker` widget is defined inline in `cargo_acceptance_page.dart`. |

---

## 3. State Management

**Used:** Raw `ChangeNotifier` + `AnimatedBuilder`

**Assessment:** Functional for this stage but will not scale.

### Current Pattern

```
SessionController extends ChangeNotifier   ← Single controller for ALL state:
                                               - Auth status
                                               - User profile
                                               - Organization list
                                               - Active organization context
                                               - Permissions
```

### Problems

1. **Single controller violates Single Responsibility.** `SessionController` manages auth, organization switching, permission checking, AND session persistence. These are 4 separate concerns.
2. **No feature-level state management.** Every screen maintains its own `StatefulWidget` state: `_loading`, `_error`, `_bookings`, `_tickets`, etc. There is no separation between state and presentation.
3. **State scattered across widget lifecycle.** `_PassengerTicketSalesPageState` manages both UI and data-loading logic. The same API call pattern is repeated verbatim in every screen (`_loading = true` → `try` → `catch` → `_loading = false`).
4. **No offline state.** `SessionController` has an `offline` property? Not present. The backend's entire offline-first sync architecture has no client-side counterpart yet.

### Recommendation

| Current | Should Evolve To |
|---------|-----------------|
| `SessionController extends ChangeNotifier` | Split into `AuthController`, `OrganizationController`, `PermissionService` |
| Inline `_loading`, `_error` in every widget | `AsyncValue<T>` or `AsyncNotifier<T>` (Riverpod) or `Bloc` per feature |
| `widget.session.api.get(...)` in widgets | Repository classes: `BookingRepository`, `TicketRepository`, `CargoRepository` |

---

## 4. Dependency Direction

**Current:** Mixed — partially correct, partially inverted.

### Correct Dependencies

```
SignInScreen → SessionController → ApiClient ✓
BusinessHome → SessionController ✓
TicketSalesPage → SessionController ✓
```

### Inverted / Leaky Dependencies

```
CounterBookingPage → SessionController (to access .api directly)  ✗
                     api.get('/organizations/$orgId/bookings/')     ✗
                     This couples presentation to HTTP transport.

PaymentDecisionPage → ApiClient (direct)                           ✗
                      api.postMultipart()                          ✗
                      api.getList()                                ✗

CargoAcceptancePage  → ApiClient (direct)                          ✗
CargoWorklistPage    → ApiClient (direct)                          ✗
```

Every feature screen bypasses `SessionController` and calls `api` directly. This means:
- Cannot unit test a screen without mocking `http.Client`
- Cannot add offline caching without modifying every widget
- Cannot add error retry logic without modifying every widget

**Correct direction should be:**

```
Screen → FeatureController/Notifier → Repository/Service → ApiClient
```

None of the feature screens uses a feature-level controller. They all talk directly to `api`.

---

## 5. Naming Conventions

| Rule | Assessment | Notes |
|------|-----------|-------|
| **File names: snake_case** | ✅ | `sign_in_screen.dart`, `api_client.dart` — correct |
| **Class names: PascalCase** | ✅ | `SessionController`, `BusinessHome` — correct |
| **Widget + `Screen`/`Page` suffix** | ✅ | `SignInScreen`, `TicketSalesPage` — correct |
| **Private members: underscore** | ✅ | `_loading`, `_error`, `_load()` — consistent |
| **Folder ↔ file name alignment** | ✅ | File in `presentation/` is `*_page.dart` — correct |
| **Model → `fromJson` factory** | ✅ | `OrganizationContext.fromJson()` — correct |
| **Myanmar labels** | ✅ | Fields use Myanmar text consistently |

**No naming violations found.**

---

## 6. SOLID Violations

### Single Responsibility Principle (SRP)

| Violation | File | Explanation |
|-----------|------|-------------|
| `SessionController` does too much | `session_controller.dart` | Auth, org state, session persistence, permission checking — should be 3-4 separate classes |
| `_CounterBookingPageState` manages the entire booking pipeline | `counter_booking_page.dart` | Passenger search, trip selection, seat selection, booking creation, fare quote — all in one 300+ line widget state |
| `_CargoWorklistPageState` does both loading AND transition logic AND handover UI | `cargo_worklist_page.dart` | Should be a `CargoController` with methods |
| `_PaymentDecisionPageState` does file upload, payment recording, AND ticket issuing | `payment_decision_page.dart` | 3 different domains handled in one widget |
| `api_client.dart` has both request AND multipart AND error handling | `api_client.dart` | 300 lines — could be broken into `HttpClient`, `MultipartClient`, `ApiErrorHandler` |

### Open/Closed Principle (OCP)

Several switch statements and if-chains make adding new payment methods or cargo statuses risky. E.g., in `payment_decision_page.dart`, payment methods are hardcoded as `wallet_qr`/`bank_transfer` in a single dropdown. Adding a new method requires modifying this widget.

### Liskov Substitution / Interface Segregation

No violations — the codebase is too shallow for these to manifest meaningfully.

### Dependency Inversion Principle (DIP)

**Major violation.** Every feature screen depends on a concrete class (`ApiClient`) rather than an abstraction:

```dart
// Current (concrete dependency):
widget.session.api.post('/organizations/$orgId/bookings/', data)

// Should be (abstract dependency):
final booking = bookingRepository.create(trip, passenger, seat)
```

The `ApiClient` is referenced directly in 6 out of 7 presentation files. Only `SessionController` wraps it, and even then, it's exposed publicly via `.api`.

---

## 7. Other Observations

### Code Duplication

The pattern:
```dart
_busy = true;
_error = null;
try { ... } on ApiException catch (e) { _error = e.message; }
finally { _busy = false; notifyListeners(); }
```

...appears 8+ times across the codebase. In every screen. This should be extracted into a base class, mixin, or a `Result<T>` type.

### Offline Support

Given that HBT's core architecture principle is "Offline First," the Flutter client has **zero offline capabilities**:
- `sqflite_sqlcipher` is listed as a dependency in `pubspec.yaml` but is not imported in any file
- No local database schema exists
- No sync queue
- No conflict resolution
- No offline auth cache beyond `flutter_secure_storage` for the token

### Test Coverage

Only 1 test file exists (`test/widget_test.dart`), which is the default Flutter template test. There are no unit tests for `SessionController`, no widget tests for any screen, no integration tests.

### Dependency Bloat

```
flutter_secure_storage: ^9.2.4     ← Used (for token storage)
http: ^1.3.0                       ← Used (API calls)
file_picker: ^8.1.2                ← Used (evidence upload)
mobile_scanner: ^6.0.2             ← Listed but not imported anywhere
sqflite_sqlcipher: ^3.3.0          ← Listed but not imported anywhere
uuid: ^4.5.1                       ← Listed but not imported anywhere
path: ^1.9.1                       ← Listed but not imported anywhere
```

Four dependencies are declared but unused: `mobile_scanner`, `sqflite_sqlcipher`, `uuid`, `path`. They should be removed or justified.

---

## 8. Summary

| Category | Score | Key Issues |
|----------|-------|-----------|
| **Architecture** | 4/10 | Clean Architecture layout exists but no repository/data layer. Presentation talks directly to HTTP. |
| **Folder Structure** | 7/10 | Feature-first intent is correct. Missing sub-layers (no data/, no application/ in most features). |
| **State Management** | 3/10 | Raw ChangeNotifier + inline widget state doesn't scale. No offline state. |
| **Dependency Direction** | 2/10 | Every screen depends on `ApiClient` directly. No abstractions. No inversions. |
| **Naming** | 10/10 | Consistent and correct across all files. |
| **SOLID** | 4/10 | SRP and DIP violations across the board. |
| **Offline Support** | 0/10 | Zero offline capability despite being an architectural requirement. `sqflite_sqlcipher` declared but unused. |
| **Test Coverage** | 0/10 | 1 default template test. No unit tests. No widget tests. |

### Immediate Fixes (Highest Impact)

1. **Extract a `Result<T>` type** and a base `AsyncNotifier` to eliminate the `_loading`/`_error`/`try`/`catch`/`finally` pattern repeated in every screen.
2. **Create repository classes** (`BookingRepository`, `CargoRepository`, `TicketRepository`) that wrap `ApiClient` and provide caching.
3. **Remove unused dependencies** (`mobile_scanner`, `sqflite_sqlcipher`, `uuid`, `path` — keep only if actively building the offline layer next).
4. **Move business logic out of widget state.** Every `StatefulWidget` that makes API calls should be split: a feature controller + a stateless presentation widget.

### Medium-Term

5. **Replace raw ChangeNotifier** with a purpose-built state management solution (Riverpod is most aligned with Clean Architecture here).
6. **Build the offline layer** using the declared `sqflite_sqlcipher` dependency — local database schema, sync queue, conflict resolution.
7. **Split `SessionController`** into `AuthService` (login/logout/token), `OrganizationService` (org list/switch), `PermissionService` (permission checking).
