import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/expense_models.dart';
import '../../auth/controllers/session_controller.dart';

/// Manages expense records: CRUD, date-range filtering, grouping, and reports.
class ExpenseController extends ChangeNotifier {
  ExpenseController({required SessionController session})
      : _api = session.api,
        _orgId = session.activeOrganization?.organization.id ?? '';

  final ApiClient _api;
  final String _orgId;

  List<Expense> _expenses = [];
  List<Expense> _filtered = [];
  ExpenseCategory? _selectedCategory;
  ExpenseDateRange _dateRange = ExpenseDateRange.all;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────
  List<Expense> get expenses =>
      (_selectedCategory != null || _dateRange != ExpenseDateRange.all)
          ? _filtered
          : _expenses;

  List<Expense> get allExpenses => _expenses;
  ExpenseCategory? get selectedCategory => _selectedCategory;
  ExpenseDateRange get dateRange => _dateRange;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  double get totalAmount =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  int get count => expenses.length;

  // ── Data loading ──────────────────────────────────────────────────────
  Future<void> loadExpenses() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getList('/organizations/$_orgId/expenses/');
      _expenses = data
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList();
      _applyFilters();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────
  void filterByCategory(ExpenseCategory? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(ExpenseDateRange range,
      {DateTime? customStart, DateTime? customEnd}) {
    _dateRange = range;
    _customStart = customStart;
    _customEnd = customEnd;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = List<Expense>.from(_expenses);

    // Category filter
    if (_selectedCategory != null) {
      result = result.where((e) => e.category == _selectedCategory).toList();
    }

    // Date range filter
    if (_dateRange != ExpenseDateRange.all) {
      final now = DateTime.now();
      DateTime? start;
      DateTime? end;

      switch (_dateRange) {
        case ExpenseDateRange.today:
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1));
        case ExpenseDateRange.thisWeek:
          final weekday = now.weekday;
          start = DateTime(now.year, now.month, now.day - weekday + 1);
          end = start.add(const Duration(days: 7));
        case ExpenseDateRange.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1);
        case ExpenseDateRange.custom:
          start = _customStart;
          end = _customEnd;
        case ExpenseDateRange.all:
          break;
      }

      if (start != null) {
        final s = start;
        result = result.where((e) => e.expenseDate.isAfter(s)).toList();
      }
      if (end != null) {
        final e = end;
        result = result.where((ex) => ex.expenseDate.isBefore(e)).toList();
      }
    }

    _filtered = result;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────
  Future<bool> createExpense(Expense expense) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/organizations/$_orgId/expenses/', {
        'category': expense.category.apiValue,
        'amount': expense.amount,
        if (expense.description != null) 'description': expense.description,
        if (expense.vehicleId != null) 'vehicle_id': expense.vehicleId,
        if (expense.tripId != null) 'trip_id': expense.tripId,
        'expense_date':
            '${expense.expenseDate.year}-${expense.expenseDate.month.toString().padLeft(2, '0')}-${expense.expenseDate.day.toString().padLeft(2, '0')}',
        if (expense.receiptNumber != null)
          'receipt_number': expense.receiptNumber,
        if (expense.paidTo != null) 'paid_to': expense.paidTo,
      });
      _recordAudit(
        action: 'expense.create',
        resourceType: 'expense',
        resourceId: expense.id ?? '',
        details: {
          'category': expense.category.label,
          'amount': expense.amount,
          if (expense.vehicleId != null) 'vehicle_id': expense.vehicleId,
          if (expense.tripId != null) 'trip_id': expense.tripId,
          if (expense.paidTo != null) 'paid_to': expense.paidTo,
        },
      );
      await loadExpenses();
      _submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to create expense: $e';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.delete('/organizations/$_orgId/expenses/$id/');
      _expenses.removeWhere((e) => e.id == id);
      _applyFilters();
      _submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to delete expense: $e';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────

  /// Total expenses grouped by category.
  Map<ExpenseCategory, double> get categoryTotals {
    final totals = <ExpenseCategory, double>{};
    for (final category in ExpenseCategory.values) {
      totals[category] = _expenses
          .where((e) => e.category == category)
          .fold(0.0, (sum, e) => sum + e.amount);
    }
    return totals;
  }

  /// Total expenses grouped by high-level group (Staff, Vehicle, Office, Admin, Other).
  Map<ExpenseGroup, double> get groupTotals {
    final totals = <ExpenseGroup, double>{};
    for (final group in ExpenseGroup.values) {
      totals[group] = 0;
    }
    for (final e in _expenses) {
      totals.update(e.category.group, (v) => v + e.amount);
    }
    return totals;
  }

  /// Total expenses for a specific date.
  double totalForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _expenses
        .where((e) =>
            e.expenseDate.year == d.year &&
            e.expenseDate.month == d.month &&
            e.expenseDate.day == d.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Total expenses for a specific month.
  double totalForMonth(int year, int month) {
    return _expenses
        .where((e) => e.expenseDate.year == year && e.expenseDate.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Expenses linked to a specific trip.
  List<Expense> expensesForTrip(String tripId) =>
      _expenses.where((e) => e.tripId == tripId).toList();

  /// Expenses linked to a specific vehicle.
  List<Expense> expensesForVehicle(String vehicleId) =>
      _expenses.where((e) => e.vehicleId == vehicleId).toList();

  /// Daily expense totals for the current month.
  Map<int, double> get dailyTotals {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totals = <int, double>{};
    for (var d = 1; d <= daysInMonth; d++) {
      totals[d] = 0;
    }
    for (final e in _expenses) {
      if (e.expenseDate.year == now.year && e.expenseDate.month == now.month) {
        totals.update(e.expenseDate.day, (v) => v + e.amount);
      }
    }
    return totals;
  }

  /// Monthly expense totals for the current year.
  Map<int, double> get monthlyTotals {
    final now = DateTime.now();
    final totals = <int, double>{};
    for (var m = 1; m <= 12; m++) {
      totals[m] = totalForMonth(now.year, m);
    }
    return totals;
  }

  /// Record an audit entry for expense operations (fire-and-forget).
  void _recordAudit({
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) {
    _api.post('/organizations/$_orgId/audit-logs/', {
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'details': ?details,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).catchError((_) => <String, dynamic>{});
  }
}
