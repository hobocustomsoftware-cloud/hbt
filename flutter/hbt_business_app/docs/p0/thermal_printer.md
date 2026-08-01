# P0-05: Production-Ready Thermal Printer

**Task ID:** P0-05
**Date:** 2026-07-30
**Priority:** P0 (Critical — cannot issue physical tickets)
**Status:** ✅ Implemented

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   THERMAL PRINTER SYSTEM                             │
│                                                                      │
│  ┌─────────────────┐    ┌──────────────────┐    ┌───────────────┐   │
│  │ PrinterSettings   │    │  PrintController  │    │ PrinterService  │   │
│  │ Controller        │    │                   │    │                 │   │
│  │                    │    │  Discovery/connect│    │ Bluetooth scan │   │
│  │ Default printer    │◄──►│  Print jobs       │◄──►│ Connection      │   │
│  │ Paper width        │    │  Retry            │    │ Print queue     │   │
│  │ Saved printers     │    │  Reprint last     │    │ Status check    │   │
│  │ Auto-connect       │    │  Settings access  │    │ Paper detection │   │
│  │ Reprint tracking   │    │                   │    │                 │   │
│  └────────┬──────────┘    └────────┬─────────┘    └────────┬──────┘   │
│           │                        │                        │          │
│           ▼                        ▼                        ▼          │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    PrintTemplateBuilder                          │ │
│  │  Ticket │ Cargo Receipt │ Refund Receipt │ Shift Summary         │ │
│  │  58mm (32 chars) │ 80mm (48 chars)     │ ESC/POS byte stream   │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Screen: PrinterSettingsScreen                                   │ │
│  │  Default printer, paper width, copies, auto-connect,             │ │
│  │  saved/discovered printers, reprint last, print queue, retry     │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. `PrinterSettingsController`

Persists printer preferences to `FlutterSecureStorage`:

| Setting | Key | Type | Default |
|---------|-----|------|---------|
| Default printer ID | `hbt_default_printer_id` | String? | null |
| Default printer name | `hbt_default_printer_name` | String? | null |
| Paper width | `hbt_default_paper_width` | `mm58` / `mm80` | `mm80` |
| Auto-connect | `hbt_printer_autoconnect` | bool | `true` |
| Copies | `hbt_default_copies` | int (1-5) | 1 |

Also tracks:
- **Saved printers** — list of `PrinterDevice` that have been used before
- **Last print** — `lastPrintType` + `lastPrintData` for reprint

### 2. `PrintController`

| Feature | Method |
|---------|--------|
| Discovery | `discoverPrinters()` |
| Connection | `connect(PrinterDevice)`, `disconnect()` |
| Printing | `printTicket()`, `printCargoReceipt()`, `printRefundReceipt()`, `printShiftSummary()` |
| Reprint | Auto-records last print data on success |
| Retry | `retryJob()`, `retryAllFailed()` |
| Queue | `printQueue`, `pendingJobCount`, `cancelJob()` |
| Status monitoring | 15-second interval, auto-disconnect on error |
| Settings | `settings` getter for `PrinterSettingsController` |

### 3. `PrinterService`

| Feature | Method |
|---------|--------|
| Bluetooth discovery | `discoverPrinters(timeout: 10s)` |
| Connection | `connect(PrinterDevice)` — RFCOMM/GATT |
| Disconnection | `disconnect()` |
| Print job lifecycle | `printTicket()`, `printCargoReceipt()`, etc. |
| Queue management | `printQueue`, `retryJob()`, `cancelJob()` |
| Status checking | `checkStatus()` via DLE EOT |
| Paper detection | `PrinterPaperException` thrown on paper error |

### 4. `PrinterSettingsScreen`

Sections:
1. **Default Printer** — shows current default, "Set Default" on saved printers
2. **Paper Size** — ChoiceChip for 58mm / 80mm
3. **Copies** — +/- controls (1-5)
4. **Auto-connect** — SwitchListTile
5. **Connected Printer** — status badge + disconnect
6. **Saved Printers** — previously used printers, set default / forget
7. **Discovered Printers** — from Bluetooth scan, connect / save
8. **Reprint** — reprint last document with one tap
9. **Print Queue** — per-job status with retry, clear completed/failed

---

## Paper Width Support

| Size | Characters | Use cases |
|------|-----------|-----------|
| **58 mm** | 32 chars | Compact receipts: cargo, refund |
| **80 mm** | 48 chars | Standard tickets, shift summaries |

---

## Retry Strategy

| Scenario | Mechanism | User action |
|----------|-----------|-------------|
| Print fails (network) | Job marked `failed`, stays in queue | Tap "Retry" on failed job, or "Retry Failed" bulk |
| Paper out | `PrinterPaperException` → `outOfPaper` status → job fails | Refill paper → "Retry" |
| Printer disconnected | Job stays `pending` | "Scan Again" → connect → auto-prints pending |
| Queue has pending jobs | `_processQueue()` called on connect | Automatic |
| All failed jobs | `retryAllFailed()` resets to pending | Available from Settings or PrinterDialog |

---

## Reprint Last Ticket

When a print job completes successfully, the `PrintController` auto-records the document type and data:

```dart
_settings.recordLastPrint(PrintDocumentType.ticket, data);
```

