# HBT Platform — Business Operations Audit (Operations Director Review)

**Audit date:** 2026-08-01
**Reviewer:** Operations Director (nationwide intercity express bus operator — Myanmar market)
**Scope:** Business workflows only. Not a code review. Every role's operational day is walked
end-to-end against what HBT actually provides (verified against endpoint + screen inventory,
2026-08-01).
**Basis of review:** 24 backend domains, ~150 endpoints, 24 business-app screens, 8 passenger-app
screens, trip/cargo/settlement/shift status lifecycles.

---

## 0. Executive summary

HBT covers the **core revenue spine** — counter ticket sales with seat locks, passenger
self-service booking, cargo, shifts with P&L, refunds, trip lifecycle, printing — to a degree
that would support a **pilot at 1–3 terminals**. It is **not yet a nationwide operations
system**. The gaps cluster into six themes:

1. **The conductor/driver (the people who actually run buses) have almost no system.** The
   richest revenue day — onboard cash sales, waybills, roadside cargo, fuel, breakdowns — is
   captured on paper or not at all. This is the single biggest revenue-integrity hole.
2. **Cash is tracked at the counter, but the float/collection chain is incomplete.** No
   cash-in-transit, no float denominations, no cashier handover, no till reconciliation against
   bank deposits.
3. **Approvals are mostly 2-step (request → decide) with no escalation, no SLA, no
   four-eyes on critical payouts.**
4. **Reporting is retrospective and terminal-centric** — no forward-looking dispatch view, no
   live fleet board, no exception-based management, no comparison of planned vs actual.
5. **Passenger experience stops at ticket purchase** — no rebooking, no transfer, no delay
   notification, no refund status self-service, no support channel.
6. **Offline capability is read-only.** The network-loss reality of Myanmar highways means
   the counter can keep selling (queued writes exist in design), but conductor/cargo/gate
   workflows cannot.

Severity key: **CRIT** = revenue/legal/safety loss likely; **HIGH** = material daily friction
or fraud exposure; **MED** = efficiency/experience; **LOW** = polish.

---

## 1. Role walkthroughs

### 1.1 Owner (company/group level)

**Workflow today (verified):**
- Owner dashboard endpoint (`reports/owner-dashboard/`), monitoring dashboard + alerts
  (`monitoring/dashboard/`, `monitoring/alerts/`), report export (`reports/export/`),
  cargo owner report (`reports/cargo/summary/`), subscription management
  (`subscription/…` incl. change-plan, suspend), organization detail + roles/permissions,
  branding (public operator page), media campaigns (operator side).

**What an owner needs but HBT does not provide:**

| # | Gap | Severity |
|---|-----|----------|
| O-1 | **No consolidated multi-terminal / multi-org P&L.** Owner dashboard exists but no ability to roll up several branches/terminals, compare branch performance, or see per-route profitability across the network. | HIGH |
| O-2 | **No fleet utilization view.** Seats sold vs seats available per trip/route/day/week; load factor trend. Owner cannot see whether a route is worth keeping. | HIGH |
| O-3 | **No driver/conductor performance view.** Punctuality, cancellations, fuel usage, on-board sales per crew. | MED |
| O-4 | **No cash-flow forecast.** Receivables (corporate invoices), payables, expected daily collection. | MED |
| O-5 | **No exception feed.** "Trips departed late >30 min", "load factor <40%", "settlement overdue" — owner must dig through dashboards. | MED |
| O-6 | **No audit/compliance export for accountants** (till data, tax-relevant revenue by date, void/cancel register). | MED |
| O-7 | **No asset register** (vehicles, spare parts, tyres, maintenance schedule) — fleet app covers layout/assignment only. | HIGH |
| O-8 | **No revenue leak analytics** — no comparison of "expected sales by load factor" vs actual, no empty-seat loss report. | HIGH |

### 1.2 Admin (terminal/branch management)

