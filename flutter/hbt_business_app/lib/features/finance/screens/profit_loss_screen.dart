import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_views.dart';
import '../../../shared/models/expense_models.dart';
import '../controllers/profit_loss_controller.dart';

/// Profit & Loss statement screen.
///
/// Shows income (ticket, cargo, other), expenses by category,
/// net profit, and profit margin.
class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key, required this.controller});

  final ProfitLossController controller;

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.load,
          ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, ProfitLossController ctrl) {
    if (ctrl.loading) return const LoadingView();
    if (ctrl.error != null) {
      return ErrorView(message: ctrl.error!, onRetry: ctrl.load);
    }

    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: ctrl.load,
      child: ListView(
        padding: AppTheme.pagePadding,
        children: [
          // ── Net profit banner ──────────────────────────────
          Card(
            color: ctrl.isProfitable ? Colors.green[50] : cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Icon(
                    ctrl.isProfitable
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 40,
                    color: ctrl.isProfitable ? Colors.green : cs.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Net Profit',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ctrl.format(ctrl.netProfit),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ctrl.isProfitable
                              ? Colors.green[700]
                              : cs.error,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ctrl.profitMargin.toStringAsFixed(1)}% margin',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Income section ─────────────────────────────────
          _sectionHeader(context, Icons.account_balance, 'Income'),
          _incomeRow(context, 'Ticket Revenue', ctrl.ticketRevenue,
              Colors.blue, cs),
          _incomeRow(context, 'Cargo Revenue', ctrl.cargoRevenue,
              Colors.indigo, cs),
          _incomeRow(context, 'Other Income', ctrl.otherIncome,
              Colors.teal, cs),
          const Divider(height: 24),
          _totalRow(context, 'Total Income', ctrl.totalRevenue, cs),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Expenses section ───────────────────────────────
          _sectionHeader(context, Icons.receipt_long, 'Expenses'),
          ...ExpenseCategory.values
              .where(
                  (cat) => (ctrl.expenseBreakdown[cat] ?? 0) > 0)
              .map((cat) => _expenseRow(context, cat,
                  ctrl.expenseBreakdown[cat] ?? 0, cs)),
          if (ctrl.expenseBreakdown.values
              .every((v) => v == 0)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No expenses recorded.',
                  style: TextStyle(color: Colors.grey[500])),
            ),
          ],
          const Divider(height: 24),
          _totalRow(context, 'Total Expenses', ctrl.totalExpenses, cs),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Net profit line ────────────────────────────────
          Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: ctrl.isProfitable
                  ? Colors.green[50]
                  : cs.errorContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  ctrl.isProfitable
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: ctrl.isProfitable
                      ? Colors.green
                      : cs.error,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'Net Profit',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  ctrl.format(ctrl.netProfit),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ctrl.isProfitable
                            ? Colors.green[700]
                            : cs.error,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
          BuildContext context, IconData icon, String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _incomeRow(BuildContext context, String label, double amount,
      Color color, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTheme.dataValueStyle(context)),
          ),
          Text(
            _fmt(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseRow(BuildContext context, ExpenseCategory cat,
      double amount, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: cs.error.withAlpha(120),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(cat.label,
                style: AppTheme.dataValueStyle(context)),
          ),
          Text(
            _fmt(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
      BuildContext context, String label, double amount, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            _fmt(amount),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0)} MMK';
}
