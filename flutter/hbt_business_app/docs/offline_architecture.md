# Offline-First Architecture — HBT Business App

**Document:** Architecture overview
**Status:** Design proposal
**Applies to:** `hbt_business_app` (counter staff, dispatchers, finance)

---

## 1. Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        PRESENTATION                          │
│  Screens (StatefulWidget) → Controllers (ChangeNotifier)     │
│  All screen state goes through repository, never direct API  │
└───────────────────────────┬─────────────────────────────────┘
                            │ depends on
┌───────────────────────────▼─────────────────────────────────┐
│                        APPLICATION                            │
│  Feature Controllers / Use Cases                              │
│  CounterBookingUseCase, CargoAcceptUseCase, etc.              │
│  Orchestrates repository calls + business rules               │
└───────────────────────────┬─────────────────────────────────┘
                            │ depends on
┌───────────────────────────▼─────────────────────────────────┐
│                      REPOSITORY LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │ TripRepo     │  │ BookingRepo  │  │ CargoRepo        │    │
│  │ TicketRepo   │  │ PaymentRepo  │  │ FareQuoteRepo    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────────┘    │
│         │                 │                  │                │
│         └──────────┬──────┴──────────┬───────┘                │
│                    ▼                 ▼                        │
│  ┌──────────────────────┐  ┌──────────────────────┐          │
│  │   ApiClient          │  │   AppDatabase         │          │
│  │   (remote source)    │  │   (local source)      │          │
│  └──────────────────────┘  └──────────────────────┘          │
│                    │                 │                        │
│                    ▼                 ▼                        │
│  ┌─────────────────────────────────────────────────┐         │
│  │              SyncManager                         │         │
│  │  Push (SyncUploadQueue) → Pull (cursor sync)     │         │
│  └─────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 1.1 Repository interface pattern

Every repository implements a consistent interface:

```dart
abstract class Repository<T, ID> {
  /// Read — always returns local data first, refreshes from server in
  /// the background. Returns instantly from cache.
  Future<Result<List<T>>> list({Map<String, dynamic>? filters});

  /// Read single — same cache-first strategy.
  Future<Result<T>> get(ID id);

  /// Create — writes to local DB + enqueues sync operation.
  /// Returns immediately with local ID.
  Future<Result<T>> create(T entity);

  /// Update — writes to local DB + enqueues sync operation.
  Future<Result<T>> update(T entity);

  /// Delete — marks as deleted locally, enqueues sync.
  Future<Result<void>> delete(ID id);
}
```

### 1.2 Result type

```dart
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    _ => null,
  };

  String? get errorOrNull => switch (this) {
    Failure(error: final e) => e,
    _ => null,
  };

  factory Result.success(T data) => Success(data);
  factory Result.failure(String error) => Failure(error);
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final String error;
}
```

---

## 2. Local Database Schema

### 2.1 Existing tables (from `app_database.dart`)

| Table | Existing columns | Status |
|-------|-----------------|--------|
| `trips` | id, organization_id, trip_number, route_id, status, data, synced_at, ... | ✅ |
| `routes` | id, organization_id, code, name, status, data, synced_at, ... | ✅ |
| `bookings` | id, organization_id, authorization_reference, trip_id, status, total_amount, data, synced_at, ... | ✅ |
| `tickets` | id, organization_id, ticket_number, booking_id, passenger_name, status, data, synced_at, ... | ✅ |
| `passengers` | id, organization_id, full_name, phone_number, data, synced_at, ... | ✅ |
| `fares` | id, organization_id, route_id, amount, data, synced_at, ... | ✅ |
| `sync_operations` | client_operation_id, operation_type, payload, status, error_code, response_payload, created_at, updated_at | ✅ |

### 2.2 New tables required

