# Offline Activation Plan

**App:** HBT Business (Flutter)
**Date:** 2026-07-30
**Status:** 🔴 Offline infrastructure built but completely disconnected

---

## 1. What Exists

### 1.1 Infrastructure components

| Component | Location | Lines | Function |
|-----------|----------|-------|----------|
| `AppDatabase` | `infrastructure/database/app_database.dart` | ~380 | Encrypted SQLCipher DB with 6 tables + sync_operations queue. Singleton: `AppDatabase.instance`. Schema v3 with migrations. |
| `DeviceRegistry` | `infrastructure/offline/device_registry.dart` | ~110 | Installation ID (UUID v4), backend registration, sync cursor tracking. `ChangeNotifier`. |
| `SyncUploadQueue` | `infrastructure/offline/sync_upload_queue.dart` | ~410 | Batched operation queue with status tracking (pending→uploading→completed/rejected/conflict/failed). Inline retry. Idempotency via UUIDs. Batch size: 50. |
| `SyncManager` | `infrastructure/offline/sync_manager.dart` | ~260 | Push (via `SyncUploadQueue.pushAll`) + Pull (cursor-based incremental sync). Manifests changes into local DB via `_applyChange` → `_database.upsert`. |

### 1.2 Database schema

```
trips              — 15 columns (id, trip_number, route_id, status, planned_departure_at, …)
routes             — 10 columns (id, code, name, display_name, region, status, …)
bookings           — 9 columns (id, authorization_reference, trip_id, status, amount, …)
tickets            — 10 columns (id, ticket_number, booking_id, passenger_name, seat, status, …)
passengers         — 7 columns (id, full_name, phone_number, …)
fares              — 7 columns (id, route_id, amount, …)
sync_operations    — 8 columns (client_operation_id UUID, operation_type, payload JSON, status, …)
```

### 1.3 Supported offline operation types

| Operation | Matches backend handler | Purpose |
|-----------|------------------------|---------|
| `trip.transition` | ✅ `trip_transition` | Advance trip status (ready, board, depart, arrive) |
| `ticket.validate` | ✅ `ticket_validate` | Validate ticket QR at boarding |
| `cargo.transition` | ✅ `cargo_transition` | Advance cargo status (assigned→loaded→in_transit→…) |
| `cargo.accept` | ✅ `cargo_accept` | Accept new cargo shipment |
| `payment.record_cash` | ✅ `payment_record_cash` | Record cash payment offline |
| `booking.walk_up` | ✅ `booking_walk_up` | Create walk-up booking for passenger |

---

## 2. The Gap — What Is Connected vs What Is Used

### Connected (imported within `infrastructure/` only)

```
device_registry.dart  ←── sync_manager.dart  ←── sync_upload_queue.dart
                           ↕                        ↕
                        app_database.dart        app_database.dart
                                                     ↕
                                                api_client.dart (postJson)
```

### Unused (never imported from outside `infrastructure/`)

| Component | Imported by any screen? | Instantiated anywhere? | Referenced in tests? |
|-----------|------------------------|------------------------|---------------------|
| `AppDatabase` | ❌ | ❌ | ❌ |
| `DeviceRegistry` | ❌ | ❌ | ❌ |
| `SyncUploadQueue` | ❌ | ❌ | ❌ |
| `SyncManager` | ❌ | ❌ | ❌ |

**Zero files in `lib/` reference any offline component.** Zero tests cover offline code. The entire infrastructure is dead code.

### What the app actually does

| Operation | Current path | Offline path |
|-----------|-------------|--------------|
| Load trips | `api.get('/orgs/{id}/trips/')` | ❌ Not called |
| Load routes | `api.get('/orgs/{id}/routes/')` | ❌ Not called |
| Load bookings | `api.getList('/orgs/{id}/bookings/')` | ❌ Not called |
| Load cargo | `api.getList('/orgs/{id}/cargo/shipments/')` | ❌ Not called |
| Create booking | `api.post('/orgs/{id}/bookings/', ...)` | ❌ Not queued |
| Accept cargo | `api.post('/orgs/{id}/cargo/shipments/', ...)` | ❌ Not queued |
| Record payment | `api.post('/orgs/{id}/payments/', ...)` | ❌ Not queued |
| Transition trip | `api.post('/orgs/{id}/trips/{id}/boarding/start/', ...)` | ❌ Not queued |
| Sync tab | Placeholder: "Sync and Pending Work" | ❌ No UI |
| Device registration | Never called | ❌ Not initialized |

