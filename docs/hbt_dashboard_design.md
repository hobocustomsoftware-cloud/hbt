# HBT — Owner Dashboard & Role-Based UI Design

**Date:** 2026-08-01
**Author:** Product Designer / UX Researcher / Enterprise Dashboard Architect
**Status:** Design proposal — awaiting approval. No code until approved.
**Derived from:** `docs/dashboard_research.md` (every pattern cited), `docs/ui_master_blueprint.md`,
`docs/design_system.md` (tokens #AA0000/#151515, HbtAdaptiveScaffold, HbtKpiGrid, HbtAdaptiveTable).

---

## 1. Design principle

> **"If I owned a transport company, what would I want to know within 5 seconds of login?"**

Answer: **today's money truth, what is broken, and what needs my approval.**
Nothing else may compete for the first five seconds. Everything else is one click away.

The 5-second test is the acceptance gate for every dashboard screen (research §2.3).

---

## 2. The Owner's 18 facts, organized

All 18 mandated facts are on the Owner dashboard, arranged by **operational gravity**
(research: money first, operations second, exceptions and approvals third):

| Zone | Facts | Format |
|---|---|---|
| **A. Money quartet** | 1 Ticket Revenue · 2 Cargo Revenue · 3 Expenses · 4 Net Profit | 4 large KPI cards, first row |
| **B. Trip operations** | 5 Running · 6 Delayed · 7 Cancelled Trips · 8 Passengers · 9 Cargo Today | 6 compact KPI cards (incl. derived On-Time %) |
| **C. Cash & pending** | 10 Cash in Counters · 11 Bank Balance · 12 Pending Refunds · 13 Pending Approvals | 4 KPI cards with drill links |
| **D. Trends** | Revenue trend · Trip status mix | Charts |
| **E. Performance** | 14 Branch Performance · 15 Top Routes · 16 Top Staff | Charts + ranking lists |
| **F. Fleet & people** | 17 Vehicle Status · 18 Driver Attendance | Status panels |
| **G. Pulse** | Recent activities · Pending approvals · Alerts | Feeds |

**Delayed trips, cancelled trips, cash differences, and pending approvals are
color-alerted (amber/red) the moment they are non-zero** (research: exception-first).

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
│              │  ┌───────────────────────────┬────────────────────────────┐  │
│              │  │ Revenue trend (30d line)  │ Trip status (donut)        │  │
│              │  │   ▁▃▅▂▄▆▇▅▆▇█▇▆▅▆▇       │  ● Run 24  ● Dly 3 ● Cxl 1│  │
│              │  └───────────────────────────┴────────────────────────────┘  │
│              │  ┌───────────────┬───────────────┬────────────────────────┐  │
│              │  │ Branch perf   │ Top routes    │ Top staff              │  │
│              │  │ (bar)         │ (bar)         │ (rank list w/ sales)   │  │
│              │  └───────────────┴───────────────┴────────────────────────┘  │
│              │  ┌──────────────┬──────────────────┬───────────────────────┐  │
│              │  │ Vehicle st.  │ Driver attendance│ Recent activity      │  │
│              │  │ 40/45 avail  │ 18/20 present    │ · U Ko settled YM-08… │  │
│              │  │ ▓▓▓▓▓▓░░░░   │ ▓▓▓▓▓▓▓▓▓░       │ · Refund #334 apprv…  │  │
│              │  └──────────────┴──────────────────┴───────────────────────┘  │
│              │  Alerts: 2 delayed · 1 cancelled · cash diff +12,000 · see all│
└──────────────┴──────────────────────────────────────────────────────────────┘
```

**Layout rules (desktop):**
- Top bar: brand · global search (entities + actions, ⌘K) · notifications bell (badge) ·
  branch switcher · profile.
- Sidebar 248px, collapsible to 72px icons; 4 groups: **Operate** (Dashboard, Trips,
  Ticket, Cargo), **Manage** (Fleet, Finance, HR), **Insight** (Reports), **Admin**
  (Settings, Users, Roles).
- KPI rows: 4 + 5 + 4 = 13 cards; each card = value + trend + drill.
- Charts ≤ 3 on home; every chart drills into Reports with the same time filter.
- Content max-width 1680 on 1440+; centered, no stretching.

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
│          │ Top routes ▸ · Top staff ▸ (cards)│
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
- **Home:** Owner Dashboard (all 18 facts; all branches; all reports; all users).
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
| O-1 | Dashboard | 13 KPI cards + 3 charts + 3 rank panels + vehicle/driver panels + activity + alerts | 5-second gate (§2) |
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
