# Offline Validation Plan — HBT Business App

**Objective:** Validate the offline-first architecture under production conditions
**Scale:** 1,000 bookings, 5 counters, 10 spare devices
**Duration:** 3 days (1 day setup, 2 days execution)
**Environment:** Isolated test environment with network fault injection

---

## 1. Test Environment

### 1.1 Hardware setup

```
Test Lab Layout
═══════════════════════════════════════════════════════════

              ┌──────────────────┐
              │  Backend Server  │  (Docker Compose + API + DB)
              │  10.0.0.1:8000   │
              └────────┬─────────┘
                       │ LAN (10.0.0.0/24)
                       │
       ┌───────────────┼───────────────────┐
       │               │                   │
  ┌────▼────┐    ┌────▼────┐         ┌─────▼─────┐
  │ Counter  │    │ Counter  │         │ Network   │
  │ A (C-01) │    │ B (C-02) │  ...    │ Fault     │
  │ 2 devices│    │ 2 devices│         │ Injector  │
  └──────────┘    └──────────┘         │ (mitmproxy │
                                       │  + tc)    │
  ┌────▼────┐    ┌────▼────┐           └───────────┘
  │ Counter  │    │ Counter  │
  │ C (C-03) │    │ D (C-04) │
  │ 2 devices│    │ 2 devices│
  └──────────┘    └──────────┘

  ┌────▼────┐
  │ Counter  │
  │ E (C-05) │
  │ 2 devices│
  └──────────┘

Total: 5 counters × 2 devices = 10 devices
```

### 1.2 Device configuration

| Device ID | Counter | Role | Emulator |
|-----------|---------|------|----------|
| dev-c01-p | C-01 | Primary | Android 14 (Pixel 7) |
| dev-c01-s | C-01 | Spare | Android 14 (Pixel 7) |
| dev-c02-p | C-02 | Primary | iOS 17 (iPhone 15) |
| dev-c02-s | C-02 | Spare | iOS 17 (iPhone 15) |
| dev-c03-p | C-03 | Primary | Android 13 (Pixel 6) |
| dev-c03-s | C-03 | Spare | Android 13 (Pixel 6) |
| dev-c04-p | C-04 | Primary | Android 14 (Pixel 7a) |
| dev-c04-s | C-04 | Spare | Android 14 (Pixel 7a) |
| dev-c05-p | C-05 | Primary | Android 12 (Pixel 5) |
| dev-c05-s | C-05 | Spare | Android 12 (Pixel 5) |

### 1.3 Network fault injection

Tool: `tc` (Linux traffic control) on the emulator host + mitmproxy

| Profile | Latency | Packet loss | Bandwidth | Duration |
|---------|---------|-------------|-----------|----------|
| Perfect | 5ms | 0% | 100 Mbps | Baseline |
| Mobile 4G | 50ms | 0.5% | 20 Mbps | Standard |
| Mobile 3G | 200ms | 2% | 5 Mbps | Standard |
| Edge / Poor | 800ms | 10% | 1 Mbps | Test cycles |
| Dead zone | — | 100% | 0 bps | 5-30 min intervals |

---

## 2. Test Data Plan

### 2.1 Pre-seeded data

| Entity | Count | Notes |
|--------|-------|-------|
| Organizations | 3 | Org-A (5 routes), Org-B (3 routes), Org-C (2 routes) |
| Routes | 10 | Various city pairs: Mandalay→Yangon, Yangon→Mandalay, etc. |
| Trips | 50 | Spread across 7 days, various departure times |
| Stops per route | 5-15 | Sequential stops with terminals |
| Terminals | 25 | Cities: Mandalay, Yangon, Naypyidaw, Taungoo, Meiktila, etc. |
| Seats per trip | 45 | Layout: 10 rows × 4 seats + 5 rear |
| Passengers | 500 | Pre-registered in the system |
| Fare rules | 10 | Standard, Student, Child, VIP, etc. |

### 2.2 Booking schedule

1,000 bookings distributed across 2 days:

