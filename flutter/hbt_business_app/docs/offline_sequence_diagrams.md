# Offline Sequence Diagrams — HBT Business App

**Document:** Swimlane sequence diagrams for key offline-first workflows
**Format:** Mermaid.js (renders on GitHub/GitLab or any Mermaid-compatible viewer)
**Status:** Design proposal

---

## Diagram 1: Normal Online Booking Flow

```mermaid
sequenceDiagram
    participant User
    participant Screen as CounterBookingPage
    participant BookingRepo as BookingRepository
    participant API as ApiClient
    participant DB as AppDatabase
    participant Queue as SyncUploadQueue
    participant Server as Backend Server

    User->>Screen: Select passenger, trip, stops, seat
    Screen->>BookingRepo: createBooking(data)

    Note over BookingRepo: Online mode

    BookingRepo->>BookingRepo: Generate client_operation_id (UUID v4)
    BookingRepo->>BookingRepo: Generate idempotency_key_hash

    BookingRepo->>DB: upsert('bookings', local_booking)
    BookingRepo->>DB: upsert('idempotency_keys', pending)

    BookingRepo->>Queue: enqueue('booking.create', payload)
    Queue->>DB: upsert('sync_operations', pending)

    BookingRepo-->>Screen: Result.success(booking, syncing=true)
    Screen-->>User: "Booking saved. Syncing..."

    Note over Queue,Server: Sync cycle (0-30s later)

    Queue->>API: POST /orgs/{id}/devices/{id}/sync/push/
    API->>Server: batch[{client_operation_id, op_type, payload}]
    Server->>Server: Validate, dedup, process
    Server-->>API: [{client_operation_id, status:'applied', response}]
    API-->>Queue: Response batch

    Queue->>Queue: Mark op 'completed'
    Queue->>DB: Update sync_operations status
    Queue->>DB: Update idempotency_keys status='completed'
    Queue->>DB: Update temp_ticket_numbers with server_number

    Queue-->>Screen: notifyListeners()
    Screen-->>User: "Booking confirmed! Ticket: HBT-ORG-001-001"
```

---

## Diagram 2: Offline Booking Flow

```mermaid
sequenceDiagram
    participant User
    participant Screen as CounterBookingPage
    participant BookingRepo as BookingRepository
    participant DB as AppDatabase
    participant Queue as SyncUploadQueue
    participant TmpNum as TicketNumberSequence

    User->>Screen: Select passenger, trip, stops, seat
    Screen->>BookingRepo: createBooking(data)

    Note over BookingRepo: Offline mode (no network)

    BookingRepo->>BookingRepo: Generate client_operation_id (UUID v4)
    BookingRepo->>BookingRepo: Generate idempotency_key_hash

    BookingRepo->>TmpNum: next(deviceId)
    TmpNum-->>BookingRepo: "TMP-A3F-001"

    BookingRepo->>DB: Insert temp_ticket_number (TMP-A3F-001, pending)
    BookingRepo->>DB: Create seat_lock (active, expires=NOW+5min)
    BookingRepo->>DB: Insert local booking (client_operation_id, status='pending_sync')
    BookingRepo->>DB: Insert idempotency_key (pending)

    BookingRepo->>Queue: enqueue('booking.create', payload with TMP-number)
    Queue->>DB: Insert sync_operation (pending)

    BookingRepo-->>Screen: Result.success(booking, syncing=false, tempNumber=TMP-A3F-001)
    Screen-->>User: "Saved offline. Ticket: TMP-A3F-001"
    Screen-->>User: Show sync-pending indicator

    Note over User,Screen: Device regains connectivity later

    Queue->>Queue: Connectivity change detected
    Queue->>Queue: Full sync cycle triggered

    Queue->>API: POST /orgs/{id}/devices/{id}/sync/push/
    API->>Server: Process booking with TMP-A3F-001
    Server->>Server: Accept booking, assign real numbers
    Server-->>API: {status:'applied', ticket_number:'HBT-ORG-001-001'}
    API-->>Queue: Response

    Queue->>DB: Update booking with server ticket number
    Queue->>DB: Update temp_ticket_number (status='confirmed', server_number='HBT-ORG-001-001')
    Queue->>DB: Mark seat_lock as 'converted_to_booking'

    Queue-->>Screen: notifyListeners()
    Screen-->>User: "Synced! Ticket: HBT-ORG-001-001 (was TMP-A3F-001)"
```

