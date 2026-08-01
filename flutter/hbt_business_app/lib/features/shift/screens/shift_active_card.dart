import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/shift_controller.dart';

/// Active shift card shown on the dashboard while a shift is running.
///
/// Displays elapsed time, revenue, ticket/cargo/refund/expense counts,
/// and a "Close Shift" action.
class ActiveShiftCard extends StatelessWidget {
  const ActiveShiftCard({
    super.key,
    required this.controller,
    required this.onCloseShift,
    this.onRefresh,
    this.onRecordExpense,
  });

  final ShiftController controller;
  final VoidCallback onCloseShift;
  final VoidCallback? onRefresh;
  final VoidCallback? onRecordExpense;

  @override
  Widget build(BuildContext context) {
    final shift = controller.activeShift;
    if (shift == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.primaryContainer.withAlpha(180),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    'Shift Active',
                    style: AppTheme.sectionHeaderStyle(context)
                        .copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: Icon(Icons.refresh,
                        size: 18, color: cs.onPrimaryContainer),
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Refresh metrics',
                  ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  controller.elapsedFormatted,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(height: 1),

            // 5-metric grid
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Row(
                children: [
                  _metric(Icons.confirmation_number,
                      '${shift.ticketSalesCount}', 'Tickets', context),
                  _metric(
                      Icons.inventory_2, '${shift.cargoCount}', 'Cargo', context),
                  _metric(
                      Icons.replay, '${shift.refundCount}', 'Refunds', context),
                  _metric(Icons.receipt_long_outlined,
                      '${shift.expenseCount}', 'Expenses', context),
                  _metric(Icons.attach_money,
                      shift.totalRevenue.toStringAsFixed(0), 'Revenue', context),
                ],
              ),
            ),
            const Divider(height: 1),

            // Cash + net revenue row
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Row(
                children: [
                  Icon(Icons.account_balance,
                      size: 16, color: cs.onPrimaryContainer),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Cash: ${shift.openingCash.toStringAsFixed(0)} MMK',
                    style: TextStyle(
                        fontSize: 12, color: cs.onPrimaryContainer),
                  ),
                  const Spacer(),
                  Icon(Icons.trending_up,
                      size: 16,
                      color: shift.netRevenue >= 0
                          ? Colors.green
                          : cs.error),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    'Net: ${shift.netRevenue.toStringAsFixed(0)} MMK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: shift.netRevenue >= 0
                          ? Colors.green[700]
                          : cs.error,
                    ),
                  ),
                ],
              ),
            ),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRecordExpense != null)
                  TextButton.icon(
                    onPressed: onRecordExpense,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Expense'),
                  ),
                const SizedBox(width: AppTheme.spacingSm),
                TextButton.icon(
                  onPressed: onCloseShift,
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Close Shift'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
      IconData icon, String value, String label, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.onPrimaryContainer),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer.withAlpha(180),
                ),
          ),
        ],
      ),
    );
  }
}
