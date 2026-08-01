import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/shift_models.dart';
import '../../auth/controllers/session_controller.dart';

/// Manages the lifecycle of a counter shift: open, track, close.
///
/// Integrates with ticket sales, cargo, expenses, and P&L.
/// Supports offline queue via [ShiftQueueItem] for future offline operation.
class ShiftController extends ChangeNotifier {
  ShiftController({required SessionController session})
      : _api = session.api,
        _orgId = session.activeOrganization?.organization.id ?? '';

  final ApiClient _api;
  final String _orgId;

  /// The underlying API client (for use by related controllers).
  ApiClient get api => _api;

  /// The active organization ID used for API calls.
  String get organizationId => _orgId;

  // ── State ─────────────────────────────────────────────────────────────
  List<Branch> _branches = [];
  List<Counter> _counters = [];
  Shift? _activeShift;

  bool _loadingBranches = false;
  bool _loadingCounters = false;
  bool _opening = false;
  bool _closing = false;
  bool _refreshing = false;
  String? _error;

  // Active shift timer
  Timer? _timer;
  DateTime? _shiftStartTime;
  Duration _elapsed = Duration.zero;

  // Offline queue (for future use with SyncUploadQueue)
  final List<ShiftQueueItem> _pendingOps = [];

  // ── Getters ───────────────────────────────────────────────────────────
  List<Branch> get branches => _branches;
  List<Counter> get counters => _counters;
  Shift? get activeShift => _activeShift;
  List<ShiftQueueItem> get pendingOps => List.unmodifiable(_pendingOps);

  bool get loadingBranches => _loadingBranches;
  bool get loadingCounters => _loadingCounters;
  bool get opening => _opening;
  bool get closing => _closing;
  bool get refreshing => _refreshing;
  String? get error => _error;
  int get pendingOpCount => _pendingOps.length;

  bool get hasActiveShift => _activeShift != null;
  Duration get elapsed => _elapsed;
  String get elapsedFormatted => _formatDuration(_elapsed);

  String get _branchName {
    if (_activeShift == null) return '';
    final match = _branches.where((b) => b.id == _activeShift!.branchId);
    return match.isNotEmpty ? match.first.name : _activeShift!.branchId;
  }

  String get _counterName {
    if (_activeShift == null) return '';
    final match = _counters.where((c) => c.id == _activeShift!.counterId);
    return match.isNotEmpty
        ? (match.first.displayName ?? match.first.code)
        : _activeShift!.counterId;
  }