---

## Diagram 3: Seat Conflict Resolution

```mermaid
sequenceDiagram
    participant DeviceA as Counter A (Primary)
    participant DeviceB as Counter B (Primary)
    participant Server as Backend Server
    participant SyncA as Sync Queue A
    participant SyncB as Sync Queue B

    Note over DeviceA,DeviceB: Both select Seat 12 on Trip T-001

    DeviceA->>DeviceA: Local seat_lock created (Seat 12)
    DeviceB->>DeviceB: Local seat_lock created (Seat 12)

    Note over DeviceA,DeviceB: Lock not yet synced between devices

    DeviceA->>DeviceA: Booking created locally (Seat 12)
    DeviceB->>DeviceB: Booking created locally (Seat 12)

    DeviceA->>SyncA: Enqueue booking.create
    DeviceB->>SyncB: Enqueue booking.create

    Note over SyncA,Server: Sync cycle for Device A

    SyncA->>Server: POST /push/ [booking, trip=t-001, seat=12]
    Server->>Server: Check seat availability
    Server->>Server: Seat 12 is FREE → assign to Device A
    Server-->>SyncA: {status:'applied', booking_id: 'bk-001'}
    SyncA->>DeviceA: Mark booking completed

    Note over SyncB,Server: Sync cycle for Device B (30s later)

    SyncB->>Server: POST /push/ [booking, trip=t-001, seat=12]
    Server->>Server: Check seat availability
    Server->>Server: Seat 12 is BOOKED (by Device A) → CONFLICT
    Server-->>SyncB: {
    Server-->>SyncB:   status:'conflict',
    Server-->>SyncB:   conflict_type:'seat_conflict',
    Server-->>SyncB:   available_alternatives: [14, 15, 8]
    Server-->>SyncB: }

    SyncB->>DeviceB: Mark booking as 'conflict_seat'
    DeviceB-->>DeviceB: Show conflict dialog

    Note over DeviceB: User sees:

    DeviceB->>DeviceB: "Seat 12 was just booked by another device."
    DeviceB->>DeviceB: "Available alternatives: Seat 14, 15, 8"
    DeviceB->>DeviceB: User taps "Seat 14"

    DeviceB->>SyncB: Enqueue new booking.create (Seat 14)
    SyncB->>Server: POST /push/ [booking, trip=t-001, seat=14]
    Server->>Server: Seat 14 is FREE
    Server-->>SyncB: {status:'applied', booking_id: 'bk-002'}
    SyncB->>DeviceB: Booking confirmed (Seat 14)

    Note over DeviceA,DeviceB: Both booked successfully — different seats
```

---

## Diagram 4: Booking Idempotency (Double-Tap Prevention)

```mermaid
sequenceDiagram
    participant User
    participant Screen
    participant BookingRepo
    participant DB as AppDatabase
    participant Queue
    participant Server

    User->>Screen: Tap "Confirm Booking"
    Screen->>BookingRepo: createBooking(data)

    BookingRepo->>BookingRepo: Generate idempotency_key_hash
    BookingRepo->>DB: SELECT * FROM idempotency_keys WHERE hash = ?
    DB-->>BookingRepo: Not found (first attempt)

    BookingRepo->>BookingRepo: Generate client_operation_id (UUID v4)
    BookingRepo->>DB: Insert idempotency_key (hash, pending)
    BookingRepo->>DB: Insert local booking (pending_sync)
    BookingRepo->>Queue: Enqueue booking.create
    BookingRepo-->>Screen: Result.success()
    Screen-->>User: "Booking confirmed!" (optimistic)

    Note over User,Screen: User accidentally taps again

    User->>Screen: Tap "Confirm Booking" (same data)
    Screen->>BookingRepo: createBooking(data) [SAME]

    BookingRepo->>BookingRepo: Generate same idempotency_key_hash
    BookingRepo->>DB: SELECT * FROM idempotency_keys WHERE hash = ?
    DB-->>BookingRepo: Found (status='pending')

    Note over BookingRepo: Dedup hit — same operation already in progress
    BookingRepo-->>Screen: Result.success(existing_booking)
    Screen-->>User: "Already confirmed!" (no duplicate)

    Note over Queue,Server: Sync runs once only

    Queue->>Server: POST /push/ [client_operation_id: "abc-123", ...]
    Server->>Server: Process once
    Server-->>Queue: {status:'applied'}

    Note over BookingRepo,Server: Second tap never generated an API call
```

