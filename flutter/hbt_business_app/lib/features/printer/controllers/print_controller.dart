import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/printer_models.dart';
import 'printer_service.dart';
import 'printer_settings_controller.dart';

/// High-level controller for printer management in the app.
///
/// Coordinates:
/// - Printer discovery and connection lifecycle
/// - Document printing (ticket, cargo, refund, shift summary)
/// - Printer status monitoring
/// - Auto-reconnect on connection loss
/// - Retry failed jobs
/// - Settings persistence
/// - Reprint last document
class PrintController extends ChangeNotifier {
  PrintController({
    PrinterService? service,
    PrinterSettingsController? settings,
  })  : _service = service ?? PrinterService(),
        _settings = settings ?? PrinterSettingsController() {
    _service.addListener(_onServiceChanged);
    _settings.addListener(_onServiceChanged);
  }

  final PrinterService _service;
  final PrinterSettingsController _settings;
  Timer? _statusTimer;

  // ── Delegated getters ──
  PrinterService get service => _service;
  PrinterSettingsController get settings => _settings;
  bool get discovering => _service.discovering;
  bool get connecting => _service.connecting;
  bool get printing => _service.printing;
  String? get lastError => _service.lastError;
  bool get isConnected => _service.isConnected;
  PrinterDevice? get connectedPrinter => _service.connectedPrinter;
  List<PrinterDevice> get discoveredDevices =>
      _service.discoveredDevices;
  List<PrintJob> get printQueue => _service.printQueue;
  int get pendingJobCount => _service.pendingJobCount;
  bool get hasQueuedJobs => _service.hasQueuedJobs;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _service.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _service.removeListener(listener);
  }

  void _onServiceChanged() {
    notifyListeners();
  }

  // ── Discovery ──
  Future<List<PrinterDevice>> discoverPrinters() =>
      _service.discoverPrinters();

  void cancelDiscovery() => _service.cancelDiscovery();

  // ── Connection ──
  Future<bool> connect(PrinterDevice device) async {
    final ok = await _service.connect(device);
    if (ok) {
      _startStatusMonitoring();
    }
    return ok;
  }

  Future<void> disconnect() async {
    _stopStatusMonitoring();
    await _service.disconnect();
  }

  // ── Printing ──
  Future<bool> printTicket(Map<String, dynamic> data,
          {PaperWidth? width, int copies = 1}) async {
    final result = await _service.printTicket(data,
        width: width ?? _settings.defaultPaperWidth,
        copies: copies);
    if (result) _settings.recordLastPrint(PrintDocumentType.ticket, data);
    return result;
  }

  Future<bool> printCargoReceipt(Map<String, dynamic> data,
          {PaperWidth? width, int copies = 1}) async {
    final result = await _service.printCargoReceipt(data,
        width: width ?? _settings.defaultPaperWidth,
        copies: copies);
    if (result) _settings.recordLastPrint(PrintDocumentType.cargoReceipt, data);
    return result;
  }

  Future<bool> printRefundReceipt(Map<String, dynamic> data,
          {PaperWidth? width, int copies = 1}) async {
    final result = await _service.printRefundReceipt(data,
        width: width ?? _settings.defaultPaperWidth,
        copies: copies);
    if (result) _settings.recordLastPrint(PrintDocumentType.refundReceipt, data);
    return result;
  }

  Future<bool> printShiftSummary(Map<String, dynamic> data,
          {PaperWidth? width, int copies = 1}) async {
    final result = await _service.printShiftSummary(data,
        width: width ?? _settings.defaultPaperWidth,
        copies: copies);
    if (result) _settings.recordLastPrint(PrintDocumentType.shiftSummary, data);
    return result;
  }

  // ── Job management ──
  Future<bool> retryJob(String jobId) => _service.retryJob(jobId);
  Future<int> retryAllFailed() => _service.retryAllFailed();
  void clearCompleted() => _service.clearCompleted();
  void cancelJob(String jobId) => _service.cancelJob(jobId);
  void cancelAllPending() => _service.cancelAllPending();

  // ── Status monitoring ──
  void _startStatusMonitoring() {
    _stopStatusMonitoring();
    _statusTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_service.connectedPrinter == null) {
        _stopStatusMonitoring();
        return;
      }
      final status = await _service.checkStatus();
      if (status.isError && _service.connectedPrinter != null) {
        // Disconnect on fatal error
        await _service.disconnect();
      }
    });
  }

  void _stopStatusMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  /// Prepare ticket print data from booking/payment result data.
  static Map<String, dynamic> ticketPrintData({
    required String ticketNumber,
    required String passengerName,
    required String tripNumber,
    required String serviceDate,
    required String departureTime,
    required String seatNumber,
    required String pickupStop,
    required String dropoffStop,
    required String fareAmount,
    required String totalAmount,
    String? serviceCharge,
    String? validationCode,
    String? companyName,
    String? branchName,
    String? counterName,
  }) =>
      {
        'ticket_number': ticketNumber,
        'passenger_name': passengerName,
        'trip_number': tripNumber,
        'service_date': serviceDate,
        'departure_time': departureTime,
        'seat_number': seatNumber,
        'pickup_stop': pickupStop,
        'dropoff_stop': dropoffStop,
        'fare_amount': fareAmount,
        'total_amount': totalAmount,
        'service_charge': ?serviceCharge,
        'validation_code': ?validationCode,
        'company_name': ?companyName,
        'branch_name': ?branchName,
        'counter_name': ?counterName,
      };

  /// Prepare cargo print data.
  static Map<String, dynamic> cargoPrintData({
    required String shipmentNumber,
    required String trackingCode,
    required String senderName,
    required String receiverName,
    required String originTerminal,
    required String destinationTerminal,
    required String itemCategory,
    required int pieceCount,
    required String weightKg,
    required String totalCharge,
    String? companyName,
  }) =>
      {
        'shipment_number': shipmentNumber,
        'tracking_code': trackingCode,
        'sender_name': senderName,
        'receiver_name': receiverName,
        'origin_terminal': originTerminal,
        'destination_terminal': destinationTerminal,
        'item_category': itemCategory,
        'piece_count': pieceCount,
        'weight_kg': weightKg,
        'total_charge': totalCharge,
        'company_name': ?companyName,
      };

  /// Prepare refund print data.
  static Map<String, dynamic> refundPrintData({
    required String refundNumber,
    required String passengerName,
    required String bookingNumber,
    required String ticketNumber,
    required String paymentReference,
    required String reason,
    required String refundAmount,
    required String refundMethod,
    String? counterName,
    String? companyName,
  }) =>
      {
        'refund_number': refundNumber,
        'passenger_name': passengerName,
        'booking_number': bookingNumber,
        'ticket_number': ticketNumber,
        'payment_reference': paymentReference,
        'reason': reason,
        'refund_amount': refundAmount,
        'refund_method': refundMethod,
        'counter_name': ?counterName,
        'company_name': ?companyName,
      };

  /// Prepare shift summary print data.
  static Map<String, dynamic> shiftPrintData({
    required String branchName,
    required String counterName,
    required String staffName,
    required String date,
    required String duration,
    required String openingCash,
    required String expectedCash,
    required String actualCash,
    required String cashDifference,
    required String ticketRevenue,
    required String cargoRevenue,
    required String expenseTotal,
    required String netRevenue,
    required int ticketCount,
    required int cargoCount,
    required int refundCount,
    required int expenseCount,
    String? companyName,
  }) =>
      {
        'branch_name': branchName,
        'counter_name': counterName,
        'staff_name': staffName,
        'date': date,
        'duration': duration,
        'opening_cash': openingCash,
        'expected_cash': expectedCash,
        'actual_cash': actualCash,
        'cash_difference': cashDifference,
        'ticket_revenue': ticketRevenue,
        'cargo_revenue': cargoRevenue,
        'expense_total': expenseTotal,
        'net_revenue': netRevenue,
        'ticket_count': ticketCount,
        'cargo_count': cargoCount,
        'refund_count': refundCount,
        'expense_count': expenseCount,
        'company_name': ?companyName,
      };

  @override
  void dispose() {
    _stopStatusMonitoring();
    _service.removeListener(_onServiceChanged);
    _service.dispose();
    super.dispose();
  }
}