```
Day 1 (600 bookings):
  Morning session (09:00-12:00):  200 bookings
  Afternoon session (13:00-17:00): 250 bookings
  Evening session (18:00-20:00):   150 bookings

Day 2 (400 bookings):
  Morning session (09:00-12:00):  150 bookings
  Afternoon session (13:00-17:00): 200 bookings
  Stress test (17:00-19:00):       50 bookings
```

---

## 3. Validation Scenarios

### 3.1 Happy path — online only

**Objective:** Validate the basic booking flow works when all devices are online.

**Steps:**
1. All 10 devices online with perfect network (5ms latency)
2. Each counter books 10 seats sequentially (50 bookings total)
3. Each device books 10 seats (100 bookings total)
4. Verify: All 150 bookings appear on the server
5. Verify: All bookings have unique seat + trip combinations
6. Verify: No duplicate operations in `sync_operations` table
7. Verify: Server-side ticket numbers are sequential without gaps

**Pass criteria:** 150/150 bookings confirmed, 0 duplicate seats, 0 errors.

### 3.2 Happy path — offline then sync

**Objective:** Validate the offline queue → sync flow works correctly.

**Steps:**
1. Take 5 devices offline (disconnect LAN)
2. Each offline device books 10 seats using TMP ticket numbers (50 bookings)
3. Keep 5 devices online, they book another 50 seats
4. Reconnect offline devices after 5 minutes
5. Wait for sync to complete (up to 2 minutes)
6. Verify: All 100 bookings appear on the server
7. Verify: All TMP numbers replaced with server-assigned numbers
8. Verify: `temp_ticket_numbers` table shows `status='replaced'` for all 50
9. Verify: No duplicate seats across online + offline bookings

**Pass criteria:** 100/100 bookings confirmed, 0 TMP orphans, 0 collisions.

### 3.3 Seat conflict — two counters, same seat

**Objective:** Validate seat conflict detection and resolution.

**Steps:**
1. Device A (Counter C-01) and Device B (Counter C-02) both select Seat 12 on Trip T-001
2. Both complete the booking form and tap "Confirm"
3. Both synced within 30 seconds of each other
4. Verify: Exactly 1 booking succeeds (first sync)
5. Verify: 1 booking shows `conflict_seat` status locally
6. Verify: Conflict dialog offers alternative seats
7. On the losing device, select an alternative seat
8. Verify: Alternative booking succeeds
9. Verify: Server has exactly 2 bookings for Trip T-001 (different seats)

**Pass criteria:** 2 successful bookings, 0 duplicate seats, 1 conflict log entry.

### 3.4 Seat conflict — counter + spare, same counter

**Objective:** Validate seat conflict between primary and spare at the same counter.

**Steps:**
1. Counter C-01 Primary and Spare both select Seat 8 on Trip T-002
2. Both complete booking simultaneously
3. Vary sync order: run 10 times, alternating which device syncs first
4. Verify: First sync wins every time (deterministic, not random)
5. Verify: Loser always sees conflict dialog
6. Verify: Conflict log records `seat_conflict` with both device IDs

**Pass criteria:** 10/10 trials produce exactly 1 winner, 1 conflict, 0 double-bookings.

### 3.5 Duplicate tap prevention

**Objective:** Validate idempotency keys prevent double bookings.

**Steps:**
1. Counter A creates a booking normally
2. Immediately tap "Confirm Booking" again (within 1 second)
3. Force-restart the app before the second sync runs
4. On next launch, the app syncs
5. Verify: Exactly 1 booking on the server
6. Verify: `idempotency_keys` table shows 1 completed entry
7. Verify: `sync_operations` shows 1 completed entry (not 2)
8. Test: Simulate network timeout on the POST response (server processes, client times out)
9. Client retries with same idempotency key
10. Verify: Server returns cached response (no duplicate)
11. Verify: Payment recorded exactly once

**Pass criteria:** 10/10 double-tap scenarios produce exactly 1 booking/ payment.

### 3.6 Offline queue — 100 concurrent bookings