  // ── Branch / Counter loading ──────────────────────────────────────────
  Future<void> loadBranches() async {
    _loadingBranches = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getList('/organizations/$_orgId/branches/');
      _branches = data
          .whereType<Map<String, dynamic>>()
          .map(Branch.fromJson)
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load branches: $e';
    } finally {
      _loadingBranches = false;
      notifyListeners();
    }
  }

  Future<void> loadCounters(String branchId) async {
    _loadingCounters = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getList(
        '/organizations/$_orgId/branches/$branchId/counters/',
      );
      _counters = data
          .whereType<Map<String, dynamic>>()
          .map(Counter.fromJson)
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load counters: $e';
    } finally {
      _loadingCounters = false;
      notifyListeners();
    }
  }

  // ── Shift lifecycle ───────────────────────────────────────────────────
  Future<bool> openShift({
    required String branchId,
    required String counterId,
    required double openingCash,
    bool printerChecked = false,
  }) async {
    _opening = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.post('/organizations/$_orgId/shifts/', {
        'branch_id': branchId,
        'counter_id': counterId,
        'opening_cash': openingCash,
        'printer_checked': printerChecked,
      });
      _activeShift = Shift.fromJson({
        ...result,
        'opened_at': DateTime.now().toUtc().toIso8601String(),
      });
      _shiftStartTime = DateTime.now();
      _startTimer();
      _recordOp(ShiftQueueOp.openShift, {
        'branchId': branchId,
        'counterId': counterId,
        'openingCash': openingCash,
      });
      // Record audit
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
      _opening = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _opening = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to open shift: $e';
      _opening = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeShift({
    required double closingCash,
    String? differenceReason,
  }) async {
    if (_activeShift == null) return false;
    _closing = true;
    _error = null;
    notifyListeners();
    try {
      final expected = _activeShift!.openingCash + _activeShift!.totalRevenue;
      final result = await _api.post(
        '/organizations/$_orgId/shifts/${_activeShift!.id}/close/',
        {
          'closing_cash': closingCash,
          'expected_cash': expected,
          'cash_difference': closingCash - expected,
          if (differenceReason != null && differenceReason.isNotEmpty)
            'difference_reason': differenceReason,
        },
      );
      _activeShift = Shift.fromJson(result);
      _stopTimer();
      _recordOp(ShiftQueueOp.closeShift, {
        'closingCash': closingCash,
        'differenceReason': differenceReason,
      });
      _recordAudit(
        action: 'shift.close',
        resourceType: 'shift',
        resourceId: _activeShift!.id ?? '',
        details: {
          'opening_cash': _activeShift!.openingCash,
          'closing_cash': closingCash,
          'expected_cash': expected,
          'cash_difference': closingCash - expected,
          if (differenceReason != null && differenceReason.isNotEmpty)
            'difference_reason': differenceReason,
          'total_revenue': _activeShift!.totalRevenue,
          'expense_total': _activeShift!.expenseTotal,
          'net_revenue': _activeShift!.netRevenue,
        },
      );
      _closing = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _closing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to close shift: $e';
      _closing = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh shift metrics by re-fetching from the server.
  /// Call after a new booking, cargo acceptance, or expense is recorded
  /// during an active shift to keep the dashboard current.
  Future<void> refreshMetrics() async {
    if (_activeShift?.id == null) return;
    _refreshing = true;
    notifyListeners();
    try {
      final data =
          await _api.get('/organizations/$_orgId/shifts/${_activeShift!.id}/');
      _activeShift = Shift.fromJson(data);
    } on ApiException {
      // Silent — metrics will update on next sync
    } catch (_) {}
    _refreshing = false;
    notifyListeners();
  }

  /// Load the active shift for the current user (if any).
  Future<void> loadActiveShift() async {
    try {
      final data = await _api.get('/organizations/$_orgId/shifts/active/');
      _activeShift = Shift.fromJson(data);
      if (_activeShift?.id != null) {
        _shiftStartTime = DateTime.tryParse(_activeShift!.openedAt ?? '');
        _startTimer();
      }
    } on ApiException {
      _activeShift = null;
    } catch (_) {
      _activeShift = null;
    }
    notifyListeners();
  }

  // ── Shift sheet data (for P&L / reporting) ────────────────────────────

  /// Returns a summary map for the active or last closed shift.
  Map<String, dynamic> get shiftSheet {
    final s = _activeShift;
    if (s == null) return {};
    return {
      'branch': _branchName,
      'counter': _counterName,
      'opened': s.openedAt ?? '-',
      'closed': s.closedAt ?? '-',
      'duration': elapsedFormatted,
      'opening_cash': s.openingCash,
      'closing_cash': s.closingCash ?? 0,
      'expected_cash': (s.openingCash + s.totalRevenue),
      'cash_difference':
          (s.closingCash ?? 0) - (s.openingCash + s.totalRevenue),
      'ticket_revenue': s.ticketRevenue,
      'cargo_revenue': s.cargoRevenue,
      'expense_total': s.expenseTotal,
      'net_revenue': s.netRevenue,
      'tickets_sold': s.ticketSalesCount,
      'cargo_accepted': s.cargoCount,
      'refunds': s.refundCount,
      'expenses': s.expenseCount,
    };
  }

  // ── Offline queue support ─────────────────────────────────────────────

  void _recordOp(ShiftQueueOp op, Map<String, dynamic> payload) {
    _pendingOps.add(ShiftQueueItem(
      operation: op,
      payload: payload,
      timestamp: DateTime.now(),
    ));
  }

  /// Record an audit entry via the API (fire-and-forget).
  /// Includes the shift's organization, branch, and counter context.
  Future<void> _recordAudit({
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _api.post('/organizations/$_orgId/audit-logs/', {
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'counter_id': ?_activeShift?.counterId,
        'branch_id': ?_activeShift?.branchId,
        'details': ?details,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Best-effort audit — never block the operation
    }
  }

  /// Flush the pending operations queue (called after successful sync).
  void flushPendingOps() {
    _pendingOps.clear();
    notifyListeners();
  }

  // ── Timer ─────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_shiftStartTime != null) {
        _elapsed = DateTime.now().difference(_shiftStartTime!);
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// A queued shift operation for future offline sync.
class ShiftQueueItem {
  final ShiftQueueOp operation;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const ShiftQueueItem({
    required this.operation,
    required this.payload,
    required this.timestamp,
  });
}

enum ShiftQueueOp { openShift, closeShift, refreshMetrics }
