# HBT — Platform Design Principles & Business Rules (The Charter)

**Date:** 2026-08-01
**Author:** Product Designer / UX Researcher / Enterprise Dashboard Architect
**Status:** Charter — supersedes earlier KPI/role lists where they conflict.
**Scope:** Every screen, workflow, model, and setting in the HBT platform
(Business App, Passenger App, Booking Website, Corporate Website).

---

## 1. Core principle

> **HBT is NOT a ticket selling system.**
> **HBT is a complete Myanmar Transport Operating Platform.**

Every feature must solve a real business problem for Myanmar transport companies.
Optimize for:

1. **Business simplicity** — a workflow confusing to a first-time owner must be
   redesigned, not documented.
2. **Offline-first** — field roles (conductor/driver/gate) never stop working without
   internet; queues sync when connectivity returns. **Offline is a normal operating
   mode, not an emergency feature** (§16).
3. **Cash integrity** — every cash node has an actor, a count, and a difference record;
   cash is sacred.
4. **Fraud prevention** — system-generated numbers, audit trails, seat-lock conflicts,
   ticket/cargo/refund controls.
5. **Speed of operation** — reduce clicks, typing, and training time. **Maximum 3 taps
   for common operations.**
6. **Zero IT knowledge required** — the 55-year-old owner test (§8) gates every screen.
7. **Decision-first dashboards** — a dashboard that only displays data is a failure;
   every dashboard must help the user make a business decision (§12).
8. **Workload test** — every feature must answer *"Will this reduce the workload of a
   Myanmar transport company?"* If not, the feature should not exist (§13).
9. **Full tenancy isolation** — one company can never see another company's data (§10).
10. **Complete audit trail** — every financial action records Who/When/Where/Device/
    Counter/Shift/Branch/Reason/Approval/History; **nothing financial is ever deleted,
    only reversed** (§11).
11. **Seasonality-aware** — Thingyan, public holidays, peak season, festival routes,
    holiday pricing/capacity, special trips (§17).

Never design generic CRUD. Every screen is justified by a real operational need.

---

## 2. System-generated vs user input

### 2.1 Auto-generated (users NEVER type these)
| Identifier | Pattern principle |
|---|---|
| Route Code | Auto from origin–destination + sequence (e.g., `YGN-MDY-01`) |
| Vehicle Code | Internal asset code (e.g., `V-0001`), distinct from registration |
| Trip Number | Date + schedule code (e.g., `YM-0801`) |
| Booking Number | Auto, org-scoped, sequential |
| Ticket Number | Auto, org+day sequential, printable on receipt |
| Cargo Number | Auto (`CG-…`) |
| Waybill Number | Auto, linked to cargo number |
| Invoice Number | Auto, org-scoped |
| Expense Number | Auto (`EX-…`) |
| Receipt Number | Auto, per counter/shift |
| Shift Number | Auto, per counter per day |
| Employee Code | Auto (`E-0001`) |

The app generates, displays, and prints them. No text field ever asks a user to type
a number the system owns.

### 2.2 Manual user input (legal identifiers — NEVER auto-generated)
| Identifier | Example |
|---|---|
| Vehicle Registration Number | `YGN-15 1P-2325` |
| NRC | `12/MaHaNa(N)123456` |
| Passport | `MM-1234567` |
| Driving License Number | — |
| Phone Number | `+9597…` |
| Bank Account | — |
| Insurance Number | — |
| License Expiry (date) | — |

These are legal identifiers recorded once at setup, validated by the user, never
fabricated by the system.

---

## 3. Company setup flow (Owner, once)

```
Company → Logo → Business Information → Branches → Counters → Vehicles → Seat Layout
→ Routes → Schedules → Employees → Roles → Business Settings → Cargo Settings
→ Payment Settings → Branding → Finish
```

- Stepper wizard, one concern per step, progress persisted (resumable).
- Every step skippable-with-warning except Company + Owner (already done in onboarding)
  and Branches; missing data surfaces as dashboard nudges, not blocks.
- After **Finish**: the Owner Dashboard is fully live (all 24 facts in §4).

---

## 4. Owner dashboard — the full spec (supersedes the earlier 18)

Owner never performs daily operations — **Owner only manages the business.**

| Zone | Facts | Format |
|---|---|---|
| **A. Money quartet** | Today's Ticket Revenue · Today's Cargo Revenue · Today's Expenses · Today's Net Profit | 4 large KPI cards (net profit is the hero) |
| **B. Trip operations** | Trips Running · Trips Delayed ⚠ · Trips Completed · Passengers Today · Cargo Today · On-Time % | 6 compact KPI cards; delayed/completed color-coded |
| **C. Cash & pending** | Cash in Counters · Bank Balance · Pending Refunds · Pending Approvals | 4 KPI cards with drill links |
| **D. Fleet & people** | Vehicles Running · Vehicles Under Maintenance · Driver Attendance · Counter Performance | 4 status tiles |
| **E. Trends** | Revenue Trends (Weekly/Monthly/Yearly toggle) · Expense Breakdown | 2 charts |
| **F. Performance** | Branch Performance · Top Routes · Top Vehicles | 3 ranking panels |
| **G. Profit** | Profit & Loss mini (period) | card → full P&L report |
| **H. Pulse** | Recent Activities · Pending Approvals · Alerts · Announcements | feeds |

