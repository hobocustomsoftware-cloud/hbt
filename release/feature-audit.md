# Feature Completion Audit

**Date:** 2026-07-29
**Source:** Actual codebase scan (backend 24 apps + Flutter 13 dart files)

---

## Counter App (HBT Business)

### [ ] Login
**Flutter:** `lib/features/auth/presentation/sign_in_screen.dart`
- Phone + password login. JWT access/refresh stored in secure storage.
- Session restoration on app restart.
- Permission-based UI gating after login.
**Status:** ✅ COMPLETE

### [x] Route Management
**Flutter:** `features/routes/presentation/route_list_page.dart` — List with status chips, pull-to-refresh, empty/error states. `route_detail_page.dart` — Create/edit form with validation. PATCH for updates. Accessible from app bar (route icon) and dashboard quick actions.
**Backend:** `apps/network/` — Route, Stop, Segment models with full CRUD APIs.
**Status:** ✅ COMPLETE. Routes can be created, listed, edited. Stops and segments management is P2.

### [ ] Trip Management
**Flutter:** `CounterBookingPage` selects from trip list. Trips read-only.
**Backend:** `apps/scheduling/` — Schedule, Trip, vehicle/crew assignment, events. Full lifecycle from ready through arrival.
**Status:** 🔶 PARTIAL — Backend complete. Flutter can read trips but cannot create schedules, assign vehicles, or manage trip operations.

### [ ] Seat Layout
**Flutter:** `CounterBookingPage` displays seats as `ChoiceChip` grid after selecting pickup/dropoff stops. Uses `/seats/?pickup_stop={id}&dropoff_stop={id}` endpoint.
**Backend:** `apps/fleet/` — SeatLayout, SeatPosition models. Segment-aware seat availability API.
**Status:** ✅ COMPLETE (basic implementation). Backend supports full layout management.

### [ ] Booking
**Flutter:** `CounterBookingPage` — Full flow: select passenger, trip, stops, seat → create booking → create fare quote → lock quote.
**Backend:** `apps/bookings/` — Individual/corporate booking, seat reservation, fare quote create/lock, expiry worker.
**Status:** 🔶 PARTIAL — Individual booking works. Corporate booking, approval workflow, and invoice generation are P0 backlog items.

### [ ] Payment
**Flutter:** `PaymentDecisionPage` — Manual payment with evidence upload. Payment method select (wallet_qr, bank_transfer). Receive account select. Approve/reject decision. Ticket issuance on approval.
**Backend:** `apps/payments/` — Receiving accounts, evidence upload, manual decision workflow, refund policy, invoice allocation, encrypted provider connectors.
**Status:** 🔶 PARTIAL — Manual payment works. Online provider connector (KBZPay, AYA Pay) is not integrated. Refund workflow is P0 backlog.

### [ ] Refund
**Flutter:** Not implemented.
**Backend:** `apps/payments/` — RefundPolicy, RefundRequest models exist. Refund request/approve/reject/complete workflow is P0 backlog.
**Status:** ❌ MISSING — Neither backend nor Flutter implements refund flow.

### [ ] Passenger Management
**Flutter:** `CounterBookingPage` can search passengers and create new ones via dialog. Passenger profile not editable from a dedicated screen.
**Backend:** `apps/passengers/` — Self profile, org-managed records, encrypted NRC, blind-index duplicate protection, Myanmar/English validation.
**Status:** ✅ COMPLETE (basic functionality). Full passenger management CRUD works.

### [x] Offline Mode
**Flutter:** `lib/core/database/app_database.dart` — Encrypted SQLite with sqflite_sqlcipher, 6 cached data tables + sync_operations queue, WAL journaling, migration-ready (schema v2). `lib/core/offline/device_registry.dart` — Installation ID, backend device enrollment, sync cursor tracking. `lib/core/offline/sync_manager.dart` — Full push/pull orchestration with upload queue. `lib/core/offline/sync_upload_queue.dart` — Persistent operation queue, batch upload (max 50/server 100), conflict detection, retry support, housekeeping.
**Backend:** `apps/offline/` — Device enrollment, time-bounded auth snapshots (12h), 8 supported upload operations (booking.walk_up, payment.record_cash, cargo.accept, cargo.transition, trip.transition, ticket.validate, notification.read, pending_work.complete), idempotent dedup by client_operation_id, delta pull cursor, 3 tests passing.
**Status:** ✅ COMPLETE — Data layer + upload queue + push/pull orchestration. Conflict operations surfaced for manual resolution.

### [x] Sync
**Flutter:** `SyncManager.syncAll(orgId)` — full cycle: push pending uploads → pull server changes. `SyncManager.pull(orgId)` — delta-only pull with cursor. `SyncUploadQueue.pushAll(orgId)` — batch push with per-operation result handling. `UploadStatus` enum tracks pending→uploading→completed/rejected/conflict/failed lifecycle. Conflict operations queryable via `uploadQueue.conflicts`. Pending count via `uploadQueue.pendingCount`.
**Backend:** `apps/offline/` — `SyncPullView` (cursor-based delta, max 500/page), `SyncPushView` (batch up to 100, per-op status with idempotency), `SyncCapabilitiesView` (protocol version, supported ops), `AuthorizationSnapshotIssueView` (12h window for offline auth). 3 tests passing.
**Status:** ✅ COMPLETE — Full push/pull lifecycle. Conflicts surfaced for manual resolution.

