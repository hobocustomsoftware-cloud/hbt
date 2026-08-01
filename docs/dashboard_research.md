# HBT — Dashboard Research: Enterprise Admin Dashboard Best Practices

**Date:** 2026-08-01
**Author:** Product Designer / UX Researcher / Enterprise Dashboard Architect
**Purpose:** Research baseline for the HBT Owner Dashboard and role-based UI. Every HBT
design decision in `docs/hbt_dashboard_design.md` is justified against a pattern in this
document.

---

## 0. Methodology & sources

- **Live web research was unavailable at authoring time** (search provider disabled;
  article URLs 404). This document is therefore compiled from **structured expert
  analysis** of the named products (public design systems, documented design decisions,
  and observed behavior of the current production UIs) and from **established dashboard
  literature**:
  - Shneiderman, *Visual Information-Seeking Mantra* — "Overview first, zoom and filter,
    then details-on-demand."
  - Tufte, *The Visual Display of Quantitative Information* — data-ink ratio, chart junk.
  - Few, *Information Dashboard Design* — at-a-glance, actionable metrics over vanity
    metrics, exception highlighting, sparklines.
  - NN/g research on scanning patterns (F-pattern), progressive disclosure, and
    "information scent."
  - Gestalt grouping principles; Hick's Law (choice time vs # of options); Miller's 7±2
    (modern practice: ≤5–7 top-level nav items); the 5-second usability test method.
- **Products studied** (direct knowledge of current production UIs):

| Category | Systems |
|---|---|
| ERP | SAP Fiori, Odoo, NetSuite, Microsoft Dynamics |
| CRM | Salesforce, HubSpot, Pipedrive |
| POS | Square, Lightspeed, Toast |
| Fleet | Samsara, Fleetio, Geotab |
| Logistics | FourKites, Project44, Transporeon |
| Financial | Stripe, QuickBooks, Xero |
| BI | Tableau, Power BI, Looker |
| SaaS refs | Google Workspace, Facebook Business Suite, Linear, Notion, ClickUp |

---

## 1. What each category does best

### ERP (SAP Fiori / Odoo / NetSuite)
- **Role-based workspaces** — a user lands on *their* job's home, not a generic page.
- **Approval centers** — "My Approvals" is a first-class destination with count badges.
- **Transaction/search codes** — power users jump anywhere by typing (Fiori search).
- Dense tables with saved views/filters per user.

### CRM (Salesforce / HubSpot / Pipedrive)
- **Pipeline as the home** (Pipedrive) — the funnel *is* the dashboard.
- **Record-centric activity timeline** — every entity shows history in one column.
- **Reporting hub separated from day-to-day ops** — reports are a destination, not the home.
- Deals/rows show stage, owner, value, next action in one glance.

### POS (Square / Lightspeed / Toast)
- **"Today" is the hero** — big sales number, open orders, shift status on load.
- **Large touch-target action grid** — Sell / Refund / Open drawer / End shift.
- **Shift & cash drawer is a first-class object** — open/close, count, difference.
- Perfect model for the HBT **Counter** screen.

### Fleet (Samsara / Fleetio / Geotab)
- **Map + status badges** — live vehicle states (moving/idle/stopped/alarm) with color.
- **Exception-first alerts feed** — speeding, idling, off-route pushed to top.
- **Utilization & maintenance dashboards** — hours used, next service due.
- Model for HBT **Vehicle Status / Driver Attendance** panels.

### Logistics (FourKites / Project44)
- **On-time performance (OTP) is the headline KPI** — % on-time with trend.
- **Shipment timeline** — one shipment's journey as a horizontal stepper.
- **Exception management** — delays/cancellations surfaced as actionable lists.
- Model for HBT **Trip Status** (running/delayed/cancelled) panel.

### Financial (Stripe / QuickBooks / Xero)
- **Cash position at top** — available / pending / total in one strip.
- **Mini P&L with trend** — revenue, expenses, profit as sparklines.
- **Bank feed reconciliation** — unmatched items are a work queue.
- **Pending approvals/refunds** as an action list, never buried.
- Model for HBT **money quartet + cash/bank + refunds** panels.

