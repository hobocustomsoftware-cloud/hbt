# HBT Transport Platform — Business Operation Blueprint

**Version:** 1.0 (master business specification)
**Date:** 2026-08-01
**Author:** COO / CPO / Enterprise Solution Architect
**Scope:** Complete operating platform design for the largest transport company in Myanmar.
This is the **master business specification** — the target architecture the product must
converge to. Runtime gap analysis (docs/runtime_gap_analysis.md) measures the current build
against this blueprint.

---

## 1. Company vision & operating model

### 1.1 Who we are
A nationwide intercity express transport operator: passenger coaches, cargo/parcel service,
multiple branches and terminals, corporate accounts, and a growing digital channel.

### 1.2 Operating principles
1. **One platform, every role.** A single integrated system covering passenger, counter,
   conductor, driver, cargo, gate, finance, fleet, HR, mechanic, manager, owner.
2. **Cash is sacred.** Every kyat — counter, onboard, cargo, expense — must be traceable from
   collection to bank deposit with a named accountable person at every step.
3. **Offline-first.** Myanmar network reality: counters, conductors, drivers, roadside agents
   must keep working with zero connectivity and reconcile when online.
4. **Roles and permissions are configurable.** The Owner decides who sees what; nothing is
   hard-coded to a person.
5. **The trip is the unit of operations.** Crew, vehicle, seats, cargo, cash, and events all
   attach to a trip; every trip closes with a full settlement.

### 1.3 System-of-record principles
- Server is the system of record for money and seat state (server-authoritative).
- Devices hold working state offline and reconcile via idempotent sync.
- Every money movement has: actor, counter/branch, trip/shift context, timestamp, and an
  immutable audit trail.

---

## 2. Application ecosystem

### 2.1 Business App (Flutter — single app, role-driven UI)

**One application. One login. Role decides what you see.**

| Role | Navigation menu (after login) |
|------|-------------------------------|
| **Owner** | Dashboard · Finance · Reports · Fleet · Users · Settings |
| **Manager** | Dashboard · Trips · Crew · Approvals · Monitoring · Reports |
| **Counter** | Booking · Cargo · Shift · Printer · Refunds |
| **Conductor** | Assigned Trip · Offline Booking · Cargo · QR · Waybill · Settlement |
| **Driver** | Trip Sheet · Inspection · Fuel · Breakdown |
| **Finance** | Settlement · P&L · Bank · Payroll · Approvals |
| **Gate** | Manifest · Validate · Boarding · Dispatch |
| **Cargo staff** | Shipments · Pricing · Claims · Tracking |
| **Fleet** | Vehicles · Maintenance · Fuel · Layouts · Assignments |
| **HR** | Staff · Rosters · Attendance · Documents |
| **Mechanic** | Work Orders · Inspections · Parts · Repairs |

### 2.2 Passenger App (Flutter)
Trip Search → Booking → Payment → QR Ticket → History → Profile → Notifications → Offline Ticket.

### 2.3 Booking Website (public)
Trip search, booking, payment, passenger login, ticket verification (QR lookup).

### 2.4 Corporate Website (public marketing)
Company profile, branches, routes, fleet, cargo service, news, careers, contact.

### 2.5 Media channels strategy
See §6.

---

## 3. Role system

### 3.1 Role hierarchy

```
Owner (platform-level; the only creator of Orgs/Users/Roles/Permissions)
│
├── Organization Owner (per-company owner — sees everything in their org)
│   ├── Manager (branch/terminal operations)
│   │   ├── Counter
│   │   ├── Conductor
│   │   ├── Driver
│   │   ├── Gate
│   │   ├── Cargo Staff
│   │   └── Mechanic
│   ├── Finance
│   │   ├── Cashier
│   │   └── Accountant
│   ├── Fleet Manager
│   └── HR
└── (Platform roles: Support, Auditor — read-only)
```

### 3.2 Permission model
- **Permission** = atomic capability (`ticket.sell`, `settlement.approve`, `refund.pay`…).
- **Role** = named bundle of permissions, configurable by Owner.
- **Scope** = which org/branch/counter the role applies to (global, org, branch, counter).
- **Approval hierarchy** = workflow definitions: who requests, who verifies, who approves,
  escalation path, SLA. Configurable per action type.