**Workflow today (verified):** staff/drivers/conductors CRUD (`workforce/`), vehicles + seat
layouts + assignments (`fleet/`), routes/stops/segments (`network/`), schedules + trip
generation + assignments + lifecycle (`scheduling/`), fare rules + promotions (`fares/`),
branches/terminal-operations (`locations/`), payment accounts + connectors (`payments/`),
printer profiles/templates (`operations/`), roles/permissions/memberships (`tenancy/`),
subscription admin, cargo categories/pricing/contacts (`cargo/`).

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| A-1 | **No roster/scheduling for staff** — driver & conductor assignments are per-trip; there is no weekly roster, no rest-day tracking, no duty-hours limit (fatigue is a safety issue in long-haul Myanmar routes). | CRIT (safety) |
| A-2 | **No maintenance workflow** — no odometer, no service due, no breakdown log, no defect reporting before dispatch. "assign-vehicle" exists but nothing ensures the vehicle is roadworthy. | CRIT (safety) |
| A-3 | **No trip-template/pattern management** — schedules generate trips, but no seasonal timetable management (festival surges, Thingyan), no capacity adjustments. | MED |
| A-4 | **No stop/terminal management for the passenger side** — terminals exist but no per-terminal facilities, opening hours, or parking/gate assignment. | LOW |
| A-5 | **No fuel management** — fuel purchase, tank capacity, per-km consumption per vehicle. Major cost line invisible. | HIGH |
| A-6 | **No document expiry tracking** — driver license, vehicle insurance, roadworthiness cert, route permits. Expired permit = legal stop. | CRIT |
| A-7 | **No approval workflow for schedule changes / off-cycle trips** — admin can create trips without a change-control record. | MED |
| A-8 | **No user lifecycle for staff leaving** — deactivating a staff member exists (status) but no handover of open shifts/settlements. | MED |

### 1.3 Counter (ticket seller — the busiest role)

**Workflow today (verified):** sign-in → open shift (opening cash) → trip list → counter
booking page (seat map, seat locks acquire/release, passenger entry, fare quote) → payment
decision page (cash/transfer evidence) → ticket issue/print → close shift (P&L: ticket rev,
cargo rev, expenses, net, cash difference). Scanner for validation. Refund create.
Expense create. Offline banner + sync tab.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| C-1 | **No reprint of tickets after close/re-issue flow** — reissue endpoint exists server-side (`tickets/<id>/reissue/`), but no obvious screen flow for "printer jammed, reprint". Printer jam = angry passenger + lost proof. | HIGH |
| C-2 | **No split payment** (cash + transfer for one booking) — single payment record per booking path. Common for groups. | MED |
| C-3 | **No multi-passenger booking in one transaction** (group/family) — audit already flagged; forces N transactions, N tickets, N locks. | MED |
| C-4 | **No hold-to-call flow** — passenger calls "hold seat 30 min"; lock TTL is 5 min, and there is no "manual hold" that a supervisor can grant. | MED |
| C-5 | **No price override with reason capture** — fare rules exist, but can a senior counter discount for VIP/corporate? If yes, is it flagged to finance? Not evident. | HIGH (fraud/leak) |
| C-6 | **No cash float management** — shift has opening cash and closing difference, but no mid-shift top-ups, no cashier-to-cashier handover, no denomination count. | HIGH |
| C-7 | **No walk-up fast path** — every sale goes through the full seat-map + traveler flow; no quick "same passenger, next trip" repeat. | LOW |
| C-8 | **No ticket void/cancel with supervisor approval** — cancel exists (`bookings/<id>/cancel/`), but a counter canceling a paid ticket needs the refund path; no separate void register with reason. | HIGH |
| C-9 | **Offline sale = read-only** — in a network outage (common), the counter can view cached trips but cannot sell and queue the sale. Every Myanmar operator knows the network will drop mid-festival. | CRIT |

### 1.4 Spare (stand-in counter / relief staff)

**Workflow today:** same as Counter (same app, same credentials). No distinct "relief" concept.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| S-1 | **No shift handover flow.** Relief arrives at 14:00; the 08:00 cashier has 1.2M MMK float and 14 open transactions. There is no "hand over till" that freezes cashier A's shift and opens B's with a counted float and a difference note. | CRIT |
| S-2 | **No per-cashier sales accountability.** All sales during a shift are attributed to whoever is logged in; without handover, two cashiers share one shift record. | HIGH |
| S-3 | **No device/handover assignment** — which tablet belongs to which shift; device registry exists (offline) but not tied to shift ownership. | MED |
| S-4 | **No training/sandbox mode.** A new spare cannot practice on a test terminal without touching real data. | LOW |

### 1.5 Passenger (self-service)