**Plus:** Quick Actions (New Trip · New Route · Approve (n) · Export PDF/Excel ·
Announce) · Notifications bell · Announcements feed.
**Exports:** PDF + Excel on every KPI group and the whole dashboard.

5-second gate: money quartet → exceptions (delayed/cancelled/cash-diff) → approvals.
Everything else is one click away.

---

## 5. Role home screens (each role = different home)

| Role | Home = | Core modules |
|---|---|---|
| **Owner** | Executive Dashboard | everything (§4) |
| **Manager** | Operations + Approvals | Approvals, Operations, Branches, Trips, Reports |
| **Counter** | Shift Dashboard | Shift, Sell Ticket (≤3 taps), Cargo, Online Booking Approval, Print, Cash, Refund* |
| **Conductor** | Assigned Trip Dashboard | Today's Trip → Boarding → Offline Ticket → Offline Cargo → QR → Settlement |
| **Driver** | Today's Trip Dashboard | Today's Trip, Trip Sheet, Inspection, Fuel, Breakdown |
| **Finance** | Finance Dashboard | Revenue, Expenses, Bank, Payroll, Refund, P&L |
| **Cargo** | Cargo Dashboard | Inbound/Outbound Manifests, Waybills, Tracking, Delivered, Settlement |
| **Gate** | QR Dashboard | QR scan queue, boarding confirmation, passenger count vs manifest |
| **Mechanic** | Maintenance Dashboard | Maintenance Schedule, Inspection Reports, Breakdown Repairs, Parts |
| **Fleet** | Fleet Dashboard | Vehicle Status, Utilization, Maintenance Due, Insurance/Road-Tax Expiry alerts |
| **HR** | Employee Dashboard | Staff, Roles, Permissions, Attendance, Payroll |
| **Passenger** | Booking Dashboard | Search → Date → Route → Trip → Seat → Info → NRC* → Pay → QR Ticket → Receipt → Notification |

*Refund on Counter only if owner grants permission; NRC only if business rule requires.

Menus are computed from permissions — **hidden, never disabled**; a user never sees a
screen they cannot use.

---

## 6. Entity definitions

### 6.1 Vehicle
Display Name · **Registration Number (manual)** · Vehicle Type · Seat Layout · Capacity
(derived from layout) · Status (Running / Maintenance / Retired) · Insurance ·
**Insurance Expiry** · Road Tax · **Road Tax Expiry** · Maintenance Schedule ·
Assigned Driver · Assigned Conductor.

### 6.2 Route
Route → Stops → Boarding Points → Drop-off Points → Distance → Duration → Fare →
Vehicle → Seat Layout → Schedule → Counter(s) → Driver → Conductor → Trip Calendar.
(One trip = one vehicle + one schedule + one date.)

### 6.3 Passenger journey
Search → Select Date → Select Route → Select Trip → Select Seat → Passenger
Information → NRC (if required) → Payment → QR Ticket → Receipt → Notification.

### 6.4 Cargo journey
Sender → Receiver → NRC → Phone → Weight → Price → Payment → Receipt → Tracking →
Delivered → Settlement.
(Cargo pricing: By Weight or Manual Price — business rule.)

---

## 7. Branding propagation

Owner uploads once → propagates everywhere automatically:

| Asset | Business App | Passenger App | Booking Site | Corporate Site | PDF / Ticket / Receipt |
|---|---|---|---|---|---|
| Logo | ✓ | ✓ | ✓ | ✓ | ✓ |
| Primary / Secondary Color | ✓ (theme) | ✓ | ✓ | ✓ | ✓ |
| Receipt Header / Footer | ✓ | ✓ | — | — | ✓ |
| Website Banner | — | — | ✓ | ✓ | — |
| Ticket Template | — | ✓ | — | — | ✓ |
| QR Style | — | ✓ | — | — | ✓ |
| Company Info | ✓ | ✓ | ✓ | ✓ | ✓ |
| Favicon / App Icon | — | ✓ | ✓ | ✓ | — |
| Email / SMS / Push Template | — | ✓ | — | — | ✓ |

Single branding record (backend `OrganizationBranding`) → all surfaces. Already
supported by `HbtTheme.fromBrand()`.

---

## 8. The 55-year-old test (acceptance gate)

