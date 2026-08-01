# P0-04: Production-Grade Seat Lock System

**Task ID:** P0-04
**Date:** 2026-07-30
**Priority:** P0 (Critical — prevents double-booking)
**Status:** ✅ Implemented

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    SEAT LOCK SYSTEM                               │
│                                                                   │
│  ┌──────────┐     ┌──────────────┐     ┌─────────────────────┐   │
│  │ Counter   │────▶│ SeatLockCtrl  │────▶│ Server (POST/DELETE)│   │
│  │ Booking   │     │              │     │                     │   │
│  │ Page      │     │ acquire()    │     │ POST /seat-lock/    │   │
│  │           │     │ release()    │     │ DELETE /seat-lock/  │   │
│  │           │     │ extend()     │     │ GET /seat-locks/    │   │
│  │           │     │              │     │                     │   │
│  │           │     │ TTL timer    │     │ SeatLock model      │   │
│  │           │     │ 1s ticks     │     │ Partial unique idx  │   │
│  │           │     │ Auto-release │     │ Auto-sweep (5 min)  │   │
│  └──────────┘     └──────────────┘     └─────────────────────┘   │
│                                                                   │
│  Duplicate prevention:                                            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ 1. UI → debounce lock acquire (no double-tap)              │  │
│  │ 2. Client → idempotency_key in POST body                   │  │
│  │ 3. Server → partial unique index (trip, seat, status=active)│  │
│  │ 4. Server → booking creation validates lock ownership       │  │
│  │ 5. Business → booking confirmed seat associated             │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## API Specification

### `POST /organizations/{orgId}/seat-lock/`

Acquire a lock on a seat. Idempotent for the same owner + seat.

**Request:**
```json
{
  "trip_id": "uuid",
  "seat_position": "1A",
  "held_by_user_id": "uuid (optional)",
  "held_by_device_id": "uuid (optional)",
  "idempotency_key": "lock_{trip}_{seat}_{user}_{device}"
}
```

**Response 201:**
```json
{
  "id": "lock-uuid",
  "trip_id": "uuid",
  "seat_position": "1A",
  "held_by_user_id": "uuid",
  "held_by_device_id": "uuid",
  "held_at": "2026-07-30T10:00:00Z",
  "expires_at": "2026-07-30T10:05:00Z",
  "status": "active"
}
```

**Response 409 — Already locked:**
```json
{
  "code": "seat_already_locked",
  "detail": "Seat 1A is locked by another counter until 2026-07-30T10:05:00Z.",
  "held_by": "device-id",
  "expires_at": "2026-07-30T10:05:00Z"
}
```

**Response 409 — Already booked:**
```json
{
  "code": "seat_booked",
  "detail": "Seat 1A belongs to a confirmed booking."
}
```

### `DELETE /organizations/{orgId}/seat-lock/{lockId}/`

Release a lock.

**Response 200:**
```json
{
  "status": "released"
}
```

**Response 404:**
```json
{
  "detail": "Lock not found or already expired."
}
```

### `GET /organizations/{orgId}/seat-locks/?trip_id={tripId}`

List all active locks for a trip.

**Response 200:**
```json
[
  {
    "id": "lock-uuid",
    "trip_id": "uuid",
    "seat_position": "1A",
    "held_by_user_id": "uuid",
    "held_by_device_id": "uuid",
    "held_at": "2026-07-30T10:00:00Z",
    "expires_at": "2026-07-30T10:05:00Z",
    "status": "active"
  }
]
```

### `POST /organizations/{orgId}/seat-lock/{lockId}/extend/`

Extend lock TTL (reset to current time + 5 min).

**Response 200:**
Same as POST response with updated `expires_at`.

---

## Database Schema (Server-side)

```sql
CREATE TABLE seat_locks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id),
    seat_position   TEXT NOT NULL,
    held_by_user_id  UUID REFERENCES users(id),
    held_by_device_id TEXT,
    held_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '5 minutes'),
    status          TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'released', 'expired')),
    idempotency_key TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partial unique index: only one active lock per seat per trip
CREATE UNIQUE INDEX uq_active_seat_lock
    ON seat_locks(trip_id, seat_position)
    WHERE status = 'active';

-- Index for listing locks by trip
CREATE INDEX idx_seat_locks_trip ON seat_locks(trip_id);

-- Index for expiry sweep
CREATE INDEX idx_seat_locks_expires ON seat_locks(expires_at)
    WHERE status = 'active';

-- Idempotency key index
CREATE UNIQUE INDEX uq_seat_lock_idempotency
    ON seat_locks(idempotency_key)
    WHERE idempotency_key IS NOT NULL;
```

### Auto-expiry sweep

```sql
-- Run every 30 seconds via pg_cron or application scheduler
UPDATE seat_locks
SET status = 'expired', updated_at = NOW()
WHERE status = 'active' AND expires_at < NOW();
```

---

## Sequence Diagram

