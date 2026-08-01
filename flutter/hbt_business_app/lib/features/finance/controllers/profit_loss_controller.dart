import 'package:flutter/foundation.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/expense_models.dart';
import '../../auth/controllers/session_controller.dart';

/// Aggregates revenue and expense data to produce a P&L summary.
///
/// Revenue sources:
/// - Ticket sales (from bookings/fare quotes)
/// - Cargo fees (from cargo shipments)
/// - Other income (manual entry)
///
/// Expenses: all [ExpenseCategory] totals from the expense system.
///
/// Net Profit = (Ticket + Cargo + Other) - Total Expenses
class ProfitLossController extends ChangeNotifier {
  ProfitLossController({required SessionController session})
      : _api = session.api,
        _orgId = session.activeOrganization?.organization.id ?? '';

  final ApiClient _api;
  final String _orgId;

  double _ticketRevenue = 0;
  double _cargoRevenue = 0;
  final double _otherIncome = 0;
  double _totalExpenses = 0;
  Map<ExpenseCategory, double> _expenseBreakdown = {};
  bool _loading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────
  double get ticketRevenue => _ticketRevenue;
  double get cargoRevenue => _cargoRevenue;
  double get otherIncome => _otherIncome;
  double get totalRevenue => _ticketRevenue + _cargoRevenue + _otherIncome;
  double get totalExpenses => _totalExpenses;
  double get netProfit => totalRevenue - _totalExpenses;
  Map<ExpenseCategory, double> get expenseBreakdown => _expenseBreakdown;
  bool get loading => _loading;
  String? get error => _error;

  bool get isProfitable => netProfit >= 0;
  double get profitMargin =>
      totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

  /// Fetch all data for the P&L summary.
  Future<void> load({
    String? startDate,
    String? endDate,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Build date query string
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    final dateParams =
        params.isEmpty ? '' : '?${params.join('&')}';

    try {
      // Fetch revenue and expenses in parallel
      final results = await Future.wait([
        _api.getList('/organizations/$_orgId/bookings/$dateParams'),
        _api.getList('/organizations/$_orgId/cargo/shipments/$dateParams'),
        _api.getList('/organizations/$_orgId/expenses/$dateParams'),
      ]);

      // ── Ticket revenue ────────────────────────────────────
      final bookings = results[0].whereType<Map<String, dynamic>>();
      _ticketRevenue = 0;
      for (final b in bookings) {
        _ticketRevenue +=
            double.tryParse(b['total_amount']?.toString() ?? '0') ?? 0;
      }

      // ── Cargo revenue ─────────────────────────────────────
      final shipments = results[1].whereType<Map<String, dynamic>>();
      _cargoRevenue = 0;
      for (final s in shipments) {
        _cargoRevenue +=
            double.tryParse(s['total_charge']?.toString() ?? '0') ?? 0;
      }

      // ── Expenses ──────────────────────────────────────────
      final rawExpenses = results[2].whereType<Map<String, dynamic>>();
      _totalExpenses = 0;
      _expenseBreakdown = {};
      for (final e in rawExpenses) {
        final cat = ExpenseCategory.fromString(
            e['category']?.toString() ?? '');
        final amt =
            double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
        _totalExpenses += amt;
        _expenseBreakdown.update(cat, (v) => v + amt, ifAbsent: () => amt);
      }

      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load financial data: $e';
      _loading = false;
      notifyListeners();
    }
  }

  /// Format a number as MMK string.
  String format(double amount) => '${amount.toStringAsFixed(0)} MMK';
}