---

## Diagram 5: Payment Idempotency (Network Loss After Server Process)

```mermaid
sequenceDiagram
    participant Screen
    participant PaymentRepo
    participant DB
    participant Queue
    participant Server

    Screen->>PaymentRepo: recordPayment(data)
    PaymentRepo->>PaymentRepo: Generate idempotency_key_hash
    PaymentRepo->>PaymentRepo: Generate client_operation_id
    PaymentRepo->>DB: Insert local payment (pending_sync)
    PaymentRepo->>DB: Insert idempotency_key (pending)
    PaymentRepo->>Queue: Enqueue 'payment.record_cash'

    Queue->>Server: POST /push/ [payment, amount=15000, ...]
    Server->>Server: Process payment
    Server->>Server: Deduct, record, generate payment_number
    Server-->>Queue: {status:'applied', payment_number:'PMT-001'}

    Note over Queue,Server: NETWORK LOSS — response never received

    Queue->>Queue: Timeout. Retry with backoff.

    Queue->>Server: POST /push/ [SAME client_operation_id, SAME data]
    Server->>Server: Check client_operation_id → ALREADY PROCESSED
    Server-->>Queue: {status:'duplicate', payment_number:'PMT-001', cached:true}

    Note over Queue: No second charge. Server returned cached result.

    Queue->>DB: Update payment with payment_number = 'PMT-001'
    Queue->>DB: Mark idempotency_key as 'completed'
    Queue-->>Screen: notifyListeners()
    Screen-->>Screen: Show "Payment recorded: PMT-001"
```

---

## Diagram 6: Seat Lock Protocol (Counter + Spare)

```mermaid
sequenceDiagram
    participant Counter as Counter Device
    participant Spare as Spare Device
    participant Queue as Sync Queue
    participant Server
    participant Timer

    Note over Counter,Spare: Both at same physical counter

    Counter->>Counter: Staff taps Seat 12
    Counter->>Counter: Create local lock (Seat 12, expires=NOW+5min)
    Counter->>Counter: Start 5-min countdown timer
    Counter->>Queue: Enqueue 'seat.lock' {trip, seat: 12}

    Queue->>Server: POST /push/ [seat.lock, trip=t-001, seat=12]
    Server->>Server: Lock Seat 12 for this device
    Server-->>Queue: {status:'applied'}

    Note over Spare,Server: 30s later — Spare syncs

    Spare->>Queue: Pull latest changes
    Queue->>Server: GET /pull/?after=cursor_xyz
    Server-->>Queue: {changes: [{resource:'seat_lock', seat:12, device:Counter}]}
    Queue->>Spare: Apply change

    Spare->>Spare: Update seat display
    Note over Spare: Seat 12 shows as "Being booked" (orange)

    Note over Counter,Timer: 4 minutes pass...

    Timer->>Counter: 1 minute remaining! Warning toast

    Note over Counter: Staff completes booking

    Counter->>Counter: Convert lock → booking
    Counter->>Queue: Update seat.lock status='converted'
    Counter->>Queue: Enqueue 'booking.create' {seat: 12}

    Queue->>Server: Push seat unlock + booking
    Server->>Server: Release lock, create booking
    Server-->>Queue: {status:'applied'}

    Spare->>Server: Pull
    Server-->>Spare: Seat 12 → booked
    Spare->>Spare: Show Seat 12 as occupied (grey)

    Note over Counter,Timer: Timer cancelled — booking completed
```

