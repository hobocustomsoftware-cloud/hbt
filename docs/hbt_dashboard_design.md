# HBT — Owner Dashboard & Role-Based UI Design

**Date:** 2026-08-01
**Author:** Product Designer / UX Researcher / Enterprise Dashboard Architect
**Status:** Design proposal — awaiting approval. No code until approved.
**Derived from:** `docs/design_principles.md` (THE charter — supersedes older KPI/role lists),
`docs/dashboard_research.md` (every pattern cited), `docs/ui_master_blueprint.md`,
`docs/design_system.md` (tokens #AA0000/#151515, HbtAdaptiveScaffold, HbtKpiGrid, HbtAdaptiveTable).

---

## 1. Design principle

> **"If I owned a transport company, what would I want to know within 5 seconds of login?"**

Answer: **today's money truth, what is broken, and what needs my approval.**
Nothing else may compete for the first five seconds. Everything else is one click away.

**Decision-first rule** (charter §12): every dashboard widget must support a business
decision and lead to an action. A widget without an action is removed. Dashboards
never exist merely to display data.

**Three-question test** (charter §12): every dashboard must answer (1) *What happened
today?* (2) *What requires my attention now?* (3) *What should I do next?* — with an
explicit next action, one tap away.

The 5-second test is the acceptance gate for every dashboard screen (research §2.3),
alongside the 55-year-old test and the workload test (charter §8, §13).

---

## 2. The Owner's 24 facts, organized

All 24 mandated facts are on the Owner dashboard, arranged by **operational gravity**
(research: money first, operations second, exceptions and approvals third):

| Zone | Facts | Format |
|---|---|---|
| **A. Money quartet** | 1 Ticket Revenue · 2 Cargo Revenue · 3 Expenses · 4 Net Profit | 4 large KPI cards, first row (net profit = hero) |
| **B. Trip operations** | 5 Running · 6 Delayed ⚠ · 7 Completed · 8 Passengers · 9 Cargo Today · 10 On-Time % | 6 compact KPI cards |
| **C. Cash & pending** | 11 Cash in Counters · 12 Bank Balance · 13 Pending Refunds · 14 Pending Approvals | 4 KPI cards with drill links |
| **D. Fleet & people** | 15 Vehicles Running · 16 Vehicles Under Maintenance · 17 Driver Attendance · 18 Counter Performance | 4 status tiles |
| **E. Trends** | Revenue trend (Weekly/Monthly/Yearly toggle) · Expense breakdown | 2 charts |
| **F. Performance** | 19 Branch Performance · 20 Top Routes · 21 Top Vehicles | 3 ranking panels |
| **G. Profit** | 22 Profit & Loss (period mini) | card → full P&L |
| **H. Pulse** | 23 Recent activities / Pending approvals · 24 Alerts · Announcements | feeds |

Plus: Quick Actions (New Trip · New Route · Approve(n) · Export PDF/Excel · Announce) ·
Notifications bell · Announcements feed.

**Delayed trips, cancelled trips, cash differences, and pending approvals are
color-alerted (amber/red) the moment they are non-zero** (research: exception-first).
Export (PDF/Excel) available on every KPI group and the whole dashboard.

---

## 3. Desktop wireframe (1024–1439 / 1440+)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ◆ HBT   [Global search… ⌘K]        🔔3   Branch ▾   U Aung Owner ▾   │ ← top bar
├──────────────┬──────────────────────────────────────────────────────────────┤
│ ▸ Dashboard  │  TODAY · 2026-08-01 · ယနေ့           [Day][Week][Month][Year] │
│ ▸ Trips      │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐     │
│ ▸ Ticket     │  │TICKET REV │ │CARGO REV  │ │ EXPENSES  │ │NET PROFIT │     │
│ ▸ Cargo      │  │ 32,450,000│ │ 8,200,000 │ │ 4,500,000 │ │ 15,800,000│     │
│ ▸ Fleet      │  │ ▲ +12%    │ │ ▲ +4%     │ │ ▼ -8%     │ │ ▲ +9%     │     │
│ ▸ Finance    │  └───────────┘ └───────────┘ └───────────┘ └───────────┘     │
│ ▸ HR         │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │
│ ▸ Reports    │  │RUNNING  │ │DELAYED ▮│ │CANCEL ▮ │ │PASSENGER│ │CARGO   │ │
│ ▸ Settings   │  │ 24      │ │ 3 ⚠     │ │ 1 ✕     │ │ 1,240   │ │ 86     │ │
│              │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └────────┘ │
│              │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐    │
│              │  │CASH CTRS  │ │BANK BAL   │ │PND REFUND │ │PND APPROVE│    │
│              │  │ 4,200,000 │ │ 58,000,000│ │ 3 · 900k  │ │ 7 ▸ review│    │
│              │  └───────────┘ └───────────┘ └───────────┘ └───────────┘    │
│              │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐    │
│              │  │VEH RUN    │ │VEH MAINT  │ │DRIVER ATT │ │CTR PERF   │    │
│              │  │ 40/45     │ │ 5 ▸ sched │ │ 18/20     │ │ 92/100    │    │
│              │  └───────────┘ └───────────┘ └───────────┘ └───────────┘    │
│              │  ┌───────────────────────────┬────────────────────────────┐  │
│              │  │ Revenue trend (30d line)  │ Expense breakdown (donut)  │  │
│              │  │   ▁▃▅▂▄▆▇▅▆▇█▇▆▅▆▇       │  ● Fuel ● Wage ● Parts    │  │
│              │  └───────────────────────────┴────────────────────────────┘  │
│              │  ┌───────────────┬───────────────┬────────────────────────┐  │
│              │  │ Branch perf   │ Top routes    │ Top vehicles           │  │
│              │  │ (bar)         │ (bar)         │ (rank list w/ revenue) │  │
│              │  └───────────────┴───────────────┴────────────────────────┘  │
│              │  ┌──────────────┬──────────────────┬───────────────────────┐  │
│              │  │ P&L (period) │ Recent activity  │ Pending approvals     │  │
│              │  │ +15.8M       │ · U Ko settled…  │ · Refund #334 … ▸     │  │
│              │  └──────────────┴──────────────────┴───────────────────────┘  │
│              │  Alerts: 2 delayed · 1 cancelled · cash diff +12,000 · see all│
│              │  📢 Announcements: [New route Yangon→Mandalay from Aug 5]     │
└──────────────┴──────────────────────────────────────────────────────────────┘
```

**Layout rules (desktop):**
- Top bar: brand · **global search** (one field: Passenger, Phone, NRC, Ticket,
  Booking, Cargo, Vehicle, Employee, Route, Trip, Receipt + quick actions, ⌘K;
  tenant-scoped — charter §18) · notifications bell (badge) ·
  branch switcher · profile.
- Sidebar 248px, collapsible to 72px icons; 4 groups: **Operate** (Dashboard, Trips,
  Ticket, Cargo), **Manage** (Fleet, Finance, HR), **Insight** (Reports), **Admin**
  (Settings, Users, Roles).
- KPI rows: 4 + 6 + 4 + 4 = 18 cards; each card = value + trend + drill.
- Charts = 2 on home (revenue trend + expense breakdown); every chart drills into
  Reports with the same time filter.
- Content max-width 1680 on 1440+; centered, no stretching.

### 3.1 Company Setup Dashboard (owner's pre-live home)

Until setup completes, the owner's post-login home is the setup readiness dashboard
(charter §20) — it answers the three questions while the business is being configured:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ◆ HBT        [Search… ⌘K]               🔔   U Aung Owner ▾        │
├──────────────┬──────────────────────────────────────────────────────────┤
│ ▸ Dashboard  │  Company Setup       ██████░░░░ 60%                     │
│ ▸ Trips      │  Remaining: ✓ Logo ✓ Branch ✓ Counter ☐ Vehicle ☐ Route│
│ ▸ Ticket     │              ☐ Employees                                │
│ ▸ Cargo      │  ┌──────────┬──────────┬──────────┬──────────┐          │
│ ▸ Fleet      │  │🟢 Company│🟡 Vehicles│🟢 Branch │🔴 Employees│          │
│ ▸ Finance    │  │ Ready    │ Missing  │ Ready    │ None     │          │
│ ▸ HR         │  │          │          │          │          │          │
│ ▸ Reports    │  │ Overall 78%                                         │
│ ▸ Settings   │  ├────────────────────────────────────────────────────┤  │
│              │  │ NEXT RECOMMENDED ACTION                             │  │
│              │  │   ↓ Create Vehicle  ↓ Assign Driver  ↓ Create Route │  │
│              │  │   ↓ Ready to Sell                                  │  │
│              │  ├────────────────────────────────────────────────────┤  │
│              │  │ Business Readiness 85%  Next: Configure Cargo      │  │
│              │  │ Estimated Time: 5 Minutes                          │  │
└──────────────┴────────────────────────────────────────────────────────┘
```

- Every health tile drills into the setup step that fixes it.
- The final "Ready to Sell" step hands off to the full Owner Dashboard (§3).
- On mobile/tablet: progress bar + health tiles on top, next-action list below
  (same hierarchy as desktop).

---

## 4. Tablet wireframe (600–1023)

```
┌─────────────────────────────────────────────┐
│ ◆ HBT  [Search…]        🔔3   Profile ▾ │
├─────────┬───────────────────────────────────┤
│  ▸ Dash │ TODAY          [Day][Week][Month] │
│  ▸ Trips │ ┌───────────┐ ┌───────────┐      │
│  ▸ Tick  │ │NET PROFIT │ │TICKET REV │      │
│  ▸ Cargo │ │ 15,800,000│ │ 32,450,000│      │
│  ▸ Fleet │ │ ▲ +9%     │ │ ▲ +12%    │      │
│  ▸ Fin   │ └───────────┘ └───────────┘      │
│  ▸ HR    │ ┌───────────┐ ┌───────────┐      │
│  ▸ Rep   │ │CARGO REV  │ │ EXPENSES  │      │
│  ▸ Set   │ └───────────┘ └───────────┘      │
│ (rail)   │ ┌──────┬──────┬──────┬──────┐    │
│          │ │RUNN  │DELAY │CXL   │PASS  │    │  ← 2×2 compact KPIs
│          │ └──────┴──────┴──────┴──────┘    │
│          │ ┌──────────────────────────────┐  │
│          │ │ Revenue trend (line)         │  │
│          │ └──────────────────────────────┘  │
│          │ ┌────────────┬────────────────┐   │
│          │ │ Branch perf│ Trip status    │   │
│          │ └────────────┴────────────────┘   │
│          │ Top routes ▸ · Top vehicles ▸ (cards)│
│          │ Vehicle st. · Driver att. ▸       │
│          │ Alerts strip (delayed/cancelled)  │
└─────────┴───────────────────────────────────┘
```

- **Navigation rail** (icons + labels); bottom sheet for overflow actions.
- KPI grid 2-col; charts 1–2 col; tables → cards (`HbtAdaptiveTable`).
- Cash & pending strip collapses to a horizontal scroll-free row of compact chips.

---

## 5. Mobile wireframe (0–599)

```
┌──────────────────────┐
│ ◆ HBT     🔔3   ▤    │
│ TODAY · ယနေ့         │
│ [Day][Week][Month]   │
│ ┌─────────┐ ┌───────┐│
│ │NET PROFIT│ │TICKET ││
│ │15,800,000│ │32.45M ││
│ │ ▲ +9%   │ │ ▲ +12%││
│ └─────────┘ └───────┘│
│ ┌─────────┐ ┌───────┐│
│ │CARGO REV│ │EXPENSE││
│ └─────────┘ └───────┘│
│ ▓ DELAYED 3 ⚠  CXL 1 ✕│ ← exception strip (always visible)
│ Revenue trend ▸       │
│ Trip status ▸         │
│ Branch perf ▸         │
│ Top routes / staff ▸  │
│ Pending approvals 7 ▸ │
│ Alerts ▸              │
│                       │
│ ┌────────────────────┐│
│ ── Dashboard ── Trips ││  ← bottom nav (5 max)
│ ── Ticket ── Cargo ▸▸▸││
└──────────────────────┘
```

- **Bottom nav (5)**: Dashboard · Trips · Ticket · Cargo · More (drawer: Fleet, Finance,
  HR, Reports, Settings, Users, Roles).
- Money quartet is 2×2; everything else is a **drill card list** (summary → tap → detail).
- Exception strip (delayed/cancelled/cash-diff/approvals) stays pinned under the KPIs.
- Never a menu the role lacks; never horizontal scroll; touch targets ≥48px.

---

## 6. Role-based UI (STEP 3)

**Rule:** the menu is computed from the user's permissions — **items are hidden, not
disabled** (blueprint §2.2). No user ever sees a screen they cannot use.

### 6.1 Owner — everything
- **Home:** Owner Dashboard (all 24 facts; all branches; all reports; all users).
- **Create:** Company, Branch, Terminal, Route, Vehicle, Driver, Conductor, Counter,
  User, Role, Permission, Pricing, Branding (logo/colors/receipts/PDF/websites).
- **Modules:** Trips, Ticket, Cargo, Fleet, Finance, HR, Reports, Settings, Users, Roles,
  Approvals (all).
- **Quick actions:** New Trip · New Route · Approve (n) · Export · Manage Branding.
- **Never:** sell/scan/cargo-accept as primary actions (those belong to field roles).

### 6.2 Counter — the POS home
```
┌──────────────────────────────┐
│ Shift · ဆိုင်း (Open · 08:00)│
├──────────────────────────────┤
│ ▓▓ Sell Ticket (big) ▓▓      │
│ ▓▓ Receive Cargo ▓▓          │
│ ▓▓ Online Booking Approve ▓▓ │
│ ▓▓ Print ▓▓                  │
│ Cash: In / Out / Count       │
│ Refund (if permitted)        │
└──────────────────────────────┘
```
- **Sell ticket ≤3 taps**: home → route/time → passenger count/seat → pay/print.
- Modules: Shift, Ticket Sales, Cargo, Online Booking Approval, Printer, Cash, Refund*.
- KPIs: today's sales (this counter), shift balance, cash difference, pending approvals.
- *Refund visible only when the owner grants the permission.

### 6.3 Conductor — trip-first offline flow
```
Today's Trip → Passenger Boarding → Offline Ticket → Offline Cargo → QR → Settlement
```
- Home = **assigned trip** (one screen, no menu hunting).
- Offline-first: tickets/cargo recorded offline, queued, synced on connectivity
  (existing `connectivity_monitor` + offline store).
- Sunlight-usable: high-contrast, large fonts/tap areas.
- Modules: My Trip, Boarding, Offline Ticket, Offline Cargo, QR Scan, Settlement.

### 6.4 Driver
- Home = **Today's Trip** + Trip Sheet.
- Modules: Today's Trip, Trip Sheet, Inspection (pre-departure checklist), Fuel,
  Breakdown (report + call).
- Never sees finance/HR.

### 6.5 Finance
- Home = **P&L** (Revenue / Expenses / Net Profit) + Bank.
- Modules: Revenue, Expenses, Bank, Payroll, Refund, P&L Reports.
- Approves refunds (if granted); never operates a counter.

### 6.6 Manager
- Home = **Operations + Approvals** (pending approvals badge is the hero).
- Modules: Approvals, Operations, Branches, Trips, Reports.
- Views branch performance across branches; no HR/Pricing/Branding/Users admin.

### 6.7 Passenger (separate app)
- Search → Booking → Payment → History → Profile.
- Never sees business data; branding is the operator's (logo/colors on trips/tickets).

### 6.8 Cargo — Cargo Dashboard
- Home = **Cargo Dashboard**: inbound/outbound manifests, pending pickups, in-transit.
- Modules: Manifests, Waybills (auto-numbered), Sender/Receiver (NRC/phone), Pricing
  (by weight / manual), Payment + Receipt, Tracking, Delivered, Settlement.
- Follows the cargo journey in `docs/design_principles.md` §6.4.

### 6.9 Gate — QR Dashboard
- Home = **QR Dashboard**: boarding queue, scan-verify passengers against manifest.
- Modules: QR Scan, Boarding Confirmation, Passenger count vs manifest (gate integrity
  check), No-show / swap handling.
- Works at the departure gate, terminal — offline-tolerant.

### 6.10 Mechanic — Maintenance Dashboard
- Home = **Maintenance Dashboard**: due/past-due services, open repairs.
- Modules: Maintenance Schedule, Inspection Reports, Breakdown Repairs, Parts/Job log.
- Never sees revenue; sees vehicle condition only.

### 6.11 Fleet — Fleet Dashboard
- Home = **Fleet Dashboard**: vehicle status grid (running/maintenance/retired),
  utilization, insurance & road-tax expiry alerts.
- Modules: Vehicles (registration number manual; vehicle code auto), Seat Layouts,
  Maintenance due, Insurance/Road Tax expiries (legal identifiers never auto-generated).

### 6.12 HR — Employee Dashboard
- Home = **Employee Dashboard**: staff list, attendance today, open leave.
- Modules: Employees (employee code auto), Roles, Permissions, Attendance, Payroll.
- Owner-only management of roles/permissions lives here; other roles never see it.

---

## 7. Responsive principles (STEP 4)

Extracted from Google Workspace, Facebook Business, Stripe, Linear, Notion, ClickUp,
HubSpot (research §2.10) and applied to HBT:

1. **Desktop-first, designed independently.** The HBT desktop dashboard is an enterprise
   product (sidebar + top bar + dense KPIs + charts); mobile is a *condensed companion*,
   never an enlarged phone UI.
2. **Breakpoints change layout, not font size**: 0–599 bottom-nav+cards · 600–1023
   rail+2-col · 1024–1439 sidebar+3-col · 1440+ sidebar+4-col, content ≤1680.
3. **No horizontal scroll at any width**; `HbtAdaptiveTable` (table→cards), charts
   reflow, sidebars collapse (already built + validated in `docs/responsive_review.md`).
4. **Priority collapse** (Gmail model): desktop shows table; tablet shows table;
   mobile shows cards — the *same data*, different density.
5. **Command search everywhere** (Stripe/Linear): one search field over
   tickets/trips/vehicles/staff/routes/branches + quick actions.
6. **Thumb-reach primary action** on mobile/tablet (bottom-anchored).
7. **Keyboard shortcuts on desktop** (Linear): ⌘K search, ⌘1-9 nav, G then T = go to
   Trips (power-user path).
8. **Consistent time-range control** drives every widget on the dashboard.

---

## 8. Screen inventory (Owner role, desktop)

| # | Screen | Content | Justification (research) |
|---|--------|---------|--------------------------|
| O-1 | Dashboard | 18 KPI cards + 2 charts + 3 rank panels + P&L + activity + approvals + alerts + announcements + PDF/Excel export | 5-second gate (§2) + 55-year-old test |
| O-2 | Trips (list) | Filters: date/branch/route/status; chips; drill to trip detail | Logistics OTP (§1) |
| O-3 | Trip detail | Timeline stepper (depart→arrive), manifest, revenue, settlement | Logistics timeline |
| O-4 | Ticket sales | Table + day chart; export PDF/Excel | Financial |
| O-5 | Cargo | Inbound/outbound manifests; revenue; waybills | Logistics |
| O-6 | Fleet | Vehicle table (status chips), maintenance due, utilization | Fleet |
| O-7 | Finance | Revenue/Expenses/Bank/Payroll/Refunds/P&L; approvals | Financial |
| O-8 | HR | Staff, roles, permissions, attendance, payroll | ERP |
| O-9 | Reports | Saved reports, time filters, PDF/Excel export | BI |
| O-10 | Settings | Company, branding, branches, terminals, pricing | ERP admin |
| O-11 | Users & Roles | User list, role matrix (permission checkboxes) | ERP admin |
| O-12 | Approvals | Queue: refunds, expenses, leave; approve/reject with audit | ERP approvals |

---

## 9. What "done" looks like (validation gate)

Per `docs/dashboard_gap_analysis.md` after implementation walkthrough:
**0 P0, 0 P1, ≤3 P2 per screen; every screen 0–100 scored against this blueprint.**
No screen ships until its mandatory facts, actions, reports, navigation, and charts
are present per the matrix above.

**Every screen must also pass the 55-year-old test and the workload test**
(`docs/design_principles.md` §8, §13): understandable without training AND proven to
reduce the company's workload — otherwise the workflow is redesigned before code is
written.