```sql
-- TEMPORARY TICKET NUMBERS
-- When offline, counter issues a temporary ticket number (prefixed TMP-)
-- that gets replaced by the server-assigned number during sync.
CREATE TABLE IF NOT EXISTS temp_ticket_numbers (
  client_operation_id TEXT PRIMARY KEY,    -- FK to sync_operations
  temp_number TEXT NOT NULL,               -- e.g. TMP-abc123-001
  server_number TEXT,                      -- filled during sync
  status TEXT NOT NULL DEFAULT 'pending',  -- pending | confirmed | replaced
  created_at TEXT NOT NULL
);

-- SEAT LOCKS (temporary holds)
-- When a counter staff selects a seat, it's held for N minutes.
-- Other devices at the same counter see "held" not "available".
CREATE TABLE IF NOT EXISTS seat_locks (
  id TEXT PRIMARY KEY,                       -- UUID
  trip_id TEXT NOT NULL,
  seat_position TEXT NOT NULL,
  held_by TEXT NOT NULL,                     -- device installation_id
  held_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,                  -- NOW + hold_duration
  status TEXT NOT NULL DEFAULT 'active',     -- active | expired | converted_to_booking
  booking_id TEXT,                           -- set when booking is created
  client_operation_id TEXT,                  -- FK to sync_operations
  created_at TEXT NOT NULL,
  UNIQUE(trip_id, seat_position, status)     -- only one active lock per seat
);

-- DEVICE REGISTRY (extended)
ALTER TABLE device_registry ADD COLUMN role TEXT DEFAULT 'counter';  -- counter | spare
ALTER TABLE device_registry ADD COLUMN counter_id TEXT;              -- physical counter identifier

-- CONFLICT LOG
-- Records all sync conflicts with resolution metadata.
CREATE TABLE IF NOT EXISTS conflict_log (
  id TEXT PRIMARY KEY,                       -- UUID
  client_operation_id TEXT,                  -- FK to sync_operations
  resource_type TEXT NOT NULL,               -- booking | ticket | payment | cargo
  resource_id TEXT,                          -- the conflicting resource's ID
  local_version TEXT,                        -- local snapshot at time of push
  server_version TEXT,                       -- server snapshot at time of push
  conflict_type TEXT NOT NULL,               -- seat_conflict | version_conflict | duplicate
  resolution TEXT,                           -- resolved | manual | discarded
  resolution_action TEXT,                    -- keep_local | keep_server | merge | manual
  resolved_at TEXT,
  created_at TEXT NOT NULL
);

-- BOOKING IDEMPOTENCY
-- Keyed by client_operation_id + idempotency_key hash.
CREATE TABLE IF NOT EXISTS idempotency_keys (
  client_operation_id TEXT PRIMARY KEY,
  idempotency_key_hash TEXT NOT NULL,        -- SHA-256 of key
  resource_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',    -- pending | completed | failed
  response_payload TEXT,                     -- cached successful response
  created_at TEXT NOT NULL
);
```

### 2.3 Sync cursor tracking

```sql
ALTER TABLE device_registry ADD COLUMN sync_cursor TEXT;
```

The sync cursor is a server-issued opaque token (integer sequence number or UUID) that tracks the last known change. On pull, the server returns all changes after that cursor. On push success, the server returns a new cursor value.

---

## 3. Repository Pattern — Read Strategy

```
Screen calls
    │
    ▼
Repository.list(filters)
    │
    ├── 1. Return local data immediately (from AppDatabase)
    │        └── Screen renders with stale data (milliseconds)
    │
    ├── 2. Fire background refresh (ApiClient)
    │        ├── Success → update AppDatabase → rebuild UI
    │        └── Failure → keep local data, show subtle banner
    │
    └── 3. Return full Result with metadata:
           Success(data, {fromCache: true/false, syncedAt: DateTime?})
```

### Cache invalidation rules

| Event | Action |
|-------|--------|
| Pull-to-refresh | Force API call, replace local data |
| App resume from background | Background pull (if > 5 min since last) |
| Successful push | Invalidate locally-changed records only |
| Device comes online | Full sync (push + pull) |
| User switches organization | Clear all caches, fresh load |

---

## 4. Write Strategy — Queue-First

