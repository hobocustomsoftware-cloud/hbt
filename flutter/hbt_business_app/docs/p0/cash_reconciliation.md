# P0-03: Cash Reconciliation — Implementation Report

**Task ID:** P0-03
**Date:** 2026-07-30
**Priority:** P0 (Critical — no cash auditability)
**Status:** ✅ Implemented

---

## Architecture

### Cash Expected Formula

```
Expected Cash = Opening Cash + Cash Sales - Cash Refunds Paid - Cash Expenses
```

| Component | Source | Direction |
|-----------|--------|-----------|
| Opening Cash | Shift start (entered by staff) | Float in drawer |
| Cash Sales | Ticket + cargo payments made in cash | Increases drawer |
| Cash Refunds Paid | Refunds paid out in cash | Decreases drawer |
| Cash Expenses | Expenses paid out in cash | Decreases drawer |
| **Expected Cash** | **Calculated total** | **Should be in drawer** |
| Actual Cash | Staff counts at end of shift | Manual entry required |
| **Difference** | **Actual − Expected** | **Over or Short** |

### Flow

```
              Shift Close Screen
┌─────────────────────────────────────────────┐
│                                             │
│  1. Load cash breakdown from server         │
│     ┌───────────────────────────────────┐   │
│     │ Opening Cash: 100,000 MMK         │   │
│     │ Cash Sales:    250,000 MMK        │   │
│     │ Cash Refunds:  -25,000 MMK        │   │
│     │ Cash Expenses: -15,000 MMK        │   │
│     │ ─────────────────────────          │   │
│     │ Expected Cash: 310,000 MMK        │   │
│     └───────────────────────────────────┘   │
│                                             │
│  2. Staff physically counts drawer cash     │
│     ↓                                       │
│     [Actual Cash in Drawer: _______ ]       │
│                                             │
│  3. Live difference calculation             │
│     │ Actual: 312,000 → Diff: +2,000 (over) │
│     │ Actual: 308,000 → Diff: -2,000 (short)│
│     │                                       │
│  4. If |diff| > 1000 MMK: require reason   │
│                                             │
│  5. Reconciliation complete → reports       │
│     ├─ Shift Summary (this shift)           │
│     ├─ Owner Report (this counter/user)     │
│     └─ Daily Report (all counters today)    │
└─────────────────────────────────────────────┘
```

---

## Files Created

| File | Purpose | Lines |
|------|---------|-------|
| `shared/models/cash_models.dart` | `ShiftCashData`, `ShiftCashReport`, `DailyCashSummary` models | 174 |
| `features/shift/controllers/cash_reconciliation_controller.dart` | Fetch cash breakdown, shift report, owner report, daily report | 191 |
| `features/finance/screens/cash_report_screen.dart` | 3-tab report screen (Shift / Owner / Daily) | 579 |

## Files Modified

| File | Change |
|------|--------|
| `features/shift/controllers/shift_controller.dart` | Exposed `api` and `organizationId` getters for use by `CashReconciliationController` |
| `features/shift/screens/shift_close_screen.dart` | Full rewrite: cash breakdown loading, proper expected cash formula, live difference display, required reason for >1000 MMK diff, enhanced success view with full cash/revenue report, link to CashReportScreen |

---

## Cash Reconciliation Flow (Close Screen)

### Load phase
On screen init:
1. Create `CashReconciliationController` using shift controller's API client
2. `GET /organizations/{id}/shifts/{id}/cash-breakdown/`
3. Returns `ShiftCashData` with opening cash, cash sales, cash refunds, cash expenses

### Entry phase
1. Display cash breakdown card (opening, sales, refunds, expenses → expected)
2. Display "Actual Cash in Drawer" text field
3. As user types, calculate difference live
4. Difference card shows expected cash, difference amount, over/short indicator

