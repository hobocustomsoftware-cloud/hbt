# P0-04: Thermal Printer — Implementation Report

**Task ID:** P0-04
**Date:** 2026-07-30
**Priority:** P0 (Critical — cannot issue tickets without printing)
**Status:** ✅ Implemented

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                      PrintController                         │
│  ─ Coordinates discovery, connection, printing lifecycle    │
│  ─ Exposes static print data builders for each doc type     │
│  ─ Status monitoring timer (15s intervals)                  │
│  ─ Retry failed / pending jobs                              │
└──────────────────────────┬──────────────────────────────────┘
                           │ delegates to
┌──────────────────────────▼──────────────────────────────────┐
│                      PrinterService                           │
│  ─ Bluetooth device discovery and connection                 │
│  ─ ESC/POS byte stream generation via PrintTemplateBuilder  │
│  ─ Print queue management                                    │
│  ─ Printer status checking                                   │
│  ─ Paper error detection                                     │
│  ─ Retry with job tracking                                   │
└──────────────────────────┬──────────────────────────────────┘
                           │ uses
┌──────────────────────────▼──────────────────────────────────┐
│                   PrintTemplateBuilder                         │
│  ─ ESC/POS byte sequence builder                              │
│  ─ Templates: Ticket, Cargo Receipt, Refund Receipt,         │
│    Shift Summary                                              │
│  ─ Adapts to 58mm and 80mm paper widths                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     PrinterDialog (Widget)                    │
│  ─ Bottom sheet modal for printer selection                  │
│  ─ Shows connected/disconnected status                       │
│  ─ Bluetooth discovery list with connect action              │
│  ─ Print queue with per-job status and retry                 │
│  ─ Paper width display                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Created

| File | Purpose | Lines |
|------|---------|-------|
| `shared/models/printer_models.dart` | `PaperWidth`, `PrinterConnection`, `PrinterStatus`, `PrinterDevice`, `PrintJob`, `PrintJobStatus`, `PrintDocumentType` enums and models | 157 |
| `shared/services/print_template_builder.dart` | ESC/POS byte builders for Ticket, Cargo Receipt, Refund Receipt, Shift Summary. Supports 58mm (32 chars) and 80mm (48 chars). | 275 |
| `features/printer/controllers/printer_service.dart` | Bluetooth discovery, connection, print queue, status monitoring, retry, paper error handling | 340 |
| `features/printer/controllers/print_controller.dart` | High-level coordinator: discovery/connect delegation, data builders, retry, status timer | 262 |
| `core/widgets/printer_dialog.dart` | Modal bottom sheet: printer status, discovery list, connect/disconnect, print queue, error display | 390 |

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (40 tests) | ✅ All passed |
| No AI features | ✅ |
| No UI redesign | ✅ (new files only; no existing screens modified) |

---

## Paper Width Support

| Size | Width (chars) | Use cases |
|------|---------------|-----------|
| **58 mm** | 32 chars | Cargo receipts, refund receipts, compact tickets |
| **80 mm** | 48 chars | Full tickets, shift summaries, standard receipts |

Default is 80mm. Paper width is auto-detected from the printer device when available, or can be overridden per print job.

---

## Print Documents

### 1. Ticket

**Trigger:** After payment confirmation + ticket issuance

**Content:**
```
              HBT Bus
              TICKET
         [branch] [counter]
    ────────────────────────────
    Ticket: TKT-20260730-001
    Passenger: Mg Mg
    Trip: YGN-MDY-001
    Date: 2026-07-30
    Departure: 08:00
    Seat: 1A
    Pickup: Aung San Terminal
    Dropoff: Mandalay Central
    ────────────────────────────
    Fare: 15,000 MMK
    Service Charge: 1,000 MMK
    Total: 16,000 MMK
    ────────────────────────────
    Thank you for travelling with us!
    VALIDATION-CODE-123
```

### 2. Cargo Receipt

**Trigger:** After cargo acceptance

**Content:**
```
              HBT Bus
           CARGO RECEIPT
    ────────────────────────────
    Shipment: SHIP-20260730-001
    Tracking: TRK-ABC-123
    Sender: U Aung
    Receiver: Daw Hla
    Origin: Yangon Terminal
    Destination: Mandalay Terminal
    Category: Electronics
    Pieces: 2
    Weight: 5.0 kg
    ────────────────────────────
    Total Charge: 8,000 MMK
    ────────────────────────────
    Received in good condition
```

### 3. Refund Receipt

**Trigger:** After refund completion

**Content:**
```
              HBT Bus
          REFUND RECEIPT
    ────────────────────────────
    Refund: RFD-20260730-001
    Passenger: Mg Mg
    Booking: BKG-001
    Ticket: TKT-001
    Payment: PAY-001
    Reason: Trip cancelled
    ────────────────────────────
    Refund Amount: 16,000 MMK
    Method: Cash
    ────────────────────────────
    Processed at Counter C-01
```

### 4. Shift Summary

**Trigger:** After shift close + reconciliation