**Workflow today (verified):** register/login (phone+password) → trip search (terminal→route→
stop→date) → trip detail → seat select (seat lock 5-min, countdown, conflict refresh) →
booking → payment (options, evidence upload for transfer, payment create) → ticket list →
cancel booking. Offline read cache for search/detail/seats/tickets.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| P-1 | **No in-app payment completion for transfer.** Passenger uploads evidence; a human must verify (payment decision). No payment status visibility in the app ("payment pending verification" — unclear to user). | HIGH |
| P-2 | **No e-ticket QR for boarding.** Ticket list shows details; boarding flow is counter-scanner. Passenger has no scannable pass → cannot self-board, no gate integration. | HIGH |
| P-3 | **No rebooking/transfer.** Missed the bus? No flow to move the ticket to another trip (reissue is admin-side). | HIGH |
| P-4 | **No delay/cancellation notification.** Notifications exist (app) but no trip-status subscription for booked passengers. Passenger arrives at terminal to find bus cancelled. | CRIT (experience) |
| P-5 | **No refund status self-service.** Refund is a counter flow; passenger cannot see refund progress or request online. | MED |
| P-6 | **No multi-passenger booking** (family/group) — same as C-3. | MED |
| P-7 | **No support channel / lost & found / complaint** — feedback exists server-side but no obvious passenger-facing complaint UX with resolution status. | MED |
| P-8 | **No booking confirmation via SMS/notification** — proof of booking is in-app only; in Myanmar, SMS confirmation is the norm. | MED |
| P-9 | **No seat preference** (window/aisle, lower deck), no meal/amenity option. | LOW |
| P-10 | **No passenger history/account** beyond ticket list — no frequent-traveller recognition, no saved travelers beyond the single travelers list. | LOW |

### 1.6 Finance (accounts / cash office)

**Workflow today (verified):** payment accounts + approval + versions; payment uploads +
download; payments list + decision; refund policy + refund request/decision/paid/complete;
expense CRUD; shift close P&L; cash report screen; profit/loss screen; subscription
invoices (issue/change/suspend); corporate customers + invoices; media campaign payments.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| F-1 | **No bank deposit reconciliation.** Cashier collects 3M MMK; does it reconcile to a bank deposit slip? No deposit entry, no bank statement import, no difference tracking. | CRIT (cash) |
| F-2 | **No receivables aging.** Corporate invoices exist but no aging (30/60/90), no dunning, no credit limit enforcement at booking time. Corporate passenger can book with zero visibility of outstanding balance. | CRIT (cash) |
| F-3 | **No GST/withholding tax handling.** Fare amounts are gross; no tax breakdown per ticket (Myanmar commercial tax), no tax report. | HIGH |
| F-4 | **No petty cash / expense approval workflow.** Expense create exists; who approves? Is a counter's own expense self-approved? No evidence of an approval gate on expenses. | HIGH (fraud) |
| F-5 | **No cash drawer / physical cash count integration** — audit flagged; cash difference is computed but there is no cash-count entry (denominations) to explain the difference. | HIGH |
| F-6 | **No journal/GL export** — profit/loss exists, but no double-entry export, no chart of accounts mapping, no integration to Xero/QuickBooks/Myanmar accounting packages. | HIGH |
| F-7 | **No payment-connector settlement reconciliation** — webhooks exist, but no daily reconciliation between connector payouts and payment records. | HIGH |
| F-8 | **No fixed assets / depreciation** (vehicles, terminals). | MED |
| F-9 | **No payroll integration** — staff exist but no salary, no commission on sales (common for counters), no advance/deduction. | MED |
| F-10 | **No refund SLA or aging** — refund request can sit in "requested" indefinitely; no escalation to finance. | MED |

### 1.7 Cargo (parcel / freight — often the profit engine)

**Workflow today (verified):** categories, pricing rules (manual/per-kg/itemized/tiered/mixed),
contacts, shipment create (draft→accepted→assigned→loaded→in_transit→arrived→ready_pickup→
handed_over; refused/cancelled/damaged/lost/returned), assign-trip, transition, charge-line
allocations paid, QR resolve, trip cargo manifest, roadside cargo accept, cargo owner report.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| G-1 | **No proof-of-identity/ID capture on handover.** Myanmar parcel business requires NRC capture at pickup and handover; NRC reference data exists but no shipment-level NRC capture + verification workflow. | CRIT (legal) |
| G-2 | **No photo evidence** — cargo condition at acceptance (damaged/boxed), signature or photo at handover. Disputes unresolvable without it. | HIGH |
| G-3 | **No volumetric weight / dimension capture** — pricing by kg only; odd-sized cargo underpriced. | MED |
| G-4 | **No cash-on-delivery (COD)** — a staple of Myanmar parcel business; absent. | HIGH |
| G-5 | **No consignee notification** — "your parcel arrived" via SMS. Notifications app exists but not wired to cargo events. | MED |
| G-6 | **No claim/loss workflow** — damaged/lost statuses exist but no claim amount, no payout approval, no link to refund/payment system. | HIGH |
| G-7 | **No load optimization / weight-per-trip limits** — cargo manifest exists but no weight/volume capacity check against vehicle; overloading is a road-safety risk on Myanmar highways. | CRIT (safety) |
| G-8 | **No roadside collection accounting** — roadside cargo accept exists; how does the roadside agent's cash reconcile to the terminal? Ties into cash chain gaps. | HIGH |
| G-9 | **No parcel tracking for the sender** — QR resolve is internal; no public tracking page/status. | MED |
| G-10 | **No multi-stop / hub-and-spoke routing of parcels.** | LOW |

