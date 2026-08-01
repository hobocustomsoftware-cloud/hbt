# HBT — Dashboard Wireframes (Wave 0)

**Date:** 2026-08-01
**Author:** Product Designer / Enterprise Dashboard Architect
**Status:** Wave 0 deliverable — no UI implementation until approved.
**Rule:** every role has a UNIQUE dashboard. **No dashboard may reuse another
dashboard's layout.** Each is designed for its decisions (charter §12: what happened /
attention now / do next).

Shared chrome: dark sidebar (#151515) + top bar (global search, bell, profile) on
desktop; rail on tablet; bottom nav on mobile.

---

## 1. Owner — Executive Dashboard

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ◆HBT  [Search… ⌘K]            🔔3  Branch▾  U Aung▾                  │
├──────────────┬───────────────────────────────────────────────────────────┤
│ ▸Dashboard   │ TODAY · ယနေ့        [Day][Week][Month][Year]   [Export▼] │
│ ▸Trips       │ ┌─────────┐┌─────────┐┌─────────┐┌─────────┐              │
│ ▸Ticket      │ │TICKET   ││CARGO    ││EXPENSES ││NET PROFIT│ ← hero     │
│ ▸Cargo       │ │32,450,000││8,200,000││4,500,000││15,800,000│            │
│ ▸Fleet       │ │▲+12%    ││▲+4%     ││▼-8%     ││▲+9%  ▓▓▓ │            │
│ ▸Finance     │ └─────────┘└─────────┘└─────────┘└─────────┘              │
│ ▸HR          │ ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐         │
│ ▸Reports     │ │RUN 24││DELAY 3⚠││CXL 1✕││PASS 1,240││CARGO 86││OT 93%││
│ ▸Settings    │ └──────┘└──────┘└──────┘└──────┘└──────┘└──────┘         │
│              │ ┌────────┐┌────────┐┌────────┐┌────────┐                  │
│              │ │CASH    ││BANK    ││PND RFND││PND APPR│                  │
│              │ │4,200,000││58,000,000││3·900k││7 ▸    │                  │
│              │ └────────┘└────────┘└────────┘└────────┘                  │
│              │ ┌─────────────────────┬──────────────────────────┐        │
│              │ │ Revenue trend (line) │ Expense donut            │        │
│              │ └─────────────────────┴──────────────────────────┘        │
│              │ ┌─────────────────┬──────────────────┬────────────┐        │
│              │ │ Branch compare  │ Trip status      │ Cash flow  │        │
│              │ │ (bars)          │ (donut)          │ (spark+bar)│        │
│              │ └─────────────────┴──────────────────┴────────────┘        │
│              │ ┌────────────┬────────────┬─────────────────────────┐      │
│              │ │Top routes  │Top staff   │ Heatmap branch×weekday  │      │
│              │ │(h-bars)    │(rank)      │ (intensity grid)        │      │
│              │ └────────────┴────────────┴─────────────────────────┘      │
│              │ ┌────────────┬──────────────────────┬───────────────────┐  │
│              │ │ P&L (period)│ Approvals panel      │ Activity timeline│  │
│              │ └────────────┴──────────────────────┴───────────────────┘  │
│              │ Alerts: 2 delayed · 1 cancelled · cash diff +12k · 📢 Ann. │
└──────────────┴───────────────────────────────────────────────────────────┘
```
**Decisions:** where is money today · what is broken · what needs approval → all
drill to Reports with the global filter. (Full spec: `hbt_dashboard_design.md` §2–3.)

---

## 2. Counter — POS Dashboard

```
┌────────────────────────────────────────────────┐
│ ◆HBT  [Search…]              🔔  U Mya▾   │
├──────────────┬─────────────────────────────────┤
│ ▸Shift       │  SHIFT: Open 08:00 · #S-2041    │
│ ▸Sell        │  ┌───────────────────────────┐  │
│ ▸Cargo       │  │   TODAY (this counter)     │  │
│ ▸Bookings    │  │   Tickets 2,850,000        │  │
│ ▸Refunds*    │  │   Cargo 640,000            │  │
│ ▸Cash        │  │   Cash diff +12,000 🟢     │  │
│ (rail)       │  └───────────────────────────┘  │
│              │  ┌─────────────┬──────────────┐ │
│              │  │ ▓▓ SELL     │ ▓▓ RECEIVE   │ │  ← 64px+ touch
│              │  │ ▓▓ TICKET   │ ▓▓ CARGO     │ │    grid
│              │  ├─────────────┼──────────────┤ │
│              │  │ ▓▓ ONLINE   │ ▓▓ PRINT     │ │
│              │  │ ▓▓ BOOKING  │ ▓▓           │ │
│              │  ├─────────────┴──────────────┤ │
│              │  │ Cash In/Out · Count · Close │ │
│              │  └────────────────────────────┘ │
└──────────────┴─────────────────────────────────┘
```
**Decisions:** what do I sell next · is my till right · close shift cleanly.
Sell ticket ≤3 taps from this grid (home → route/time → seats → pay/print).

---

## 3. Conductor — Trip Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]                🔔  U Ko▾    │
├──────────────┬───────────────────────────────────┤
│ ▸My Trip     │  TRIP YM-0801 · Yangon→Mandalay   │
│ ▸Boarding    │  Vehicle V-014 · Dep 08:00        │
│ ▸Offline     │  ┌─────────────────────────────┐  │
│ ▸Settlement  │  │ Seats 24/32 · Cargo 3 · 86kg │  │
│ (rail)       │  │ [████████████████░░░░░░░░]   │  │
│              │  └─────────────────────────────┘  │
│              │  Timeline                        │
│              │  ● Received trip (offline) 07:40  │
│              │  ● Boarding… 07:55                │
│              │  ○ Departed  ○ On route  ○ Arrived│
│              │  ┌────────────┬────────────────┐  │
│              │  │ ▓▓ SCAN QR │ ▓▓ OFF TICKET  │  │
│              │  │ ▓▓ OFF CGO │ ▓▓ SETTLE      │  │
│              │  └────────────┴────────────────┘  │
│              │  Sync queue: 3 pending · 🟢 1s    │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** where is my trip · board them fast · settle correctly. Offline is
normal — queue + conflict alerts visible.

---

## 4. Driver — Trip Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]                🔔  U Ba▾    │
├──────────────┬───────────────────────────────────┤
│ ▸My Trip     │  TODAY 08:00 YM-0801 → Mandalay   │
│ ▸Trip Sheet  │  Vehicle V-014 · Conductor U Ko   │
│ ▸Inspection  │  ┌───────────┬─────────────────┐  │
│ ▸Fuel        │  │ Pre-trip  │ Fuel: 60/100L   │  │
│ ▸Breakdown   │  │ checklist │ (log today)     │  │
│ (rail)       │  │ 8/8 ✓     │                 │  │
│              │  └───────────┴─────────────────┘  │
│              │  Route: YGN 07:00 → BAG 10:30 →   │
│              │  MDY 14:00 (rest stops marked)    │
│              │  ┌────────────┬────────────────┐  │
│              │  │ ▓▓ TRIP    │ ▓▓ INSPECTION  │  │
│              │  │ ▓▓ SHEET   │ ▓▓             │  │
│              │  │ ▓▓ FUEL    │ ▓▓ BREAKDOWN 🆘│  │
│              │  └────────────┴────────────────┘  │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** am I cleared to drive · log fuel · report breakdown in one tap.
Distinct from Conductor: vehicle/trip-sheet/inspection focus, no boarding/cash.

---

## 5. Finance — Finance Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]              🔔2  U Thida▾  │
├──────────────┬───────────────────────────────────┤
│ ▸Revenue     │  AUGUST 2026       [Month][Year]  │
│ ▸Expenses    │  ┌───────────┐ ┌───────────┐      │
│ ▸Bank        │  │REVENUE    │ │EXPENSES   │      │
│ ▸Payroll     │  │ 980,000,000│ │ 310,000,000│    │
│ ▸Refunds     │  └───────────┘ └───────────┘      │
│ ▸P&L         │  ┌────────────────────────────┐   │
│ (rail)       │  │ P&L: Revenue / Expenses /  │   │
│              │  │ Net · margin 68% (stacked) │   │
│              │  └────────────────────────────┘   │
│              │  ┌──────────────┬───────────────┐ │
│              │  │ Bank: avail  │ Expense by    │ │
│              │  │ 58M · pending│ category (bar)│ │
│              │  │ 12M          │               │ │
│              │  └──────────────┴───────────────┘ │
│              │  ┌──────────┬───────────────────┐ │
│              │  │ Payroll  │ Refund approvals  │ │
│              │  │ due 5th  │ 3 pending ▸       │ │
│              │  └──────────┴───────────────────┘ │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** are we profitable · cash position · what to approve. Report/export
centric; no operations tiles.

---

## 6. Cargo — Cargo Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]                🔔  U Hla▾   │
├──────────────┬───────────────────────────────────┤
│ ▸Manifests   │  INBOUND        OUTBOUND          │
│ ▸Waybills    │  ┌──────────┐  ┌──────────┐       │
│ ▸Tracking    │  │ 12 today │  │ 18 today │       │
│ ▸Delivered   │  │ 4 in-    │  │ 6 loaded │       │
│ ▸Settlement  │  │ transit  │  │          │       │
│ (rail)       │  └──────────┘  └──────────┘       │
│              │  Pipeline (Accepted→Loaded→In     │
│              │  Transit→Arrived→Delivered→Settle)│
│              │  [▓▓▓▓▓▓░░░░░░░░░░░░░░░░] 62%     │
│              │  ┌──────────────┬───────────────┐  │
│              │  │ Tracking now │ Revenue today │  │
│              │  │ CG-2041 ▸    │ 3,200,000     │  │
│              │  │ CG-2042 ▸    │ (weight/mixed)│  │
│              │  └──────────────┴───────────────┘  │
│              │  Activity: accepted/loaded/deliv…  │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** what is moving · what is stuck · settle correctly. Pipeline is the
hero (logistics OTP pattern); no ticket/sales mix.

---

## 7. Mechanic — Maintenance Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]                🔔  U Aye▾   │
├──────────────┬───────────────────────────────────┤
│ ▸Due         │  DUE NOW (past due first)          │
│ ▸Repairs     │  ┌──────────────────────────────┐  │
│ ▸Inspections │  │ V-009 oil+brakes · due 2d ⚠  │  │
│ ▸Jobs        │  │ V-012 tyres · due 5d         │  │
│ (rail)       │  │ V-021 AC · due 9d            │  │
│              │  └──────────────────────────────┘  │
│              │  ┌─────────────┬────────────────┐  │
│              │  │ Open repairs│ Completed this │  │
│              │  │ 4 (2 urgent)│ week: 11       │  │
│              │  └─────────────┴────────────────┘  │
│              │  ┌──────────────────────────────┐  │
│              │  │ Job log (vehicle + status)   │  │
│              │  │ ▓▓ NEW INSPECTION            │  │
│              │  └──────────────────────────────┘  │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** what breaks next · what to fix now. Queue-first; no revenue data.

---

## 8. Fleet — Fleet Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]                🔔  U Win▾   │
├──────────────┬───────────────────────────────────┤
│ ▸Vehicles    │  STATUS GRID (all vehicles)       │
│ ▸Seat Layouts│  ┌────┬────┬────┬────┬────┬────┐  │
│ ▸Utilization │  │V-001│V-002│V-003│…   │    │    │
│ ▸Expiries    │  │ 🟢  │ 🟢  │ 🟡M │🔴R │    │    │
│ (rail)       │  └────┴────┴────┴────┴────┴────┘  │
│              │  ┌──────────────────────────────┐  │
│              │  │ Utilization by vehicle (bars)│  │
│              │  └──────────────────────────────┘  │
│              │  ┌───────────────┬──────────────┐  │
│              │  │ Expiry watch  │ Maintenance  │  │
│              │  │ Insurance 3 ⚠ │ schedule due │  │
│              │  │ Road tax 1 🔴 │ 5            │  │
│              │  └───────────────┴──────────────┘  │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** which vehicle is where · what expires next · utilization.
Grid-of-status + expiry watch; no ticketing.

---

## 9. HR — Employee Dashboard

```
┌──────────────────────────────────────────────────┐
│ ◆HBT  [Search…]                🔔  U Cho▾   │
├──────────────┬───────────────────────────────────┤
│ ▸Staff       │  TODAY: present 18/20 · on leave 1│
│ ▸Attendance  │  ┌──────────────────────────────┐  │
│ ▸Payroll     │  │ Attendance by role (bars)    │  │
│ ▸Leave       │  └──────────────────────────────┘  │
│ ▸Performance │  ┌────────────┬─────────────────┐  │
│ (rail)       │  │ Payroll    │ Leave requests  │  │
│              │  │ due 5th    │ 2 pending ▸     │  │
│              │  │ 42 staff   │                 │  │
│              │  └────────────┴─────────────────┘  │
│              │  ┌──────────────────────────────┐  │
│              │  │ Top performers (rank)        │  │
│              │  │ ▓▓ NEW STAFF · ASSIGN ROLE   │  │
│              │  └──────────────────────────────┘  │
└──────────────┴───────────────────────────────────┘
```
**Decisions:** who is here · payroll due · hire/assign. People-first; employee
lifecycle (Hire→…→Resign) as the state machine.

---

## 10. Passenger — Booking Dashboard (app)

```
┌──────────────────────────────┐
│ ◆ [Operator logo]      🔔   ▤ │
│ ┌──────────────────────────┐ │
│ │ FROM ▾ Yangon            │ │
│ │ TO   ▾ Mandalay          │ │
│ │ DATE  [2026-08-03]       │ │
│ │      [ ▓▓ SEARCH TRIPS ] │ │
│ └──────────────────────────┘ │
│ Upcoming trips (cards)       │
│ ┌──────────────────────────┐ │
│ │ YM-0801 · 08:00 · 32 seats│ │
│ │ 30,000 MMK  [ Book ]     │ │
│ └──────────────────────────┘ │
│ ── Home ── Trips ── Tickets ── Profile │
└──────────────────────────────┘
```
**Decisions:** find my trip · book fast · show my ticket. Branding = operator's
(logo/colors); journey per charter §6.3.

---

## 11. Layout uniqueness matrix

| Dashboard | Hero element | Distinct from |
|---|---|---|
| Owner | money quartet + heatmap + approvals | all |
| Counter | touch action grid + shift box | all |
| Conductor | trip occupancy + boarding timeline | Driver (vehicle/sheet focus) |
| Driver | pre-trip checklist + fuel | Conductor |
| Finance | P&L stacked + bank | Owner (monthly, report-centric) |
| Cargo | in/out + pipeline | all |
| Mechanic | due-queue + job log | Fleet (expiry/utilization) |
| Fleet | status grid + expiries | Mechanic |
| HR | attendance + payroll | all |
| Passenger | search → book | app variant |
