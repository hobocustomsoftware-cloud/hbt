# HBT — Dashboard Component Library (Wave 0)

**Date:** 2026-08-01
**Author:** Product Designer / Enterprise Dashboard Architect
**Status:** Wave 0 deliverable — no UI implementation until approved.
**Rule:** use these components everywhere. **No duplicate UI.**

All components: brand tokens (`docs/design_system.md`), Myanmar-first text,
48px+ touch targets, WCAG AA, skeleton loading, named empty state, inline error.
Standard card: surface white (light) / #1A1A1A (dark), radius 14, shadow-sm,
16–20px padding, title = `HbtTypography.title`, one accent max.

---

## 1. Core data cards

### 1.1 KPI Card
- **Anatomy:** icon chip (brand gradient 40×40) · value (32/800 tabular) · label
  (13/500, 2 lines max) · trend (▲/▼ + % vs period) · optional sparkline.
- **States:** normal / alert (danger or warning tint when value crosses threshold) /
  loading (skeleton) / empty (—).
- **Usage:** all KPI rows; click → drill to filtered report.
- **Variants:** Hero (Net Profit — gradient header strip), Compact (trip ops row).

### 1.2 Chart Card
- **Anatomy:** title + period toggle · chart canvas (brand primary line/bars, grid
  hairline, tooltip on hover) · drill link.
- **States:** loading (skeleton canvas) / empty (illustration + "No data for this
  period" + action) / error (retry inline).
- **Usage:** Revenue trend, Expense donut, Branch comparison, Trip status.

### 1.3 Report Card
- **Anatomy:** report name · description · last-run time · export buttons (PDF/Excel).
- **Usage:** Reports hub; links to saved/parameterized reports.

### 1.4 Summary Widget
- **Anatomy:** small value + label + icon (quiet tier, container bg).
- **Usage:** secondary stats (on-time %, cash difference, seat occupancy).

### 1.5 Metric Badge
- **Anatomy:** pill (radius 999) with value/status; colors: success/warning/danger/info.
- **Usage:** counts on nav (Approvals 7), delta chips, compact statuses.

---

## 2. Domain status cards

### 2.1 Vehicle Status Card
- **Anatomy:** vehicle code + display name · status chip (Running/Maintenance/Retired/
  Available) · capacity + occupancy bar · next maintenance/insurance/road-tax expiry.
- **Usage:** Fleet dashboard, Owner fleet tiles. Status color drives the card edge.

### 2.2 Trip Status Card
- **Anatomy:** trip number + route + time · status chip (Planned/Ready/Boarding/
  Departed/On Route/Arrived/Settlement/Closed) · vehicle + driver · seats sold /
  occupancy · delayed badge (⚠ + minutes).
- **Usage:** Trips list, Conductor/Driver trip dashboards.

### 2.3 Counter Card
- **Anatomy:** counter name + branch · shift state (Open/Closed) · today's sales ·
  cash difference (green/red) · pending approvals count.
- **Usage:** Owner/Manager branch & counter performance.

### 2.4 Branch Card
- **Anatomy:** branch name · revenue + trend · trips run · staff present ·
  mini bar (routes). Click → branch drill-down.
- **Usage:** Branch Performance zone.

### 2.5 Expense Card
- **Anatomy:** category · amount · trend · share bar (of total). 
- **Usage:** Expense breakdown panel + Finance.

### 2.6 Profit Card
- **Anatomy:** period · revenue / expenses / net profit · margin % · trend ·
  export link. 
- **Usage:** Owner P&L tile, Finance P&L.

### 2.7 Notification Card
- **Anatomy:** type icon · title + body · time · primary action button.
- **Usage:** Notification center (grouped today/earlier; unread dot).

### 2.8 Approval Card
- **Anatomy:** type (refund/expense/leave) · amount/period · requester · reason ·
  **Approve / Reject** buttons (audit recorded).
- **Usage:** Approval panel (Owner/Manager/Finance per permission).

---

## 3. Structural components

### 3.1 Timeline
- **Anatomy:** vertical stepper (node + label + time + state) for lifecycle states
  (Trip: Planned→…→Closed; Cargo; Shift; Settlement).
- **Usage:** Trip detail, Cargo detail, Shift detail, Conductor settlement.

### 3.2 Activity Feed
- **Anatomy:** reverse-chronological one-line entries: actor · action · object ·
  time ("U Ko settled YM-0801 · 2m"), filter by type, click → record.
- **Usage:** Owner pulse zone, Finance, HR.

### 3.3 Quick Action
- **Anatomy:** large touch tile (icon + label, ≥64px) or primary FAB row; distinct
  from data cards.
- **Usage:** Counter POS grid, Owner next-action path, empty-state CTAs.

### 3.4 Search Bar
- **Anatomy:** global search field (top bar, ⌘K hint on desktop) with type-ahead
  grouped results (11 entity types) + quick actions.
- **Usage:** every role; tenant-scoped.

### 3.5 Global Filter
- **Anatomy:** filter bar: date range · branch · route · status chips · clear.
  One time-range control (Today/Week/Month/Year) drives all dashboard widgets.
- **Usage:** dashboards + all lists.

### 3.6 Status Chip
- **Anatomy:** pill, colored dot + label (semantic colors only). Never raw colored
  text.
- **Usage:** all status columns/rows (trip, vehicle, shift, cargo, approval).

### 3.7 Skeleton (loading)
- **Anatomy:** shimmer blocks mirroring final layout (KPI card, chart canvas, table
  rows) — brand-tinted grey, 1.2s loop, respect reduced-motion.
- **Usage:** every async area on first load.

---

## 4. Animation spec (subtle, purposeful)

| Element | Motion | Timing |
|---|---|---|
| Card hover | elevation up + border tint | 120ms ease |
| KPI counter | count-up on load | 600ms easeOutCubic |
| Chart draw-in | line/bars animate in | 380ms |
| Page transition | fade + 4px slide | 220ms |
| Sidebar collapse | width tween | 220ms |
| Skeleton shimmer | loop | 1.2s |
| All (reduced-motion) | disabled | — |

---

## 5. Component map (role → components)

| Role dashboard | Primary components |
|---|---|
| Owner Executive | KPI (hero+compact), Chart, Branch, Expense, Profit, Vehicle Status, Notification, Approval, Timeline, Activity, Badge, Quick Action, Summary, Global Filter |
| Counter POS | Quick Action grid (Sell/Receive Cargo/Online Booking/Print/Cash/Refund*), Counter, KPI (today), Summary, Status Chip |
| Conductor Trip | Trip Status, Timeline, Activity, Quick Action (Boarding/Offline Ticket/Cargo/QR/Settlement) |
| Driver Trip | Trip Status, Vehicle Status, Summary, Quick Action (Trip Sheet/Inspection/Fuel/Breakdown) |
| Finance | Profit, Expense, Chart, Report, Approval, Activity, Global Filter |
| Cargo | Trip Status (cargo), Timeline, Activity, Quick Action, Status Chip |
| Mechanic | Vehicle Status, Summary, Report (inspection), Quick Action |
| Fleet | Vehicle Status, Chart (utilization), Report (expiries), Quick Action |
| HR | Report (payroll), Activity, Approval (leave), Summary |
| Passenger | Search, Trip Status, Timeline (booking), Quick Action (pay) — app variant |