- **Every permission configurable** — Owner can create roles with any subset.

### 3.3 Approval hierarchy (money & risk actions)

| Action | Requester | Verifier | Approver | Escalation | SLA |
|--------|-----------|----------|----------|------------|-----|
| Ticket refund | Counter | Finance | Manager (> threshold) | Owner | 24h |
| Trip settlement | Conductor/Counter | Finance | Manager | Owner | 24h |
| Expense | Counter/Conductor | Finance | Manager | Owner | 48h |
| Price override | Counter | Manager | — | Owner | 4h |
| Ticket void | Counter | Manager | — | — | 4h |
| Corporate credit | Sales | Finance | Owner | — | 48h |
| Cargo claim payout | Cargo | Finance | Manager | Owner | 72h |
| Payment account change | Finance | Manager | Owner | — | 48h |
| Salary/payroll run | HR | Finance | Owner | — | 7d |
| Subscription change | — | — | Owner | — | — |

---

## 4. Role definitions

For every role: responsibilities, daily/weekly/monthly workflow, permissions, screens,
reports, notifications, offline behaviour, cash flow, approval chain, fraud prevention, KPIs.

### 4.1 Owner

- **Responsibilities:** company performance, capital decisions, org/user/role/permission
  administration, setting policies (fare, refund, credit), approval of major payouts.
- **Daily workflow:** review exception feed → approve escalated items → check cash position.
- **Weekly workflow:** P&L by branch/route, fleet utilization, staff KPIs, outstanding receivables.
- **Monthly workflow:** network performance review, budget vs actual, pricing review, HR decisions.
- **Permissions:** everything (org-scoped), user/role/permission management, subscription.
- **Screens:** Dashboard, Finance, Reports, Fleet, Users, Settings.
- **Reports:** consolidated P&L, branch comparison, route profitability, load factor, cash
  exception, receivables aging, crew performance.
- **Notifications:** settlement overdue, refund SLA breached, low cash at branch, subscription
  renewal, system alerts.
- **Offline:** dashboard read-only cache; no approvals offline (safety).
- **Cash flow:** visibility of all cash, no physical handling.
- **Approval chain:** final approver; delegation to Manager.
- **Fraud prevention:** separation of duties audit, anomaly flags (negative sales, price
  override frequency, settlement deltas).
- **KPIs:** revenue, net margin, load factor, on-time %, cash leakage rate, receivables DSO.

### 4.2 Manager (branch/terminal)

- **Responsibilities:** daily operations at the terminal: dispatch, staffing, approvals,
  dispute resolution, monitoring SLAs.
- **Daily workflow:** open ops board → approve pending refunds/settlements/overrides →
  resolve alerts → check departures vs schedule → end-of-day review.
- **Weekly workflow:** staff review, route performance, incident log review, cash float audit.
- **Monthly workflow:** branch P&L, staffing plan, KPI review with Owner.
- **Permissions:** approve within limits, monitoring, reports, dispatch actions, incident log.
- **Screens:** Dashboard (live ops board), Trips, Crew, Approvals, Monitoring, Reports.
- **Reports:** terminal P&L, on-time %, load factor, alert history, settlement register.
- **Notifications:** late departures, cash differences, approval requests, incidents.
- **Offline:** read cached ops board; queued approvals rejected (must be online).
- **Cash flow:** accountable for terminal cash; reviews cashier handovers and bank deposits.
- **Approval chain:** approver for most; escalates to Owner.
- **Fraud prevention:** spot-check random settlements, enforce separation of duties.
- **KPIs:** on-time %, settlement closure rate, approval SLA, incidents resolved, terminal sales.

### 4.3 Counter

- **Responsibilities:** sell tickets, handle cash/transfers, accept cargo, manage shift till,
  print tickets/receipts, refunds at counter.
- **Daily workflow:** open shift (count float) → sell tickets (seat lock → payment → print) →
  accept cargo → record expenses → handle walk-ins → close shift (count cash, reconcile).