```
Counter A                  Server                    Counter B
    │                         │                         │
    │──POST /seat-lock/ ──────┤                         │
    │  {trip, seat: "1A"}     │                         │
    │                         ├── Check: no active lock │
    │                         ├── INSERT seat_lock       │
    │                         │   (UQ: trip+seat active) │
    │  201 Created ←──────────┤                         │
    │                         │                         │
    │  [seat=1A selected]     │                         │
    │  [5 min TTL starts]     │                         │
    │                         │                         │
    │                         │                         │──POST /seat-lock/ ──┤
    │                         │                         │  {trip, seat:"1A"} │
    │                         │                         ├── Check: active    │
    │                         │                         │   lock exists!     │
    │                         │                         │   → 409 Conflict   │
    │                         │                         │←───────────────────│
    │                         │                         │  [seat=1A blocked] │
    │                         │                         │  [shown as locked] │
    │                         │                         │                     │
    │──POST /bookings/ ───────┤                         │                     │
    │  {seat: "1A"}           │                         │                     │
    │                         ├── Validate lock exists  │                     │
    │                         │   for this device       │                     │
    │                         ├── Validate lock active  │                     │
    │                         ├── Create booking        │                     │
    │                         ├── Release lock          │                     │
    │                         │   (DELETE /seat-lock/)  │                     │
    │  201 Booked ←───────────┤                         │                     │
    │                         │                         │                     │
    │  [seat=1A now booked]   │                         │                     │
    │                         │                         │                     │
```

---

## Failure Scenarios

### F1: Seat already locked by another counter

**Trigger:** Counter B taps seat 1A while Counter A holds it.

**Client:** Receives 409 with `code: "seat_already_locked"`.
**UI:** Seat shows orange with lock icon, disabled. Error message: "Held by another counter until 10:05".

### F2: Seat already booked

**Trigger:** Counter B taps seat 1A which already has a confirmed booking.

**Client:** Receives 409 with `code: "seat_booked"`.
**UI:** Seat shows grey with block icon, disabled. No error shown (seats load with `available: false`).

### F3: Lock TTL expires during booking

**Trigger:** Staff selects seat, waits >5 minutes, then taps "Book".

**Client:** `POST /bookings/` → server validates lock, finds it expired → returns 409.
**UI:** "Seat lock expired. Please re-select the seat." — seat selection cleared, staff must retap.

### F4: Network failure during lock acquire

**Trigger:** Staff taps seat, network drops.

**Client:** `POST /seat-lock/` times out → `SeatLockController` shows error.
**UI:** Error text under seat grid: "Failed to lock seat: No internet." Staff retaps to retry.

### F5: Network failure during lock release

**Trigger:** Staff navigates away from booking page.

**Client:** `DELETE /seat-lock/` fails silently → best-effort.
**Recovery:** Server-side TTL (5 min) auto-releases the lock. Staff can retap after expiry.

### F6: Concurrent duplicate lock (race condition)

**Trigger:** Two POST /seat-lock/ requests arrive at exactly the same nanosecond.

**Server:** The partial unique index `uq_active_seat_lock` enforces one winner. PostgreSQL returns exactly one INSERT success and one unique constraint violation. The second request gets 409.

### F7: Staff closes app mid-booking

**Trigger:** Staff has lock on seat 1A, closes the app.

**Client:** `SeatLockController.dispose()` calls `_doRelease()` (best-effort).
**Recovery:** If release fails, server-side TTL (5 min) releases the lock. Seat becomes available within 5 minutes.

### F8: Booking creation uses different seat than locked seat

**Trigger:** Staff locked seat 1A, but booking payload says seat 1B (bug or manipulation).

**Server:** Booking creation endpoint validates that `seat_position` matches an active lock held by this device. If no match, returns 409: "Seat not locked."

---

## Concurrency Strategy

### 5-layer duplicate prevention

| Layer | Mechanism | Scope |
|-------|-----------|-------|
| **1. Client UI** | `_acquiring` boolean → `if (_acquiring) return false` | Per-controller |
| **2. Client request** | `idempotency_key` in POST body → same key = same lock | Per-session |
| **3. Database** | Partial unique index `uq_active_seat_lock` (trip_id, seat_position) WHERE status='active' | Server-wide |
| **4. Booking validation** | Server checks lock ownership + validity before creating booking | Server-wide |
| **5. Business logic** | Booking confirmed → seat associated with booking → `available=false` | Permanent |

### Atomic lock acquisition

The POST /seat-lock/ endpoint uses this PostgreSQL atomic pattern:

```sql
WITH attempt AS (
    INSERT INTO seat_locks (trip_id, seat_position, held_by_user_id, held_by_device_id, idempotency_key)
    SELECT $1, $2, $3, $4, $5
    WHERE NOT EXISTS (
        SELECT 1 FROM seat_locks
        WHERE trip_id = $1 AND seat_position = $2 AND status = 'active'
    )
    RETURNING *
)
SELECT * FROM attempt
UNION ALL
SELECT * FROM seat_locks
WHERE trip_id = $1 AND seat_position = $2 AND status = 'active'
LIMIT 1;
```

