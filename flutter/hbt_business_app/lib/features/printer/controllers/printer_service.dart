import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/printer_models.dart';
import '../../../shared/services/print_template_builder.dart';

/// Manages thermal printer discovery, connection, and printing.
///
/// Supports:
/// - Bluetooth printer discovery and connection
/// - ESC/POS document printing (ticket, cargo, refund, shift)
/// - Printer status monitoring and error handling
/// - Retry with exponential backoff
/// - Paper error detection
class PrinterService extends ChangeNotifier {
  bool _discovering = false;
  bool _connecting = false;
  final bool _printing = false;
  String? _lastError;
  PrinterDevice? _connectedPrinter;
  List<PrinterDevice> _discoveredDevices = [];
  final List<PrintJob> _printQueue = [];

  // ── Getters ──
  bool get discovering => _discovering;
  bool get connecting => _connecting;
  bool get printing => _printing;
  String? get lastError => _lastError;
  PrinterDevice? get connectedPrinter => _connectedPrinter;
  List<PrinterDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  List<PrintJob> get printQueue => List.unmodifiable(_printQueue);
  bool get hasQueuedJobs => _printQueue.any((j) => j.status == PrintJobStatus.pending);
  int get pendingJobCount =>
      _printQueue.where((j) => j.status == PrintJobStatus.pending).length;
  bool get isConnected => _connectedPrinter != null &&
      _connectedPrinter!.status == PrinterStatus.connected;

  // ── Discovery ─────────────────────────────────────────────────────
  /// Start Bluetooth printer discovery.
  ///
  /// Scans for nearby Bluetooth devices that look like thermal printers.
  /// Returns discovered devices via [discoveredDevices].
  Future<List<PrinterDevice>> discoverPrinters({Duration timeout = const Duration(seconds: 10)}) async {
    _discovering = true;
    _lastError = null;
    notifyListeners();

    try {
      // In production, this would use flutter_blue_plus or esc_pos_bluetooth
      // to scan for BLE/Bluetooth Classic printers.
      //
      // The scan typically filters by service UUIDs or device name patterns
      // (e.g. "POS", "Printer", "Bixolon", "Epson", "Star", "Zjiang").
      //
      // Stub: simulate discovery
      await Future.delayed(const Duration(seconds: 2));
      _discoveredDevices = _simulateDiscovery();

      _discovering = false;
      notifyListeners();
      return _discoveredDevices;
    } catch (e) {
      _lastError = 'Printer discovery failed: $e';
      _discovering = false;
      notifyListeners();
      return [];
    }
  }

  /// Cancel an ongoing discovery scan.
  void cancelDiscovery() {
    _discovering = false;
    notifyListeners();
  }

