# HBT — UI Master Blueprint

**Version:** 1.0 · **Date:** 2026-08-01
**Author:** CPO / UX Director / Transport Operations Director
**Status:** Design contract — governs all role implementation (Owner → Counter → Conductor → Passenger).
**Companion docs:** `business_operation_blueprint.md` (business spec), `role_permission_matrix.md`
(permissions), `runtime_gap_analysis.md` (current gaps). This document defines **what the UI is**.

---

## 0. Design principles

1. **One app per audience.** One Business App (all staff roles), one Passenger App,
   one Booking Website, one Corporate Website. Never more.
2. **Role decides UI.** After login the navigation, dashboards, and actions are computed
   from the user's roles + permissions. A user NEVER sees a menu they cannot use.
3. **Business over implementation.** If existing screens conflict with these rules, they
   are redesigned — the blueprint wins.
4. **The trip is the unit.** All operational screens anchor to trips (crew, vehicle,
   seats, cargo, cash, events).
5. **Cash is sacred.** Every money screen shows: actor, context, amount, and a clear
   audit trail; approvals are visible and separable.
6. **Offline-first.** Field roles (counter, conductor, driver, gate) work fully offline
   and sync; the UI shows online/offline state always.
7. **Branding is automatic.** The whole UI (web + apps + tickets + receipts + PDFs)
   inherits the company brand (logo, colors, templates) — no per-screen theming.
8. **Myanmar is default.** Every string, validation, notification, report, and receipt
   ships in Myanmar (Burmese) with English as an optional language.

---

## 1. Application map

| App | Audience | Platform | Entry |
|-----|----------|----------|-------|
| **Business App** | All staff: Owner, Manager, Counter, Conductor, Driver, Gate, Cargo, Finance, Fleet, HR, Mechanic | Flutter (mobile + web) | Role-aware login |
| **Passenger App** | Passengers | Flutter (mobile + web) | Login/register |
| **Booking Website** | Public (book without app) | Web | Public search |
| **Corporate Website** | Public (marketing/B2B) | Web | Public |

All four share: branding service, localization, fare/payment/cargo APIs, notification
channels. One backend.

---

## 2. Screen hierarchy (Business App)

```
Login (phone + password, Myanmar default)
└── App Shell (role-computed)
    ├── Navigation Rail / Bottom Nav (role-filtered)
    ├── Global header: org switcher · online/offline · language · user menu
    └── Role Home (each role lands on its OWN dashboard)
```

### 2.1 Role home screens