- **Weekly workflow:** float review, printer maintenance check, personal KPI.
- **Monthly workflow:** cashier performance review with Manager.
- **Permissions:** ticket.sell, cargo.accept, expense.create, refund.request, shift.manage,
  print, ticket.void (with approval), price.override (with approval).
- **Screens:** Booking, Cargo, Shift, Printer, Refunds, Trip list.
- **Reports:** own shift summary, own sales.
- **Notifications:** shift reminders, approval results, lock expiry warnings.
- **Offline behaviour:** **full offline selling** — local seat state + lock, queue sales,
  sync on reconnect (idempotent); offline cargo acceptance; offline ticket printing with
  temp numbering.
- **Cash flow:** own till; float in/out; handover to next cashier; deposit to bank.
- **Approval chain:** requests refunds/voids/overrides through workflow.
- **Fraud prevention:** per-cashier sales attribution, shift handover counts, random audits,
  no self-approval.
- **KPIs:** tickets sold, sales value, cash difference (must be 0), handling time, void rate.

### 4.4 Conductor (Spare)

- **Responsibilities:** onboard ticket sales (cash), waybill, boarding count per stop, onboard
  cargo, trip-end cash handover to counter/finance.
- **Daily workflow:** pick up trip sheet (assigned trip) → board at origin (count) →
  sell onboard tickets at stops → record cargo picked up en-route → record expenses
  (tolls/meals) → arrive → hand over cash + waybill to Finance/Counter → sign off.
- **Weekly/monthly:** attendance, cash record review, training refresh.
- **Permissions:** onboard.sell, waybill.manage, cargo.accept (roadside), expense.create,
  settlement.submit.
- **Screens:** Assigned Trip, Offline Booking, Cargo, QR (ticket verify), Waybill, Settlement.
- **Reports:** own trip waybills, own cash summary.
- **Notifications:** trip assignment, departure reminders, settlement approval result.
- **Offline behaviour:** **must be fully offline** — onboard sales queue, waybill local,
  sync at terminal; QR verify offline against cached ticket list.
- **Cash flow:** carries trip cash; hands over at end; every note counted.
- **Approval chain:** settlement verified by Finance, approved by Manager.
- **Fraud prevention:** sequential ticket numbers, manifest vs sales reconciliation at trip
  end, random spot checks at mid-way stops.
- **KPIs:** onboard sales value, ticket count vs manifest, cash handover accuracy, waybill
  timeliness.

### 4.5 Driver

- **Responsibilities:** safe operation, trip sheet, pre-trip inspection, fuel, breakdown
  reporting, end-of-trip handover.
- **Daily workflow:** pre-trip inspection (checklist) → accept trip sheet → fuel log →
  drive (record stops/events) → breakdown/incident report if any → end-of-trip handover
  (odometer, fuel, defects).
- **Weekly/monthly:** license/medical renewal reminders, safety training.
- **Permissions:** inspection.submit, fuel.log, breakdown.report, trip.sheet.view,
  end-of-trip.handover.
- **Screens:** Trip Sheet, Inspection, Fuel, Breakdown.
- **Reports:** own trips, own fuel consumption.
- **Notifications:** trip assignment, inspection due, document expiry, safety alerts.
- **Offline behaviour:** fully offline — inspection/fuel/breakdown logged locally, synced.
- **Cash flow:** none (unless advance); records tolls/expenses for reimbursement.
- **Approval chain:** expense reimbursement via Manager.
- **Fraud prevention:** fuel log vs odometer variance alerts, inspection required before
  dispatch (gate blocks).
- **KPIs:** on-time departures, fuel efficiency (km/l), inspection compliance %, incident rate.

### 4.6 Finance

- **Responsibilities:** verify & approve settlements, bank reconciliation, P&L, payroll,
  receivables, tax.
- **Daily workflow:** verify conductor/counter settlements → approve refunds/expenses in
  limit → reconcile cash received vs bank deposits → flag exceptions.
- **Weekly workflow:** bank rec, receivables aging, cash position report, expense review.
- **Monthly workflow:** P&L, payroll run, tax report, GL export, close books.
- **Permissions:** settlement.verify, refund.approve, expense.approve, bank.reconcile,
  payroll.run, report.finance, GL.export.