### Validation
| Condition | Action |
|-----------|--------|
| Actual cash not entered | Button disabled |
| Invalid number entered | Error message shown |
| Actual cash < 0 | Error message shown |
| `|diff| > 1000 MMK` and no reason | Button disabled, "Reason required" shown |
| All valid | Button enabled → confirm dialog → close |

### Close API call
```json
POST /organizations/{id}/shifts/{id}/close/
{
  "closing_cash": 312000,
  "expected_cash": 310000,
  "cash_difference": 2000,
  "difference_reason": "Minor rounding from loose change"
}
```

### Success view
Shows:
1. ✅ Reconciliation Complete header
2. Cash Summary card (opening, cash sales in, cash refunds out, cash expenses out, expected, actual, difference with colour indicator)
3. Revenue Summary card (ticket, cargo, expenses, net, counts)
4. Action buttons: "Report" (opens CashReportScreen) and "Done" (pop to first route)

---

## Reports

### Shift Report (Tab 1)
Full breakdown for a specific closed shift:
- Shift Info: counter, staff, opened/closed timestamps
- Cash Breakdown: opening, sales, refunds, expenses, expected, actual, difference, reason
- Activity: ticket count, cargo count, refund count, expense count

### Owner Report (Tab 2)
All shifts for the current user/counter today:
- List of shift cards showing: staff name, counter, times, mini metrics
- Summary card: total expected, total actual, total difference, over count, short count

### Daily Report (Tab 3)
Aggregated across all counters for the day:
- Shifts count, total opening cash, total cash sales, total cash refunds, total cash expenses
- Total expected cash, total actual cash, total difference
- Over count / short count breakdown
- Per-shift activity list

---

## Validation: No Close Without Reconciliation

| Rule | Enforced at | Method |
|------|------------|--------|
| Actual cash must be entered | UI button | `BusyButton.onPressed` is `null` when `cash == null` or `cash < 0` |
| Valid number required | UI validation | Text shown when invalid: "Closing cash must be a valid positive number." |
| Reason required if `|diff| > 1000` | UI button | Button disabled until reason entered |
| Confirm dialog before close | UI dialog | `AppDialog.confirm()` shows full summary before posting |
| Shift already closed check | API | Server returns error; screen displays it |

---

## Server-side API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/organizations/{id}/shifts/{id}/cash-breakdown/` | Returns ShiftCashData (opening, cash sales, cash refunds, cash expenses) |
| `GET` | `/organizations/{id}/shifts/{id}/cash-report/` | Returns full ShiftCashReport |
| `GET` | `/organizations/{id}/shifts/cash-reports/` | Lists shift reports (with date/user/counter filters) |
| `GET` | `/organizations/{id}/shifts/daily-cash-summary/` | Aggregated DailyCashSummary |

### Server-side expected cash calculation (for reference)

```sql
WITH shift_cash AS (
  SELECT
    s.opening_cash,
    COALESCE(SUM(p.amount) FILTER (WHERE p.method = 'cash'), 0) AS cash_sales,
    COALESCE(SUM(r.amount) FILTER (WHERE r.payment_method = 'cash'), 0) AS cash_refunds,
    COALESCE(SUM(e.amount) FILTER (WHERE e.payment_method = 'cash'), 0) AS cash_expenses
  FROM shifts s
  LEFT JOIN payments p ON p.shift_id = s.id AND p.status = 'confirmed'
  LEFT JOIN refunds r ON r.shift_id = s.id AND r.status = 'paid'
  LEFT JOIN expenses e ON e.shift_id = s.id
  WHERE s.id = :shift_id
  GROUP BY s.id
)
SELECT
  opening_cash,
  cash_sales,
  cash_refunds,
  cash_expenses,
  (opening_cash + cash_sales - cash_refunds - cash_expenses) AS expected_cash
FROM shift_cash;
```

---

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (40 tests) | ✅ All passed |
| No AI features | ✅ |
| No UI redesign | ✅ (enhanced existing close screen + new report screen) |
| No offline implementation | ✅ |