> Before implementing any screen ask: *"If a 55-year-old Myanmar bus owner with almost
> no computer experience uses this screen for the first time, can they understand it
> without training?"*
> If the answer is **NO**, redesign the workflow before writing code.
> **Business simplicity is always more important than technical elegance.**

Every screen ships with this test passed, in both Myanmar and English.

---

## 9. Localization (non-negotiable)

- **Myanmar is the default language; English is optional.**
- **No hardcoded strings.** Every label, validation, notification, report, receipt,
  and PDF supports Myanmar + English (existing `AppLocalizations` pattern extends to
  all new screens).

---

## 10. Responsive & validation loop

- Desktop = Google Workspace quality · Tablet = adaptive layout · Mobile = native feel.
- **Never** overflow, horizontal-scroll, or clip at 320/375/768/1024/1366/1920/2560.
- Desktop must NOT look like a stretched mobile app (validated in
  `docs/responsive_review.md`).
- **After every implementation:** run backend + business app + passenger app → open
  browser → walk every journey → screenshots → compare with blueprint → fix until
  **P0 = 0, P1 = 0, P2 ≤ 3** → update `docs/dashboard_gap_analysis.md`.

---

## 11. Business rules (all configurable, Myanmar-visible)

| Setting | Options / Default |
|---|---|
| NRC Required (Passenger) | ON / OFF · default ON |
| Cargo Sender NRC | ON / OFF |
| Cargo Receiver NRC | ON / OFF |
| Cargo Pricing | By Weight / Manual Price |
| Ticket Printing | Automatic / Manual |
| Online Booking | Auto Confirm / Counter Confirm |
| Seat Lock Timeout | configurable (default 10 min) |
| Receipt Footer | editable text |
| Refund Rules | configurable (cutoff hours / retention %) |
| Company Branding | configurable |
| Theme | from branding colors (light/dark) |
| Language | Myanmar default, English optional |

Stored per-company; enforced in backend serializers/validators; surfaced in the
setup wizard (Business / Cargo / Payment Settings steps).

---

## 12. Decision-first dashboards

> Dashboards must never exist to display data. Every dashboard must help the user
> make a business decision.

Every dashboard section must answer one of:
- **What do I do now?** (approvals, delayed/cancelled trips, cash differences,
  expiring insurance/road-tax)
- **How is money moving?** (revenue/expenses/net profit vs yesterday/week/month)
- **Where should I act?** (worst branch, worst route, worst vehicle, staff ranking)
- **Is anything broken?** (vehicle maintenance due, driver absent, deviation)

Design test: for each dashboard widget, name the decision it supports and the action
it leads to. A widget without an action is removed (research: actionable > vanity).

**The three-question test** — every dashboard (any role) must answer:
1. **What happened today?** (money, trips, passengers, cargo, exceptions)
2. **What requires my attention now?** (approvals, delays, cash differences, breakdowns)
3. **What should I do next?** (next recommended action — explicit, actionable, one tap)

---

## 13. Workload test (acceptance gate #2)

> Every feature must answer: **"Will this reduce the workload of a Myanmar transport
> company?"** If not, the feature should not exist.

Applied together with the 55-year-old test (§8): a feature must both be understandable
without training AND reduce real workload. Features that only add process (e.g.,
needless approval hops, redundant fields) are cut at design review.

---

## 14. Tenancy & isolation (absolute)

One company must **NEVER** see another company's:
`routes · passengers · bookings · vehicles · reports · staff · branding`

Every company owns its own: logo · theme · ticket · receipt · website · settings ·
users · branches · reports.

Enforcement (backend):
- Every model carries `organization`; every query filters by the resolved tenant
  (org context from auth token / subdomain / slug) — never by client-supplied org id.
- `OrganizationBranding` is per-tenant; brand assets are served only within tenant
  scope.
- Global search, reports, exports, and PDF generation are tenant-scoped.
- Row-level tenant filter is unit-tested for every new model (contract test).

Entity chain: `Company → Branch → Counter → Trip → Vehicle → Staff → Cash → Report`.

---

## 15. Lifecycle state machines

Every operational object is a state machine. UI shows current state + allowed next
states; backend validates transitions (no illegal jumps); every transition is
recorded (who/when) for audit.

### Vehicle
`Registration → Seat Layout → Insurance → Road Tax → Inspection → Maintenance →
Assignment → Trip → Repair → Retirement`

### Employee
`Hire → Assign Branch → Assign Role → Assign Vehicle → Attendance → Payroll →
Performance → Leave → Resign`

### Trip
`Planned → Ready → Boarding → Departed → On Route → Arrived → Settlement → Closed`

### Cargo
`Accepted → Loaded → In Transit → Arrived → Delivered → Settlement → Closed`