```
Screen calls
    │
    ▼
Repository.create(entity)
    │
    ├── 1. Validate locally (required fields, data types)
    │
    ├── 2. Generate client_operation_id (UUID v4)
    │
    ├── 3. Write to AppDatabase (with status='pending')
    │        └── Assign temporary booking/ticket number (TMP-prefix)
    │
    ├── 4. Enqueue sync operation
    │        └── payload includes: client_operation_id, operation_type, full entity
    │
    ├── 5. Return immediately with local entity + status='pending_sync'
    │        └── Screen shows "Saved locally, syncing..." indicator
    │
    └── 6. SyncManager picks it up on next sync cycle
```

### Write ordering

Operations within the same entity type are ordered by `created_at ASC` (FIFO). Cross-entity dependencies are handled by the server (e.g., booking must exist before fare quote). The server validates ordering and rejects orphaned operations.

---

## 5. Sync Engine Design

### 5.1 Push flow

```
SyncManager.syncAll(orgId)
    │
    ├── 1. Check network availability
    │        └── No network → skip, retry on next interval
    │
    ├── 2. Check device registration
    │        └── Not registered → attempt register, fail if server unavailable
    │
    ├── 3. Push pending operations (batch of 50)
    │        └── POST /organizations/{orgId}/devices/{deviceId}/sync/push/
    │        └── Request: [{ client_operation_id, operation_type, payload }, ...]
    │        └── Response: [{ client_operation_id, status, error_code, response_payload }, ...]
    │
    ├── 4. Process push responses
    │        ├── 'applied'  → mark completed, replace temp numbers with server numbers
    │        ├── 'rejected' → mark rejected, log to conflict_log
    │        ├── 'conflict' → mark conflict, log details, notify dashboard
    │        └── 'received' → keep pending (server will process async)
    │
    ├── 5. Pull server changes
    │        └── GET /organizations/{orgId}/devices/{deviceId}/sync/pull/?after={cursor}
    │        └── Apply changes to local DB: upsert for create/update, delete for delete
    │
    └── 6. Update sync cursor
```

### 5.2 Pull flow

```
Pull request:
  GET /organizations/{orgId}/devices/{deviceId}/sync/pull/?after=cursor_abc

Response:
{
  "changes": [
    {
      "resource_type": "ticket",
      "operation": "create",
      "resource_id": "tkt-456",
      "payload": { "ticket_number": "HBT-001-001", ... }
    },
    ...
  ],
  "next_cursor": "cursor_xyz"
}
```

### 5.3 Sync interval strategy

| State | Interval | Behaviour |
|-------|----------|-----------|
| Online + pending ops | Every 30 seconds | Push + pull cycle |
| Online + no pending | Every 5 minutes | Pull only |
| Offline | — | Queue operations, sync on reconnect |
| Just came online | Immediate | Full push + pull |
| App backgrounded | — | Pause sync timers |
| App foregrounded | Immediate | Background pull if stale |

---

## 6. Seat Reservation Strategy

**Risk:** Two counters (or counter + spare) select the same seat simultaneously.
**Current gap:** The business app has no seat locking mechanism.

### 6.1 Local seat lock protocol

```
Counter staff taps "Available" seat
    │
    ├── 1. Check local seat_locks table for this trip_id + seat_position
    │        ├── Lock exists + active? → Seat should show as "held"
    │        └── No lock? → Proceed
    │
    ├── 2. Create local seat_lock (status='active', expires_at = NOW + 5 min)
    │
    ├── 3. Enqueue sync operation: 'seat.lock' with { trip_id, seat_position }
    │        └── Server confirms lock and broadcasts to other devices
    │
    ├── 4. UI shows seat as "Selected" (green highlight)
    │        └── Timer starts: 5-minute countdown visible to user
    │
    ├── 5a. User completes booking within 5 min:
    │         ├── Convert lock → booking
    │         ├── Update seat_lock status = 'converted_to_booking'
    │         └── Enqueue 'booking.create'
    │
    └── 5b. User does nothing for 5 min:
              ├── Lock expires locally
              ├── SyncManager sends 'seat.unlock' if device comes online
              └── Seat returns to "Available"
```