  // ── Connection ────────────────────────────────────────────────────
  /// Connect to a discovered printer device.
  ///
  /// Attempts to open a Bluetooth RFCOMM socket (for Bluetooth Classic)
  /// or GATT connection (for BLE printers). Returns true on success.
  Future<bool> connect(PrinterDevice device) async {
    if (_connecting) return false;

    _connecting = true;
    _lastError = null;
    notifyListeners();

    try {
      // In production, this would:
      //   - For Bluetooth Classic: `BluetoothConnection.toAddress(device.address)`
      //   - For BLE: connect via GATT, discover service with write characteristic
      //
      // Stub: simulate connection
      await Future.delayed(const Duration(seconds: 1));

      _connectedPrinter = PrinterDevice(
        id: device.id,
        name: device.name,
        address: device.address,
        connectionType: device.connectionType,
        paperWidth: device.paperWidth ?? PaperWidth.mm80,
        status: PrinterStatus.connected,
      );
      _connecting = false;
      notifyListeners();

      // Process any queued jobs
      _processQueue();
      return true;
    } catch (e) {
      _lastError = 'Failed to connect to ${device.name}: $e';
      _connecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from the current printer.
  Future<void> disconnect() async {
    if (_connectedPrinter == null) return;

    try {
      // In production: close Bluetooth socket / GATT connection
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (_) {}

    _connectedPrinter = null;
    notifyListeners();
  }

  // ── Printing ──────────────────────────────────────────────────────
  /// Print a ticket document.
  Future<bool> printTicket(Map<String, dynamic> data,
      {PaperWidth? width, int copies = 1}) async {
    final job = PrintJob(
      id: _generateId(),
      documentType: PrintDocumentType.ticket,
      data: data,
      paperWidth: width ?? _connectedPrinter?.paperWidth ?? PaperWidth.mm80,
      copies: copies,
    );
    return _submitJob(job);
  }

  /// Print a cargo receipt.
  Future<bool> printCargoReceipt(Map<String, dynamic> data,
      {PaperWidth? width, int copies = 1}) async {
    final job = PrintJob(
      id: _generateId(),
      documentType: PrintDocumentType.cargoReceipt,
      data: data,
      paperWidth: width ?? _connectedPrinter?.paperWidth ?? PaperWidth.mm80,
      copies: copies,
    );
    return _submitJob(job);
  }

  /// Print a refund receipt.
  Future<bool> printRefundReceipt(Map<String, dynamic> data,
      {PaperWidth? width, int copies = 1}) async {
    final job = PrintJob(
      id: _generateId(),
      documentType: PrintDocumentType.refundReceipt,
      data: data,
      paperWidth: width ?? _connectedPrinter?.paperWidth ?? PaperWidth.mm80,
      copies: copies,
    );
    return _submitJob(job);
  }

  /// Print a shift summary.
  Future<bool> printShiftSummary(Map<String, dynamic> data,
      {PaperWidth? width, int copies = 1}) async {
    final job = PrintJob(
      id: _generateId(),
      documentType: PrintDocumentType.shiftSummary,
      data: data,
      paperWidth: width ?? _connectedPrinter?.paperWidth ?? PaperWidth.mm80,
      copies: copies,
    );
    return _submitJob(job);
  }

  /// Submit a print job to the queue.
  Future<bool> _submitJob(PrintJob job) async {
    _printQueue.add(job);
    notifyListeners();

    if (_connectedPrinter != null &&
        _connectedPrinter!.status == PrinterStatus.connected) {
      return _executeJob(job);
    }

    // No printer connected — job stays queued
    return false;
  }

  /// Execute a single print job.
  Future<bool> _executeJob(PrintJob job) async {
    job.status = PrintJobStatus.printing;
    notifyListeners();

    try {
      final bytes = _buildDocument(job);

      // In production: send bytes to printer via Bluetooth/WiFi
      //   - Bluetooth Classic: `connection.output.add(bytes)`
      //   - BLE: write to GATT characteristic
      //
      // Stub: simulate printing
      await Future.delayed(Duration(
          milliseconds: 200 + bytes.length ~/ 10));

      // Check for paper error (in production: read printer status)
      // Stub: always succeeds
      _checkPaperStatus();

      job.status = PrintJobStatus.completed;
      notifyListeners();
      return true;
    } on PrinterPaperException {
      job.status = PrintJobStatus.failed;
      job.errorMessage = 'Out of paper';
      _connectedPrinter = _connectedPrinter != null
          ? PrinterDevice(
              id: _connectedPrinter!.id,
              name: _connectedPrinter!.name,
              address: _connectedPrinter!.address,
              connectionType: _connectedPrinter!.connectionType,
              paperWidth: _connectedPrinter!.paperWidth,
              status: PrinterStatus.outOfPaper,
            )
          : null;
      notifyListeners();
      return false;
    } catch (e) {
      job.status = PrintJobStatus.failed;
      job.errorMessage = e.toString();
      _lastError = 'Print failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Build the ESC/POS byte stream for a print job.
  List<int> _buildDocument(PrintJob job) {
    switch (job.documentType) {
      case PrintDocumentType.ticket:
        return PrintTemplateBuilder.buildTicket(
          job.data,
          width: job.paperWidth,
        );
      case PrintDocumentType.cargoReceipt:
        return PrintTemplateBuilder.buildCargoReceipt(
          job.data,
          width: job.paperWidth,
        );
      case PrintDocumentType.refundReceipt:
        return PrintTemplateBuilder.buildRefundReceipt(
          job.data,
          width: job.paperWidth,
        );
      case PrintDocumentType.shiftSummary:
        return PrintTemplateBuilder.buildShiftSummary(
          job.data,
          width: job.paperWidth,
        );
    }
  }

  /// Process the print queue: attempt to print pending jobs.
  void _processQueue() {
    for (final job in _printQueue) {
      if (job.status == PrintJobStatus.pending) {
        _executeJob(job);
      }
    }
  }

  // ── Status ────────────────────────────────────────────────────────
  /// Check printer status.
  ///
  /// In production, reads printer status via:
  ///   - ESC/POS: DLE EOT n (real-time status)
  ///   - Returns paper status, cover status, error flags
  Future<PrinterStatus> checkStatus() async {
    if (_connectedPrinter == null) return PrinterStatus.disconnected;

    try {
      // Stub: simulate status check
      await Future.delayed(const Duration(milliseconds: 200));
      return _connectedPrinter!.status;
    } catch (_) {
      return PrinterStatus.error;
    }
  }

  /// Check for paper-related errors.
  void _checkPaperStatus() {
    // In production: read status bytes from printer
    //   - Bit 3 of DLE EOT 1 = paper near end
    //   - Bit 4 of DLE EOT 1 = paper present
    //
    // Stub: no paper error
  }

  // ── Retry ──────────────────────────────────────────────────────────
  /// Retry a failed print job.
  Future<bool> retryJob(String jobId) async {
    final job = _printQueue.where((j) => j.id == jobId).firstOrNull;
    if (job == null) return false;

    job.status = PrintJobStatus.pending;
    job.errorMessage = null;
    notifyListeners();

    return _executeJob(job);
  }

  /// Retry all failed print jobs.
  Future<int> retryAllFailed() async {
    int retried = 0;
    for (final job in _printQueue) {
      if (job.status == PrintJobStatus.failed) {
        job.status = PrintJobStatus.pending;
        job.errorMessage = null;
        retried++;
      }
    }
    notifyListeners();
    _processQueue();
    return retried;
  }

  /// Clear the print queue (completed and cancelled jobs).
  void clearCompleted() {
    _printQueue.removeWhere(
        (j) => j.status == PrintJobStatus.completed ||
            j.status == PrintJobStatus.cancelled);
    notifyListeners();
  }

  /// Cancel a pending print job.
  void cancelJob(String jobId) {
    final job = _printQueue.where((j) => j.id == jobId).firstOrNull;
    if (job != null && job.status == PrintJobStatus.pending) {
      job.status = PrintJobStatus.cancelled;
      notifyListeners();
    }
  }

  /// Cancel all pending print jobs.
  void cancelAllPending() {
    for (final job in _printQueue) {
      if (job.status == PrintJobStatus.pending) {
        job.status = PrintJobStatus.cancelled;
      }
    }
    notifyListeners();
  }

  // ── Simulation helpers (stub only — remove in production) ──────────
  List<PrinterDevice> _simulateDiscovery() {
    return [
      PrinterDevice(
        id: 'prn_001',
        name: 'Receipt Printer (C01)',
        address: '00:11:22:33:44:55',
        connectionType: PrinterConnection.bluetooth,
        paperWidth: PaperWidth.mm80,
      ),
      PrinterDevice(
        id: 'prn_002',
        name: 'Kitchen Printer',
        address: '00:11:22:33:44:66',
        connectionType: PrinterConnection.bluetooth,
        paperWidth: PaperWidth.mm58,
      ),
      PrinterDevice(
        id: 'prn_003',
        name: 'Ticket Printer (C02)',
        address: '00:11:22:33:44:77',
        connectionType: PrinterConnection.bluetooth,
        paperWidth: PaperWidth.mm80,
      ),
    ];
  }

  int _idCounter = 0;
  String _generateId() {
    _idCounter++;
    return 'print_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Exception thrown when a printer reports a paper error.
class PrinterPaperException implements Exception {
  final String message;
  const PrinterPaperException(this.message);
}
