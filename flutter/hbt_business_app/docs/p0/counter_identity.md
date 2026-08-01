# P0-02: Counter Identity — Implementation Report

**Task ID:** P0-02
**Date:** 2026-07-30
**Priority:** P0 (Critical — no counter-level audit trail)
**Status:** ✅ Implemented

---

## Architecture

### Design

Every business operation is now tagged with:

| Field | Source | Present in audit? |
|-------|--------|-------------------|
| **Counter ID** | Active shift → `CounterController` | ✅ Yes |
| **Branch ID** | Active shift → `CounterController` | ✅ Yes |
| **User ID** | `SessionController.auth.user['id']` | ✅ Yes |
| **Device ID** | Future integration with `DeviceRegistry.installationId` | ✅ Ready (field present, set via `session.setDeviceId()`) |
| **Timestamp** | `DateTime.now().toUtc().toIso8601String()` | ✅ Yes |

### Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Counter Identity                        │
│                                                              │
│  Shift Open → sets counter + branch on CounterController     │
│              (persisted to FlutterSecureStorage)              │
│                                                              │
│  Shift Close → clears counter + branch                       │
│                                                              │
│  Session restore → restores persisted counter identity       │
│                                                              │
│  Every operation → records audit via AuditService or         │
│                    direct API call with counter context       │
└─────────────────────────────────────────────────────────────┘
```

### Audit data flow

```
     Operation            CounterController          API
        │                       │                     │
        ├── recordAudit(─────── │                     │
        │    action,            │                     │
        │    resourceType,      │                     │
        │    resourceId,        │                     │
        │    details)           │                     │
        │                       │                     │
        │      ┌────────────────┴──────────┐          │
        │      │  counterId (from active   │          │
        │      │  counter), branchId,      │          │
        │      │  userId (from auth),      │          │
        │      │  deviceId (if set)        │          │
        │      └───────────────────────────┘          │
        │                                             │
        ├──── POST /orgs/{id}/audit-logs/ ────────────┤
        │                                             │
```

---

## Files Created

| File | Purpose | Lines |
|------|---------|-------|
| `features/counter/controllers/counter_controller.dart` | Active counter identity management (set on shift open, clear on close, persist to storage) | 97 |
| `shared/models/audit_entry.dart` | `AuditEntry` model with all identity fields | 97 |
| `shared/services/audit_service.dart` | Fire-and-forget HTTP recording of audit entries with context | 60 |

## Files Modified

| File | Change | Lines |
|------|--------|-------|
| `features/auth/controllers/session_controller.dart` | Added `CounterController` sub-controller, `AuditService` lazy init, `recordAudit()` delegation, `setDeviceId()` | +70 |
| `features/business/screens/business_home.dart` | `_syncCounterIdentity()` watches shift state transitions → sets/clears counter, imports `shift_models.dart` | +40 |
| `features/ticket_sales/screens/counter_booking_page.dart` | Audit call after successful booking (`booking.create`) | +15 |
| `features/cargo/screens/cargo_acceptance_page.dart` | Audit call after cargo acceptance (`cargo.accept`) | +11 |
| `features/refund/screens/refund_create_page.dart` | Audit call after refund request (`refund.request`) | +14 |
| `features/expense/controllers/expense_controller.dart` | Added `_recordAudit()`, called after expense creation (`expense.create`) | +17 |
| `features/shift/controllers/shift_controller.dart` | Added `_recordAudit()`, called after shift open (`shift.open`) and close (`shift.close`) | +40 |

---

## Integration Details

### 1. Ticket Sales

**Hook:** `CounterBookingPage._createAndLockQuote()` — after successful booking + fare quote lock.

```dart
widget.session.recordAudit(
  action: 'booking.create',
  resourceType: 'booking',
  resourceId: booking['id']?.toString() ?? '',
  details: {
    'trip_id': _trip!['id'],
    'trip_number': _trip!['trip_number'],
    'passenger_id': _passenger!['id'],
    'seat': _seat!['identifier'],
    'pickup': _pickup!['id'],
    'dropoff': _dropoff!['id'],
    'total_amount': locked['total_amount']?.toString(),
  },
);
```

### 2. Cargo

**Hook:** `CargoAcceptancePage._accept()` — after successful cargo shipment creation.

```dart
widget.session.recordAudit(
  action: 'cargo.accept',
  resourceType: 'cargo_shipment',
  resourceId: shipment['id']?.toString() ?? '',
  details: {
    'shipment_number': shipment['shipment_number']?.toString(),
    'origin': _origin!['id'],
    'destination': _destination!['id'],
    'charge': _manualCharge.text.trim(),
  },
);
```

### 3. Refund

**Hook:** `RefundCreatePage._save()` — after successful refund request via `RefundService`.

```dart
widget.session.recordAudit(
  action: 'refund.request',
  resourceType: 'refund',
  resourceId: _selectedPayment!['id'] as String,
  details: {
    'payment_id': _selectedPayment!['id'],
    'amount': _requestedAmount,
    'reason': _reasonController.text.trim(),
    if (_selectedTicket != null) 'ticket_id': _selectedTicket!['id'],
  },
);
```

### 4. Expense

**Hook:** `ExpenseController.createExpense()` — after successful API POST (fire-and-forget via catchError).

```dart
_recordAudit(
  action: 'expense.create',
  resourceType: 'expense',
  resourceId: expense.id ?? '',
  details: {
    'category': expense.category.label,
    'amount': expense.amount,
    'vehicle_id': ?expense.vehicleId,
    'trip_id': ?expense.tripId,
    'paid_to': ?expense.paidTo,
  },
);
```

### 5. Shift

**Hook:** `ShiftController.openShift()` and `ShiftController.closeShift()` — after each API call succeeds.

```dart
// Open
_recordAudit(
  action: 'shift.open',
  resourceType: 'shift',
  resourceId: _activeShift!.id ?? '',
  details: {
    'branch_id': branchId,
    'counter_id': counterId,
    'opening_cash': openingCash,
    'printer_checked': printerChecked,
  },
);