### BI (Tableau / Power BI / Looker)
- **Importance-first layout** — most important metric top-left, least bottom-right
  (F/Z scanning).
- **Pre-attentive attributes** — color/size/position encode meaning *before* reading.
- **Overview → drill path** — every chart leads to a filtered detail view.
- **Consistent time-range control** — one control (day/week/month) drives all widgets.

### SaaS references (the "enterprise feel" bar)

| Product | Signature pattern |
|---|---|
| **Stripe Dashboard** | Global search/command bar; balance strip; today's volume + trend chart; recent-transactions table with inline filters; per-row hover actions; calm empty states; superb type hierarchy |
| **Google Workspace** | Top app bar with global search + app launcher; left nav; right-side contextual panels; graceful column collapse (mail → list → preview) |
| **Facebook Business Suite** | Icon rail (collapsible); Home = overview tiles + charts; bulk actions in tables; notification bell with unread counts |
| **Linear** | Keyboard-first; command menu (⌘K) for everything; Inbox as triage queue; density toggle; zero decorative clutter |
| **Notion** | Search-first sidebar; template-driven empty states; sections for navigation groups |
| **ClickUp** | Add-widget dashboard canvas (user-configurable); multiple views of the same data (list/board/table/chart); dense sidebar with grouping |

---

## 2. Extracted best practices

### 2.1 Dashboard layout
1. **F/Z importance-first**: most critical metric top-left; descending importance
   rightward/downward. (BI, financial)
2. **Structured zones, not free-form**: header strip → KPI row(s) → primary chart →
   secondary panels (tables/lists) → feed. Users read in this order.
3. **Hero number**: one number dominates (Square: today's sales; Stripe: today's volume).
4. **Content column ≤ 1680px** on ultra-wide; whitespace carries hierarchy.
5. **Everything on the dashboard is a drill target** — every KPI/chart opens the filtered
   detail view (Shneiderman: overview → zoom → details-on-demand).

### 2.2 Navigation
1. **≤7 top-level destinations**, grouped into 3–5 sections (label, not just icon).
2. **Collapsible sidebar on desktop** (icons ↔ icons+labels) — GWS, FB, Linear.
3. **Role-computed menu**: menu = f(user permissions). What you can't do doesn't exist
   (ERP role-based workspaces). **Never show a menu item the user lacks permission for.**
4. **Global search as a command bar** (Stripe `/`, Linear ⌘K): search entities *and*
   run actions from one field.
5. **Breadcrumbs on desktop** for depth > 1.
6. **Branch/company switcher in the top bar** for multi-entity owners.

### 2.3 Information hierarchy
1. **Money first, operations second, people third** (financial + logistics rule).
2. **5-second test as a design gate**: after login, the eye must land on today's money
   truth, what's broken, and what needs approval — nothing else competes.
3. **Status encoded with color before text** (pre-attentive): green/amber/red for
   running/delayed/cancelled; cash difference positive/negative.
4. **Progressive disclosure**: summary on the dashboard, detail one click away; never
   dump a 40-column grid on the home.
5. **Consistent scoping**: one time-range control (Today/Week/Month/Year) drives every
   widget (BI rule).

### 2.4 KPI cards
1. **Structure**: value (large, tabular numerals) + label + trend (▲/▼ + % vs same period)
   + optional sparkline. (Stripe, QuickBooks, HubSpot)
2. **Semantic color**: growth green / decline red / neutral grey; no rainbow.
3. **Click = drill** into that metric's report.
4. **Grouping by meaning**: 4 money KPIs in one row reads as a P&L; mixing money and
   trips in one row destroys the story (Gestalt proximity).
5. **Actionable over vanity**: "Pending approvals (7)" beats "Total customers (4,212)".

### 2.5 Charts
1. **One chart type per message**: line = trend over time; bar = comparison; donut =
   share of total; gauge/sparkline = status. Don't mix on one question.
2. **Trend with context**: revenue chart shows today vs yesterday or last period, not a
   bare line.
