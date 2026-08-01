# HBT Transport Platform — User Journeys

**Version:** 1.0 · **Date:** 2026-08-01
**Author:** CPO
**Purpose:** Complete end-to-end journeys for every actor. Each journey lists steps,
system touches, data created, cash movements, failure paths, and offline behaviour.

---

## 1. Passenger journey

### 1.1 Book a trip (online)
1. Discover HBT (website / social / referral / ad).
2. Open booking website or passenger app.
3. Search: from terminal → to terminal → date.
4. View trip options (time, price, seats left, operator).
5. Select trip → view seat map → pick seat(s) → hold (lock, 5-min countdown).
6. Enter traveler details (name, phone, NRC).
7. Pay: cash (terminal), transfer (upload evidence), e-wallet (KBZ/Wave), card.
8. Receive confirmation: app push + SMS + email.
9. Receive e-ticket with QR (in-app + downloadable).
10. Boarding: show QR at gate → validated → board.

**Failure paths:** seat conflict (auto-suggest alternatives) · payment pending
(reminder) · trip cancelled (auto refund offer + alternative) · delayed (notification).

**Offline:** search/detail from cache; booking requires online (or queued with risk
policy).

### 1.2 Walk-up passenger (terminal)
1. Queue at counter.
2. Counter sells (see Counter journey) → prints ticket.
3. Board with paper ticket/QR.

### 1.3 Manage booking
- View history, cancel (refund policy applied), rebook/transfer (target), download
  e-ticket, view refund status.

### 1.4 Post-trip
- Feedback (rating), lost & found, complaint tracking.

---

## 2. Owner journey

### 2.1 Daily ops review
1. Login → dashboard.
2. Exception feed: settlements overdue, refund SLA breached, cash differences, low load.
3. Drill into branch/route.
4. Approve escalated items (above manager limits).
5. Check cash position (expected vs deposited).

### 2.2 Administer platform
1. Users → create user → assign org → assign role.
2. Roles → create/edit → select permissions → save.
3. Organizations → create org → appoint org owner.
4. Settings: fare policy, refund policy, thresholds.

### 2.3 Weekly/monthly
- P&L by branch/route; fleet utilization; receivables aging; crew KPIs; payroll approval.

---

## 3. Counter journey

### 3.1 Open shift
1. Login → tap "Open Shift".
2. Count float (opening cash) → enter denominations → confirm.
3. System opens till with float; counter is now the accountable cashier.

### 3.2 Sell a ticket
1. Pick trip (today list / search).
2. Seat map: tap seat → lock acquired (5-min) → passenger details.
3. Price shown (fare rule) → optional promo/discount (needs approval if override).
4. Payment: cash → till update; transfer → upload evidence; e-wallet.
5. Issue ticket → print (reprint if jammed).
6. Lock consumed; seat reserved.

### 3.3 Accept cargo
1. New shipment: sender info (NRC) → receiver info → description.
2. Photo of item → weigh → price (rule or manual) → payment.
3. Assign trip → print cargo receipt (QR).

### 3.4 Close shift
1. Count cash (denominations) → system computes expected vs counted → difference.
2. Submit shift → finance verifies.
3. Handover to next cashier (count + transfer) OR deposit to bank.

### 3.5 Offline
- Full offline selling (queue); print temp-numbered tickets; sync on reconnect; conflict
  resolution for seat races (server decides, second sale refunded).

---

## 4. Conductor journey

1. Receive trip assignment (push/notification).
2. Collect trip sheet/waybill at dispatch (assigned trip, manifest, float if any).
3. Board at origin: count passengers vs manifest.
4. En-route: sell onboard tickets (cash) — sequential numbers; record boarding per stop.
5. En-route cargo: accept roadside parcels (photo, weight, price, cash).
6. Record expenses (tolls, meals, parking).
7. Arrive: count cash → complete waybill (sales, cargo, expenses) → submit settlement.
8. Hand over cash to Finance/Counter → get receipt → sign off.

**Offline:** everything works offline; sync at terminal; QR verify uses cached list.

---

## 5. Driver journey

1. Receive trip assignment.
2. Pre-trip inspection checklist (tyres, brakes, lights, fuel, documents) → submit.
3. Accept trip sheet (route, stops, times, manifest summary).
4. Drive: record fuel top-ups, stops, delays.
5. Breakdown/incident → report (location, photos) → dispatch/manager notified.
6. Arrive → end-of-trip handover: odometer, fuel, defects → sign.

**Offline:** full offline; inspection blocks dispatch when online (gate checks).

---

## 6. Finance journey

### 6.1 Daily
1. Pending queue: settlements, refunds, expenses, payment verifications.
2. Verify settlement (waybill vs cash) → approve within limit / escalate.
3. Verify payment evidence → confirm → ticket issued.
4. Bank: expected deposits per branch vs received slips → reconcile.

### 6.2 Weekly
- Aging report → dunning corporate customers.

### 6.3 Monthly
- P&L by branch/route; payroll run (HR input) → approve; GL export; tax report.

---

## 7. Gate journey

1. Open manifest for trip (expected passengers, seats).
2. Validate tickets: scan QR (online or cached) → mark boarded.
3. No-show handling: call passenger, hold seat until cutoff.
4. Headcount at cutoff: boarded vs manifest → confirm dispatch.
5. Dispatch: bus departs → trip status update → crew notified.

---

## 8. Cargo journey (staff)

1. Accept: sender ID (NRC), item photo, weight/dims → price → payment/COD flag.
2. Assign trip + vehicle; add to cargo manifest.
3. Load (weight check vs vehicle capacity).
4. In-transit: status updates at stops (scan).
5. Arrival: notify consignee (SMS).
6. Handover: verify ID + signature + photo → close.
7. Claim: dispute → photos/evidence → claim record → payout approval.

---

## 9. Fleet journey

1. Vehicle register (documents: registration, insurance, permit).
2. Maintenance schedule (service due by km/date) → work order.
3. Mechanic repairs → parts + labour logged → cost to vehicle/trip.
4. Fuel monitoring: top-ups vs odometer → variance alerts.
5. Assignment planning: vehicle + crew to trips (avoid fatigue/overlap).

---

## 10. HR journey

1. Hire: staff record (docs, NRC, license) → create user → assign role.
2. Roster: weekly plan (drivers/conductors/counters) → publish.
3. Attendance: check-in/out (app or biometric) → payroll input.
4. Document expiry alerts → renewals.
5. Disciplinary/incident records.

---

## 11. Manager journey

1. Open live ops board (today's trips, status, load, crew, alerts).
2. Approvals queue: refunds, settlements, overrides, voids.
3. Resolve alerts: late departures, cash differences, no-shows, incidents.
4. Manual interventions: breakdown → transfer passengers to next bus; overbooking →
   reroute.
5. Reports: terminal P&L, on-time, load factor, crew performance.

---

## 12. Cross-cutting journey notes

- **Every journey is offline-capable** for field roles; money actions reconcile online.
- **Every money step** has: actor, scope, trip/shift, timestamp, audit event.
- **Every approval** is: request → verify → approve → (escalate) with SLA.
- **Notifications** fire at every meaningful state change (per channel matrix in
  blueprint §6).

---

*Runtime review (docs/runtime_ui_review.md, docs/runtime_gap_analysis.md) measures how
much of these journeys the current build supports today.*