// Close
_recordAudit(
  action: 'shift.close',
  resourceType: 'shift',
  resourceId: _activeShift!.id ?? '',
  details: {
    'opening_cash': _activeShift!.openingCash,
    'closing_cash': closingCash,
    'expected_cash': expected,
    'cash_difference': closingCash - expected,
    'difference_reason': ?differenceReason,
    'total_revenue': _activeShift!.totalRevenue,
    'expense_total': _activeShift!.expenseTotal,
    'net_revenue': _activeShift!.netRevenue,
  },
);
```

---

## Automatic Counter Identity Propagation

When a shift is opened (`ShiftOpenScreen`), the `BusinessHome` widget's `_syncCounterIdentity()` method detects the state change and calls:

```dart
widget.session.setActiveCounter(
  branchId: shift.branchId,
  branchName: branch?.name ?? shift.branchId,
  counterId: shift.counterId,
  counterName: counter?.displayName ?? counter?.code ?? shift.counterId,
);
```

When a shift is closed (status changes to `closed`) or the shift becomes `null`:

```dart
widget.session.clearCounter();
```

The counter identity is persisted to `FlutterSecureStorage` and restored on app startup (called during `SessionController.signIn()`).

---

## Audit Table Schema (Server-side)

```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    action          TEXT NOT NULL,       -- e.g. 'booking.create', 'shift.open'
    resource_type   TEXT NOT NULL,       -- e.g. 'booking', 'cargo_shipment'
    resource_id     TEXT NOT NULL,       -- UUID of the affected resource
    counter_id      TEXT,                -- Counter UUID
    branch_id       TEXT,                -- Branch UUID
    user_id         UUID,                -- Staff user UUID
    device_id       TEXT,                -- Installation UUID (from DeviceRegistry)
    details         JSONB,               -- Arbitrary detail payload
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_org ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_counter ON audit_logs(counter_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);
```

API endpoint: `POST /organizations/{id}/audit-logs/`

---

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (40 tests) | ✅ All passed |
| No AI features | ✅ |
| No offline implementation | ✅ |
| No UI redesign | ✅ (audit calls are fire-and-forget; no UI changes) |

---

## Audit Coverage Summary

| Domain | Audit event | Where triggered |
|--------|------------|-----------------|
| **Ticket Sales** | `booking.create` | `counter_booking_page.dart` after booking + quote + lock |
| **Cargo** | `cargo.accept` | `cargo_acceptance_page.dart` after shipment POST |
| **Refund** | `refund.request` | `refund_create_page.dart` after service request |
| **Expense** | `expense.create` | `expense_controller.dart` after API POST |
| **Shift** | `shift.open` | `shift_controller.dart` after shift POST |
| **Shift** | `shift.close` | `shift_controller.dart` after close POST |