3. **Drill-down on click**; hover tooltips for exact values; Myanmar numerals in labels.
4. **Limit to 3–5 charts** on the home; everything else lives in Reports.
5. **No 3D, no pie-overload, no chart junk** (Tufte data-ink ratio).

### 2.6 Quick actions
1. **The 3 most common jobs get persistent, large actions** (POS: Sell; ERP: New …).
2. Mobile/tablet: **bottom-anchored primary action** (thumb reach).
3. Counter rule (HBT): **sell a ticket in ≤3 taps** — the sell action is always one tap
   from the counter home, never behind a menu.
4. Quick actions sit **above the fold**, visually distinct from nav (FAB or primary
   button row), never mixed with data cards.

### 2.7 Tables
1. **Sortable, filterable, searchable** — always; pagination or virtual scroll.
2. **Row hover → inline actions** (Stripe) — avoids cluttered action columns.
3. **Status chips** instead of raw text for state columns.
4. **Responsive: table → card list below 600px** (HBT `HbtAdaptiveTable`), never
   horizontal scroll on mobile.
5. **Saved views/filters** for power users (ERP standard).

### 2.8 Activity feed
1. **Reverse-chronological, one-line entries**: actor + action + object + time
   ("U Ko Ko settled Trip YM-0801 · 2m ago").
2. **Filterable by type** (sales/cash/trips/system); silent system noise excluded.
3. **Click → the record**, not a dead row.
4. Lives bottom-right as secondary content — never above the money.

### 2.9 Notifications
1. **Bell with unread count badge**, grouped (today/earlier), click → center.
2. **Types**: pending approvals, exceptions (delayed/cancelled trips, cash difference),
   system (offline sync). Owner gets approvals + exceptions; staff get exceptions.
3. **Actionable**: each notification has a primary action ("Review", "Approve").
4. Silent for success; loud only for exceptions (Few: exception highlighting).

### 2.10 Responsive desktop (enterprise quality)
1. **Desktop is designed first and independently** — not an enlarged mobile UI
   (Google Workspace, Stripe: the desktop is the product; mobile is a companion).
2. **Breakpoint = layout change, not font change**: sidebar ↔ rail ↔ bottom-nav;
   table ↔ cards; KPI 4-col → 2-col.
3. **No horizontal scroll at any width**; tables adapt, never clip.
4. **Multi-pane collapse with priorities** (Gmail: keep list, drop preview below 900px).
5. **Content max-width with centering** on ultra-wide (1680) — no stretched lines.
6. **Keyboard + shortcuts on desktop** (Linear) — power users live on the keyboard.

---

## 3. Anti-patterns (what we will NOT do)
- Vanity KPIs with no action attached (counters nobody acts on).
- 12 charts on the home (dashboard becomes a museum).
- Raw 3-digit colour-coded status text without chips.
- Menu items that exist but error "no permission".
- Mobile UI stretched to fill a 2560px screen (no max-width).
- Tables with horizontal scroll on phones.
- Notifications that say nothing actionable ("System updated").
- Mixing money and trip metrics in one unlabelled row.

---

## 4. Application to HBT (bridge to design doc)

| Best practice | HBT application |
|---|---|
| Hero number + money quartet | Today's Ticket / Cargo / Expenses / Net Profit as the top row |
| Exception-first | Delayed/Cancelled trips + cash differences + pending approvals visible on load |
| Role-computed menu | Owner/Counter/Conductor/Driver/Finance/Manager each get a distinct menu |
| POS action grid | Counter home: Shift / Sell Ticket / Receive Cargo / Online Booking / Print / Cash |
| Pipeline-as-home → Trip-as-home | Conductor home = Today's Trip → Boarding → Offline Ticket/Cargo → QR → Settlement |
| Command bar search | Top-bar search over tickets/trips/vehicles/staff/routes |
| Cash position strip | Counter cash + bank balance + outstanding refunds on the Owner dashboard |
| OTP headline | Trip status panel: running / delayed / cancelled counts + % on-time |
| Table→cards + sidebar/rail/bottom-nav | Already implemented in the HBT design system (`hbt_responsive.dart`) |
| Drill-everything | Every KPI/chart opens the filtered report (Reports module) |
