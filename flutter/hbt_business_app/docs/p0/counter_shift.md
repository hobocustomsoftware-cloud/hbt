# P0-03R: Counter Shift & Cash Reconciliation — Implementation Report

**Task ID:** P0-03R
**Date:** 2026-07-30
**Priority:** P0 (Critical — no shift management, no cash auditability)
**Status:** ✅ Implemented

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    COUNTER SHIFT SYSTEM                           │
│                                                                   │
│  1. Open Counter         2. Active Shift        3. Close Shift   │
│  ┌─────────────────┐     ┌────────────────┐     ┌──────────────┐ │
│  │ Branch select    │     │ Dashboard card │     │ Cash breakdown│ │
│  │ Counter select   │     │ Live timer     │     │ Expected cash │ │
│  │ Opening cash     │     │ 5-metric grid  │     │ Actual cash   │ │
│  │ User assignment  │     │ Quick actions  │     │ Difference     │ │
│  │ Printer check    │     │ Record expense │     │ Reason (req'd) │ │
│  │ Shift POST       │     │ Refresh button │     │ P&L summary    │ │
│  └────────┬────────┘     └───────┬────────┘     └──────┬───────┘ │
│           │                      │                      │         │
│           ▼                      ▼                      ▼         │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              AUDIT (Counter + User + Shift + Timestamp)      │ │
│  │  booking.create │ cargo.accept │ refund.request │ expense    │ │
│  │  shift.open     │ shift.close  │                │ create     │ │
│  └──────────────────────────────────────────────────────────────┘ │
│           │                      │                      │         │
│           ▼                      ▼                      ▼         │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                    REPORTS                                    │ │
│  │  Shift Tab (per-close) │ Owner Tab (per-user)               │ │
│  │  Counter Tab (per-counter) │ Daily Tab (aggregated)          │ │
│  └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## 1. Open Counter

### Screen: `ShiftOpenScreen`

| Field | Implementation |
|-------|---------------|
| Branch | `FormDropdown` populated from `GET /organizations/{id}/branches/` |
| Counter | `FormDropdown` populated from `GET /organizations/{id}/branches/{id}/counters/` (after branch select) |
| Opening Cash | `FormTextField` with MMK numeric keyboard |
| User Assignment | Auto from `SessionController.auth.user` — sent in shift POST body |
| Device Assignment | Printer check + connectivity check checkboxes |
| Printer Check | `CheckboxListTile` — must be checked to enable Start button |

### API call
```http
POST /organizations/{id}/shifts/
{
  "branch_id": "branch-uuid",
  "counter_id": "counter-uuid",
  "opening_cash": 100000,
  "printer_checked": true
}
```

### Validation
- Branch must be selected
- Counter must be selected
- Opening cash must be a valid number
- Printer check must be confirmed
- Button disabled until all criteria met

---

## 2. Active Shift

### Dashboard card: `ActiveShiftCard`

| Metric | Source |
|--------|--------|
| Tickets | `shift.ticketSalesCount` — updated via `refreshMetrics()` |
| Cargo | `shift.cargoCount` |
| Refunds | `shift.refundCount` |
| Expenses | `shift.expenseCount` — NEW (added in this task) |
| Revenue | `shift.totalRevenue` |
| Net Revenue | `shift.netRevenue` (= totalRevenue − expenseTotal) |
| Elapsed Time | `HH:MM:SS` live timer |
| Opening Cash | Reference display |

### Actions
| Action | Behaviour |
|--------|-----------|
| Refresh | Calls `shiftCtrl.refreshMetrics()` — re-fetches shift data from server |
| Record Expense | Navigates to `ExpenseCreateScreen` |
| Close Shift | Navigates to `ShiftCloseScreen` |

### Live timer
- Starts when shift is opened (`_startTimer()`)
- `Timer.periodic(1s)` updates elapsed duration
- Displays `HH:MM:SS` format
- Stops and cleared on shift close

---

## 3. Close Shift

### Screen: `ShiftCloseScreen`

#### Phase 1: Load cash breakdown
```http
GET /organizations/{id}/shifts/{id}/cash-breakdown/
```
Returns:
```json
{
  "opening_cash": 100000,
  "cash_ticket_sales": 250000,
  "cash_cargo_revenue": 50000,
  "cash_refunds_paid": 25000,
  "cash_expenses": 15000,
  "cash_other": 0
}
```

#### Phase 2: Display P&L Summary + Cash Breakdown
Two cards:
1. **Revenue** — ticket sales, cargo revenue, total revenue
2. **Expenses** — total expenses, net revenue (green/red)
3. **Cash Breakdown** — opening, cash in (sales), cash out (refunds, expenses), expected cash

#### Phase 3: Cash Reconciliation
| Field | UI |
|-------|-----|
| Actual Cash in Drawer | `FormTextField` with MMK keyboard |
| Expected Cash | Calculation: `opening + cash_sales - cash_refunds - cash_expenses` |
| Difference | Live as user types: green if ≤ 1,000 MMK diff, red if > 1,000 MMK |
| Reason | Required text field only when `|diff| > 1000` |

#### Phase 4: Confirm & Close
```http
POST /organizations/{id}/shifts/{id}/close/
{
  "closing_cash": 312000,
  "expected_cash": 310000,
  "cash_difference": 2000,
  "difference_reason": "Minor rounding"
}
```

#### Phase 5: Success View
Shows:
1. ✅ Reconciliation Complete header
2. **Cash Summary** — opening, cash in, cash out, expected, actual, difference (with colour)
3. **Revenue Summary** — ticket, cargo, expenses, net, counts
4. Action buttons: **Report** (→ `CashReportScreen`), **Done** (pop to home)

---

## 4. Reports

### Screen: `CashReportScreen` — 3 tabs

| Tab | Content | API |
|-----|---------|-----|
| **Shift** | Individual closed shift: cash breakdown, revenue, activity counts, difference | `GET .../shifts/{id}/cash-report/` |
| **Owner** | All shifts today for current user/counter, with per-shift cards and summary totals | `GET .../shifts/cash-reports/?start_date=&end_date=&user_id=&counter_id=` |
| **Daily** | Aggregated across all counters: total opening, sales, refunds, expenses, expected, actual, difference, over/short counts | `GET .../shifts/daily-cash-summary/?date=` |

### Report features

| Feature | Shift Tab | Owner Tab | Daily Tab |
|---------|-----------|-----------|-----------|
| Shift info | ✅ Counter, staff, times | ✅ Per-card header | N/A |
| Cash breakdown | ✅ Full | ✅ Per-card + summary | ✅ Aggregated |
| Difference indicator | ✅ Colour badge | ✅ Per-card badge | ✅ Total diff badge |
| Over/short counts | N/A | ✅ | ✅ |
| Per-shift activity | ✅ Tickets, cargo, refunds, expenses | ✅ Mini metrics | ✅ Drill-down list |

---

## 5. Audit Trail

### Every transaction records:
| Field | Source | Included in |
|-------|--------|-------------|
| **Counter ID** | `SessionController.counter.counterId` | Every `recordAudit()` call |
| **User ID** | `SessionController.auth.user['id']` | Every `recordAudit()` call |
| **Shift ID** | `SessionController.shiftId` | Every `recordAudit()` call |
| **Timestamp** | Server-side `created_at` via `NOW()` | Server-generated |

### Audit points (fire-and-forget):

| Trigger | Action | `resourceType` | `resourceId` |
|---------|--------|----------------|--------------|
| Booking created | `booking.create` | `booking` | Booking UUID |
| Cargo accepted | `cargo.accept` | `cargo_shipment` | Shipment UUID |
| Refund requested | `refund.request` | `refund` | Payment UUID |
| Expense created | `expense.create` | `expense` | Expense UUID |
| Shift opened | `shift.open` | `shift` | Shift UUID |
| Shift closed | `shift.close` | `shift` | Shift UUID |

### Audit API format:
```http
POST /organizations/{id}/audit-logs/
{
  "action": "booking.create",
  "resource_type": "booking",
  "resource_id": "uuid",
  "counter_id": "uuid",
  "branch_id": "uuid",
  "user_id": "uuid",
  "shift_id": "uuid",
  "device_id": "uuid (optional, future)",
  "details": { ... }
}
```

### Shift identity lifecycle:
1. Shift opened → `BusinessHome._syncCounterIdentity()` sets:
   - `session.shiftId = shift.id`
   - `session.setActiveCounter(branchId, branchName, counterId, counterName)`
2. All subsequent `session.recordAudit()` calls include shift ID + counter ID
3. Shift closed → `_syncCounterIdentity()` clears:
   - `session.shiftId = null`
   - `session.clearCounter()`

---

## Files Summary

### New files (from previous P0 tasks)
| File | Purpose |
|------|---------|
| `shared/models/shift_models.dart` | Shift, Branch, Counter, ShiftStatus (enhanced) |
| `shared/models/cash_models.dart` | ShiftCashData, ShiftCashReport, DailyCashSummary |
| `features/shift/controllers/shift_controller.dart` | Shift lifecycle (open, close, timer, metrics) |
| `features/shift/controllers/cash_reconciliation_controller.dart` | Cash data fetching, reports |
| `features/shift/screens/shift_open_screen.dart` | Open counter form |
| `features/shift/screens/shift_active_card.dart` | Active shift dashboard card |
| `features/shift/screens/shift_close_screen.dart` | Close shift with full P&L + cash reconciliation |
| `features/counter/controllers/counter_controller.dart` | Active counter identity management |
| `features/finance/screens/cash_report_screen.dart` | 3-tab report screen (Shift/Owner/Daily) |
| `shared/models/audit_entry.dart` | AuditEntry model |
| `shared/services/audit_service.dart` | Fire-and-forget audit recording (enhanced with shift_id) |

### Enhanced files (this task)
| File | Change |
|------|--------|
| `shared/services/audit_service.dart` | Added `shiftId` parameter to `record()` |
| `features/auth/controllers/session_controller.dart` | Added `shiftId` field, included in `recordAudit()` |
| `features/business/screens/business_home.dart` | Sets `session.shiftId` on shift open, clears on close |

---

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (57 tests) | ✅ All passed |
| No offline implementation | ✅ |
| No UI redesign | ✅ (used existing shared widgets + patterns) |
| Counter ID on every transaction | ✅ (via `SessionController.recordAudit()`) |
| User ID on every transaction | ✅ (via `auth.user['id']`) |
| Shift ID on every transaction | ✅ (via `session.shiftId`) |
| Timestamp on every transaction | ✅ (server-side `created_at`) |
| Open counter | ✅ Branch + counter + opening cash + checks |
| Active shift | ✅ Live timer + 5 metrics + actions |
| Close shift | ✅ Expected cash + actual + difference + reason |
| Daily report | ✅ Per-counter aggregated |
| Counter report | ✅ Owner tab shows per-counter |
| User report | ✅ Owner tab filters by user |