- **Screens:** Settlement, P&L, Bank, Payroll, Approvals.
- **Reports:** daily cash, bank rec, aging, P&L by branch/route, payroll register, tax.
- **Notifications:** deposit expected vs received, aging breaches, approval queue.
- **Offline:** read-only cache of pending work; approvals online-only.
- **Cash flow:** monitors every kyat; no physical cash unless cashiering.
- **Approval chain:** verifies; Manager/Owner approve above limits.
- **Fraud prevention:** separation of duties (verifier ≠ approver), anomaly detection,
  complete audit trail.
- **KPIs:** reconciliation accuracy, aging DSO, approval SLA, reporting timeliness.

### 4.7 Gate

- **Responsibilities:** boarding control, manifest check, headcount, dispatch confirmation.
- **Daily workflow:** open trip manifest → validate tickets (QR) → mark boarded → chase
  no-shows → confirm headcount at cutoff → dispatch.
- **Permissions:** manifest.view, ticket.validate, boarding.mark, dispatch.confirm.
- **Screens:** Manifest, Validate, Boarding, Dispatch.
- **Reports:** boarding summary per trip.
- **Notifications:** no-show alerts, cutoff reminders.
- **Offline:** cached manifest + offline validation queue.
- **Cash flow:** none.
- **Approval chain:** dispatch confirmation recorded; overrides by Manager.
- **Fraud prevention:** headcount vs manifest at dispatch; duplicate validation blocked.
- **KPIs:** boarding accuracy, on-time dispatch, no-show rate.

### 4.8 Cargo staff

- **Responsibilities:** accept cargo (ID + photo + weight), price, load manifest, track,
  handover, claims.
- **Daily workflow:** accept shipment (capture NRC, photo, weight) → price → assign trip →
  load → track → arrival notify → handover (ID + signature) → close.
- **Permissions:** cargo.accept, cargo.price, cargo.assign, cargo.handover, claim.manage.
- **Screens:** Shipments, Pricing, Claims, Tracking.
- **Reports:** cargo P&L, claims aging, per-route cargo volume.
- **Notifications:** consignee arrival, claim updates.
- **Offline:** accept shipments offline (queue), sync at terminal.
- **Cash flow:** cargo COD + cash collections handed to counter/finance.
- **Approval chain:** claims via Finance/Manager.
- **Fraud prevention:** photo + ID at both ends, weight spot checks, COD register.
- **KPIs:** shipment volume, on-time delivery, claims rate, revenue per kg.

### 4.9 Fleet

- **Responsibilities:** vehicles, maintenance, fuel, layouts, assignments.
- **Daily/weekly/monthly:** maintenance schedule, service due alerts, assignment planning,
  fuel monitoring, compliance (docs).
- **Permissions:** vehicle.manage, maintenance.manage, assignment.manage.
- **Screens:** Vehicles, Maintenance, Fuel, Layouts, Assignments.
- **Reports:** fleet utilization, maintenance cost, fuel efficiency, doc expiry.
- **Offline:** maintenance logs offline.
- **Cash flow:** maintenance/fuel costs tracked to trips.
- **Approval chain:** major repairs via Manager/Owner.
- **Fraud prevention:** fuel variance alerts, maintenance cost vs vehicle age.
- **KPIs:** availability %, maintenance cost/km, fuel efficiency, compliance %.

### 4.10 HR

- **Responsibilities:** staff records, rosters, attendance, documents, disciplinary.
- **Daily/weekly/monthly:** roster, attendance, document expiry, payroll input.
- **Permissions:** staff.manage, roster.manage, attendance.manage, payroll.input.
- **Screens:** Staff, Rosters, Attendance, Documents.
- **Reports:** attendance, roster coverage, doc expiry, payroll.
- **Offline:** attendance capture offline.
- **Fraud prevention:** ghost-employee checks (payroll vs roster vs biometric).
- **KPIs:** roster coverage, doc compliance, payroll accuracy.

### 4.11 Mechanic

- **Responsibilities:** inspections, repairs, parts, work orders.
- **Daily:** open work orders, inspect, repair, log parts/labour, close.
- **Permissions:** workorder.manage, inspection.perform, parts.log.
- **Screens:** Work Orders, Inspections, Parts, Repairs.
- **Offline:** fully offline shop floor logging.
- **KPIs:** turnaround time, first-time-fix rate, parts cost.

