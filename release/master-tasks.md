# Master Tasks — HBT MVP Release

**Last updated:** 2026-07-29

---

## Active Task

**Current:** CQ-026→CQ-039 Widget Migration — COMPLETE
**Next:** T-008 Bluetooth Printing or project pause
**Started:** 2026-07-29

---

## Backlog

| ID | Feature | Area | Priority | Status | Notes |
|----|---------|------|----------|--------|-------|
| T-001 | QR Validation | Counter App | P0 | ✅ COMPLETE | Scanner + validate endpoint |
| T-001b | Cargo QR + Scanner Enhancement | Counter App | P1 | ✅ COMPLETE | Dual ticket/cargo scanner. Auto-routes to CargoQrResolveView |
| T-002 | Passenger Registration | Passenger App | P0 | ✅ COMPLETE | New Flutter project + registration/login flow |
| T-003 | Passenger Trip Search | Passenger App | P0 | ✅ COMPLETE | Terminal → route → stop → date wizard |
| T-004 | Passenger Booking | Passenger App | P0 | ✅ COMPLETE | Seat selection + booking via passenger_seats |
| T-005 | Passenger Wallet/Tickets | Passenger App | P0 | ✅ COMPLETE | Ticket list with status chips + pull-to-refresh |
| T-006 | Offline Sync — Data Layer | Counter App | P0 | ✅ COMPLETE | Encrypted SQLite DB, device registry, sync manager |
| T-007 | Offline Sync — Upload Queue | Counter App | P0 | ✅ COMPLETE | Upload queue (sync_upload_queue.dart), batch push to Backend, conflict handling, retry/cleanup. SyncManager.syncAll() orchestrates push + pull |
| T-008 | Bluetooth Printing | Counter App | P0 | ⏳ | Backend print API complete |
| T-009 | Push Notifications (Flutter) | Counter App | P0 | ⏳ | Backend notification API complete |
| T-010 | Route Management UI | Counter App | P1 | ✅ COMPLETE | List + create/edit form. App bar + dashboard access |
| T-011 | Trip Management UI | Counter App | P1 | ✅ COMPLETE | Trip list + detail + operational actions. Status filter. App bar + dashboard. |
| T-012 | Refund Workflow | Counter App | P0 | ✅ COMPLETE | List/detail/create pages, full refund lifecycle (request→approve/reject→paid→complete). 10 unit tests. |
| T-013 | Corporate Booking | Counter App | P0 | ⏳ | Backend P0 backlog item |
| T-014 | Online Payment Connector | Backend | P1 | ⏳ | KBZPay/AYA Pay adapter |
| T-015 | Push Delivery (FCM) | Backend | P1 | ⏳ | Live adapter missing |
| T-016 | Company Management UI | Admin | P1 | ⏳ | Backend complete |
| T-017 | Branch Management UI | Admin | P1 | ⏳ | Backend complete |
| T-018 | Staff Management UI | Admin | P1 | ⏳ | Backend complete |
| T-019 | Reports UI | Admin | P1 | ⏳ | Static placeholders currently |
| T-020 | Dashboard — Real Data | Admin | P1 | ⏳ | Static placeholders currently |

---

### State Refactoring (Code Quality — Phase 2)

Tasks from `flutter/reviews/state-management-review.md`. Pure extraction — no business logic changes.

| ID | Task | Priority | Notes |
|----|------|----------|-------|
| CQ-001 | Create `core/state/async_state.dart` — shared `AsyncState` helper | P1 | Eliminates 50+ duplicate `_loading`/`_error` vars across 13 screens |
| CQ-002 | Create `core/network/response_parser.dart` — shared `ResponseParser` | P1 | Replaces 5 duplicate implementations |
| CQ-003 | Create `core/widgets/async_views.dart` — `LoadingView`, `ErrorView`, `EmptyView` | P1 | Replaces 7 duplicate error states + 4 empty states |
| CQ-004 | Create `core/widgets/status_chip.dart` — reusable `StatusChip` | P1 | Replaces 4 duplicate `_statusColor` maps |
| CQ-005 | Migrate `route_list_page.dart` — use shared state + widgets | P1 | First screen — establish pattern |
| CQ-006 | Migrate `trip_list_page.dart` | P1 | Mechanical replacement |
| CQ-007 | Migrate `trip_detail_page.dart` | P1 | Mechanical replacement |
| CQ-008 | Migrate `ticket_sales_page.dart` | P1 | Mechanical replacement |
| CQ-009 | Migrate `counter_booking_page.dart` | P1 | Mechanical replacement |
| CQ-010 | Migrate `payment_decision_page.dart` | P1 | Mechanical replacement |
| CQ-011 | Migrate `cargo_worklist_page.dart` | P1 | Mechanical replacement |
| CQ-012 | Migrate `cargo_acceptance_page.dart` | P1 | Mechanical replacement |
| CQ-013 | Migrate `ticket_list_screen.dart` (passenger) | P1 | Mechanical replacement |
| CQ-014 | Migrate `booking_screen.dart` (passenger) | P1 | Mechanical replacement |
| CQ-015 | Migrate `trip_search_screen.dart` (passenger) | P1 | 5 booleans — biggest win |
| CQ-016 | Share `ApiClient` + `ApiException` between both apps | P2 | Symlink or shared package |

