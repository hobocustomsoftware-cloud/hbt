import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/async_views.dart';
import '../../../shared/models/expense_models.dart';
import '../controllers/expense_controller.dart';
import 'expense_create_screen.dart';

/// Expense list screen with category + date-range filtering,
/// group-level summary, and per-category breakdown.
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key, required this.controller});

  final ExpenseController controller;

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  bool _showGroups = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.loadExpenses();
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
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(_showGroups ? Icons.list : Icons.grid_view),
            tooltip: _showGroups ? 'List view' : 'Group view',
            onPressed: () => setState(() => _showGroups = !_showGroups),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Record Expense',
            onPressed: () => _createExpense(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: ctrl.loadExpenses,
          ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, ExpenseController ctrl) {
    if (ctrl.loading) return const LoadingView();
    if (ctrl.error != null) {
      return ErrorView(message: ctrl.error!, onRetry: ctrl.loadExpenses);
    }

    return Column(
      children: [
        _DateRangeFilterBar(
          selected: ctrl.dateRange,
          onChanged: (range) => ctrl.setDateRange(range),
        ),
        _CategoryFilterBar(
          selected: ctrl.selectedCategory,
          totals: ctrl.categoryTotals,
          onChanged: (cat) => ctrl.filterByCategory(cat),
        ),
        _TotalBar(total: ctrl.totalAmount, count: ctrl.count),
        Expanded(
          child: _showGroups
              ? _buildGroupView(context, ctrl)
              : _buildExpenseList(ctrl),
        ),
      ],
    );
  }

  Widget _buildGroupView(BuildContext context, ExpenseController ctrl) {
    final groups = ctrl.groupTotals;
    if (ctrl.expenses.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      onRefresh: ctrl.loadExpenses,
      child: ListView(
        padding: AppTheme.listPadding,
        children: [
          for (final group in ExpenseGroup.values)
            if ((groups[group] ?? 0) > 0) ...[
              _GroupTotalCard(
                group: group,
                total: groups[group]!,
                categories: ExpenseCategory.values
                    .where((c) => c.group == group)
                    .toList(),
                categoryTotals: ctrl.categoryTotals,
                onCategoryTap: (cat) {
                  ctrl.filterByCategory(cat);
                  setState(() => _showGroups = false);
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],
        ],
      ),
    );
  }

  Widget _buildExpenseList(ExpenseController ctrl) {
    if (ctrl.expenses.isEmpty) return _buildEmpty(context);

    return RefreshIndicator(
      onRefresh: ctrl.loadExpenses,
      child: ListView.separated(
        padding: AppTheme.listPadding,
        itemCount: ctrl.expenses.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSm),
        itemBuilder: (context, index) {
          final expense = ctrl.expenses[index];
          return _ExpenseCard(
            expense: expense,
            onDelete: () => _deleteExpense(context, expense),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    if (widget.controller.expenses.isNotEmpty) {
      // Filtered to empty — show clear filter hint
      return Center(
        child: Padding(
          padding: AppTheme.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt_off, size: 48, color: Colors.grey),
              const SizedBox(height: AppTheme.spacingMd),
              const Text('No expenses match the current filter.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: AppTheme.spacingMd),
              OutlinedButton(
                onPressed: () {
                  widget.controller.filterByCategory(null);
                  widget.controller.setDateRange(ExpenseDateRange.all);
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: AppTheme.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: AppTheme.spacingMd),
            const Text('No expenses recorded.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: AppTheme.spacingMd),
            FilledButton.icon(
              onPressed: () => _createExpense(context),
              icon: const Icon(Icons.add),
              label: const Text('Record Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createExpense(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseCreateScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _deleteExpense(
      BuildContext context, Expense expense) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete Expense',
      content:
          'Delete ${expense.category.label} of ${expense.amount.toStringAsFixed(0)} MMK?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true) {
      await widget.controller.deleteExpense(expense.id!);
    }
  }
}

// ── Date range filter bar ──────────────────────────────────────────────────
class _DateRangeFilterBar extends StatelessWidget {
  const _DateRangeFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final ExpenseDateRange selected;
  final ValueChanged<ExpenseDateRange> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final range in ExpenseDateRange.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(range.label, style: const TextStyle(fontSize: 12)),
                    selected: selected == range,
                    onSelected: (_) => onChanged(range),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
      );
}

// ── Category filter bar ────────────────────────────────────────────────────
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.totals,
    required this.onChanged,
  });

  final ExpenseCategory? selected;
  final Map<ExpenseCategory, double> totals;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _filterChip(context, null, 'All',
                totals.values.fold(0.0, (a, b) => a + b)),
            for (final cat in ExpenseCategory.values)
              _filterChip(context, cat, cat.label, totals[cat] ?? 0),
          ],
        ),
      );

  Widget _filterChip(BuildContext context, ExpenseCategory? cat, String label,
      double total) {
    final isSelected = selected == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(total.toStringAsFixed(0),
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onChanged(cat),
      ),
    );
  }
}

// ── Total bar ──────────────────────────────────────────────────────────────
class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            const Icon(Icons.attach_money, size: 18),
            const SizedBox(width: 8),
            Text(
              'Total: ${total.toStringAsFixed(0)} MMK',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            Text('$count items',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
}

// ── Group total card ───────────────────────────────────────────────────────
class _GroupTotalCard extends StatelessWidget {
  const _GroupTotalCard({
    required this.group,
    required this.total,
    required this.categories,
    required this.categoryTotals,
    required this.onCategoryTap,
  });

  final ExpenseGroup group;
  final double total;
  final List<ExpenseCategory> categories;
  final Map<ExpenseCategory, double> categoryTotals;
  final ValueChanged<ExpenseCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_groupIcon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.label,
                    style: AppTheme.cardTitleStyle(context)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} MMK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final cat in categories) ...[
              if ((categoryTotals[cat] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () => onCategoryTap(cat),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(cat.label,
                              style: AppTheme.dataValueStyle(context)),
                        ),
                        Text(
                          '${(categoryTotals[cat] ?? 0).toStringAsFixed(0)} MMK',
                          style: AppTheme.dataValueStyle(context),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _groupIcon {
    switch (group) {
      case ExpenseGroup.staff:
        return Icons.people_outline;
      case ExpenseGroup.vehicle:
        return Icons.directions_bus_outlined;
      case ExpenseGroup.office:
        return Icons.business;
      case ExpenseGroup.admin:
        return Icons.account_balance;
      case ExpenseGroup.other:
        return Icons.more_horiz;
    }
  }
}

// ── Expense card ────────────────────────────────────────────────────────────
class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onDelete});

  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(_categoryIcon(expense.category), size: 20, color: cs.primary),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category.label,
                    style: AppTheme.cardTitleStyle(context),
                  ),
                  if (expense.description != null &&
                      expense.description!.isNotEmpty)
                    Text(expense.description!,
                        style: AppTheme.sectionSubtitleStyle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Text(
                    '${expense.expenseDate.year}-'
                    '${expense.expenseDate.month.toString().padLeft(2, '0')}-'
                    '${expense.expenseDate.day.toString().padLeft(2, '0')}'
                    '${expense.paidTo != null ? ' • ${expense.paidTo}' : ''}'
                    '${expense.vehicleId != null ? ' • 🚌 ${expense.vehicleId}' : ''}'
                    '${expense.tripId != null ? ' • 🎫 ${expense.tripId}' : ''}',
                    style: AppTheme.sectionSubtitleStyle(context),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  expense.amount.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: expense.amount > 100000 ? cs.error : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline,
                      size: 18, color: cs.error.withAlpha(160)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.driverSalary:
      case ExpenseCategory.spareSalary:
      case ExpenseCategory.counterSalary:
        return Icons.people_outline;
      case ExpenseCategory.fuel:
        return Icons.local_gas_station;
      case ExpenseCategory.vehicleRepair:
        return Icons.build_outlined;
      case ExpenseCategory.tires:
        return Icons.radar;
      case ExpenseCategory.officeRent:
      case ExpenseCategory.electricity:
      case ExpenseCategory.internet:
        return Icons.business;
      case ExpenseCategory.municipalTax:
        return Icons.account_balance;
      case ExpenseCategory.insurance:
        return Icons.verified;
      case ExpenseCategory.parking:
        return Icons.local_parking;
      case ExpenseCategory.toll:
        return Icons.toll;
      case ExpenseCategory.cleaning:
        return Icons.cleaning_services;
      case ExpenseCategory.miscellaneous:
        return Icons.more_horiz;
    }
  }
}