---

## 3. Minimal Changes Required to Activate Offline Mode

### Phase 1 — Bootstrap (est. 1-2 hours)

**Goal:** Infrastructure is initialized and devices register on first launch.

| # | Change | File(s) | Risk |
|---|--------|---------|------|
| 1 | Initialize `AppDatabase.instance.initialize()` in `main()` before `runApp` | `lib/main.dart` | Low — non-blocking DB init, tables created if absent |
| 2 | Create `DeviceRegistry` alongside `SessionController` in `app.dart` | `lib/app/app.dart` | Low — takes `ApiClient` which already exists |
| 3 | Call `deviceRegistry.initialize()` in `initState` of `_HbtBusinessAppState` | Same file | Low — reads from `flutter_secure_storage` |
| 4 | Call `deviceRegistry.register()` after successful sign-in | `session_controller.dart` or `sign_in_screen.dart` | Low — POST to `/me/devices/` |
| 5 | Create `SyncManager` instance wired to `AppDatabase`, `DeviceRegistry`, `ApiClient` | `lib/app/app.dart` | Low — all dependencies already exist in scope |
| 6 | Call `deviceRegistry.clear()` on sign-out | `session_controller.dart` | Low — matches existing cleanup pattern |

**Backend dependency:** Device registration endpoint `POST /me/devices/` must exist and accept `installation_id`, `platform`, `app_id`, `app_version`. Verify against backend OpenAPI spec.

### Phase 2 — Repository Layer (est. 2-3 days)

**Goal:** Screens read from local DB first, fall back to network. Writes go to local DB + sync queue.

The key change: screens must stop calling `widget.session.api.get/post(...)` directly and instead go through repositories that know about offline.

| # | Change | File(s) | Risk |
|---|--------|---------|------|
| 7 | Create `TripRepository`: `list(orgId)` → reads `AppDatabase.query('trips')` and returns cached trips immediately, then syncs from API | New: `shared/repositories/trip_repository.dart` | Medium — changes how TripListPage gets data |
| 8 | Create `BookingRepository`: `create(...)` → writes to `AppDatabase.upsert('bookings', ...)` + `SyncUploadQueue.enqueue('booking.walk_up', ...)` | New: `shared/repositories/booking_repository.dart` | Medium — replaces direct `api.post` |
| 9 | Create `CargoRepository`, `TicketRepository`, `PaymentRepository` (same pattern) | New files | Medium — 5 repos total |
| 10 | Inject repositories into `SessionController` or pass to screens as constructor args | `app.dart` + all screen files | Low — `session` already threaded through screens |
| 11 | Pull-to-refresh triggers `SyncManager.pull(orgId)` to get latest from server | All list screens (trips, routes, cargo, tickets) | Low — replaces existing refresh logic |
| 12 | Online check: if `api` request fails with network error, still serve local data instead of showing error | Repository layer | Medium — changes error UX from "show error" to "show stale + banner" |

**Design decision:** Repository methods should return a `Result<T>` type:
```dart
sealed class Result<T> {
  data class Success<T>(T data, {bool fromCache}) implements Result<T>;
  data class Failure<T>(String message) implements Result<T>;
}
```

This replaces the current pattern where screens have `_loading`/`_error` booleans and catch `ApiException`.

### Phase 3 — Sync UI (est. 1 day)

**Goal:** Users can see sync status, pending operations, and retry failed ones.