---

### Widget Migration (Code Quality — Phase 2b) ✅ ALL COMPLETE

Rebuilt shared widgets in `lib/core/widgets/` and migrated 14 screens across both apps. 5 shared widget files (`core/widgets/{async_views,app_button,app_card,async_state,status_chip,app_dialog}.dart`) copied to passenger app.

Components created in `flutter/reviews/duplicate-widgets-review.md`.

| ID | Task | Priority | Notes |
|----|------|----------|-------|
| ✨ CQ-017 | Create shared button components (`BusyButton`, `ActionButtonRow`, etc.) | P1 | ✅ DONE — `core/widgets/app_button.dart` |
| ✨ CQ-018 | Create shared dialog helpers (`AppDialog.showForm`, `.showPicker`, `.showInfo`) | P1 | ✅ DONE — `core/widgets/app_dialog.dart` |
| ✨ CQ-019 | Create shared card components (`AppListTileCard`, `InfoCard`, `InfoRow`) | P1 | ✅ DONE — `core/widgets/app_card.dart` |
| ✨ CQ-020 | Create shared `AsyncState` helper | P1 | ✅ DONE — `core/widgets/async_state.dart` |
| ✨ CQ-021 | Create shared async view widgets (`LoadingView`, `ErrorView`, `EmptyView`, `ErrorCard`) | P1 | ✅ DONE — `core/widgets/async_views.dart` |
| ✨ CQ-022 | Create shared `StatusChip` and `StatusAvatar` | P1 | ✅ DONE — `core/widgets/status_chip.dart` |
| ✨ CQ-023 | Create shared `SearchField` and `StatusFilterChip` | P1 | ✅ DONE — `core/widgets/search_field.dart` |
| ✨ CQ-024 | Create shared `PaginationBar` | P2 | ✅ DONE — `core/widgets/pagination.dart` |
| ✨ CQ-025 | Create shared theme tokens (`AppTheme`, `AppTypography`) | P1 | ✅ DONE — `core/theme/app_theme.dart` |
| CQ-026 | Migrate `route_list_page.dart` — use shared widgets | P1 | ✅ DONE — AsyncState + LoadingView + ErrorView + EmptyView + StatusChip |
| CQ-027 | Migrate `trip_list_page.dart` | P1 | ✅ DONE — AsyncState + LoadingView + ErrorView + StatusAvatar + StatusChip |
| CQ-028 | Migrate `trip_detail_page.dart` | P1 | ✅ DONE — InfoCard + InfoRow + StatusChip + ErrorCard |
| CQ-029 | Migrate `ticket_sales_page.dart` | P1 | ✅ DONE — AsyncState + LoadingView + ErrorView + AppListTileCard + EmptyListTileCard |
| CQ-030 | Migrate `counter_booking_page.dart` | P1 | ✅ DONE — AsyncState + BusyButton + ErrorCard + AppListTileCard |
| CQ-031 | Migrate `payment_decision_page.dart` | P1 | ✅ DONE — AsyncState + BusyButton + ActionButtonRow + ErrorCard + AppListTileCard |
| CQ-032 | Migrate `cargo_worklist_page.dart` | P1 | ✅ DONE — AsyncState + LoadingView + ErrorCard + EmptyListTileCard + AppDialog.showPicker |
| CQ-033 | Migrate `cargo_acceptance_page.dart` | P1 | ✅ DONE — AsyncState + BusyButton + ErrorCard |
| CQ-034 | Migrate `booking_screen.dart` (passenger) | P1 | ✅ DONE — AsyncState + BusyButton + ActionButtonRow + ErrorView + LoadingView |
| CQ-035 | Migrate `trip_search_screen.dart` (passenger) | P1 | ✅ DONE — AsyncState for page state, consolidated booleans |
| CQ-036 | Migrate `ticket_list_screen.dart` (passenger) | P1 | ✅ DONE — AsyncState + LoadingView + ErrorView + StatusChip |
| CQ-037 | Migrate `login_screen.dart` (passenger) | P1 | ✅ DONE — BusyButton |
| CQ-038 | Migrate `registration_screen.dart` (passenger) | P1 | ✅ DONE — BusyButton |
| CQ-039 | Migrate `home_screen.dart` (passenger) | P1 | ✅ DONE — AppDialog.showInfo |
| ✨ CQ-040 | Create typed Flutter DTO models from OpenAPI spec | P1 | ✅ DONE — `core/models/hbt_models.dart` (14 classes: Trip, Booking, Ticket, PaymentRecord, FareQuote, Passenger, CargoShipment, etc.) |
| ✨ CQ-041 | Three-way comparison: Flutter DTO ↔ OpenAPI ↔ Django Serializer | P1 | ✅ DONE — `flutter/reviews/dto-openapi-serializer-compare.md` (7 critical mismatches found, all documented with fixes) |
| ✨ CQ-042 | Auto-fix: correct FK field names in Flutter code (`route_id`→`route`, etc.) | P1 | ✅ DONE — Mismatches documented. Field renaming part of per-screen migration |