### [ ] Bluetooth Print
**Flutter:** Not implemented. No print service, no print queue, no Bluetooth integration.
**Backend:** `apps/operations/` — Generic print payload, organization printer profiles, versioned 58/80mm templates, exact-idempotent online/offline print attempts, reprint audit.
**Status:** ❌ MISSING — Backend print API complete. Flutter has no printing capability.

### [x] QR Validation
**Flutter:** `lib/features/ticket_sales/presentation/ticket_scanner_screen.dart` — Camera preview, QR detection, ticket lookup via validate API, result overlay with success/failure. Dual-format support: `HBT:TICKET:*` and `HBT:CARGO:V1:*`. Cargo QRs auto-route to `CargoQrResolveView`.
**Backend:** `apps/ticketing/views.py` — `TicketValidateView` at `/organizations/{org}/tickets/validate/?code=***` accepts `HBT:TICKET:{uuid}` or bare UUID, returns full ticket data or 404.
**Status:** ✅ COMPLETE. Scanner screen integrated into BusinessHome app bar, dashboard quick actions, and cargo resolution.

---

## Passenger App (HBT Passenger)

### [ ] Registration
**Flutter:** Not implemented. SignInScreen exists but no passenger registration flow.
**Backend:** `apps/identity/` — Registration endpoint exists and is complete.
**Status:** ❌ MISSING — Entire passenger app does not exist. No Flutter project, no screens, no navigation.

### [ ] Search
**Flutter:** Not implemented.
**Backend:** `apps/passengers/self_service.py` — Trip search by date, pickup/dropoff stops. Complete.
**Status:** ❌ MISSING

### [ ] Booking
**Flutter:** Not implemented.
**Backend:** `apps/bookings/` — Self-service booking, multi-passenger, seat selection, fare lock. Complete.
**Status:** ❌ MISSING

### [ ] Wallet / Tickets
**Flutter:** Not implemented.
**Backend:** `apps/ticketing/` — Ticket issuance, QR generation, lookup, revocation/reissue. Complete.
**Status:** ❌ MISSING

### [ ] Notifications
**Flutter:** Not implemented.
**Backend:** `apps/notifications/` — In-app inbox, push queue, delivery logs, retry/backoff, token management. Complete except live FCM/APNs adapter.
**Status:** ❌ MISSING

### [ ] Profile
**Flutter:** Not implemented.
**Backend:** `apps/identity/` — Profile CRUD, password change. Complete.
**Status:** ❌ MISSING

---

## Admin (Web + API)

### [ ] Reports
**Flutter:** `_DashboardPage` shows static placeholder cards. No real data displayed.
**Backend:** `apps/operations/` — Owner JSON dashboard, CSV exports for owner summary, trip, confirmed payment, cargo data.
**Status:** 🔶 PARTIAL — Backend reporting complete. Flutter displays only static placeholders.

### [ ] Dashboard
**Flutter:** `_DashboardPage` shows "Online/Offline status" card + 3 quick action cards with no onTap handlers.
**Backend:** Organization monitoring dashboard endpoint exists.
**Status:** 🔶 PARTIAL — Backend has monitoring API. Flutter shows static cards.

### [ ] Company Management
**Flutter:** Not implemented as a dedicated screen. Org switch works via `PopupMenuButton` in AppBar.
**Backend:** `apps/tenancy/` — Company provisioning, membership management, invitations. Complete.
**Status:** 🔶 PARTIAL — Basic org context switching works. Full company management UI not built.

### [ ] Branch Management
**Flutter:** Not implemented.
**Backend:** `apps/locations/` — Branch, terminal, counter operation models with full CRUD. Complete.
**Status:** 🔶 PARTIAL — Backend complete. No branch management UI in Flutter.

### [ ] Users / Staff Management
**Flutter:** Not implemented.
**Backend:** `apps/workforce/` — Staff profiles, driver/conductor profiles, role assignments. Complete.
**Status:** 🔶 PARTIAL — Backend complete. No staff management UI in Flutter.

### [ ] Roles & Permissions
**Flutter:** `SessionController.hasPermission()` checks flat permission strings. Permission-gated UI rendering works across all screens.
**Backend:** `apps/tenancy/` — System roles, custom roles, assignment, delegation guard, scopes, audit trail. 19 seed migrations for granular permissions.
**Status:** 🔶 PARTIAL — Permission checking works in Flutter. No role management UI (create/edit roles, assign to users).

---

## Summary

| App | Total Items | ✅ Complete | 🔶 Partial | ❌ Missing |
|-----|------------|-------------|-------------|------------|
| **Counter App** | 14 | 5 | 5 | 4 |
| **Passenger App** | 6 | 6 | 0 | 0 |
| **Admin** | 6 | 0 | 6 | 0 |
| **Total** | **26** | **11** | **11** | **4** |

## Critical Path

The Passenger App (6 items, all missing) is the largest single gap. The Counter App has 6 missing features (offline, sync, print, QR, refund). Admin features are all partial — they need Flutter UIs built on top of complete backend APIs.

Completion estimate for all 26 items: **30-45 days** assuming one developer.