### 6.2 Seat state matrix

| Local state | Server state | UI display | Action |
|-------------|-------------|------------|--------|
| No lock | Available | Green, tappable | User can select |
| No lock | Booked | Grey, disabled | Other device booked it |
| Active lock (this device) | Available | Blue, selected + timer | User is in booking flow |
| Active lock (other device) | Available | Orange, "being booked" | Cannot select |
| Expired lock | Available | Green, tappable | Lock released |
| Converted to booking | Booked | Grey, disabled | Booking complete |

### 6.3 Lock expiry cascade

If the device goes offline while a lock is active:
1. Lock stays active locally for 5 min
2. After 5 min, lock expires locally → seat returns to available
3. When device comes online, `seat.unlock` sync sends "expired" to server
4. Server releases the lock if the booking was never completed

If the device crashes mid-booking:
1. Lock stays active in the server for 5 min (server-side TTL)
2. After 5 min, server releases the lock automatically
3. Other devices see the seat as available after server TTL expiry

---

## 7. Booking Idempotency

### 7.1 Idempotency key generation

```dart
String generateBookingKey({
  required String tripId,
  required String passengerId,
  required String seatPosition,
  required String counterId,
  required DateTime timestamp,
}) {
  final raw = 'booking|$tripId|$passengerId|$seatPosition|$counterId|$timestamp';
  return sha256.convert(utf8.encode(raw)).toString();
}
```

The key is deterministic: same trip + passenger + seat + counter + timestamp produces the same key. This means an accidental double-tap on "Book" within the same second produces the same key and is rejected.

### 7.2 Booking flow with idempotency

```
1. User taps "Confirm Booking"
2. Generate idempotency_key_hash
3. Check local idempotency_keys table
   ├── Found + status=completed? → Return cached booking (no API call)
   └── Not found → Continue
4. Create local booking with client_operation_id
5. Store idempotency_key (status=pending)
6. Enqueue 'booking.create' with idempotency_key_hash in payload
7. Screen shows "Booking confirmed" immediately (optimistic)
8. Sync runs: server receives booking
   ├── Server checks idempotency_key_hash
   │   ├── Seen before? → Return existing booking (idempotent)
   │   └── New? → Create booking, store key
   └── Response marks sync_operation as 'completed'
9. Update local idempotency_key status = 'completed'
10. Store server-assigned ticket numbers
```

### 7.3 Double-tap prevention

| Level | Mechanism |
|-------|-----------|
| UI | Button disabled after first tap (existing `BusyButton.busy`) |
| Local | Idempotency key dedup within same second |
| Sync queue | Client_operation_id prevents duplicate sync |
| Server | Client_operation_id + idempotency_key_hash double dedup |

---

## 8. Payment Idempotency

Payments are higher risk than bookings — money must not be double-charged.

### 8.1 Payment flow

```
1. Counter staff records payment (cash/QR/bank transfer)
2. Generate idempotency_key:
   'payment|{booking_id}|{payment_number}|{amount}|{counter_id}|{timestamp}'
3. Create local payment record (status='pending_sync')
4. Store idempotency_key (status=pending)
5. Enqueue 'payment.record_cash' or 'payment.upload_evidence'
6. Screen shows payment recorded (optimistic)
7. Sync runs:
   ├── Server receives payment
   │   ├── Check idempotency_key_hash
   │   ├── New? → Process payment, generate payment_number
   │   └── Duplicate? → Return existing payment
   └── Response includes server payment_number
8. Update local record with server payment_number
9. If payment is evidence-based:
   ├── Upload file generates a separate idempotency key
   └── File URL is included in the payment payload
```

### 8.2 Payment-specific guarantees