**Objective:** Stress-test the offline queue with high volume.

**Steps:**
1. Take all 10 devices offline simultaneously
2. Each device rapidly creates 10 bookings (100 total, ~1 booking per 10 seconds per device)
3. Keep devices offline for 30 minutes
4. Bring all devices online simultaneously (connect all at once)
5. Watch sync queue: 100 operations push in batches of 50
6. Verify: All 100 bookings appear on the server
7. Verify: Sync operation order: `seat.lock` → `booking.create` (correct dependency chain)
8. Verify: `sync_operations` shows 100 `completed` entries
9. Verify: No `rejected` or `conflict` entries (no seat overlap in this test)

**Pass criteria:** 100/100 bookings confirmed, 0 queue errors, 0 dependency failures.

### 3.7 Network failure — mid-sync

**Objective:** Validate retry behaviour when network drops during a sync push.

**Steps:**
1. Device has 5 pending offline bookings
2. Start sync cycle
3. Inject network failure at different points:
   a. Before push request body is sent (client-side failure)
   b. After request body sent, before server response (half-open TCP)
   c. After server confirms, before response received (client timeout)
   d. After partial batch processing (server processed 2 of 5)
4. Verify (a): All 5 ops still `pending`, retry on next cycle
5. Verify (b): Client timeout, ops go to `failed_network`, retry with backoff
6. Verify (c): Client retries with same `client_operation_id`, server returns cached
7. Verify (d): Server processes remaining 3 on retry

**Pass criteria:** All 5 bookings eventually confirmed in all 4 network failure patterns. 0 duplicate bookings. 0 lost bookings.

### 3.8 Device crash during booking

**Objective:** Validate data integrity when device crashes mid-flow.

**Steps:**
1. Each device, for each crash point (10 devices × 5 crash points = 50 tests):
   a. Crash after seat lock, before booking form
   b. Crash after booking form filled, before tapping "Confirm"
   c. Crash after tapping "Confirm", before local DB write finishes
   d. Crash after local DB write, before sync queue enqueue
   e. Crash after sync queue enqueue, before sync push
