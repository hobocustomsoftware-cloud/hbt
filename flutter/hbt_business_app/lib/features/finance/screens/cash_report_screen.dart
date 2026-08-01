import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_views.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/models/cash_models.dart';
import '../../shift/controllers/cash_reconciliation_controller.dart';

/// Cash reconciliation report screen.
///
/// Shows:
/// - Shift-level cash breakdown
/// - Owner report (per-counter per-user for date range)
/// - Daily report (aggregated across all counters)
class CashReportScreen extends StatefulWidget {
  const CashReportScreen({
    super.key,
    required this.api,
    required this.organizationId,
    this.initialShiftId,
    this.initialTab = 0,
  });

  final ApiClient api;
  final String organizationId;
  final String? initialShiftId;
  final int initialTab;

  @override
  State<CashReportScreen> createState() => _CashReportScreenState();
}

class _CashReportScreenState extends State<CashReportScreen>
    with SingleTickerProviderStateMixin {
  late final CashReconciliationController _ctrl;
  late final TabController _tabCtrl;

  List<ShiftCashReport> _ownerReports = [];
  DailyCashSummary? _dailySummary;
  bool _loading = true;
  String _startDate = '';
  String _endDate = '';

  @override
  void initState() {
    super.initState();
    _ctrl = CashReconciliationController(
      api: widget.api,
      organizationId: widget.organizationId,
    );
    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _ctrl.addListener(_onChanged);
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final now = DateTime.now();
    _startDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _endDate = _startDate;

    // Load all tabs in parallel
    await Future.wait([
      _loadShiftReport(),
      _loadOwnerReport(),
      _loadDailyReport(),
    ]);

    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _loadShiftReport() async {
    if (widget.initialShiftId == null) return;
    // Re-fetch the shift report
  }

  Future<void> _loadOwnerReport() async {
    _ownerReports = await _ctrl.loadOwnerReport(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _loadDailyReport() async {
    _dailySummary = await _ctrl.loadDailyReport(_startDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Reports'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Shift'),
            Tab(text: 'Owner'),
            Tab(text: 'Daily'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingView()
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildShiftTab(context),
                _buildOwnerTab(context),
                _buildDailyTab(context),
              ],
            ),
    );
  }

  // ── Shift tab ───────────────────────────────────────────────────────
  Widget _buildShiftTab(BuildContext context) {
    if (widget.initialShiftId == null) {
      return const Center(
        child: Text('Select a closed shift to view its report.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _ctrl.loading
          ? const LoadingView()
          : _ctrl.shiftReport != null
              ? _buildShiftReport(context, _ctrl.shiftReport!)
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_ctrl.error != null)
                        ErrorCard(message: _ctrl.error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildShiftReport(BuildContext context, ShiftCashReport report) {
    return ListView(
      padding: AppTheme.pagePadding,
      children: [
        _section(context, 'Shift Info', [
          _infoRow('Counter', report.counterName ?? '-'),
          _infoRow('Staff', report.staffName ?? '-'),
          _infoRow('Opened', report.openedAt ?? '-'),
          _infoRow('Closed', report.closedAt ?? '-'),
        ]),
        const SizedBox(height: AppTheme.spacingMd),
        _section(context, 'Cash Breakdown', [
          _cashRow('Opening Cash', report.cashData.openingCash),
          _cashRow('Cash Sales (In)', report.cashData.totalCashIn),
          _cashRow('Cash Refunds (Out)', -report.cashData.cashRefundsPaid),
          _cashRow('Cash Expenses (Out)', -report.cashData.cashExpenses),
          const Divider(),
          _cashRow('Expected Cash', report.cashData.expectedCash,
              bold: true),
          _cashRow(
            'Actual Cash Counted',
            report.cashData.actualCash ?? 0,
            bold: true,
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: report.cashData.difference != null &&
                      report.cashData.difference!.abs() > 1000
                  ? Theme.of(context).colorScheme.errorContainer
                  : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  report.cashData.difference != null &&
                          report.cashData.difference!.abs() > 1000
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: report.cashData.difference != null &&
                          report.cashData.difference!.abs() > 1000
                      ? Theme.of(context).colorScheme.error
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Difference: ${(report.cashData.difference ?? 0).toStringAsFixed(0)} MMK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: report.cashData.difference != null &&
                            report.cashData.difference!.abs() > 1000
                        ? Theme.of(context).colorScheme.error
                        : Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          if (report.differenceReason != null &&
              report.differenceReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Reason: ${report.differenceReason}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ]),
        const SizedBox(height: AppTheme.spacingMd),
        _section(context, 'Activity', [
          _infoRow('Tickets Sold', '${report.ticketCount}'),
          _infoRow('Cargo Accepted', '${report.cargoCount}'),
          _infoRow('Refunds', '${report.refundCount}'),
          _infoRow('Expenses', '${report.expenseCount}'),
        ]),
      ],
    );
  }

  // ── Owner tab ───────────────────────────────────────────────────────
  Widget _buildOwnerTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadOwnerReport,
      child: _ctrl.loading
          ? const LoadingView()
          : _ownerReports.isEmpty
              ? ListView(
                  children: [
                    const EmptyView(
                      icon: Icons.inbox,
                      message: 'No shifts found for today.',
                    ),
                  ],
                )
              : ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    Text(
                      'Owner Report — $_startDate',
                      style: AppTheme.sectionHeaderStyle(context),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '${_ownerReports.length} shift(s)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    ..._ownerReports.map(
                      (r) => _ownerReportCard(context, r),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildOwnerSummary(context),
                  ],
                ),
    );
  }

  Widget _ownerReportCard(BuildContext context, ShiftCashReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  report.staffName ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: report.cashData.difference != null &&
                            report.cashData.difference!.abs() > 1000
                        ? Theme.of(context).colorScheme.errorContainer
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.cashData.difference != null
                        ? '${report.cashData.difference!.toStringAsFixed(0)} MMK'
                        : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: report.cashData.difference != null &&
                              report.cashData.difference!.abs() > 1000
                          ? Theme.of(context).colorScheme.error
                          : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${report.counterName ?? report.shiftId}'
              ' • ${report.openedAt ?? "-"} → ${report.closedAt ?? "-"}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniMetric('Sales',
                    report.cashData.totalCashIn.toStringAsFixed(0)),
                _miniMetric('Expenses',
                    report.cashData.cashExpenses.toStringAsFixed(0)),
                _miniMetric('Expected',
                    report.cashData.expectedCash.toStringAsFixed(0)),
                _miniMetric('Tickets', '${report.ticketCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildOwnerSummary(BuildContext context) {
    final totalExpected =
        _ownerReports.fold(0.0, (s, r) => s + r.cashData.expectedCash);
    final totalActual = _ownerReports.fold(
        0.0, (s, r) => s + (r.cashData.actualCash ?? 0));
    final totalDiff = _ownerReports.fold(
        0.0, (s, r) => s + (r.cashData.difference ?? 0));
    final overCount =
        _ownerReports.where((r) => (r.cashData.difference ?? 0) > 0).length;
    final shortCount =
        _ownerReports.where((r) => (r.cashData.difference ?? 0) < 0).length;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(120),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary',
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _infoRow('Total Expected', CashReconciliationController.fmt(totalExpected)),
            _infoRow('Total Actual', CashReconciliationController.fmt(totalActual)),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: totalDiff.abs() > 1000
                    ? Theme.of(context).colorScheme.errorContainer
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Total Difference: ${totalDiff.toStringAsFixed(0)} MMK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: totalDiff.abs() > 1000
                          ? Theme.of(context).colorScheme.error
                          : Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _infoRow('Over Count', '$overCount'),
            _infoRow('Short Count', '$shortCount'),
          ],
        ),
      ),
    );
  }

  // ── Daily tab ───────────────────────────────────────────────────────
  Widget _buildDailyTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDailyReport,
      child: _ctrl.loading
          ? const LoadingView()
          : _dailySummary == null
              ? ListView(
                  children: [
                    if (_ctrl.error != null)
                      ErrorCard(message: _ctrl.error!),
                    const EmptyView(
                      icon: Icons.inbox,
                      message: 'No daily summary available.',
                    ),
                  ],
                )
              : ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    Text(
                      'Daily Report — $_startDate',
                      style: AppTheme.sectionHeaderStyle(context),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _dailySummaryCard(context, _dailySummary!),
                    const SizedBox(height: AppTheme.spacingMd),
                    _dailyActivityCard(context, _dailySummary!),
                  ],
                ),
    );
  }

  Widget _dailySummaryCard(BuildContext context, DailyCashSummary summary) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash Summary',
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _infoRow('Shifts Today', '${summary.shiftCount}'),
            _infoRow(
                'Total Opening Cash',
                CashReconciliationController.fmt(summary.totalOpeningCash)),
            _infoRow(
                'Total Cash Sales',
                CashReconciliationController.fmt(summary.totalCashSales)),
            _infoRow(
                'Total Cash Refunds',
                CashReconciliationController.fmt(summary.totalCashRefunds)),
            _infoRow(
                'Total Cash Expenses',
                CashReconciliationController.fmt(summary.totalCashExpenses)),
            const Divider(),
            _infoRow(
                'Total Expected Cash',
                CashReconciliationController.fmt(summary.totalExpectedCash)),
            _infoRow(
                'Total Actual Cash',
                CashReconciliationController.fmt(summary.totalActualCash)),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: summary.totalDifference.abs() > 1000
                    ? Theme.of(context).colorScheme.errorContainer
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        summary.totalDifference.abs() > 1000
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: summary.totalDifference.abs() > 1000
                            ? Theme.of(context).colorScheme.error
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Difference: '
                        '${summary.totalDifference.toStringAsFixed(0)} MMK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: summary.totalDifference.abs() > 1000
                              ? Theme.of(context).colorScheme.error
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalOverCount} over  •  ${summary.totalShortCount} short',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyActivityCard(BuildContext context, DailyCashSummary summary) {
    // For daily activity drill-down, show the owner report shifts
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity',
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            if (_ownerReports.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No shift data available.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._ownerReports.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${r.staffName ?? "?"} @ ${r.counterName ?? "?"}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        CashReconciliationController.fmt(
                            r.cashData.expectedCash),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  Widget _section(
      BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTheme.cardTitleStyle(context)
                    .copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );

  Widget _cashRow(String label, double amount, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  )),
            ),
            Text(
              '${amount.abs().toStringAsFixed(0)} MMK'
              '${amount < 0 ? " (out)" : ""}',
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: amount < 0
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ],
        ),
      );
}