---

## Diagram 7: Temporary Ticket Number Reconciliation

```mermaid
sequenceDiagram
    participant DeviceA as Counter A (offline)
    participant DeviceB as Counter B (offline)
    participant Server
    participant SeqA as Seq Manager A
    participant SeqB as Seq Manager B

    Note over DeviceA: Goes offline at 10:00
    Note over DeviceB: Goes offline at 10:00

    DeviceA->>SeqA: next()
    SeqA-->>DeviceA: TMP-A3F-001

    DeviceA->>DeviceA: Create booking (Seat 5) with TMP-A3F-001
    DeviceA->>DeviceA: Queue for sync

    DeviceA->>SeqA: next()
    SeqA-->>DeviceA: TMP-A3F-002

    DeviceA->>DeviceA: Create booking (Seat 8) with TMP-A3F-002
    DeviceA->>DeviceA: Queue for sync

    DeviceB->>SeqB: next()
    SeqB-->>DeviceB: TMP-B7C-001

    DeviceB->>DeviceB: Create booking (Seat 12) with TMP-B7C-001
    DeviceB->>DeviceB: Queue for sync

    Note over DeviceA,Server: 10:15 — Device A comes online

    DeviceA->>Server: Push [booking(TMP-A3F-001), booking(TMP-A3F-002)]
    Server->>Server: Accept both. Assign HBT-ORG-001-001, HBT-ORG-001-002
    Server->>Server: Map TMP-A3F-001 → HBT-ORG-001-001
    Server->>Server: Map TMP-A3F-002 → HBT-ORG-001-002
    Server-->>DeviceA: {
    Server-->>DeviceA:   applied: [
    Server-->>DeviceA:     {client_op:..., ticket_number:'HBT-ORG-001-001'},
    Server-->>DeviceA:     {client_op:..., ticket_number:'HBT-ORG-001-002'}
    Server-->>DeviceA:   ]
    Server-->>DeviceA: }

    DeviceA->>DeviceA: Update local tickets with server numbers
    DeviceA->>DeviceA: Show "TMP-A3F-001 → HBT-ORG-001-001"

    Note over DeviceB,Server: 10:30 — Device B comes online

    DeviceB->>Server: Push [booking(TMP-B7C-001)]
    Server->>Server: Accept. Assign HBT-ORG-001-003
    Server-->>DeviceB: {ticket_number:'HBT-ORG-001-003'}

    Note over Server: All TMP numbers reconciled.
    Note over Server: No collisions (different device_short_id prefixes).
```

---

## Diagram 8: Multi-Device Spare Promotion

```mermaid
sequenceDiagram
    participant Counter as Counter (Primary)
    participant SpareDevice as Spare
    participant Server
    participant Sync as Spare Sync

    Note over SpareDevice: Initial setup

    SpareDevice->>Server: POST /me/devices/ {role:'spare', counter_id:'C-01'}
    Server->>Server: Register spare device for Counter C-01
    Server-->>SpareDevice: {device_id:'spare-001', status:'active'}

    SpareDevice->>Sync: Perform initial full sync
    Sync->>Server: GET /sync/pull/?full=true
    Server-->>Sync: {all_trips, all_routes, all_bookings, ...}
    Sync->>SpareDevice: Write to local DB
    Note over SpareDevice: Spare has full local copy

    Note over Counter,SpareDevice: Normal operation

    Counter->>Counter: Create booking
    Counter->>Server: Sync booking
    Server->>SpareDevice: Pull notification (next sync)
    SpareDevice->>SpareDevice: Update local copy

    Note over Counter,SpareDevice: Primary FAILS (battery dies)

    SpareDevice->>SpareDevice: Detect primary offline (no sync from primary)
    SpareDevice->>Server: POST /devices/promote/ {spare_device_id:'spare-001'}
    Server->>Server: Mark primary as inactive
    Server->>Server: Promote spare to primary role
    Server-->>SpareDevice: {role:'primary', counter_id:'C-01'}

    Note over SpareDevice: Spare is now primary for Counter C-01

    SpareDevice->>SpareDevice: Start accepting new bookings
    SpareDevice->>SpareDevice: Create seat locks as primary
    SpareDevice->>Server: Sync new bookings
    Server->>Server: Process bookings (same counter ID)

    Note over Counter,SpareDevice: Primary comes back online

    Counter->>Server: POST /me/devices/sync/
    Server->>Server: Detect primary was deactivated
    Server-->>Counter: {role:'spare', ...}
    Note over Counter: Old primary is now spare
```