| Role | Landing dashboard | Primary nav (visible) |
|------|-------------------|------------------------|
| **Owner** | Business Dashboard (KPIs, charts, exports) | Dashboard · Finance · Reports · Fleet · Users · Settings |
| **Manager** | Ops Board (today's trips, alerts, approvals) | Dashboard · Trips · Crew · Approvals · Monitoring · Reports |
| **Counter** | Shift/Till card + quick sell | Booking · Cargo · Shift · Printer · Refunds |
| **Conductor** | Assigned Trip card | Assigned Trip · Offline Booking · Cargo · QR · Waybill · Settlement |
| **Driver** | Today's Trip card | Trip Sheet · Inspection · Fuel · Breakdown |
| **Gate** | Trip Manifest list | Manifest · Validate · Boarding · Dispatch |
| **Finance** | Settlement queue | Settlement · P&L · Bank · Payroll · Approvals |
| **Cargo staff** | Shipment worklist | Shipments · Pricing · Claims · Tracking |
| **Fleet** | Fleet availability | Vehicles · Maintenance · Fuel · Layouts |
| **HR** | Roster + attendance | Staff · Rosters · Attendance · Documents |
| **Mechanic** | Work orders | Work Orders · Inspections · Parts · Repairs |

### 2.2 Navigation rules
- The nav is generated from `RoleMenuConfig` = (permission set) → menu items.
- Owner edits roles → menu changes for affected users on next login/refresh.
- Hidden items are **removed**, not disabled (no "you can't do this" screens).
- Every screen enforces its own permission on load (defense in depth: UI + API).

---

## 3. Owner Dashboard (the flagship screen)

### 3.1 Layout (12-column grid, responsive)

```
┌────────────────────────────────────────────────────────────────────┐
│ HEADER:  Shwe Yoke Lay Express      [Switch org] [MM/EN] [User]   │
├────────────────────────────────────────────────────────────────────┤
│ KPI ROW (8 cards, 4x2 on mobile)                                  │
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                       │
│ │Today's │ │Today's │ │Today's │ │Today's │                       │
│ │Ticket  │ │Cargo   │ │Net     │ │Expenses│                       │
│ │Sales   │ │Revenue │ │Profit  │ │        │                       │
│ ├────────┤ ├────────┤ ├────────┤ ├────────┤                       │
│ │Trips   │ │Trips   │ │Passen- │ │Cargo   │                       │
│ │Running │ │Comple- │ │gers    │ │Today   │                       │
│ │        │ │ted     │ │Today   │ │        │                       │
│ └────────┘ └────────┘ └────────┘ └────────┘                       │
│ SECOND ROW (8 cards)                                              │
│ Bank Balance · Outstanding Refunds · Cash Difference · Pending    │
│ Approvals · Driver Attendance · Vehicle Availability              │
├────────────────────────────────────────────────────────────────────┤
│ CHARTS                                                            │
│ ┌────────────────────────┐ ┌────────────────────────┐             │
│ │ Revenue trend (line)   │ │ Sales by route (bar)   │             │
│ ├────────────────────────┤ ├────────────────────────┤             │
│ │ Sales by branch (bar)  │ │ Top staff (list)       │             │
│ └────────────────────────┘ └────────────────────────┘             │
│ RANKINGS                                                        │
│ Top Routes · Top Branches · Top Staff (tables)                   │
│ EXPORT BAR:  [Daily] [Weekly] [Monthly] [Yearly]  [PDF] [Excel]  │
└────────────────────────────────────────────────────────────────────┘
```

### 3.2 KPI definitions
| KPI | Source | Notes |
|-----|--------|-------|
| Today's Ticket Sales | sum(tickets) today | by org |
| Today's Cargo Revenue | sum(cargo charge lines) today | |
| Today's Net Profit | ticket + cargo − expenses today | |
| Today's Expenses | sum(expenses) today | |
| Trips Running | trips in boarding/departed/in_progress | live |
| Trips Completed | trips completed/closed today | |
| Passengers Today | distinct passengers boarded today | |
| Cargo Today | shipments accepted today | |
| Bank Balance | sum(deposits) − sum(withdrawals) | finance ledger |
| Outstanding Refunds | refunds requested/approved not paid | |
| Cash Difference | Σ |till expected − counted| open shifts | |
| Pending Approvals | open refund/settlement/expense/override items | |
| Driver Attendance | drivers assigned today vs confirmed | |
| Vehicle Availability | vehicles available vs fleet total | |

### 3.3 Charts
- **Revenue trend** — line, 30 days, ticket + cargo series.
- **Sales by route** — bar, top 10.
- **Sales by branch** — bar.
- **Top staff** — list with sales + variance.
- Period control: Daily / Weekly / Monthly / Yearly.
- **Export:** PDF (branded) + Excel (CSV/XLSX) buttons on every chart and the KPI summary.

---

## 4. Widget hierarchy (design system)

```
DesignTokens (colors from brand, spacing, radius, type)
├── HbtApp (shell: locale, theme, connectivity, idle lock)
│   ├── RoleNavigator (menu from permissions)
│   ├── AppHeader (org switcher, lang, user)
│   ├── ConnectivityBanner
│   └── PageFrame (title + actions + scroll)
├── KpiCard (value, label, delta, icon, sparkline)
├── ChartCard (title, chart, export)
├── DataTable (sortable, paginated, export)
├── FormField family (phone, NRC, money, search)
├── StatusChip (trip/cargo/ticket/settlement statuses)
├── ApprovalCard (requester, amount, actions: verify/approve/reject)
├── TicketView (branded ticket render)
├── ReceiptView (branded receipt render)
├── WaybillView (conductor trip sheet)
├── SeatMap (deck/rows/cols, lock/held/occupied states)
├── OfflineIndicator (queue count, sync button)
└── EmptyState / ErrorState / LoadingState (skeleton)
```

Every widget: Myanmar + English strings, brand-aware colors, RTL-safe layout where
relevant, keyboard + a11y support.

---

## 5. Permission visibility (concrete)

- `MenuNode { id, label, icon, permission, children }`.
- `buildNav(user)` filters MenuNode tree by `user.permissions`.
- Examples of hidden-by-role:
  - `route.manage`, `fare.manage`, `user.manage` → never visible to Counter.
  - `settlement.approve`, `bank.reconcile`, `payroll.run` → never visible to Counter/Conductor.
  - `ticket.sell`, `cargo.accept`, `shift.manage` → never visible to Driver/Finance-only users.
  - Owner sees all; **Owner never sees sell/scan/cargo-accept as primary actions**
    (they exist only if the Owner also holds the staff role).
- Route guards: `PermissionGuard` wraps routes; unauthorized → 403 screen with "Contact
  your administrator", not a blank page.

---

## 6. Branding system

### 6.1 What each company configures (branding admin, Owner-only)
| Field | Type |
|-------|------|
| Logo | image upload |
| Primary color | color picker |
| Secondary color | color picker |
| Receipt header / footer | text + logo |
| Company name | text (EN + MM) |
| Phone / address | text |
| Ticket template | selectable layout (A5/A6, fields) |
| QR style | preset (rounded, color, logo-in-center) |

### 6.2 Propagation (automatic, zero per-screen work)
- **Design tokens** at app start: `ColorScheme.fromSeed(brand.primary)`, secondary, logo asset.
- **Tickets/receipts/PDFs**: rendered from the same `TicketTemplate` engine → header, colors, QR.
- **Booking Website + Corporate Website**: CSS variables from brand endpoint.
- **Passenger App**: shows operator branding on the trip detail/booking screens (which
  company's bus), while the app chrome stays neutral (multi-operator).
- **Business App**: the whole chrome is the active organization's brand; switching org
  re-themes instantly.

### 6.3 Cache & offline
- Branding payload cached locally (logo + tokens) so tickets print branded even offline.

---

## 7. Localization (Myanmar default)

- **Default locale: `my` (Burmese).** English selectable via header toggle; per-device persisted.
- Full string extraction to `AppLocalizations` (ARB): UI, validations, errors,
  notifications, reports, receipts, tickets.
- Date/time/number formats follow locale (MMK currency formatting, Myanmar numerals toggle).
- All API error messages mapped to localized strings (never raw server text).
- Booking Website + Corporate Website: `?lang=my|en` + browser detection, `my` default.
- Notifications/SMS: sent in the user's chosen language (Myanmar default).

---

## 8. Demo data strategy (realistic Myanmar ecosystem)

Purpose: dashboards/charts/reports look real; journeys can be exercised end-to-end.

### 8.1 Scale
| Entity | Count | Notes |
|--------|-------|-------|
| Companies (orgs) | 20 | mix of active + 1 suspended |
| Branches | ~40 | 1–3 per company |
| Terminals | 25 | real Myanmar cities: Yangon (Aung Mingalar, Hlaing Thar Yar, Dagon Seikkan), Mandalay (Kyaw Zay, Chan Mya Tharsi), Naypyidaw, Taunggyi, Mawlamyine, Myeik, Pathein, Bago, Pyay, Meiktila, Lashio, Myitkyina |
| Routes | 150 | Yangon↔Mandalay (day/night), Yangon↔Taunggyi, Mandalay↔Lashio, Yangon↔Mawlamyine, etc. |
| Vehicles | 500 | brands: Hino, Yutong, King Long, Scania, Fuso; 24–45 seats |
| Schedules | 300+ | morning/night patterns, 7-day operating |
| Trips | 1000 | today ±7 days, statuses spread (planned/ready/boarding/departed/completed/cancelled/delayed) |
| Staff | 100 | drivers + conductors + counters + managers per company |
| Passengers | 5000 | Myanmar names, NRC-format IDs, phone +95 9… |
| Bookings/Tickets | 8000+ | spread over last 30 days for realistic charts |
| Cargo shipments | 3000 | parcel/box/valuable, per-kg pricing, statuses |
| Expenses | 2000 | fuel, tolls, meals, parking, repairs |
| Refunds | 150 | various statuses (requested → paid) |
| Payments | 8000 | cash / KBZ Pay / Wave Pay / bank transfer evidence |
| Shift records | 600 | open/closed with opening cash + difference |
| Settlements | 300 | pending → approved |

### 8.2 Generator rules
- Names: realistic Burmese names (U/Ko/Daw/Ma prefixes), cities, phone +95 9XXXXXXXXX.
- Fares: distance-based (Yangon–Mandalay ≈ 25,000–35,000 MMK, 620 km; per-km rule).
- Cargo: 2,000–15,000 MMK per parcel by route distance.
- Time distribution: evening bookings peak (6–10pm), festival spikes (Thingyan period
  multiplier ×2.5).
- Status mix reflects time of day the seed runs (today's morning trips completed,
  midday in_progress, evening planned).
- Deterministic seed (fixed RNG seed) so re-runs don't duplicate; idempotent upserts.

### 8.3 Tooling
- `backend/scripts/seed_demo_ecosystem.py` (new) — runs in <2 min, prints summary.
- Dev-only: gated by `DEBUG` or `HBT_DEMO_SEED=1`; never in production path.

---

## 9. Booking Website + Corporate Website (summary screens)

### 9.1 Booking Website
Public: trip search (city → city, date) → results → seat pick → booking → payment
(cash/transfer/e-wallet) → passenger login → ticket download/QR → **Track Bus**
(live trip position via trip events) → notifications.

### 9.2 Corporate Website
Company profile, branches, routes, fleet showcase, cargo service, news, careers, contact.
Fully branded, Myanmar + English.

---

## 10. Implementation order (one role at a time)

| Phase | Role | Gate |
|-------|------|------|
| 1 | **Owner** | Dashboard + branding + localization + demo data + Users/Roles admin |
| 2 | **Counter** | Sell/refund/shift/cargo/printer, permission-hidden nav |
| 3 | **Conductor** | Waybill/offline sales/QR/settlement |
| 4 | **Passenger** | Full journey + Track Bus + notifications |

Each phase: implement → launch backend + web → browser walk → screenshots →
`docs/ui_review_<role>.md` → fix → repeat until production quality → **user approval**
before next role.

---

## 11. Acceptance criteria (per role)

- [ ] User logs in and lands on the role's own dashboard.
- [ ] Every visible menu item is permitted; no permission-less menu is visible.
- [ ] All strings appear in Myanmar (default) and English.
- [ ] Branding (logo/colors/templates) applies across screens + tickets.
- [ ] Offline/online state is visible; field roles can do their core job offline.
- [ ] Dashboards show realistic data (from demo seed) with working charts + exports.
- [ ] Screenshots captured for each journey step; review doc written.
- [ ] Full test suite green; analyze clean; app runnable.
