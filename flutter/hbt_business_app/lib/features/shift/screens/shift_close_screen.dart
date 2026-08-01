import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/error_states.dart';
import '../../../core/widgets/loading.dart';
import '../../../shared/models/cash_models.dart';
import '../../finance/screens/cash_report_screen.dart';
import '../controllers/cash_reconciliation_controller.dart';
import '../controllers/shift_controller.dart';

/// Screen shown when closing an active shift.
///
/// Performs full cash reconciliation:
/// 1. Loads cash breakdown from server (cash sales, refunds, expenses)
/// 2. Calculates expected cash: opening + cash_sales - cash_refunds - cash_expenses
/// 3. Staff enters actual cash counted
/// 4. Difference is computed and displayed
/// 5. Discrepancy > threshold requires explanation
/// 6. On close, report is generated and linked to owner/daily reports
class ShiftCloseScreen extends StatefulWidget {
  const ShiftCloseScreen({super.key, required this.controller});

  final ShiftController controller;

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  final _closingCashCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitted = false;

  CashReconciliationController? _cashCtrl;
  ShiftCashData? _cashData;
  bool _cashLoading = true;
  String? _cashError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _loadCashData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _cashCtrl?.removeListener(_onChanged);
    _cashCtrl?.dispose();
    _closingCashCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCashData() async {
    final shift = widget.controller.activeShift;
    if (shift?.id == null) return;

    _cashLoading = true;
    _cashError = null;
    if (mounted) setState(() {});

    _cashCtrl = CashReconciliationController(
      api: widget.controller.api,
      organizationId: widget.controller.organizationId,
    );
    _cashCtrl!.addListener(_onChanged);

    _cashData = await _cashCtrl!.loadShiftCashData(shift!);
    if (_cashData == null) {
      _cashError = _cashCtrl!.error ?? 'Failed to load cash breakdown.';
    }
    _cashLoading = false;
    if (mounted) setState(() {});
  }

  /// Expected cash = Opening cash + Cash sales - Cash refunds - Cash expenses
  double get _expectedCash {
    if (_cashData != null) return _cashData!.expectedCash;
    final shift = widget.controller.activeShift;
    if (shift == null) return 0;
    // Fallback: opening + total revenue (less accurate but safe)
    return shift.openingCash + shift.totalRevenue;
  }

  double? get _difference {
    final entered = double.tryParse(_closingCashCtrl.text.trim());
    if (entered == null) return null;
    return entered - _expectedCash;
  }

  Future<void> _confirmClose() async {
    final cash = double.tryParse(_closingCashCtrl.text.trim());
    if (cash == null) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Close Shift?',
      content: _buildSummaryText(cash),
      confirmLabel: 'Close Shift',
      destructive: false,
    );
    if (confirmed != true) return;