| # | Change | File(s) | Risk |
|---|--------|---------|------|
| 13 | Replace sync tab placeholder with real UI: pending count, progress bar, operation list | `features/shell/screens/sync_page.dart` (new) | Low — new screen, no existing code changed |
| 14 | Show `UploadStatus.conflict` operations with resolve/reject buttons | Same file | Low — data model already exists |
| 15 | Auto-sync trigger: `SyncManager.syncAll()` on app resume + periodic timer (every 5 min) | `app.dart` + new timer service | Low — `WidgetsBindingObserver` already used |
| 16 | Show sync status banner when offline: "X pending operations" | `business_home.dart` AppBar or body | Low — text + icon only |
| 17 | `UploadQueue.clean(maxAge: 7 days)` on app startup | `app.dart` | Low — housekeeping |

### Phase 4 — Offline Writes (est. 2-3 days)

**Goal:** Forms work offline — data is saved locally and queued for later sync.

| # | Change | File(s) | Risk |
|---|--------|---------|------|
| 18 | Counter booking: save to local DB + enqueue `booking.walk_up` instead of calling `api.post` directly | `counter_booking_page.dart` | High — core business flow |
| 19 | Cargo acceptance: save to local DB + enqueue `cargo.accept` | `cargo_acceptance_page.dart` | High |
| 20 | Trip transitions: enqueue `trip.transition` | `trip_detail_page.dart` | Medium |
| 21 | Payment recording: enqueue `payment.record_cash` | `payment_decision_page.dart` | Medium |
| 22 | Validation exception: pending operations display "synced" / "pending" status on list items | All feature list screens | Medium — needs async state per item |

---

## 4. Summary

| Layer | Current state | Target state | Effort |
|-------|--------------|--------------|--------|
| **Infrastructure** | ✅ Built | ✅ Built — no changes needed | 0 days |
| **Bootstrap** | ❌ Never initialized | Initialize in `main()` + `app.dart` | 1-2 hours |
| **Device registration** | ❌ Never called | Call after sign-in | 30 min |
| **Read path** | Direct HTTP only | Local DB first, API fallback | 2-3 days |
| **Write path** | Direct POST only | Local DB + sync queue | 2-3 days |
| **Sync UI** | Placeholder only | Status banner + sync page | 1 day |
| **Offline forms** | No offline support | 5 features queued | 2-3 days |
| **Conflict resolution** | Model exists | No UI | 1 day |

**Total to full offline activation:** ~10-12 days of engineering work. Backend endpoints assumed to exist per OpenAPI spec.

### Risk matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Backend device registration not implemented | Medium | Blocks offline entirely | Check `POST /me/devices/` in OpenAPI spec first |
| Repository layer breaks screen assumptions | Medium | Widget tests fail | Refactor one screen (TripListPage) as pilot, test, then roll out |
| Offline writes create duplicate records on sync | Low (UUID idempotency) | Data corruption | `client_operation_id` dedup on backend; test with forced duplicates |
| Large sync queues block the UI | Low (async, batches of 50) | UX freeze | Run sync in isolate; show progress bar only |
| Schema mismatch between local DB and API | Medium | Sync failures | Add DB schema version to device registration; force re-sync on version bump |
| `sqflite_sqlcipher` not working on target Android/iOS | Low | App crashes | Add try/catch with fallback to unencrypted DB for dev |

### Quick start checklist

```
[ ] Verify backend has POST /me/devices/ endpoint
[ ] Verify backend has POST /orgs/{id}/devices/{id}/sync/push/ endpoint
[ ] Verify backend has GET /orgs/{id}/devices/{id}/sync/pull/ endpoint
[ ] Add AppDatabase.instance.initialize() to main()
[ ] Add DeviceRegistry(api:) to app.dart
[ ] Call deviceRegistry.initialize() in initState
[ ] Call deviceRegistry.register() after sign-in success
[ ] Create TripRepository as proof-of-concept
[ ] Inject TripRepository into TripListPage
[ ] Rewrite TripListPage to use repository (fallback to local DB)
[ ] Build sync page UI
[ ] Roll out to remaining 4 features
```