### 1.8 Gate (terminal gate / dispatch)

**Workflow today:** no dedicated gate role/screen. Trip lifecycle has boarding/start/depart
(`trips/<id>/boarding/start/`, `depart/`, `en-route/`, `stops/<id>/reach/`, `arrive/`) and
boarding validate + board passenger (ticket + boarding records). Scanner screen exists on the
business app.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| Gt-1 | **No gate/boarding manifest view** — who is supposed to be on this bus, who has boarded, who is missing. Boarding records exist but no manifest screen for gate staff (audit flagged as missing too). | HIGH |
| Gt-2 | **No cutoff/late-passenger policy enforcement** — gate cannot see "passenger checked in but not boarded" vs "booked but never arrived"; no calls to missing passengers. | HIGH |
| Gt-3 | **No gate device/role separation** — anyone with counter login can run the gate; no distinct gate permission set. | MED |
| Gt-4 | **No departure confirmation with headcount** — trip depart exists but no driver/cashier headcount confirmation against manifest at dispatch. | HIGH (safety) |
| Gt-5 | **No platform/gate assignment for vehicles** (which bay, which gate). | LOW |
| Gt-6 | **No delayed-departure notification trigger to booked passengers.** | HIGH |

### 1.9 Manager (terminal/operations manager — supervisor tier)

**Workflow today:** monitoring dashboard/alerts, trip close, settlement create/action
(pending→verified→approved→closed/rejected), payment decisions, refund decisions, feedback
triage, pending-work list + complete, notification logs, report export.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| M-1 | **No approval SLA/escalation.** A refund or settlement can sit "pending" with no due-date, no reminder, no escalation to owner. | HIGH |
| M-2 | **No four-eyes on settlement.** SettlementActionView exists — is verify and approve the same person? No evidence of separation-of-duties enforcement (cashier ≠ verifier ≠ approver). | CRIT (fraud) |
| M-3 | **No incident log** (accident, breakdown, passenger complaint escalation, theft). Feedback triage exists for complaints; operational incidents have no register. | HIGH |
| M-4 | **No staff performance / disciplinary trail.** | MED |
| M-5 | **No live operations board** — manager cannot see all today's trips, their status, load, delays, crew, vehicle in one view. Monitoring dashboard exists but is it trip-centric live? | HIGH |
| M-6 | **No manual intervention workflows** — e.g., "bus broke down, move passengers to next bus" (transfer) has no manager workflow. | HIGH |
| M-7 | **No key-metrics KPI tracking** (on-time %, load factor, sales per counter, cancellations per route). | MED |

### 1.10 Driver

**Workflow today:** **no driver-facing workflow exists.** Driver records are CRUD; trips get a
driver assignment. The driver has no app, no login workflow, no trip sheet.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| D-1 | **No driver trip sheet / waybill.** The driver is legally responsible for the trip document; HBT does not produce or capture it. | CRIT (legal) |
| D-2 | **No pre-trip inspection checklist** (tyres, brakes, lights, fuel) with signature. | CRIT (safety) |
| D-3 | **No fuel log / distance log per trip** — fuel fraud and consumption tracking impossible. | HIGH |
| D-4 | **No breakdown/incident reporting from the road.** | CRIT |
| D-5 | **No rest/duty-hour tracking** (ties to A-1). | CRIT (safety) |
| D-6 | **No route/stop guidance or timetable access offline** — driver relies on paper. | MED |
| D-7 | **No end-of-trip handover** (odometer, fuel, defects, cash from conductor) — nothing for the driver to acknowledge. | HIGH |

### 1.11 Conductor (onboard — the most revenue-rich untracked role)

**Workflow today:** **none.** Conductor records are CRUD; trip assignment exists. The
conductor has no workflow, no onboard sales, no waybill.

**Gaps:**