2. After each crash, restart the device
3. Verify (a): Seat lock was created — on restart, lock shows as expired (5-min TTL)
4. Verify (b): Form data is lost (no persistence) — user must re-enter
5. Verify (c): Incomplete booking — no record in DB (write didn't complete)
6. Verify (d): Booking exists in local DB — shows as `pending_sync` on restart
7. Verify (e): Sync queue has the operation — syncs on next cycle

**Pass criteria:** No data corruption in any crash scenario. Partial operations don't reach server.

### 3.9 Power loss during sync

**Objective:** Validate behaviour when device battery dies mid-sync.

**Steps:**
1. Device has 20 pending offline bookings
2. Start sync cycle
3. When sync batch reaches 40% progress, simulate power loss (kill process)
4. On restart, app initializes:
   a. `AppDatabase.initialize()` re-opens encrypted DB
   b. `SyncUploadQueue` reads pending operations from DB
   c. Sync resumes from where it left off
5. Verify: No operations lost (DB write-ahead log preserves data)
6. Verify: Operations that were `uploading` status revert to `pending`
   (needs `failStaleOperations()` or equivalent recovery)
7. Verify: No orphaned server-side operations (idempotency prevents duplicates)
8. Repeat: Power loss during DB write (before transaction commits)
9. Verify: Transaction rolled back, no partial data

**Pass criteria:** 20/20 bookings confirmed after restart. 0 corrupted records. 0 lost operations.

### 3.10 Clock drift — 10 minutes fast

**Objective:** Validate that devices with fast clocks don't break seat lock TTLs.

**Steps:**
1. Set Device A system clock 10 minutes ahead of real time
2. Device A creates a seat lock (lock expiry = device time + 5 min = real time + 15 min? No — server uses server time)
3. Device B (correct clock) tries to book the same seat
4. Verify: Device A's lock expires based on **server time** = real 5 min
5. Verify: Device B can book the seat after 5 real minutes
6. Device A creates a booking (timestamp in payload shows wrong time)
7. Verify: Server records booking with server timestamp, not device timestamp
8. Verify: Cursor-based sync still works (not affected by clock)

**Pass criteria:** Seat lock expires correctly. Booking timestamps use server time. Sync cursor advances correctly.

### 3.11 Clock drift — 10 minutes slow

**Objective:** Validate that devices with slow clocks don't cause issues.

**Steps:**
1. Set Device A system clock 10 minutes behind real time
2. Device A creates a seat lock
3. Verify: Server sets lock expiry to SERVER_NOW + 5 min (correct)
4. Device A holds the lock for 5 real minutes
5. Verify: Lock expires after 5 real minutes (server-side TTL sweep)
6. Device A creates a booking
7. Verify: Booking appears in correct chronological position on server
8. Device A syncs — cursor-based pull returns all changes after last cursor
9. Verify: No changes skipped or duplicated due to time mismatch

**Pass criteria:** Lock TTL from local clock is irrelevant — server uses server time. All operations succeed.

### 3.12 Server restart during sync

**Objective:** Validate client recovers from server outage mid-sync.

**Steps:**
1. 5 devices with pending offline bookings (25 operations total)
2. Initiate sync on all devices simultaneously
3. Restart backend server mid-sync:
   a. Before accepting push request
   b. During push processing (server crashes with operations half-processed)
   c. After push response sent, before client receives it
4. Server comes back up (5 second restart)
5. Verify (a): Client gets connection refused → retry after backoff → succeeds
6. Verify (b): Server recovers — processed operations are persisted (idempotent on retry)
7. Verify (c): Client retries with same `client_operation_id` → server returns cached
8. Verify: All 25 operations eventually complete
9. Verify: `sync_operations` on all devices show `completed`

**Pass criteria:** 25/25 operations complete after server restart. 0 duplicate operations. 0 orphaned bookings.

### 3.13 Temporary ticket number — 1,000 sequential

**Objective:** Validate TMP numbering doesn't overflow or collide at scale.

**Steps:**
1. Take 10 devices offline
2. Each device generates TMP numbers for 100 bookings (1,000 total)
3. Verify: All 1,000 TMP numbers are unique
4. Verify: Format is `TMP-XXX-001` through `TMP-XXX-100` (3 digits, no overflow)
5. Verify: Sequence persists across app restarts (kill process, restart, continue from 101)
6. Bring devices online, sync all 1,000 bookings
7. Verify: Server assigns 1,000 unique ticket numbers
8. Verify: TMP → server number mapping is complete (no orphans)
9. Verify: No duplicate server ticket numbers

**Pass criteria:** 1,000/1,000 TMP numbers unique. 1,000/1,000 server numbers assigned. 0 collisions.

### 3.14 Spare device promotion — primary fails

**Objective:** Validate spare takeover when primary device dies.

**Steps:**
1. Counter C-01 Primary has 5 pending offline bookings
2. Counter C-01 Spare device takes over:
   a. Spare detects primary is offline (no sync from primary for > 5 min)
   b. Spare requests promotion: `POST /devices/promote/`
   c. Server promotes spare to primary role
3. Newly-promoted spare creates 5 new bookings
4. Old primary comes back online
5. Verify: Old primary is now `role=spare`
6. Verify: New primary continues accepting bookings normally
7. Verify: Old primary's 5 pending bookings sync correctly as spare
8. Verify: All 10 bookings (5 from old primary + 5 from new primary) appear on server

**Pass criteria:** Seamless promotion. No data loss. No split-brain (only 1 primary per counter).

### 3.15 Spare promotion race — two spares

**Objective:** Validate that two spares can't both become primary.

**Steps:**
1. Counter C-02 Primary fails
2. Spare A and Spare B both detect primary offline simultaneously
3. Both send promotion requests at the same time
4. Verify: Exactly 1 promotion succeeds (atomic server operation)
5. Verify: The other spare gets `promotion_failed` response
6. Verify: Failed spare stays as spare with message "Spare-X is now primary"
7. Repeat 10 times with varying request order
8. Verify: Deterministic — first request processed wins every time

**Pass criteria:** 10/10 trials: 1 primary, 1 spare. No split-brain state.

### 3.16 Retry exhaustion — server down 30 minutes

**Objective:** Validate dead letter queue when server is unavailable for extended period.

**Steps:**
1. 5 devices create 2 bookings each (10 total)
2. Take backend server offline
3. Devices attempt sync every 2-300 seconds (exponential backoff)
4. After ~18.5 minutes, all 10 operations reach `dead_letter` status
5. Verify: `sync_operations.status = 'dead_letter'` for all 10
6. Verify: Sync dashboard shows 10 dead letter entries
7. Verify: Local bookings still visible to staff (marked "pending sync")
8. Bring server back online
9. Staff taps "Retry All" on sync dashboard
10. Verify: All 10 operations retry and succeed

**Pass criteria:** 10/10 bookings survive retry exhaustion. Staff can manually retry.

### 3.17 Queue ordering — cross-device dependency

**Objective:** Validate that dependent operations across devices are handled correctly.

**Steps:**
1. Device A creates a booking (offline)
2. Device B creates a fare quote for Device A's booking (offline)
   (This requires Device A's booking to exist on the server first)
3. Both devices come online at the same time
4. Device A's booking syncs first
5. Device B's fare quote syncs next
6. Verify: Device B's fare quote succeeds (booking exists on server)
7. If Device B's fare quote syncs BEFORE Device A's booking:
   a. Server returns `dependency_missing` error
   b. Device B retries after backoff
   c. On retry, Device A's booking has synced → fare quote succeeds
8. Verify: Fare quote eventually succeeds regardless of sync order

**Pass criteria:** Fare quote succeeds in all ordering scenarios. 0 orphaned fare quotes.

### 3.18 Concurrent booking — 5 counters, same trip

**Objective:** Stress-test seat locking with all counters booking the same popular trip.

**Steps:**
1. Trip T-001 (Mandalay→Yangon, 45 seats) is the target
2. All 5 counters (10 devices) attempt to book seats simultaneously
3. Each device books as many seats as possible (target: 45 total = full bus)
4. All devices offline for first 50 bookings (TMP numbers)
5. All devices come online simultaneously
6. Verify: Exactly 45 bookings succeed (one per seat)
7. Verify: 5 bookings receive `seat_conflict` and require reselection
8. 5 conflict bookings select remaining seats (there should be none)
9. Verify: Those 5 fail again — bus is full
10. Staff offers alternative trip to affected passengers

**Pass criteria:** 45 confirmed bookings, 0 double-booked seats, 5 visible conflicts requiring manual intervention.

### 3.19 Payment idempotency — crash after charge

**Objective:** Validate that payments are never charged twice.

**Steps:**
1. Counter records a cash payment of 15,000 MMK
2. Payment written to local DB (status: pending_sync)
3. Sync sends payment to server
4. Server processes payment (accounting entry created)
5. Server response lost due to network timeout
6. Client retries with same `idempotency_key_hash`
7. Server returns cached payment (no second charge)
8. Verify: Accounting shows exactly 1 payment entry for 15,000 MMK
9. Repeat 20 times with varying crash points:
   a. Crash before idempotency key stored
   b. Crash after key stored, before sync enqueue
   c. Crash mid-sync (server processed, response lost)
   d. Server crash after processing, before response

**Pass criteria:** 20/20 trials: exactly 1 payment charged. 0 duplicate charges. 0 lost payments.

### 3.20 Clock drift + seat lock + sync

**Objective:** Validate combined clock drift + seat lock + sync scenario.

**Steps:**
1. Device A: clock = real time + 8 minutes
2. Device B: clock = real time - 5 minutes
3. Device A locks Seat 12 on Trip T-001
4. Device A goes offline
5. 6 real minutes pass (Device A's lock should expire server-side)
6. Device B (correct lock timing) tries to book Seat 12
7. Verify: Device B succeeds — server-side TTL has expired
8. Device A comes back online after 10 real minutes
9. Device A's lock operation syncs (already expired on server)
10. Verify: Server accepts the expired lock notification gracefully
11. Device A's pending booking (if any) gets `seat_conflict`
12. Verify: No stale locks on server. No double-booking.

**Pass criteria:** Server-side TTL is authoritative. Clock drift does not extend lock duration. No stale locks survive server-side sweep.

---

## 4. Monitoring & Metrics

### 4.1 Metrics to capture

| Metric | Collection point | Target |
|--------|-----------------|--------|
| API call count per screen | mitmproxy logs | N/A (baseline) |
| Sync queue size over time | Local DB queries | N/A (baseline) |
| Sync push latency (ms) | Client-side timer | < 5s for batch of 50 |
| Sync pull latency (ms) | Client-side timer | < 3s per pull |
| Conflict count | `conflict_log` table | < 5% of total ops |
| Seat conflict count | `conflict_log WHERE type='seat_conflict'` | < 2% of total ops |
| Duplicate tap prevention hits | `idempotency_keys` table | N/A (measure rate) |
| Retry count per operation | `sync_operations` retry field | < 2 avg |
| Dead letter count | `sync_operations WHERE status='dead_letter'` | < 1% of total ops |
| TMP→server reconciliation time | `temp_ticket_numbers` age | < 2 min |
| Server-side TTL sweep catch count | Server logs | N/A (measure rate) |
| Clock drift detection count | Client logs | N/A (measure rate) |
| Crash recovery count | Client crash logs | N/A (measure rate) |

### 4.2 Dashboard during test execution

```
┌─────────────────────────────────────────────────────────────────────┐
│  OFFLINE TEST DASHBOARD                               LIVE: 12:34  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Overall Progress: ████████████░░░░░░░░░░  52% (520/1000 bookings)  │
│                                                                      │
│  ┌────────────┬──────────┬──────────┬──────────┬──────────────────┐ │
│  │ Counter    │ Confirmed│ Pending  │ Conflict │ Dead Letter      │ │
│  ├────────────┼──────────┼──────────┼──────────┼──────────────────┤ │
│  │ C-01       │ 104      │ 2        │ 1        │ 0                │ │
│  │ C-02       │ 98       │ 5        │ 3        │ 0                │ │
│  │ C-03       │ 112      │ 0        │ 0        │ 0                │ │
│  │ C-04       │ 96       │ 8        │ 2        │ 1                │ │
│  │ C-05       │ 110      │ 0        │ 1        │ 0                │ │
│  ├────────────┼──────────┼──────────┼──────────┼──────────────────┤ │
│  │ Total      │ 520      │ 15       │ 7        │ 1                │ │
│  └────────────┴──────────┴──────────┴──────────┴──────────────────┘ │
│                                                                      │
│  Sync Latency (last 10):  1.2s  0.8s  3.1s  0.9s  1.5s  2.2s      │
│  Seat Conflicts: 7  |  Duplicate Taps Blocked: 23                   │
│  Dead Letters: 1 (retry pending)                                    │
│                                                                      │
│  Network Profile: MOBILE_4G (50ms, 0.5% loss)                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5. Success Criteria

### 5.1 Hard pass/fail

| Criteria | Threshold |
|----------|-----------|
| All 1,000 bookings confirmed on server | 100% |
| No duplicate seat assignments | 0 duplicates |
| No double-charged payments | 0 duplicates |
| All TMP numbers reconciled with server numbers | 100% |
| All crash scenarios recover without data loss | 100% |
| All power-loss scenarios recover without corruption | 100% |
| All network-failure scenarios complete within 10 retries | 100% |
| Spare promotion always produces exactly 1 primary | 100% |
| Clock drift never causes stale lock to persist beyond server TTL + 1 min | 100% |

### 5.2 Soft pass/fail

| Criteria | Target | Acceptable |
|----------|--------|------------|
| Seat conflict rate | < 5% | < 10% |
| Operations in dead letter | < 1% | < 3% |
| Average sync latency (batch of 50) | < 3s | < 5s |
| Retry count per operation (avg) | < 2 | < 4 |
| Time to reconcile 1000 offline bookings | < 5 min | < 10 min |

---

## 6. Runbook

### 6.1 Test execution order

```
Day 1 — Morning (Setup):
  └── 1.1 Hardware setup
  └── 1.2 Device provisioning
  └── 1.3 Data seeding
  └── 1.4 Network injector calibration
  └── 1.5 Dry run: 5 bookings, happy path

Day 1 — Afternoon (Foundation tests):
  └── 3.1 Happy path — online only (150 bookings)
  └── 3.2 Happy path — offline then sync (100 bookings)
  └── 3.3 Seat conflict — two counters (20 bookings)
  └── 3.4 Seat conflict — counter + spare (10 trials)
  └── 3.5 Duplicate tap prevention (10 trials)
  └── 3.6 Offline queue — 100 concurrent (100 bookings)

Day 2 — Morning (Failure scenarios):
  └── 3.7 Network failure — mid-sync (20 bookings)
  └── 3.8 Device crash during booking (50 crash tests)
  └── 3.9 Power loss during sync (20 bookings)
  └── 3.10 Clock drift — fast (20 bookings)
  └── 3.11 Clock drift — slow (20 bookings)
  └── 3.12 Server restart during sync (25 bookings)

Day 2 — Afternoon (Stress scenarios):
  └── 3.13 TMP numbering — 1,000 sequential (no server, measure locally)
  └── 3.14 Spare promotion — primary fails (10 bookings)
  └── 3.15 Spare promotion race (10 trials)
  └── 3.16 Retry exhaustion — server down 30min (10 bookings)
  └── 3.17 Queue ordering — cross-device dependency (10 bookings)
  └── 3.18 Concurrent booking — 5 counters, full bus (45 bookings)
  └── 3.19 Payment idempotency — crash after charge (20 trials)
  └── 3.20 Clock drift + seat lock + sync (20 bookings)

Day 2 — Evening:
  └── Data export and analysis
  └── Report generation
```

### 6.2 Abort criteria

Stop the test and investigate if:

1. Any test produces a double-charged payment
2. Any test loses a booking (written locally but never synced)
3. Server data corruption detected (wrong seat assignment)
4. Two spares both become primary (split-brain)
5. TMP number collision in the first 500
6. Crash recovery produces corrupted database

### 6.3 Recovery procedures

| Issue | Recovery |
|-------|----------|
| Double-charged payment | Reverse in accounting system; fix idempotency bug |
| Lost booking | Check `sync_operations` dead letter + `conflict_log`; restore from backup |
| Split-brain promotion | Manually demote one primary; merge booking records |
| DB corruption after crash | Restore from last `AppDatabase` backup (WAL allows point-in-time) |
| Server data corruption | Restore from DB dump; replay sync_operations from dead letter |
| Sync queue stuck | Clear `uploading` status → all ops revert to `pending`; force retry |

---

## 7. Data Collection

At the end of Day 2, collect from each device:

| Artifact | Source | Format |
|----------|--------|--------|
| Sync operation log | `SELECT * FROM sync_operations ORDER BY created_at` | CSV |
| Conflict log | `SELECT * FROM conflict_log ORDER BY created_at` | CSV |
| Temp number mapping | `SELECT * FROM temp_ticket_numbers ORDER BY created_at` | CSV |
| Idempotency key log | `SELECT * FROM idempotency_keys ORDER BY created_at` | CSV |
| Seat lock events | App debug log (filter: `seat_lock`) | Text |
| Network trace | mitmproxy dump | HAR |
| Client crash logs | Android `logcat` / iOS device console | Text |
| Server booking table | `SELECT * FROM bookings JOIN tickets ...` | CSV |
| Server sync operations | `SELECT * FROM processed_operations ORDER BY created_at` | CSV |
| Server payment table | `SELECT * FROM payments WHERE created_at BETWEEN ...` | CSV |