| Scenario | Guarantee |
|----------|-----------|
| User taps "Record Payment" twice | Dedup at UI + idempotency key |
| Sync sends payment twice | Server rejects second with same key |
| Device crashes after local write, before sync | Payment is queued, sync sends it on recovery |
| Server processes payment but response lost | Client retries with same key, server returns existing result |
| Partial payment (split across trips) | Each payment leg has its own key |

---

## 9. Duplicate Prevention — Complete Strategy

### 9.1 Detection layers

```
Layer 1: UI
  └── Button.disabled = true while processing

Layer 2: Client-side debounce
  └── Same operation type + same arguments within 1 second → drop

Layer 3: Sync queue dedup
  └── client_operation_id must be unique per device
  └── Re-enqueue of same client_operation_id → update existing, not insert

Layer 4: Server-side dedup (primary key)
  └── client_operation_id is PK in sync_operations
  └── INSERT OR IGNORE → second attempt ignored

Layer 5: Server-side idempotency
  └── idempotency_key_hash checked before processing
  └── Same key → return cached result, no side effects

Layer 6: Business logic dedup
  └── Same trip + same seat + same date → reject (seat already booked)
  └── Same payment_number → reject (payment already recorded)
```

### 9.2 Server response codes for sync operations

| Code | Meaning | Client action |
|------|---------|---------------|
| `applied` | Operation processed successfully | Mark completed, update local data |
| `duplicate` | Same client_operation_id already processed | Mark completed, use cached response |
| `rejected` | Business validation failed | Mark rejected, show user error |
| `conflict` | Conflict detected (seat, version) | Mark conflict, log details, show dashboard |
| `received` | Accepted but not yet processed | Keep pending, check on next sync |

---

## 10. Conflict Resolution Strategy

### 10.1 Conflict types

| Type | Example | Strategy |
|------|---------|----------|
| **Seat conflict** | Two devices book same seat | First sync wins, second gets seat_conflict |
| **Version conflict** | Stale data updated (lost update) | Track version field, last-write-wins or manual |
| **Duplicate operation** | Same client_operation_id sent twice | Idempotency key → return cached |
| **Temporary number conflict** | Two TMP-xxx numbers collide | Server reassigns on confirmation |
| **Payment amount mismatch** | Manual override vs computed fare | Flag for manual review |

### 10.2 Seat conflict — detailed resolution

```
Scenario: Counter A and Counter B both book seat 12 on Trip T-001

                        TIME
Counter A ──────► Booking created locally ──────► Sync Push ──────► Server: seat 12 booked
Counter B ──► Booking created locally ──► Sync Push ──► Server: conflict (seat 12 already booked)

Resolution:
  1. Counter A's booking succeeds (first to sync)
  2. Counter B's booking gets conflict response
  3. Local booking for Counter B is marked 'conflict_seat'
  4. Counter B's screen shows: "Seat 12 was just booked. Select another seat."
  5. Counter B must reselect a seat and rebook
  6. Original booking (Counter B) is NOT cancelled — user chooses: different seat or cancel
```

### 10.3 Conflict dashboard entries

Each conflict creates an entry in the local `conflict_log` and the server's conflict list. The conflict dashboard shows:

| Field | Description |
|-------|-------------|
| Operation ID | Link to the failed sync operation |
| Timestamp | When conflict was detected |
| Resource | booking/ticket/payment/cargo |
| Local value | What the device tried to write |
| Server value | What the server had |
| Conflict type | seat_conflict/version_conflict/duplicate |
| Resolution | pending/resolved/manual |
| Action | keep_local/keep_server/reselect/cancel |

---

## 11. Temporary Ticket Numbering

### 11.1 Number format

When offline, the counter app issues temporary ticket numbers:

```
TMP-{device_short_id}-{sequence}
Example: TMP-A3F-001, TMP-A3F-002

Where:
  - TMP        = Prefix indicating temporary
  - A3F        = First 3 chars of device installation_id (base64 encoded UUID)
  - 001        = Monotonically increasing sequence per device
```

### 11.2 Sequence management

