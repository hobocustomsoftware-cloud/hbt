# Conflict Resolution — HBT Offline-First Architecture

**Document:** Detection, classification, and resolution strategies for sync conflicts
**Status:** Design proposal

---

## 1. Conflict Taxonomy

```
                        ┌──────────────────────┐
                        │    SYNC CONFLICT       │
                        └──────────┬───────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
     ┌──────────────┐   ┌──────────────────┐   ┌──────────────┐
     │ SEAT          │   │ VERSION / DATA    │   │ DUPLICATE    │
     │ CONFLICT      │   │ CONFLICT          │   │ OPERATION    │
     └──────────────┘   └──────────────────┘   └──────────────┘
              │                    │                    │
     ┌────────┴────────┐   ┌──────┴──────┐     ┌──────┴──────┐
     │ Same seat       │   │ Stale read   │     │ Same         │
     │ booked by two   │   │ → write on   │     │ operation     │
     │ devices         │   │ outdated data │     │ sent twice    │
     └─────────────────┘   └─────────────┘     └─────────────┘

              ┌──────────────────────┐
              │ NUMBER CONFLICT       │
              │ (TMP number collision  │
              │  or sequence overlap)   │
              └──────────────────────┘
```

---

## 2. Conflict Detection

### 2.1 Where conflicts are detected

| Layer | Detects | How |
|-------|---------|-----|
| **Client (before enqueue)** | Duplicate operation | Checks `idempotency_keys` table for existing key |
| **Client (before push)** | Duplicate client_operation_id | DB UNIQUE constraint on sync_operations.client_operation_id |
| **Server (on push receive)** | Seat conflict | Server checks seat_locks + bookings for same trip_id + seat_position |
| **Server (on push receive)** | Duplicate operation | Server checks processed_operations table for client_operation_id |
| **Server (on push receive)** | Version conflict | Server checks resource version field against provided version |
| **Server (on push send)** | Temporary number collision | Server detects TMP- prefix and checks for existing mapping |

### 2.2 Conflict response payload

```json
{
  "client_operation_id": "uuid-abc-123",
  "status": "conflict",
  "error_code": "seat_conflict",
  "response_payload": {
    "conflict_type": "seat_conflict",
    "resource_type": "booking",
    "resource_id": "bk-001",
    "local_value": {
      "trip": "trip-001",
      "seat_position": "12",
      "passenger": "p-001"
    },
    "server_value": {
      "trip": "trip-001",
      "seat_position": "12",
      "passenger": "p-002",
      "existing_booking": "bk-002"
    },
    "suggested_resolution": "reselect_seat",
    "available_alternatives": [
      {"seat_position": "14", "identifier": "14"},
      {"seat_position": "15", "identifier": "15"}
    ]
  }
}
```

---

## 3. Resolution Strategies by Conflict Type

### 3.1 Seat conflict — automated resolution

```
Trigger: Two devices book the same seat on the same trip.

Resolution flow:
  1. Server processes first device's booking → success
  2. Server processes second device's booking → conflict detected
  3. Server responds with:
     - conflict_type: "seat_conflict"
     - available_alternatives: list of unbooked seats
  4. Client marks booking as 'conflict_seat'
  5. Client shows dialog:

     ┌─────────────────────────────────────┐
     │  ⚠️ Seat Conflict                   │
     │                                     │
     │  Seat 12 was just booked by          │
     │  another device.                     │
     │                                     │
     │  Available alternatives:             │
     │  ○ Seat 14 (Aisle)                   │
     │  ○ Seat 15 (Window)                  │
     │  ○ Seat 08 (Aisle)                   │
     │                                     │
     │  [Select Different Seat]  [Cancel]   │
     └─────────────────────────────────────┘

  6. User selects alternative or cancels
  7. If selected, new booking is created with new seat_position
  8. Original conflict booking is replaced (not duplicated)

Result: Conflicting booking never reaches the server.
         No orphaned bookings. No refunds needed.
```

### 3.2 Version / Data conflict — LWW with manual fallback

