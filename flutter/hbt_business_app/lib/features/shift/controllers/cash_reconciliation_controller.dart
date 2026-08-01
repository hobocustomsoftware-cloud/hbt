import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/cash_models.dart';
import '../../../shared/models/shift_models.dart';

/// Fetches and aggregates cash reconciliation data.
///
/// Provides shift-level and daily-level cash breakdowns:
/// - Opening cash
/// - Cash ticket sales (payments made in cash)
/// - Cash refunds paid out
/// - Cash expenses
/// - Expected cash calculation
/// - Owner report (per-counter per-shift)
/// - Daily report (all shifts for a date)
class CashReconciliationController extends ChangeNotifier {
  CashReconciliationController({
    required ApiClient api,
    required String organizationId,
  })  : _api = api,
        _orgId = organizationId;

  final ApiClient _api;
  final String _orgId;

  ShiftCashData? _shiftCashData;
  ShiftCashReport? _shiftReport;
  DailyCashSummary? _dailySummary;
  List<ShiftCashReport> _dailyReports = [];
  bool _loading = false;
  String? _error;

  // ── Getters ──
  ShiftCashData? get shiftCashData => _shiftCashData;
  ShiftCashReport? get shiftReport => _shiftReport;
  DailyCashSummary? get dailySummary => _dailySummary;
  List<ShiftCashReport> get dailyReports => _dailyReports;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch cash reconciliation data for the given shift.
  ///
  /// Returns the expected cash calculation based on:
  /// opening_cash + cash_payments - cash_refunds - cash_expenses
  Future<ShiftCashData?> loadShiftCashData(Shift shift) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch cash payments, cash refunds, cash expenses in parallel
      final result = await _api.get(
        '/organizations/$_orgId/shifts/${shift.id}/cash-breakdown/',
      );
      _shiftCashData = ShiftCashData.fromJson(result);
      _loading = false;
      notifyListeners();
      return _shiftCashData;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to load cash data: $e';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Fetch the full cash reconciliation report for a shift.
  Future<ShiftCashReport?> loadShiftReport(Shift shift) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.get(
        '/organizations/$_orgId/shifts/${shift.id}/cash-report/',
      );
      _shiftReport = ShiftCashReport.fromJson(result);
      _loading = false;
      notifyListeners();
      return _shiftReport;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to load shift report: $e';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Fetch owner report — all shifts for the given user/counter on a date.
  Future<List<ShiftCashReport>> loadOwnerReport({
    String? userId,
    String? counterId,
    required String startDate,
    required String endDate,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final params = StringBuffer('?start_date=$startDate&end_date=$endDate');
      if (userId != null) params.write('&user_id=$userId');
      if (counterId != null) params.write('&counter_id=$counterId');

      final data = await _api.getList(
        '/organizations/$_orgId/shifts/cash-reports/$params',
      );
      _dailyReports = data
          .whereType<Map<String, dynamic>>()
          .map(ShiftCashReport.fromJson)
          .toList();
      _loading = false;
      notifyListeners();
      return _dailyReports;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return [];
    } catch (e) {
      _error = 'Failed to load owner report: $e';
      _loading = false;
      notifyListeners();
      return [];
    }
  }

  /// Fetch daily report — aggregated across all counters for a date.
  Future<DailyCashSummary?> loadDailyReport(String date) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.get(
        '/organizations/$_orgId/shifts/daily-cash-summary/?date=$date',
      );
      _dailySummary = DailyCashSummary.fromJson(result);
      _loading = false;
      notifyListeners();
      return _dailySummary;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to load daily report: $e';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Validate that cash reconciliation can proceed.
  /// Returns null if valid, or an error message if blocked.
  String? validateReconciliation(Shift shift, ShiftCashData? cashData) {
    if (cashData == null) return 'Cash data not loaded.';
    if (shift.status == ShiftStatus.closed) return 'Shift already closed.';
    return null;
  }

  /// Format a double as MMK.
  static String fmt(double v) => '${v.toStringAsFixed(0)} MMK';
}