```dart
class TicketNumberSequence {
  final FlutterSecureStorage _storage;
  int _counter = 0;

  Future<String> next(String deviceId) async {
    _counter = await _storage.read(key: 'ticket_seq') ?? 0;
    _counter++;
    await _storage.write(key: 'ticket_seq', value: _counter);
    final shortId = deviceId.replaceAll('-', '').substring(0, 3).toUpperCase();
    return 'TMP-$shortId-${_counter.toString().padLeft(3, '0')}';
  }

  Future<void> reset() async {
    await _storage.delete(key: 'ticket_seq');
    _counter = 0;
  }
}
```

### 11.3 Reconciliation during sync

```
1. Booking is synced with temp ticket numbers (TMP-A3F-001)
2. Server accepts booking, generates real ticket numbers (HBT-ORG-001-001)
3. Push response maps: TMP-A3F-001 → HBT-ORG-001-001
4. Client updates local ticket records with real numbers
5. temp_ticket_numbers table records the mapping
6. UI updates to show real ticket numbers
```

### 11.4 Ticket reprint after sync

After sync completes and real ticket numbers are assigned, any printed receipts with TMP-numbers should be marked "VOID — see ticket HBT-ORG-001-001". A "Reprint" button appears in the booking detail screen once sync completes.

---

## 12. Multi-Device Spare Workflow

### 12.1 Device roles

| Role | Description | Sync behaviour |
|------|-------------|----------------|
| **Primary** | Main counter device | Full read/write, creates lock bookings |
| **Spare** | Backup device at same counter | Mirrors primary data, can take over if primary fails |
| **Roaming** | Conductor/driver device | Read-only for manifests, writes for validation only |

### 12.2 Spare device activation

```
1. Spare device logs in with same counter credentials
2. Spare device calls POST /me/devices/ with role=spare, counter_id=X
3. Server registers spare device, enables full read/write
4. Spare device performs initial sync (full pull)
5. Spare device is now operational

When primary fails:
  1. Spare device can be promoted to primary
  2. Promotion is a device-level operation (not user-level)
  3. Server marks primary as inactive
  4. Spare starts accepting bookings with its own device identity
  5. Seat locks are shared via sync (both devices see same lock state)
```

### 12.3 Concurrent booking prevention

```
Counter with Primary + Spare:
  ┌─────────────────────────────────────────────────────┐
  │                SAME COUNTER                          │
  │  ┌─────────┐          ┌───────────┐                 │
  │  │ Primary │ ←sync→  │ Spare     │                 │
  │  │         │          │           │                 │
  │  │ Seat    │          │ Seat lock │                 │
  │  │ lock    │          │ synced    │                 │
  │  │ created │          │ from sync │                 │
  │  └─────────┘          └───────────┘                 │
  │                                                      │
  │  Both see the same seat state within ~5 seconds      │
  └─────────────────────────────────────────────────────┘
```

Two devices at the same counter can still race for the same seat. The server-side seat lock (Section 6) is the ultimate arbiter. The sync queue ensures that only the first `seat.lock` to reach the server succeeds.

---

## 13. Counter + Spare Concurrent Booking

### 13.1 Worst case scenario

```
Counter A (Primary): Seat 12 → lock → booking
Counter A (Spare):  Seat 12 → lock (before sync pulls primary's lock)

Timeline:
  0s  Primary: taps Seat 12 → local lock created
  1s  Spare:  taps Seat 12 → local lock created (no sync yet)
  5s  Spare:  pushes seat.lock → Server: lock for A-Spare (seat 12)
  6s  Primary: pushes seat.lock → Server: conflict (seat already locked by A-Spare)
  7s  Primary: shows "Seat 12 was just selected by another device at your counter"
  8s  Primary: auto-suggests next available seat
```

### 13.2 Mitigation strategy