| # | Gap | Severity |
|---|-----|----------|
| Co-1 | **No onboard ticket sales.** Passengers boarding en-route (no pre-booking) — the conductor sells; this revenue is entirely outside HBT. In Myanmar this can be 30–50% of a trip's revenue. | CRIT (revenue) |
| Co-2 | **No waybill/crew manifest.** The conductor's trip sheet (boarding count per stop, tickets sold, cargo, expenses) is paper. | CRIT |
| Co-3 | **No onboard cargo handling** — cargo accepted en-route by the conductor; ties to G-8. | HIGH |
| Co-4 | **No cash handover to the counter/depot at trip end** — no end-of-trip cash settlement for the conductor. | CRIT (cash) |
| Co-5 | **No stop-by-stop boarding record** (who got on where, ticket or cash). | HIGH |
| Co-6 | **No offline-first onboard app** — highways have dead zones; any conductor tool must be offline-first with sync. | CRIT (design constraint) |
| Co-7 | **No expense recording en-route** (tolls, parking, meals for crew) — currently impossible. | HIGH |

---

## 2. Cross-cutting gap register

### 2.1 Missing workflows (consolidated)
- Conductor onboard sales + waybill + trip-end cash handover (Co-1..Co-4) — **the largest single missing workflow**
- Driver trip sheet, pre-trip inspection, fuel log, breakdown reporting (D-1..D-7)
- Shift handover / till transfer between cashiers (S-1, S-2)
- Bank deposit reconciliation + cashier cash count (F-1, F-5)
- Receivables aging + credit-limit enforcement (F-2)
- COD for cargo, parcel claims (G-4, G-6)
- Passenger delay/cancellation notification + rebooking/transfer (P-3, P-4)
- Gate manifest + headcount confirmation (Gt-1, Gt-4)
- Maintenance + document expiry (A-2, A-6)
- Manual transfer of passengers on breakdown (M-6)

### 2.2 Operational risks (real-world failure scenarios)
| Scenario | Likelihood | Impact | Covered? |
|----------|-----------|--------|----------|
| Network drops at counter during festival rush → cannot sell | High (Myanmar) | Revenue loss, queue chaos | ❌ (read-only offline) |
| Two cashiers share a shift, no handover → till difference unresolved | High | Fraud/blame | ❌ |
| Conductor pockets en-route cash sales — invisible to system | Certain over time | Revenue leak | ❌ |
| Overloaded vehicle (cargo + passengers) → breakdown/accident | Med | Safety/legal | ❌ |
| Expired driver license/insurance → legal stop | Med | Legal | ❌ |
| Corporate customer with unpaid invoices books more | High | Cash loss | ❌ |
| Passenger not notified of cancellation → shows up, refund demand | High | Experience/refund | ❌ |
| Cashier discounts price with no reason trail | Med | Revenue leak | ❌ |
| Printer jam → no ticket reprint → passenger denied boarding | Med | Experience | ⚠️ (reissue API, no clear flow) |
| Parcel lost/damaged → dispute with no photo/ID evidence | Med | Legal/cash | ❌ |

### 2.3 Accounting gaps
1. No bank reconciliation (F-1)
2. No tax/GST breakdown (F-3)
3. No expense approval gate (F-4)
4. No GL/journal export / accounting-package integration (F-6)
5. No payment-connector settlement reconciliation (F-7)
6. No receivables aging (F-2)
7. No fixed assets/payroll (F-8, F-9)
8. No conductor/cashier cash ledger (Co-4, C-6)
9. No fuel cost capture (A-5, D-3)
10. No COD/claims ledger (G-4, G-6)

### 2.4 Reporting gaps
1. Consolidated multi-terminal P&L (O-1)
2. Load factor / fleet utilization (O-2)
3. Planned vs actual (departure times, revenue per trip vs expectation) (O-5, O-8)
4. Exception-based management feed (O-5)
5. Tax/statutory exports (F-3)
6. Per-crew performance (O-3)
7. Cash difference register by cashier (C-6, S-1)
8. Cargo claims aging (G-6)
9. Live dispatch board (M-5)
10. Refund/settlement SLA aging (F-10, M-1)

### 2.5 Approval gaps
1. **No separation-of-duties enforcement** — verify vs approve on settlements; payment decisions (M-2)
2. **No expense approval** (F-4)
3. **No price-override approval/reason** (C-5)
4. **No void/cancel approval register** (C-8)
5. **No escalation/SLA** on refunds, settlements, corporate approvals (M-1)
6. **No supervisor manual-hold grant** (C-4)
7. **No claim payout approval** (G-6)
8. **No schedule-change approval trail** (A-7)