The Settings screen shows a "Reprint" button for the last document. Tapping it reconstructs the print job with the same data.

---

## Multiple Printer Support

| Feature | How |
|---------|-----|
| Discovery | `discoverPrinters()` scans for Bluetooth printers |
| Save | "Save" button on discovered devices → added to `savedPrinters` |
| Set default | "Set Default" on any saved/discovered printer |
| Connect switching | Direct connect to any discovered device |
| Forget | "Delete" on saved printers removes from list |
| Persistence | Saved printers stored in `PrinterSettingsController._savedPrinters` |

---

## Bluetooth Detection & Pairing

```
1. PrinterSettingsScreen or PrinterDialog → "Scan"
2. PrinterService.discoverPrinters():
   - Uses flutter_blue_plus / esc_pos_bluetooth
   - Filters for thermal printer names: "POS", "Printer", "Bixolon", "Epson", "Star"
   - Returns List<PrinterDevice> with name, address, paperWidth heuristic
3. User taps "Connect" or "Save":
   - Connect: opens RFCOMM socket → starts status monitoring
   - Save: stores in savedPrinters for later use
4. Auto-connect on startup:
   - If autoconnect=true and defaultPrinterId != null:
     - Find saved printer by ID
     - Attempt connection
     - Silent failure if printer not available
```

---

## Paper Out Detection

```
1. checkStatus() → sends DLE EOT n (real-time status)
2. Bit 3 of response = paper near end
3. Bit 4 of response = paper present
4. If paper absent:
   - Sets connectedPrinter.status = outOfPaper
   - Triggers notifyListeners()
   - Current print job → PrinterPaperException → status=failed
5. UI shows paper error indicator
6. Staff refills paper → taps "Retry"
```

---

## Test Cases

### PrinterSettingsController tests

| # | Test | Expected |
|---|------|----------|
| 1 | Restore loads saved settings | Default printer, paper width, copies restored |
| 2 | Set default printer persists | `defaultPrinterId` and `defaultPrinterName` saved |
| 3 | Clear default printer | Values cleared from storage |
| 4 | Set paper width | `defaultPaperWidth` updated and persisted |
| 5 | Set copies (clamped 1-5) | Values < 1 → 1, >5 → 5 |
| 6 | Save printer adds to list | Duplicate IDs not added |
| 7 | Forget printer removes from list | Also clears if it was default |
| 8 | Record last print | `lastPrintType` and `lastPrintData` set |
| 9 | Clear last print | Both cleared |

### PrintController tests

| # | Test | Expected |
|---|------|----------|
| 10 | Print ticket records last print | `settings.hasLastPrint` = true |
| 11 | Reprint last document | Same data sent to printer service |
| 12 | Uses default paper width from settings | `printTicket` passes `settings.defaultPaperWidth` |
| 13 | Connect saves printer | `settings.savedPrinters` includes device |

### Integration tests

| # | Test | Expected |
|---|------|----------|
| 14 | Full flow: discover → connect → print → reprint | All 4 steps succeed |
| 15 | Paper out → retry | Job fails with paper error, retry succeeds |
| 16 | Multiple saved printers | Switch between them, each prints |
| 17 | Auto-connect on restore | Default printer auto-connects |
| 18 | Reprint after app restart | Last print data still available |

---

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `shared/models/printer_models.dart` | 157 | PaperWidth, PrinterStatus, PrinterDevice, PrintJob, PrintDocumentType |
| `shared/services/print_template_builder.dart` | 275 | ESC/POS byte builders for 4 document types |
| `features/printer/controllers/printer_service.dart` | 340 | Bluetooth discovery, connection, print queue, status, retry |
| `features/printer/controllers/print_controller.dart` | 285 | High-level coordinator + settings integration + reprint tracking |
| `features/printer/controllers/printer_settings_controller.dart` | 155 | Printer settings persistence + reprint tracking |
| `features/printer/screens/printer_settings_screen.dart` | 440 | Printer management UI: defaults, discovery, saved, queue, reprint |
| `core/widgets/printer_dialog.dart` | 390 | Bottom sheet printer selection + queue management |

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (57 tests) | ✅ All passed |
| No offline implementation | ✅ |
| Bluetooth printers | ✅ Discovery + connect + auto-connect |
| 58mm paper | ✅ 32 chars via `PaperWidth.mm58` |
| 80mm paper | ✅ 48 chars via `PaperWidth.mm80` |
| Ticket printing | ✅ ESC/POS template + data builder |
| Cargo receipt printing | ✅ ESC/POS template |
| Refund receipt printing | ✅ ESC/POS template |
| Shift summary printing | ✅ ESC/POS template |
| Printer discovery | ✅ `discoverPrinters()` with timeout |
| Printer pairing | ✅ Connect action + save for reconnection |
| Printer status | ✅ 15s monitoring + DLE EOT check |
| Paper out detection | ✅ `PrinterPaperException` + `outOfPaper` status |
| Retry | ✅ Per-job + bulk retry + auto-process on reconnect |
| Reprint last ticket | ✅ `recordLastPrint()` + Settings "Reprint" button |
| Multiple printer support | ✅ Saved printers list + switchable connections |
| Settings persistence | ✅ `FlutterSecureStorage` for all preferences |
| Default printer | ✅ Set + clear + auto-connect on startup |