    await widget.controller.closeShift(
      closingCash: cash,
      differenceReason: _reasonCtrl.text.trim(),
    );
    if (mounted && widget.controller.activeShift?.status.name == 'closed') {
      setState(() => _submitted = true);
    }
  }

  String _buildSummaryText(double closingCash) {
    final shift = widget.controller.activeShift!;
    final diff = closingCash - _expectedCash;
    return [
      '── Shift Info ──',
      'Duration: ${widget.controller.elapsedFormatted}',
      '',
      '── Cash Breakdown ──',
      'Opening: ${shift.openingCash.toStringAsFixed(0)} MMK',
      'Cash Sales: ${_cashData?.totalCashIn.toStringAsFixed(0) ?? "?"} MMK',
      'Cash Refunds: ${(_cashData?.cashRefundsPaid ?? 0).toStringAsFixed(0)} MMK',
      'Cash Expenses: ${(_cashData?.cashExpenses ?? 0).toStringAsFixed(0)} MMK',
      '',
      'Expected Cash: ${_expectedCash.toStringAsFixed(0)} MMK',
      'Closing Cash: ${closingCash.toStringAsFixed(0)} MMK',
      'Difference: ${diff.toStringAsFixed(0)} MMK'
          ' ${diff >= 0 ? '(over)' : '(short)'}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final shift = ctrl.activeShift;
    if (shift == null) return const SizedBox.shrink();

    if (_submitted) return _buildSuccess();

    return Scaffold(
      appBar: AppBar(title: const Text('Close Shift')),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_cashLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: InlineLoading(),
              )
            else ...[
              _buildPLSummary(context, shift, ctrl),
              const SizedBox(height: AppTheme.spacingXl),
              _buildCashBreakdown(context, shift),
              const SizedBox(height: AppTheme.spacingXl),
              _buildCashReconciliation(context, shift),
              const SizedBox(height: AppTheme.spacingXxl),
              _buildAction(context, ctrl),
            ],
          ],
        ),
      ),
    );
  }

  // ── P&L Summary section ─────────────────────────────────────────────
  Widget _buildPLSummary(
      BuildContext context, dynamic shift, ShiftController ctrl) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue',
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _row('Ticket Sales',
                shift.ticketRevenue, Colors.blue, context),
            _row('Cargo Revenue',
                shift.cargoRevenue, Colors.indigo, context),
            const Divider(height: 12),
            _totalRow('Total Revenue', shift.totalRevenue, context),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Expenses',
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _row('Total Expenses',
                shift.expenseTotal, cs.error, context),
            const Divider(height: 12),
            _totalRow('Net Revenue',
                shift.netRevenue, context,
                color: shift.netRevenue >= 0 ? Colors.green : cs.error),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount, Color indicator,
      BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 20,
              color: indicator,
              margin: const EdgeInsets.only(right: 8)),
          Expanded(
              child: Text(label,
                  style: AppTheme.dataValueStyle(context))),
          Text('${amount.toStringAsFixed(0)} MMK',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, BuildContext context,
      {Color? color}) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Text('${amount.toStringAsFixed(0)} MMK',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ── Cash Breakdown section ──────────────────────────────────────────
  Widget _buildCashBreakdown(BuildContext context, dynamic shift) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash Breakdown',
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _row('Opening Cash', shift.openingCash,
                Colors.teal, context),
            _row('Cash Sales (Tickets + Cargo)',
                _cashData?.totalCashIn ?? 0, Colors.green, context),
            _row('Cash Refunds Paid',
                _cashData?.cashRefundsPaid ?? 0, Colors.red, context),
            _row('Cash Expenses Paid',
                _cashData?.cashExpenses ?? 0, cs.error, context),
            const Divider(height: 12),
            _totalRow('Expected Cash', _expectedCash, context,
                color: Colors.teal[700]),
          ],
        ),
      ),
    );
  }

  // ── Cash Reconciliation section ─────────────────────────────────────
  Widget _buildCashReconciliation(
      BuildContext context, dynamic shift) {
    // Pre-fill with expected cash if user hasn't typed
    if (_closingCashCtrl.text.trim().isEmpty && _cashData != null) {
      // Don't auto-fill — always require manual entry
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Count Actual Cash',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Enter the total cash counted in your drawer.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        FormTextField(
          label: 'Actual Cash in Drawer (MMK)',
          controller: _closingCashCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.monetization_on_outlined),
          onChanged: (_) => setState(() {}),
        ),

        // Live difference display
        if (_difference != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Card(
            color: _difference!.abs() > 1000
                ? Theme.of(context).colorScheme.errorContainer
                : Colors.green[50],
            child: Padding(
              padding: AppTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _difference!.abs() > 1000
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: _difference!.abs() > 1000
                            ? Theme.of(context).colorScheme.error
                            : Colors.green,
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          'Difference: ${_difference!.toStringAsFixed(0)} MMK'
                          ' (${_difference! >= 0 ? "Over" : "Short"})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _difference!.abs() > 1000
                                ? Theme.of(context).colorScheme.error
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expected: ${_expectedCash.toStringAsFixed(0)} MMK',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Reason for difference (required when |diff| > 1000)
        if (_difference != null && _difference!.abs() > 1000) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'A reason is required for differences over 1,000 MMK.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          FormTextField(
            label: 'Reason for difference',
            controller: _reasonCtrl,
            maxLines: 3,
            hintText: 'Explain why the cash count differs from expected…',
          ),
        ],
      ],
    );
  }

  // ── Action button ───────────────────────────────────────────────────
  Widget _buildAction(BuildContext context, ShiftController ctrl) {
    // Validate: must enter cash amount AND reason if diff > 1000
    final cash = double.tryParse(_closingCashCtrl.text.trim());
    final cashEntered = cash != null && cash >= 0;
    final reasonEntered = _reasonCtrl.text.trim().isNotEmpty ||
        _difference == null ||
        _difference!.abs() <= 1000;
    final canClose = cashEntered && reasonEntered;

    return Column(
      children: [
        if (_cashError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: ErrorCard(message: _cashError!),
          ),
        if (ctrl.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: ErrorCard(message: ctrl.error!),
          ),
        if (!cashEntered && _closingCashCtrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Text(
              'Closing cash must be a valid positive number.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        BusyButton(
          label: 'Complete Reconciliation & Close Shift',
          icon: const Icon(Icons.check_circle),
          onPressed: canClose ? _confirmClose : null,
          busy: ctrl.closing,
        ),
      ],
    );
  }

  // ── Success view ────────────────────────────────────────────────────
  Widget _buildSuccess() {
    final shift = widget.controller.activeShift!;
    final diff = shift.cashDifference;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Closed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: AppTheme.pagePadding,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 48,
                      color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Text('Reconciliation Complete',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spacingMd),

                // Cash summary
                Card(
                  child: Padding(
                    padding: AppTheme.cardPadding,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Cash Summary',
                            style: AppTheme.cardTitleStyle(context)
                                .copyWith(
                                    fontWeight: FontWeight.bold)),
                        const Divider(height: 16),
                        _finalRow('Opening Cash',
                            '${shift.openingCash.toStringAsFixed(0)} MMK'),
                        _finalRow('Cash Sales (In)',
                            '${(_cashData?.totalCashIn ?? 0).toStringAsFixed(0)} MMK'),
                        _finalRow('Cash Refunds (Out)',
                            '${(_cashData?.cashRefundsPaid ?? 0).toStringAsFixed(0)} MMK'),
                        _finalRow('Cash Expenses (Out)',
                            '${(_cashData?.cashExpenses ?? 0).toStringAsFixed(0)} MMK'),
                        const Divider(),
                        _finalRow('Expected Cash',
                            '${_expectedCash.toStringAsFixed(0)} MMK'),
                        _finalRow('Actual Cash Counted',
                            '${(shift.closingCash ?? 0).toStringAsFixed(0)} MMK'),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: diff != null && diff.abs() > 1000
                                ? Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                diff != null && diff.abs() > 1000
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle,
                                size: 20,
                                color: diff != null &&
                                        diff.abs() > 1000
                                    ? Theme.of(context)
                                        .colorScheme
                                        .error
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Difference: ${(diff ?? 0).toStringAsFixed(0)} MMK'
                                ' ${diff != null && diff >= 0 ? "(over)" : "(short)"}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: diff != null &&
                                          diff.abs() > 1000
                                      ? Theme.of(context)
                                          .colorScheme
                                          .error
                                      : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Revenue summary
                Card(
                  child: Padding(
                    padding: AppTheme.cardPadding,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Revenue Summary',
                            style: AppTheme.cardTitleStyle(context)
                                .copyWith(
                                    fontWeight: FontWeight.bold)),
                        const Divider(height: 16),
                        _finalRow('Ticket Revenue',
                            '${shift.ticketRevenue.toStringAsFixed(0)} MMK'),
                        _finalRow('Cargo Revenue',
                            '${shift.cargoRevenue.toStringAsFixed(0)} MMK'),
                        _finalRow('Expenses',
                            '${shift.expenseTotal.toStringAsFixed(0)} MMK'),
                        const Divider(),
                        _finalRow('Net Revenue',
                            '${shift.netRevenue.toStringAsFixed(0)} MMK'),
                        const SizedBox(height: 8),
                        _finalRow('Tickets Sold',
                            '${shift.ticketSalesCount}'),
                        _finalRow('Cargo Accepted',
                            '${shift.cargoCount}'),
                        _finalRow('Expenses Recorded',
                            '${shift.expenseCount}'),
                        _finalRow('Refunds',
                            '${shift.refundCount}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Actions
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => CashReportScreen(
                          api: widget.controller.api,
                          organizationId:
                              widget.controller.organizationId,
                          initialShiftId: shift.id,
                        ),
                      )),
                      icon: const Icon(Icons.receipt_long,
                          size: 18),
                      label: const Text('Report'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _finalRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13))),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
}