```
Trigger: A device modified a record (e.g., trip notes) that was
         already modified on the server by another device.

Resolution: Last-Write-Wins (LWW) with logging.

Flow:
  1. Client sends update with { version: 5 }
  2. Server has version: 6 (stale update)
  3. Server responds with conflict (version_conflict)
  4. Client receives server's current version
  5. If update is non-critical (notes, labels):
     → Auto-accept server version (LWW)
     → Log to conflict_log for audit
  6. If update is critical (fare override, status change):
     → Show conflict to user:
       "This record was updated by another device.
        Your change: X
        Server change: Y
        Which should we keep?"
  7. User chooses: keep_local, keep_server, or merge

Resolution data:
  ┌─────────────────────────────────────────────┐
  │  ⚠️ Update Conflict                          │
  │                                              │
  │  This trip was updated while you were         │
  │  offline.                                     │
  │                                              │
  │  Your version (2 min ago):                    │
  │    Status: Boarding                           │
  │    Notes: "Delayed 15 min"                    │
  │                                              │
  │  Server version:                              │
  │    Status: Departed                           │
  │    Notes: "On time"                           │
  │                                              │
  │  [Keep Mine]  [Keep Server]  [Cancel]        │
  └─────────────────────────────────────────────┘
```

### 3.3 Duplicate operation — silent dedup

```
Trigger: Same client_operation_id sent twice (network retry).

Resolution: Automatic. No user visible.

Flow:
  1. Client sends operation with client_operation_id = "abc-123"
  2. Server processes it, sends response
  3. Response lost (network timeout)
  4. Client retries with same client_operation_id = "abc-123"
  5. Server detects duplicate, returns cached response
  6. Client receives response, continues normally

User sees: Nothing. Operation completes as expected.
Conflict log: Not logged (expected behaviour).
```

### 3.4 Temporary number conflict — server reassignment

```
Trigger: Two offline devices generate the same TMP-xxx-(nnn) number
         (extremely unlikely due to device_short_id in the prefix).

Resolution: Server-side reassignment.

Flow:
  1. Device A pushes booking with TMP-A3F-001
  2. Device B pushes booking with TMP-B7C-001 (no collision)
  3. Server processes both, detects no TMP collision (different prefixes)
  4. Server assigns real numbers: HBT-ORG-001-001, HBT-ORG-001-002
  5. Server maps: TMP-A3F-001 → HBT-ORG-001-001
                   TMP-B7C-001 → HBT-ORG-001-002
  6. Client A receives mapping, updates local ticket
  7. Client B receives mapping, updates local ticket

Edge case: If two devices somehow generate the same TMP:
  1. Second device's booking gets conflict response
  2. Server assigns a new temp number for the second booking
  3. Second booking succeeds with re-assigned temp number
  4. Conflict log records: temp_number_collision (info only)

User sees: Nothing. Numbers are reconciled in background.
```

### 3.5 Payment amount mismatch — manual review

```
Trigger: Counter staff manually overrides the fare amount, but the
         server has a different computed fare.

Resolution: Flagged for manual review (no auto-accept).

Flow:
  1. Counter enters manual fare: 12,000 MMK
  2. Server computed fare: 15,000 MMK
  3. Booking is created with manual fare
  4. Sync sends booking with manual_fare flag = true
  5. Server detects mismatch
  6. Server creates booking with manual_fare, flags for review
  7. Server adds to "Manual Fare Override" dashboard queue
  8. Client shows: "Fare override noted. Pending supervisor review."
  9. Supervisor reviews and approves/rejects override

Conflict log entry:
  ┌─────────────────────────────────────────────┐
  │  ⚠️ Fare Override                            │
  │  Booking: BN-001                             │
  │  Computed fare: 15,000 MMK                   │
  │  Charged fare: 12,000 MMK                    │
  │  Difference: -3,000 MMK                      │
  │  Reason: "Regular customer discount"         │
  │                                              │
  │  [Approve Override]  [Reject → Revert Fare] │
  └─────────────────────────────────────────────┘
```

---

## 4. Conflict Lifecycle