### 2.6 Offline gaps
1. Counter **cannot sell offline** (read-only cache) — queued writes designed but not delivered (C-9) — **CRIT**
2. No conductor offline tool at all (Co-6)
3. No cargo roadside offline capture (G-8)
4. No gate offline validation (Gt-2)
5. Sync is pull/push device-based; no conflict-resolution UI for real cash disputes (M2 design exists server-side, not surfaced)
6. Offline ticket validation (scanner) — validated state requires network to POST; risk of double-use if offline scan falls back to local only (F-03 fixed server-side, but gate offline behavior undefined)

---

## 3. Priority roadmap for the business (not code)

### Phase 1 — Revenue & cash integrity (do first)
1. **Conductor waybill + onboard sales** (Co-1/Co-2/Co-4) — offline-first conductor app; trip-end cash handover to counter; stop-by-stop boarding.
2. **Shift handover / till transfer** (S-1/S-2) — cashier A close-with-count → B open; difference note; per-cashier sales.
3. **Bank deposit reconciliation + cash count** (F-1/F-5).
4. **Offline counter sales with queue** (C-9) — sells queue locally, sync on reconnect, idempotency already designed.
5. **Price override + void approval with reason trail** (C-5/C-8).
6. **Receivables aging + credit hold on corporate bookings** (F-2).

### Phase 2 — Safety & legal (must-have for nationwide)
7. **Driver pre-trip inspection + trip sheet + fuel log** (D-1..D-3).
8. **Document expiry tracking** (A-6) + **duty-hours** (A-1/D-5).
9. **Cargo ID/photo capture + weight limit enforcement** (G-1/G-2/G-7).
10. **Gate manifest + headcount at dispatch** (Gt-1/Gt-4).

### Phase 3 — Passenger experience (differentiator)
11. **Delay/cancellation notifications** to booked passengers (P-4).
12. **Rebooking/transfer + refund status self-service** (P-3/P-5).
13. **E-ticket QR for boarding** (P-2).
14. **SMS booking confirmation** (P-8).
15. **Public parcel tracking** (G-9).

### Phase 4 — Management & finance depth
16. **Consolidated P&L + load factor + exception feed** (O-1/O-2/O-5).
17. **Separation-of-duties + SLA/escalation engine** (M-2/M-1).
18. **GL export** (F-6).
19. **COD + claims** (G-4/G-6).
20. **Live dispatch board** (M-5).

---

## 4. What HBT gets right (acknowledgments)
- **Seat locks** prevent double-booking — genuinely production-grade.
- **Counter shift P&L** (opening cash → closing net → difference) is a strong foundation most competitors lack.
- **Trip lifecycle** (planned→…→closed) with operational events is complete and correct.
- **Cargo status machine** is industry-real (incl. refused/damaged/lost/returned).
- **Offline sync architecture** (device registry, cursor pull, idempotency) is the right skeleton — it just needs the write path and the missing roles.
- **Corporate bookings + approvals** exist — rare in this market.
- **Refund workflow** (request→decision→paid→complete) is disciplined.

## 5. Verdict

| Dimension | Assessment |
|-----------|------------|
| Revenue spine (counter sales, seat locks, ticketing) | **Strong — pilot-ready** |
| Cargo | **Good foundation — missing COD, claims, ID/photo, capacity** |
| Passenger self-service | **Functional MVP — stops at purchase; no service recovery** |
| Cash & accounting | **Weak — no bank rec, no handover, no tax, no GL** |
| Crew (driver/conductor) | **Absent — the biggest gap in the whole platform** |
| Gate/dispatch | **Partial — lifecycle exists, manifest/headcount missing** |
| Management oversight | **Weak — retrospective, no exceptions, no SLA** |
| Offline | **Read-only — insufficient for the Myanmar network reality** |

**Bottom line:** HBT is a **strong single-terminal ticketing system with a real offline
skeleton**, but to run a nationwide bus company it must add: (1) the conductor/driver
workflows that capture the untracked majority of cash, (2) cash/accounting integrity
(handover, bank rec, tax, GL), (3) offline write capability, (4) passenger service
recovery (delay/notification/rebooking), and (5) safety/legal controls (inspection,
document expiry, cargo capacity). None of this requires re-architecting what exists —
it requires building the roles and workflows that are missing.

*This audit reviewed business workflows only; no code was modified.*