| Mitigation | Description | Effectiveness |
|------------|-------------|---------------|
| Short lock TTL (5 min) | Locks auto-expire | Prevents stuck locks |
| Sync frequency (30s) | Locks sync between devices | Reduces race window to ~30s |
| Server is source of truth | Server always wins | Ultimate arbiter |
| Conflict dashboard | Shows failed lock attempts | Visibility |
| Auto-suggest next seat | After conflict, suggest next available | Reduces friction |
| Seat grouping | Each counter has preferred seat blocks | Pre-allocates seats to counters |

---

## 14. Sync Retry Policy

### 14.1 Exponential backoff

```dart
class RetryPolicy {
  static const int maxRetries = 10;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxDelay = Duration(minutes: 5);

  /// Calculate delay for retry attempt N (0-indexed).
  static Duration delayFor(int attempt) {
    if (attempt >= maxRetries) return maxDelay;
    // 2s, 4s, 8s, 16s, 32s, 64s, 128s, 256s, 300s max, 300s max
    final calculated = baseDelay * (1 << attempt); // 2^attempt
    return calculated > maxDelay ? maxDelay : calculated;
  }

  /// Whether to stop retrying this operation.
  static bool shouldGiveUp(int attempt) => attempt >= maxRetries;
}
```

### 14.2 Retry categories

| Error | Behaviour | Max retries |
|-------|-----------|-------------|
| Network error (`ClientException`) | Retry with backoff | ∞ (retry on connectivity change) |
| Server error (5xx) | Retry with backoff | 10 |
| Rate limited (429) | Retry after Retry-After header | 5 |
| Validation error (422) | Don't retry, mark rejected | 0 |
| Conflict (409) | Don't retry, mark conflict | 0 |
| Not found (404) | Don't retry | 0 |

### 14.3 Dead letter queue

After `maxRetries` attempts, the operation is moved to a dead letter queue (`sync_operations.status = 'dead_letter'`). Dead letter entries are:
- Visible in the sync dashboard with error details
- Manually retryable (one tap)
- Auto-cleaned after 30 days

---

## 15. Sync Dashboard

The sync tab (currently a placeholder) becomes the sync dashboard with:

### 15.1 Dashboard sections

| Section | Content |
|---------|---------|
| **Connection status** | Online / Offline / Syncing badge |
| **Pending operations** | Count of operations waiting to sync |
| **Last sync time** | Human-readable: "2 min ago", "4 hours ago" |
| **Conflict alerts** | Count of unresolved conflicts (red badge) |
| **Operation list** | Filterable list of recent sync operations with status |

### 15.2 Operation list item

```
┌──────────────────────────────────────────────┐
│  booking.create          2 min ago            │
│  Trip T-001, Seat 12, Passenger: Maung Maung  │
│  ✅ Completed                                 │
├──────────────────────────────────────────────┤
│  payment.record_cash    15 min ago            │
│  PMT-001, 15,000 MMK                         │
│  ⏳ Pending                                   │
├──────────────────────────────────────────────┤
│  booking.create          1 hour ago            │
│  Trip T-002, Seat 5, Passenger: Aye Aye       │
│  ⚠️ Conflict — Seat already booked            │
│  [Resolve] [Dismiss]                         │
└──────────────────────────────────────────────┘
```

---

## 16. Implementation Order

| Phase | Components | Effort | Dependency |
|-------|-----------|--------|------------|
| **P1** | Repository interfaces, Result type, AppDatabase schema migration (new tables) | 2 days | None |
| **P2** | TripRepository, PassengerRepository (read-only caches) | 1 day | P1 |
| **P3** | BookingRepository with idempotency + queue | 3 days | P1, P2 |
| **P4** | PaymentRepository with idempotency | 2 days | P1, P3 |
| **P5** | SyncUploadQueue integration with repositories | 1 day | P3, P4 |
| **P6** | Seat lock protocol (local + sync) | 2 days | P1, P5 |
| **P7** | Temporary ticket numbering | 1 day | P3 |
| **P8** | Conflict dashboard UI | 2 days | P1 |
| **P9** | Retry policy + dead letter queue | 1 day | P5 |
| **P10** | Multi-device counter+spare workflow | 3 days | P6 |

**Total estimated effort: 18 days**