### Shift (counter)
`Open Shift → Ticket → Cargo → Refund → Expense → Close Shift → Cash Verify →
Approved`
(Cash verify = count vs system; difference recorded, not hidden.)

### Conductor settlement
`Receive Trip → Offline → Settlement → Approved`

---

## 16. Offline as a normal operating mode

Not an emergency feature. **Every workflow explicitly defines:**

| Dimension | Definition per workflow |
|---|---|
| **Online** | Normal path, real-time sync, seat locks active |
| **Offline** | What is recorded locally (tickets, cargo, boarding, settlement) with
  full validation rules cached (routes, fares, seat layouts, vehicle/crew) |
| **Reconnection** | Queued actions replay in order; seat conflicts detected and
  surfaced per conflict policy |
| **Conflict resolution** | Explicit rule per object (e.g., same seat sold twice →
  second is refunded automatically + alert; cash difference at settlement → recorded
  with actor and reason) |
| **User experience** | Offline banner (already built), local confirmation with
  provisional number, queue status, no data loss, no double-entry |
| **Support** | Field roles can always call/see what synced vs pending; admins can
  inspect a device's queue |

Existing building blocks: `ConnectivityMonitor`, offline cache, queue — extended to
conductor/gate workflows.

---

## 17. Seasonality

Myanmar transport demand is seasonal. Platform supports:
- **Thingyan** (water festival) — route/capacity surge, price ceilings
- **Public holidays** — special schedules
- **Peak season** — holiday pricing and holiday capacity per route/date
- **Festival routes** — temporary routes with own fares/schedules
- **Special trips** — one-off trips (vehicle + crew + route + date) with full
  ticketing/cargo support

Seasonality is configurable per company (dates, routes affected, multipliers),
visible in the Owner dashboard as planning signals (capacity vs demand).

---

## 18. Global search

One search field (top bar, ⌘K on desktop) searches **across the whole company** (tenant
scoped):

`Passenger · Phone · NRC · Ticket · Booking · Cargo · Vehicle · Employee · Route ·
Trip · Receipt`

Each result type opens its record (or a filtered list). Search also supports quick
actions ("New Trip", "Approve 7"). Never searches across tenants.

---

## 19. Implementation order (approved phases, wave-gated)

```
Wave 1   Design System + Company Setup Wizard + Branding Engine
Wave 2   Owner Dashboard + Role Navigation
Wave 3   Users · Roles · Branches
Wave 4   Vehicle · Seat Layout Designer · Route Wizard
Wave 5   Counter
Wave 6   Conductor (spare — lower priority)
Wave 7   Passenger
```

### Sequential validation rule (hard gate)
> Before implementing a new screen, launch the previous implementation, walk the
> complete user journey, verify no regression, then continue.
> **Never implement two business modules without validating the previous one.**

Each wave: run apps → walk every journey → screenshots → compare with blueprint → fix
until P0=0, P1=0, P2≤3 → update gap analysis → commit separately (remediation rules,
AGENTS.md).

---

## 20. Company Setup Dashboard (owner's pre-live home)

Until setup is complete, the owner's post-login home is the **Company Setup Dashboard**
(not the empty Owner Dashboard). It answers the three questions with a readiness view:

```
Company Setup          ██████░░░░  60%
Remaining: ✓ Logo  ✓ Branch  ✓ Counter  ☐ Vehicle  ☐ Route  ☐ Employees

System Health
🟢 Company Ready     🟡 Missing Vehicles     🟢 Branch Ready     🔴 No Employees
Overall 78%

Next Recommended Action
  ↓ Create Vehicle
  ↓ Assign Driver
  ↓ Create Route
  ↓ Ready to Sell

Business Readiness   85%    Next Step: Configure Cargo    Estimated Time: 5 Minutes
```

Elements:
- **Progress bar** (setup steps completed / total) + remaining checklist.
- **System Health tiles** — per-area status (🟢 ready / 🟡 partial / 🔴 blocked) +
  overall %. Each tile drills to the setup step that fixes it.
- **Next Recommended Action** — a one-tap guided path to "Ready to Sell"; each step
  opens the wizard at that step; the final state is a celebration + handoff to the
  Owner Dashboard.
- **Business Readiness %** + next step + estimated time (reduces anxiety, sets
  expectation — 55-year-old test).

Readiness drives dashboard content: until "Ready to Sell" is achieved, the owner sees
setup nudges, not sales KPIs.

---

## 21. Demo companies (canonical names)

Demo/seed ecosystem uses these seven named companies (+ generated ones to reach 20):

`Shwe Ayeyar · Myanmar Star · Golden Road · Royal Express · Unity Express ·
Blue Mandalay · Delta Line`

(They supersede earlier ad-hoc demo names in seed scripts; the ecosystem generator
uses this list for the 20-company demo set.)