---

## 5. User journeys (summary — full detail in docs/user_journeys.md)

| Journey | Steps (high level) |
|---------|--------------------|
| Passenger | Discover → Search → Select seat → Pay (cash/transfer/online) → Get e-ticket → Board (QR) → Ride → Feedback |
| Owner | Login → Dashboard → Exception feed → Approve → Review P&L → Manage org/users |
| Counter | Open shift → Sell → Print → Close shift → Handover |
| Conductor | Get assignment → Board → Sell onboard → Waybill → Handover cash → Settle |
| Driver | Inspect → Trip sheet → Drive → Fuel → Handover |
| Finance | Verify settlements → Approve → Reconcile bank → P&L → Payroll |
| Gate | Open manifest → Validate → Board → Dispatch |
| Cargo | Accept → Price → Ship → Track → Handover → (Claim) |
| Fleet | Plan → Maintain → Assign → Monitor |
| HR | Hire → Roster → Attend → Payroll |
| Manager | Monitor → Approve → Resolve → Report |

---

## 6. Media channel strategy

| Channel | Purpose | Content |
|---------|---------|---------|
| **Facebook** | Primary acquisition + customer service | Trip promos, festival schedules, route launches, FAQs, reviews, live chat |
| **TikTok** | Brand awareness (young travellers) | Short clips of coaches, destinations, behind-the-scenes, crew stories, viral route content |
| **Telegram** | Operational broadcast + power users | Channel: schedule updates, delays, booking links; group: customer service |
| **Viber** | Mass reach + transactional (Myanmar default) | Booking confirmations, payment receipts, delay alerts, promo blasts |
| **YouTube** | Long-form trust content | Company profile, safety story, destination guides, driver/crew features, investor/corporate videos |
| **Email** | Corporate + B2B + formal comms | Corporate accounts, invoices, policy changes, newsletters, careers |
| **SMS** | Critical transactional fallback | Booking confirmation, delay/cancel alerts, OTP |
| **Push notification** | In-app engagement (passenger app) | Ticket ready, delay, payment verified, refund status, promo |

**Content rules:** Facebook/Viber = timely + local language (Myanmar); TikTok = short +
emotional; Telegram = factual broadcast; Email = formal; SMS = only critical; Push = only
personalized.

---

## 7. Cash flow design (the spine)

```
Passenger cash ─┐
Onboard cash  ──┤
Cargo cash    ──┼──► Counter/Conductor till ──► Shift close ──► Settlement (verified/approved)
Expense        ─┘            │
                             ▼
                     Bank deposit (slip captured)
                             ▼
                     Bank reconciliation (Finance)
                             ▼
                      GL / P&L / Tax
```

- Every cash node has an accountable actor, a count, and a difference record.
- Separation of duties: collector ≠ verifier ≠ approver.
- All electronic payments reconcile via connector settlement reports.

---

## 8. KPI system (org-wide)

- **Revenue integrity:** cash difference rate, void rate, override rate, settlement delta.
- **Operations:** on-time %, load factor, cancellations, no-show rate, boarding accuracy.
- **Fleet:** availability, maintenance cost/km, fuel efficiency.
- **Cargo:** volume, on-time delivery, claims rate, revenue/kg.
- **Finance:** DSO, reconciliation accuracy, approval SLA.
- **People:** attendance, doc compliance, turnover.

---

## 9. Non-functional requirements

- **Offline:** all field roles (counter, conductor, driver, gate, cargo, mechanic) fully
  functional offline; sync idempotent; conflict policy defined per entity.
- **Audit:** immutable trail on all money/approval/state transitions.
- **Multi-tenant:** org isolation; Owner-level platform admin.
- **Localization:** Myanmar + English.
- **Notifications:** push/SMS/Viber/email per event matrix.

---

*This is the target. See docs/role_permission_matrix.md, docs/user_journeys.md,
docs/application_architecture.md for detail; docs/runtime_ui_review.md and
docs/runtime_gap_analysis.md measure the current build against this blueprint.*