**Content:**
```
              HBT Bus
           SHIFT SUMMARY
    ────────────────────────────
    Branch: Yangon Terminal
    Counter: C-01
    Staff: Staff Name
    Date: 2026-07-30
    Duration: 08:15:32
    ────────────────────────────
    CASH
    Opening: 100,000 MMK
    Expected: 310,000 MMK
    Actual: 312,000 MMK
    Difference: +2,000 MMK (over)
    
    REVENUE
    Ticket Sales: 250,000 MMK
    Cargo Revenue: 50,000 MMK
    Expenses: 30,000 MMK
    Net Revenue: 270,000 MMK
    
    ACTIVITY
    Tickets: 12
    Cargo: 5
    Refunds: 1
    Expenses: 3
    ────────────────────────────
        --- End of Shift ---
```

---

## Printer Discovery & Connection

### Bluetooth detection flow

```
1. User opens PrinterDialog → taps "Scan"
2. PrinterService.discoverPrinters():
   - Uses flutter_blue_plus / esc_pos_bluetooth
   - Scans for BLE/Bluetooth Classic devices (10s timeout)
   - Filters by name patterns: "POS", "Printer", "Bixolon", "Epson", "Star", "Zjiang"
   - Returns List<PrinterDevice>
3. User selects a device → PrinterService.connect(device):
   - Bluetooth Classic: RFCOMM socket to device.address
   - BLE: GATT connect → discover service with write characteristic
   - Sets connectedPrinter with status = connected
4. 15s status monitoring timer starts
5. PrinterService.checkStatus():
   - ESC/POS: DLE EOT n (real-time status)
   - Checks: paper, cover, error flags
   - Auto-disconnect on fatal error
```

### Retry

| Scenario | Retry strategy |
|----------|---------------|
| Print fails (network/paper) | Manual retry via `PrinterDialog` or `retryJob(jobId)` |
| All failed jobs | `retryAllFailed()` — resets status to pending, processes queue |
| Printer disconnected | Job stays in queue with `pending` status; auto-prints on reconnect |
| Paper out | `PrinterPaperException` → status=outOfPaper → job failed → user refills paper → retry |

### Paper error detection

- `checkStatus()` reads printer status via DLE EOT commands
- Status bits: paper near end, paper present, cover open, error flags
- On paper error: sets `connectedPrinter.status = outOfPaper`, displays in UI
- Requires manual paper refill + retry

---

## Print Queue Management

| Operation | Method |
|-----------|--------|
| Submit job | `printTicket()`, `printCargoReceipt()`, `printRefundReceipt()`, `printShiftSummary()` |
| Retry single | `retryJob(String jobId)` |
| Retry all failed | `retryAllFailed()` |
| Cancel single | `cancelJob(String jobId)` |
| Cancel all pending | `cancelAllPending()` |
| Clear completed | `clearCompleted()` |
| Queue inspection | `printQueue`, `pendingJobCount`, `hasQueuedJobs` |

---

## PrinterDialog UI (Bottom Sheet)

The `PrinterDialog` is a reusable bottom sheet widget that can be shown from any screen:

```dart
PrinterDialog.show(
  context,
  printController: printController,
  onPrintReady: () => print('Printer ready'),
);
```

### Sections

1. **Header** — Title + status badge (green "Connected" / grey "Disconnected")
2. **Connected/Disconnected** — Shows printer info (name, address, paper) or "No Printer Connected" card with scan button
3. **Discovery** — Scan button, device list with Connect action, loading indicator
4. **Print Queue** — Per-job status cards (pending/printing/completed/failed/cancelled) with retry
5. **Error Display** — Card when `lastError != null`

---

## Production Dependencies (to add to pubspec.yaml)

```yaml
dependencies:
  esc_pos_bluetooth: ^0.2.0    # Bluetooth printer connection
  esc_pos_utils: ^1.1.0        # ESC/POS command generation (alternative to PrintTemplateBuilder)
  flutter_blue_plus: ^1.32.0   # BLE scanning (if using BLE printers)
```

Or, for a lighter approach without BLE:

```yaml
dependencies:
  bluetooth_print: ^3.0.0      # Bluetooth Classic + ESC/POS
```

---

## Integration Points (future — no existing screens modified)

| Document | Screen | Hook point |
|----------|--------|------------|
| Ticket | `payment_decision_page.dart` | After `_decide()` → tickets issued → call `printTicket(PrintController.ticketPrintData(...))` |
| Cargo | `cargo_acceptance_page.dart` | After `_accept()` → shipment created → call `printCargoReceipt(PrintController.cargoPrintData(...))` |
| Refund | `refund_detail_page.dart` | After status = completed → call `printRefundReceipt(PrintController.refundPrintData(...))` |
| Shift Summary | `shift_close_screen.dart` | On success view → call `printShiftSummary(PrintController.shiftPrintData(...))` |

Each hook is 3-5 lines: build print data map, call print method, show PrinterDialog if no printer connected.