---

## Diagram 9: Sync Retry with Exponential Backoff

```mermaid
sequenceDiagram
    participant Queue as SyncUploadQueue
    participant API as ApiClient
    participant Server

    Queue->>API: POST /push/ [batch of 50]
    API->>Server: Request
    Server-->>API: Server Error (500)
    API-->>Queue: ApiException('Server error')

    Queue->>Queue: Retry attempt 1
    Queue->>Queue: Wait 2 seconds (baseDelay * 2^0)

    Queue->>API: POST /push/ [same batch]
    API->>Server: Request
    Server-->>API: Server Error (500)
    API-->>Queue: ApiException('Server error')

    Queue->>Queue: Retry attempt 2
    Queue->>Queue: Wait 4 seconds (baseDelay * 2^1)

    Queue->>API: POST /push/ [same batch]
    API->>Server: Request
    Server-->>API: Server Error (500)
    API-->>Queue: ApiException('Server error')

    Queue->>Queue: Retry attempt 3
    Queue->>Queue: Wait 8 seconds

    Queue->>API: POST /push/
    API->>Server: Request
    Server-->>API: 200 OK
    API-->>Queue: Success

    Note over Queue: 3 retries, 14 seconds total delay
    Note over Queue: Operations preserved in queue throughout

    Note over Queue: If all 10 retries fail:

    Queue->>Queue: attempt >= 10
    Queue->>Queue: Move to dead_letter queue
    Queue->>Queue: Set status = 'dead_letter'
    Queue-->>Queue: Show in sync dashboard for manual retry
```

---

## Diagram 10: Conflict Dashboard Flow

```mermaid
sequenceDiagram
    participant User as Staff
    participant Dashboard as Sync Dashboard
    participant Queue as SyncUploadQueue
    participant DB as AppDatabase
    participant Server

    Note over Queue,Server: Sync detects conflict

    Queue->>Server: POST /push/ [booking, seat=12]
    Server-->>Queue: {status:'conflict', type:'seat_conflict', alternatives:[14,15,8]}
    Queue->>DB: Insert conflict_log entry (seat_conflict, pending)
    Queue->>DB: Update booking status to 'conflict_seat'

    Note over User,Dashboard: User opens Sync tab

    User->>Dashboard: Open Sync tab
    Dashboard->>DB: SELECT * FROM conflict_log WHERE status='pending'
    DB-->>Dashboard: [{conflict_id:'CF-001', type:'seat_conflict', ...}]

    Dashboard-->>User: Show 1 unresolved conflict (red badge)

    User->>Dashboard: Tap conflict notification
    Dashboard->>DB: SELECT * FROM conflict_log WHERE id='CF-001'
    Dashboard->>DB: SELECT * FROM sync_operations WHERE client_op_id = ?
    Dashboard->>DB: Query available alternatives

    Dashboard-->>User: Conflict detail view
    Note over User,Dashboard: Shows local vs server state + alternatives

    User->>Dashboard: Tap "Reselect & Rebook"
    Dashboard->>Dashboard: Create new booking with alternative seat
    Dashboard->>Queue: Enqueue new booking.create
    Dashboard->>DB: Update conflict_log status='resolved'
    Dashboard-->>User: "Conflict resolved. New booking created."

    Note over User,Dashboard: Conflict badge count decreases
```

---

## Diagram Legend

| Symbol | Meaning |
|--------|---------|
| `->>` | Synchronous/async call |
| `-->>` | Return/response |
| `Note over X` | Annotation over a participant or time span |
| `participant X as Label` | Participant with display label |
| `Box colour` | N/A (Mermaid renders in greyscale by default) |