```
                    ┌─────────────┐
                    │ DETECTED    │
                    │ (on sync)   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ AUTO-     │ │ PROMPT   │ │ SILENT   │
        │ RESOLVED │ │ USER     │ │ DEDUP    │
        │ (seat     │ │ (version │ │ (dup op) │
        │ conflict) │ │ conflict)│ │          │
        └──────────┘ └────┬─────┘ └──────────┘
                          │
                    ┌─────┴──────┐
                    ▼            ▼
              ┌──────────┐ ┌──────────┐
              │ RESOLVED  │ │ PENDING  │
              │ (user     │ │ (user    │
              │  chose)   │ │ ignored) │
              └──────────┘ └────┬─────┘
                                │ 24h timeout
                                ▼
                          ┌──────────┐
                          │ ESCALATED │
                          │ (sent to  │
                          │  admin)   │
                          └──────────┘
```

### Conflict states

| State | Meaning | Transitions |
|-------|---------|-------------|
| `detected` | Conflict identified during sync | → resolved / pending |
| `resolved` | Conflict resolved (auto or manual) | → closed (after 7 days) |
| `pending` | Waiting for user action | → resolved / escalated |
| `escalated` | No user action for 24h, sent to supervisor | → resolved |
| `closed` | Archived. Conflict resolved. | — (terminal) |

---

## 5. Conflict Dashboard

### 5.1 Dashboard filters

| Filter | Options |
|--------|---------|
| Type | seat / version / duplicate / payment / all |
| Status | pending / resolved / escalated |
| Time range | Today / Last 7 days / All |
| Device | Specific device / all |

### 5.2 Conflict detail view

```
┌─────────────────────────────────────────────────────────────┐
│  Conflict #CF-001     ⚠️ Seat Conflict    2 min ago          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Booking: BN-003                                             │
│  Trip: T-001 (Mandalay → Yangon, 2026-07-30 08:00)          │
│                                                              │
│  Your selection:          Server state:                      │
│  ┌────────────────────┐  ┌────────────────────┐             │
│  │ Seat 12             │  │ Seat 12            │             │
│  │ Passenger: Su Su    │  │ Passenger: Maung   │             │
│  └────────────────────┘  │                   │             │
│                           │ (booked 30s before │             │
│                           │  your sync)       │             │
│                           └────────────────────┘             │
│                                                              │
│  Available alternatives:                                     │
│  ┌──────┬──────────┬──────────┐                              │
│  │ Seat │ Position  │ Status   │                              │
│  ├──────┼──────────┼──────────┤                              │
│  │ 14   │ Aisle     │ ✅ Free  │                              │
│  │ 15   │ Window    │ ✅ Free  │                              │
│  │ 08   │ Aisle     │ ✅ Free  │                              │
│  └──────┴──────────┴──────────┘                              │
│                                                              │
│  [Reselect & Rebook]  [Cancel Booking]    [Dismiss]         │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Conflict notification badge

The conflict dashboard icon shows a badge with the count of unresolved conflicts:

```dart
// Sync tab indicator
Badge(
  isLabelVisible: unresolvedCount > 0,
  label: Text('$unresolvedCount'),
  child: const NavigationDestination(
    icon: Icon(Icons.sync_outlined),
    selectedIcon: Icon(Icons.sync),
    label: 'Sync',
  ),
)
```

---

## 6. Resolution Timeouts

| Conflict type | Max wait for user resolution | Auto-escalation action |
|---------------|------------------------------|------------------------|
| Seat conflict | Immediate (must reselect to continue) | N/A — user must act |
| Version conflict (data) | 24 hours | Keep server version after 24h |
| Payment mismatch | 7 days | Keep manual fare, flag permanently |
| Temporary number | Immediate (auto-reconciled) | N/A |

---

## 7. Conflict Log Cleanup

- Resolved conflicts: purged after 90 days
- Pending conflicts (escalated): purged after 180 days
- Seat conflicts (resolved): purged after 30 days
- Duplicate operation logs: purged after 7 days (no user value)

```sql
-- Housekeeping query (run daily)
DELETE FROM conflict_log
WHERE (status = 'resolved' AND created_at < datetime('now', '-90 days'))
   OR (status = 'escalated' AND created_at < datetime('now', '-180 days'))
   OR (conflict_type = 'duplicate' AND created_at < datetime('now', '-7 days'));
```
