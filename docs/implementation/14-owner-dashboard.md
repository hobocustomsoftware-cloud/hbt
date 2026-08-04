# Owner Dashboard — Implementation Notes (Phase 1)

**Date:** 2026-08-04
**Status:** Phase 1 implemented — real-data dashboard, no seeded/fake data.
**Scope rule:** every KPI/widget is backed by an existing backend model and
real aggregate. Widgets whose domain model does not exist yet are **omitted**
from this phase and listed under *Future enhancements* — never faked.

---

## 1. Architecture (presentation / domain / data)

```
Flutter                                      Django
─────────────────────────────                ─────────────────────────────
lib/features/dashboard/                      apps/operations/dashboard.py
├── owner_dashboard_screen.dart  (UI)        │  build_owner_dashboard() — pure
├── dashboard_models.dart        (domain)    │  aggregation over real models
├── dashboard_controller.dart    (state)     │
└── dashboard_repository.dart    (data)      │  apps/operations/views.py
    └── ApiDashboardRepository ──HTTP────────▶  OwnerDashboardView
                                               (?period=day|week|month|year)
```

- **Data layer** — `DashboardRepository` interface + `ApiDashboardRepository`
  (real `GET /organizations/{id}/reports/owner-dashboard/?period=…`). No
  demo/seed repository exists in production code.
- **Domain layer** — `DashboardSnapshot` + typed section models, parsed with
  `fromJson`. Sections tolerate absence: missing backend data renders as
  `0` / empty / "No data for this period".
- **Presentation layer** — reusable design-system widgets in
  `lib/core/widgets/` (component library §1–§3):
  - `hbt_kpi_card.dart` (KPI card: hero/compact/alert/skeleton)
  - `hbt_revenue_trend_chart.dart` (line chart w/ grid + compact labels)
  - `hbt_ranking_panel.dart` (top routes / vehicles / branches)
  - `hbt_activity_feed.dart` (pulse), `hbt_alert_banner.dart` (alerts)
  - `hbt_quick_action_tile.dart`, `hbt_metric_badge.dart`,
    `hbt_time_range_selector.dart` (Day/Week/Month/Year)
- **State** — `DashboardController` (ChangeNotifier): period + loading /
  error / snapshot lifecycle. Owned by `BusinessHome`, swapped with the org
  context when the active organization changes.

## 2. Snapshot zones (all real aggregates)

| Zone | Data source (backend model) |
|---|---|
| Money (ticket/cargo/total revenue) | `Ticket.total_amount` (excl. cancelled) · `CargoShipment.total_charge` (excl. cancelled) |
| Trip operations | `Trip` by status + service_date; on-time % = departed ≤ planned + 15 min |
| Passengers / cargo today | `Ticket` count · `CargoShipment` count |
| Bookings | `Booking` by status |
| Cash & pending | confirmed `PaymentRecord` (cash) · `RefundRequest` (requested) |
| Fleet & people | `Vehicle` (in_service / maintenance) · `DriverProfile` on-duty via trips |
| Revenue trend | per-day ticket+cargo sums over the period window (monthly buckets for year) |
| Rankings | ticket revenue grouped by route / vehicle / branch |
| Pulse | `AuditEvent` (activities) · derived alerts · `Notification` (announcements) |

## 3. Future enhancements (documented, not faked)

These blueprint zones are intentionally **absent** until their backend
domain models exist. When a model lands, add the aggregate to
`apps/operations/dashboard.py` + the serializer, then render the widget —
the response structure is additive and the Flutter models tolerate absence.

- **Expenses** — no `Expense` model/endpoint yet (Flutter `ExpenseController`
  targets `/expenses/` which does not exist in the backend). Blocks: Expense
  KPI, expense-breakdown donut, net-profit hero, full P&L.
- **Shifts** — no `Shift` model/endpoint yet (Flutter `ShiftController`
  targets `/shifts/` which does not exist). Blocks: shift status card,
  cash-difference alerts, counter performance.
- **Bank balance** — no banking/ledger model. Blocks: Bank Balance KPI.
- **Approval actions** — the dashboard shows the pending-approvals count;
  inline Approve/Reject actions can reuse the existing
  `POST /refunds/{id}/decision/` endpoint when the approval card is built.

## 4. Verification

- Backend: `DJANGO_DB_ENGINE=sqlite python3 manage.py test apps.operations`
  → 13 tests OK (7 new dashboard tests).
- Flutter: `flutter analyze` clean; `flutter test` → 111 tests OK (7 new
  dashboard tests incl. real-snapshot rendering + error/retry).
- Pre-existing, unrelated: `test_composite_indexes.py` PRAGMA assertions fail
  on modern SQLite (index-name column position) — Postgres-oriented test,
  untouched by this work.