This atomically checks "no active lock exists → insert → return" or "lock exists → return it as conflict."

### Retry strategy (client-side)

| Attempt | Delay | On failure |
|---------|-------|------------|
| 1 | 0ms | Throws `SeatLockConflictException` (another counter holds it) |
| 2 | 500ms | Retries on transient API error only |
| 3 | 1000ms | Retries on transient API error only |

Only transient errors (network timeouts, 5xx) trigger retries. 409 conflicts propagate to the UI immediately.

---

## Booking-Side Validation (Server)

When creating a booking:

```sql
-- Validate: seat must be locked by this user/device
SELECT 1 FROM seat_locks
WHERE trip_id = :trip_id
  AND seat_position = :seat_position
  AND status = 'active'
  AND expires_at > NOW()
  AND (held_by_user_id = :user_id OR held_by_device_id = :device_id);

-- If no match: return 409 "Seat not locked" or "Seat lock expired"
-- If match: proceed with booking creation
```

On booking success, the server releases the lock:
```sql
UPDATE seat_locks
SET status = 'released', updated_at = NOW()
WHERE trip_id = :trip_id AND seat_position = :seat_position;
```

On booking cancellation, the server releases the lock the same way.

---

## Lock Owner Metadata

| Field | Source | Purpose |
|-------|--------|---------|
| `held_by_user_id` | `SessionController.auth.user['id']` | Audit trail: which staff holds the lock |
| `held_by_device_id` | `DeviceRegistry.installationId` | Audit trail: which device holds the lock |
| `idempotency_key` | `lock_{trip}_{seat}_{user}_{device}` | Prevents duplicate lock creation |

---

## Test Scenarios

### Unit tests (SeatLockController)

| # | Test | Expected |
|---|------|----------|
| 1 | Acquire lock on available seat | `hasActiveLock == true` |
| 2 | Acquire lock on already locked seat | Returns `false`, `error` contains conflict message |
| 3 | Release lock via DELETE | `hasActiveLock == false` |
| 4 | Release when no lock held | No-op, no API call |
| 5 | Lock timer counts down | `remaining` decreases over time |
| 6 | Lock expiry auto-clears | After expiry, `hasActiveLock == false` |
| 7 | Acquiring while already acquiring | Returns `false` |
| 8 | `onBookingSuccess()` clears lock | Timer stopped, lock cleared |
| 9 | `onBookingCancelled()` releases lock | DELETE called |
| 10 | `extend()` refreshes TTL | `expiresAt` extended |
| 11 | `fetchTripLocks()` returns locks | Returns list of SeatLock |
| 12 | Acquire retry on transient failure | Retries up to 2 times |
| 13 | Dispose releases lock | `_doRelease` called |
| 14 | Concurrent acquire guard | `acquiring=true` blocks second call |

### Integration tests

| # | Test | Expected |
|---|------|----------|
| 15 | Full flow: acquire → booking → success | Lock → booking → lock released |
| 16 | Cancel booking releases lock | Lock released on booking failure |
| 17 | Two devices, same seat: first wins | Second gets 409 |
| 18 | TTL expiry: seat becomes available | `available` after 5 min |
| 19 | Booking with expired lock | 409 returned |
| 20 | Extend lock mid-TTL | `expires_at` extended |

---

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `shared/models/seat_lock_models.dart` | 127 | `SeatLock`, `SeatWithLock`, `SeatLockStatus` |
| `features/ticket_sales/controllers/seat_lock_controller.dart` | 310 | Lock lifecycle, TTL timer, acquire/release/extend, conflict handling, retry |
| `features/ticket_sales/screens/counter_booking_page.dart` | ~600 | Lock-aware seat chips, timer display, lock legend, cancellation release |

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (57 tests) | ✅ All passed |
| No offline implementation | ✅ |
| Server-side seat reservation | ✅ (POST /seat-lock/ CREATE, DELETE /seat-lock/{id}/) |
| Atomic lock acquisition | ✅ (partial unique index, idempotency key) |
| Lock expiration (configurable) | ✅ (server: 5 min default, extend API) |
| Auto release | ✅ (TTL sweep + booking success/cancel) |
| Booking confirmation releases lock | ✅ (`onBookingSuccess()`) |
| Cancellation releases lock | ✅ (`onBookingCancelled()` → DELETE) |
| Lock owner metadata | ✅ (user_id + device_id + idempotency_key) |
| Lock timestamp | ✅ (`held_at` + `expires_at`) |
| Conflict handling | ✅ (409 codes: seat_already_locked, seat_booked, lock_expired) |
| Duplicate booking prevention | ✅ (5-layer stack: UI → idempotency → DB → booking validation → business) |
| High-concurrency safe | ✅ (Pg partial unique index, idempotency, retry with backoff) |
