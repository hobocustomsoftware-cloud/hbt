# Release Progress Log

**Started:** 2026-07-29

---

## T-001: QR Validation (Flutter + Cargo)

**Status:** ✅ COMPLETE

Backend `TicketValidateView` + Flutter `TicketScannerScreen` with dual ticket/cargo support.

---

## T-001b: Cargo QR Support

**Status:** ✅ COMPLETE

Scanner auto-detects cargo QR (`HBT:CARGO:V1:`) and routes to `CargoQrResolveView`.

---

## T-010: Route Management UI (Flutter)

**Status:** ✅ COMPLETE

`RouteListPage` + `RouteDetailPage` with CRUD. `put()`, `patch()`, `delete()` added to `ApiClient`.

---

## T-002 through T-005: Passenger App (Flutter)

**Status:** ✅ COMPLETE

New `hbt_passenger_app` Flutter project at `flutter/hbt_passenger_app/`.

- **T-002 Registration:** Phone + password register, auto-login, JWT secure storage, session restore
- **T-003 Trip Search:** Two-step wizard — select terminals → find routes → stops → date → search
- **T-004 Booking:** Seat availability display, traveler auto-creation, booking via passenger_seats
- **T-005 Wallet/Tickets:** Ticket list with status chips, pull-to-refresh, color-coded status
- **Shell:** Bottom nav (Search + Tickets), profile popup, sign out, auth-aware routing

**Architecture:** `core/config`, `core/network/api_client`, `core/auth/auth_controller`, feature-based presentation.

---

## T-011: Trip Management UI (Flutter)

**Status:** ✅ COMPLETE

- **Trip list:** `features/trip/presentation/trip_list_page.dart` — full list with status filter popup, colored status chips/icons, pull-to-refresh, empty/error states
- **Trip detail:** `features/trip/presentation/trip_detail_page.dart` — full info display + status-appropriate operational actions (ready → boarding → depart → en-route → arrive)
- **Navigation:** App bar bus icon + dashboard quick action "Manage Trips"

---

## T-006: Offline Sync — Data Layer (Flutter)

**Status:** ✅ COMPLETE

- **`AppDatabase`:** `core/database/app_database.dart` — Encrypted SQLite database using sqflite_sqlcipher
  - Master key generated and stored in FlutterSecureStorage
  - Tables: trips, routes, bookings, tickets, passengers, fares
  - Indexes on organization_id and status columns
  - WAL journal mode + foreign keys enabled
  - CRUD: upsert, upsertAll, query, get, delete, count, raw execute
  - Migration-ready with `onUpgrade` support

- **`DeviceRegistry`:** `core/offline/device_registry.dart`
  - Unique installation_id (UUID v4, persisted)
  - Backend device registration via `/me/devices/`
  - Sync cursor tracking (persisted)
  - Sign-out cleanup

- **`SyncManager`:** `core/offline/sync_manager.dart`
  - Pull changes from backend via `/sync/pull/` with cursor
  - Applies changes to local database (create/update/delete per resource type)
  - Maps backend resource types to local tables
  - Progress tracking per change batch

## T-007: Offline Sync — Upload Queue (Flutter)

**Status:** ✅ COMPLETE

- **`SyncUploadQueue`:** `core/offline/sync_upload_queue.dart` — Full upload queue implementation
  - `UploadOperation` model with `clientOperationId` (UUID v4) and `UploadStatus` enum
  - `enqueue()` — queue offline operations for later push
  - `pushAll()` — batch push to backend (50 op / batch, under server max 100)
  - `retry()` / `retryAll()` — retry individual or all failed operations
  - `clean()` — remove completed/conflict/rejected operations
  - `conflicts` getter — surface conflict operations for UI
  - `clearCompletedOperations()` / `failStaleOperations()` — DB-level housekeeping

- **`SyncManager` rewrite:** `syncAll(orgId)` now orchestrates push → pull
  - Push via `uploadQueue.pushAll()`
  - Pull with delta cursor via `pull(orgId)`
  - Full service integration

## T-012: Refund Workflow (Flutter)

**Status:** ✅ COMPLETE

- **`RefundService`:** `features/refund/application/refund_service.dart` — Full lifecycle API wrapper
  - `getPolicy()` / `updatePolicy()` — refund policy management
  - `list()` / `get()` — list/fetch refund requests
  - `request()` — create new refund request with payment + optional ticket
  - `decide()` — approve (with amount) or reject
  - `markPaid()` — record payout
  - `complete()` — finalize refund

- **`RefundListPage`:** `features/refund/presentation/refund_list_page.dart`
  - Status filter bar (All, Requested, Approved, Paid, Completed, Rejected, Cancelled)
  - Pull-to-refresh
  - Empty state with create button (gated by `refund.request`)
  - List tiles with refund number, amount, reason preview, StatusChip

- **`RefundDetailPage`:** `features/refund/presentation/refund_detail_page.dart`
  - Status banner with color coding
  - Info rows (refund number, payment, amounts, reason, ticket, decision note)
  - Timeline (created → decided → paid → completed)
  - Action buttons per status:
    - `requested` → Approve / Reject (gated by `refund.approve`)
    - `approved` → Mark Paid (gated by `refund.pay`)
    - `paid` → Complete (gated by `refund.complete`)

- **`RefundCreatePage`:** `features/refund/presentation/refund_create_page.dart`
  - Payment selector (confirmed payments only)
  - Optional ticket selector (filtered by payment's booking)
  - Amount field (defaults to payment amount)
  - Reason text field
  - Submit confirmation with success view

- **Integration:** BusinessHome app bar icon + dashboard quick action (gated by `refund.view`)
- **Tests:** 10 unit tests covering all 7 service methods + error handling
- **Dart analyze:** 0 issues
