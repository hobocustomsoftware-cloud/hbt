import 'package:flutter/material.dart';

import '../../core/theme/hbt_tokens.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/hbt_activity_feed.dart';
import '../../core/widgets/hbt_alert_banner.dart';
import '../../core/widgets/hbt_kpi_card.dart';
import '../../core/widgets/hbt_quick_action_tile.dart';
import '../../core/widgets/hbt_ranking_panel.dart';
import '../../core/widgets/hbt_responsive.dart';
import '../../core/widgets/hbt_revenue_trend_chart.dart';
import '../../core/widgets/hbt_time_range_selector.dart';
import '../auth/controllers/session_controller.dart';
import '../cargo/screens/cargo_worklist_page.dart';
import '../refund/screens/refund_list_page.dart';
import '../routes/screens/route_list_page.dart';
import '../ticket_sales/screens/counter_booking_page.dart';
import '../ticket_sales/screens/ticket_scanner_screen.dart';
import '../trip/screens/trip_list_page.dart';
import 'dashboard_controller.dart';
import 'dashboard_models.dart';

/// Owner dashboard screen — production home tab.
///
/// Renders the real backend snapshot (via [DashboardController]) into
/// design-system widgets. Sections without backend data are omitted, not
/// faked; future zones can be added without changing this structure.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.controller,
    required this.session,
  });

  final DashboardController controller;
  final SessionController session;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  DashboardController get controller => widget.controller;
  SessionController get session => widget.session;

  @override
  void initState() {
    super.initState();
    controller.organizationId =
        session.activeOrganization?.organization.id ?? '';
    controller.addListener(_onControllerChanged);
    if (!controller.hasData && controller.error == null) {
      controller.load();
    }
  }

  @override
  void didUpdateWidget(OwnerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final orgId = session.activeOrganization?.organization.id ?? '';
    if (orgId != controller.organizationId) {
      controller.organizationId = orgId;
      controller.load();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    if (controller.loading && snapshot == null) {
      return const _DashboardSkeleton();
    }
    if (snapshot == null) {
      return ErrorView(
        message: controller.error ?? 'Unable to load dashboard.',
        onRetry: controller.load,
      );
    }
    return _DashboardBody(
      controller: controller,
      snapshot: snapshot,
      session: session,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.controller,
    required this.snapshot,
    required this.session,
  });

  final DashboardController controller;
  final DashboardSnapshot snapshot;
  final SessionController session;

  static const _periods = [
    DashboardPeriodSegment(value: 'day', label: 'Day'),
    DashboardPeriodSegment(value: 'week', label: 'Week'),
    DashboardPeriodSegment(value: 'month', label: 'Month'),
    DashboardPeriodSegment(value: 'year', label: 'Year'),
  ];

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: r.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Header: period + refresh ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dashboard · ${_dateLabel(snapshot.date)}',
                  style: HbtTypography.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              HbtTimeRangeSelector(
                periods: _periods,
                selected: controller.period.apiValue,
                onChanged: (value) => controller.setPeriod(
                  DashboardPeriod.fromApi(value),
                ),
              ),
              const SizedBox(width: HbtSpacing.sm),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.loading ? null : controller.refresh,
                icon: controller.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone A: Money ────────────────────────────────────────
          HbtKpiGrid(
            children: [
              HbtKpiCard(
                label: 'Ticket Revenue',
                value: _money(snapshot.money.ticketRevenue),
                icon: Icons.confirmation_number_outlined,
                onTap: () => _openTrips(context, session),
              ),
              HbtKpiCard(
                label: 'Cargo Revenue',
                value: _money(snapshot.money.cargoRevenue),
                icon: Icons.inventory_2_outlined,
                onTap: () => _openCargo(context, session),
              ),
              HbtKpiCard(
                label: 'Total Revenue',
                value: _money(snapshot.money.totalRevenue),
                icon: Icons.payments_outlined,
                onTap: () => _openTrips(context, session),
              ),
              HbtKpiCard(
                label: 'Confirmed Payments',
                value: '${snapshot.money.confirmedPayments.length}',
                icon: Icons.account_balance_wallet_outlined,
                subtitle: snapshot.money.confirmedPayments.isEmpty
                    ? null
                    : snapshot.money.confirmedPayments
                        .map((p) => '${p.method}: ${_money(p.amount)}')
                        .join(' · '),
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone B: Trip operations ──────────────────────────────
          _SectionTitle('Trip Operations'),
          const SizedBox(height: HbtSpacing.sm),
          HbtKpiGrid(
            children: [
              HbtKpiCard(
                label: 'Running',
                value: '${snapshot.tripOps.running}',
                icon: Icons.directions_bus_outlined,
                compact: true,
              ),
              HbtKpiCard(
                label: 'Delayed',
                value: '${snapshot.tripOps.delayed}',
                icon: Icons.schedule,
                compact: true,
                tone: snapshot.tripOps.delayed > 0
                    ? KpiTone.warning
                    : KpiTone.normal,
              ),
              HbtKpiCard(
                label: 'Cancelled',
                value: '${snapshot.tripOps.cancelled}',
                icon: Icons.cancel_outlined,
                compact: true,
                tone: snapshot.tripOps.cancelled > 0
                    ? KpiTone.danger
                    : KpiTone.normal,
              ),
              HbtKpiCard(
                label: 'Completed',
                value: '${snapshot.tripOps.completed}',
                icon: Icons.flag_outlined,
                compact: true,
              ),
              HbtKpiCard(
                label: 'Passengers',
                value: '${snapshot.tripOps.passengers}',
                icon: Icons.people_outline,
                compact: true,
              ),
              HbtKpiCard(
                label: 'On-Time',
                value: snapshot.tripOps.onTimePercent == null
                    ? '—'
                    : '${snapshot.tripOps.onTimePercent!.toStringAsFixed(0)}%',
                icon: Icons.timer_outlined,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone C: Cargo + Bookings ─────────────────────────────
          HbtKpiGrid(
            children: [
              HbtKpiCard(
                label: 'Cargo Accepted',
                value: '${snapshot.cargoOps.accepted}',
                icon: Icons.inventory_2_outlined,
                onTap: () => _openCargo(context, session),
              ),
              HbtKpiCard(
                label: 'Cargo In Transit',
                value: '${snapshot.cargoOps.inTransit}',
                icon: Icons.local_shipping_outlined,
              ),
              HbtKpiCard(
                label: 'Cargo Exceptions',
                value: '${snapshot.cargoOps.exceptions}',
                icon: Icons.report_problem_outlined,
                tone: snapshot.cargoOps.exceptions > 0
                    ? KpiTone.danger
                    : KpiTone.normal,
              ),
              HbtKpiCard(
                label: 'Bookings',
                value: '${snapshot.bookings.total}',
                icon: Icons.event_seat_outlined,
                subtitle:
                    '${snapshot.bookings.confirmed} confirmed · '
                    '${snapshot.bookings.expired} expired',
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone D: Cash & pending ───────────────────────────────
          _SectionTitle('Cash & Pending'),
          const SizedBox(height: HbtSpacing.sm),
          HbtKpiGrid(
            children: [
              HbtKpiCard(
                label: 'Cash in Counters',
                value: _money(snapshot.cashPending.cashInCounters),
                icon: Icons.payments_outlined,
              ),
              HbtKpiCard(
                label: 'Pending Refunds',
                value: '${snapshot.cashPending.pendingRefunds.count}',
                icon: Icons.replay_outlined,
                subtitle: _money(snapshot.cashPending.pendingRefunds.amount),
                tone: snapshot.cashPending.pendingRefunds.count > 0
                    ? KpiTone.warning
                    : KpiTone.normal,
                onTap: session.hasPermission('refund.view')
                    ? () => _openRefunds(context, session)
                    : null,
              ),
              HbtKpiCard(
                label: 'Pending Approvals',
                value: '${snapshot.cashPending.pendingApprovals}',
                icon: Icons.fact_check_outlined,
                tone: snapshot.cashPending.pendingApprovals > 0
                    ? KpiTone.warning
                    : KpiTone.normal,
                onTap: session.hasPermission('refund.view')
                    ? () => _openRefunds(context, session)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone E: Fleet & people ───────────────────────────────
          _SectionTitle('Fleet & People'),
          const SizedBox(height: HbtSpacing.sm),
          HbtKpiGrid(
            children: [
              HbtKpiCard(
                label: 'Vehicles Running',
                value:
                    '${snapshot.fleetPeople.vehiclesRunning.count}/'
                    '${snapshot.fleetPeople.vehiclesRunning.total}',
                icon: Icons.directions_bus_filled_outlined,
              ),
              HbtKpiCard(
                label: 'Vehicles Maintenance',
                value: '${snapshot.fleetPeople.vehiclesMaintenance}',
                icon: Icons.build_outlined,
                tone: snapshot.fleetPeople.vehiclesMaintenance > 0
                    ? KpiTone.warning
                    : KpiTone.normal,
              ),
              HbtKpiCard(
                label: 'Drivers On Duty',
                value:
                    '${snapshot.fleetPeople.driverAttendance.onDuty}/'
                    '${snapshot.fleetPeople.driverAttendance.total}',
                icon: Icons.badge_outlined,
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone F: Revenue trend ────────────────────────────────
          HbtRevenueTrendChart(
            title: 'Revenue Trend',
            points: [
              for (final p in snapshot.revenueTrend)
                TrendPointView(label: p.label, total: p.total),
            ],
            onDrill: () => _openTrips(context, session),
            drillLabel: 'View trips',
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone G: Rankings ─────────────────────────────────────
          HbtResponsiveGridWrap(
            children: [
              HbtRankingPanel(
                title: 'Top Routes',
                icon: Icons.route_outlined,
                rows: [
                  for (final row in snapshot.rankings.routes)
                    HbtRankingRow(
                      name: row.name,
                      value: _money(row.revenue),
                      secondary: '${row.trips} trips',
                    ),
                ],
              ),
              HbtRankingPanel(
                title: 'Top Vehicles',
                icon: Icons.directions_bus_outlined,
                rows: [
                  for (final row in snapshot.rankings.vehicles)
                    HbtRankingRow(
                      name: row.name,
                      value: _money(row.revenue),
                      secondary: '${row.trips} trips',
                    ),
                ],
              ),
              HbtRankingPanel(
                title: 'Branch Performance',
                icon: Icons.store_outlined,
                rows: [
                  for (final row in snapshot.rankings.branches)
                    HbtRankingRow(
                      name: row.name,
                      value: _money(row.revenue),
                      secondary: '${row.trips} trips',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone H: Pulse — alerts ───────────────────────────────
          if (snapshot.pulse.alerts.isNotEmpty) ...[
            _SectionTitle('Alerts'),
            const SizedBox(height: HbtSpacing.sm),
            for (final alert in snapshot.pulse.alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: HbtSpacing.sm),
                child: HbtAlertBanner(
                  message: alert.message,
                  severity: switch (alert.severity) {
                    'danger' => HbtAlertSeverity.danger,
                    'warning' => HbtAlertSeverity.warning,
                    _ => HbtAlertSeverity.info,
                  },
                ),
              ),
            const SizedBox(height: HbtSpacing.sm),
          ],

          // ── Zone I: Pulse — activity + announcements ─────────────
          HbtResponsiveGridWrap(
            children: [
              HbtActivityFeed(
                title: 'Recent Activity',
                entries: [
                  for (final a in snapshot.pulse.activities)
                    HbtActivityEntry(
                      icon: _activityIcon(a.resourceType),
                      text: _activityText(a),
                      time: _timeAgo(a.occurredAt),
                    ),
                ],
              ),
              if (snapshot.pulse.announcements.isNotEmpty)
                HbtActivityFeed(
                  title: 'Announcements',
                  entries: [
                    for (final a in snapshot.pulse.announcements)
                      HbtActivityEntry(
                        icon: Icons.campaign_outlined,
                        text: '${a.title}\n${a.body}',
                        time: _timeAgo(a.createdAt),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: HbtSpacing.lg),

          // ── Zone J: Quick actions ────────────────────────────────
          _SectionTitle('Quick Actions'),
          const SizedBox(height: HbtSpacing.sm),
          HbtResponsiveGridWrap(
            children: [
              HbtQuickActionTile(
                icon: Icons.directions_bus_outlined,
                label: 'Manage Trips',
                onTap: () => _openTrips(context, session),
              ),
              HbtQuickActionTile(
                icon: Icons.route_outlined,
                label: 'Manage Routes',
                onTap: () => _openRoutes(context, session),
              ),
              HbtQuickActionTile(
                icon: Icons.qr_code_scanner,
                label: 'Scan Ticket',
                onTap: () => _openScanner(context, session),
              ),
              HbtQuickActionTile(
                icon: Icons.add_shopping_cart_outlined,
                label: 'New Booking',
                onTap: () => _openBooking(context, session),
              ),
              if (session.hasPermission('refund.view'))
                HbtQuickActionTile(
                  icon: Icons.replay_outlined,
                  label: 'Refunds',
                  badge: snapshot.cashPending.pendingRefunds.count,
                  onTap: () => _openRefunds(context, session),
                ),
              HbtQuickActionTile(
                icon: Icons.inventory_2_outlined,
                label: 'Cargo Worklist',
                onTap: () => _openCargo(context, session),
              ),
            ],
          ),
          const SizedBox(height: HbtSpacing.xxl),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HbtSpacing.xs),
        child: Text(title, style: HbtTypography.bodyStrong),
      );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    return ListView(
      padding: r.pagePadding,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        SkeletonLine(width: 220, height: 24),
        const SizedBox(height: HbtSpacing.lg),
        HbtKpiGrid(
          children: const [
            HbtKpiCard(label: '', value: '', loading: true),
            HbtKpiCard(label: '', value: '', loading: true),
            HbtKpiCard(label: '', value: '', loading: true),
            HbtKpiCard(label: '', value: '', loading: true),
          ],
        ),
        const SizedBox(height: HbtSpacing.lg),
        SkeletonLine(height: 200),
        const SizedBox(height: HbtSpacing.lg),
        SkeletonLine(height: 120),
      ],
    );
  }
}

// ── Formatting helpers ────────────────────────────────────────────────

String _money(double v) {
  final rounded = v.round();
  final s = rounded.abs() >= 1000
      ? rounded.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
      : rounded.toString();
  return v < 0 ? '-$s' : s;
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}';
}

IconData _activityIcon(String resourceType) {
  final r = resourceType.toLowerCase();
  if (r.contains('trip')) return Icons.directions_bus_outlined;
  if (r.contains('ticket')) return Icons.confirmation_number_outlined;
  if (r.contains('payment')) return Icons.payments_outlined;
  if (r.contains('cargo')) return Icons.inventory_2_outlined;
  if (r.contains('refund')) return Icons.replay_outlined;
  if (r.contains('booking')) return Icons.event_seat_outlined;
  return Icons.history;
}

String _activityText(ActivityItem a) {
  final actor = a.actor.isEmpty ? 'System' : a.actor;
  final action = a.action.replaceAll('_', ' ');
  return '$actor · $action';
}

// ── Navigation (real screens only) ────────────────────────────────────

void _openTrips(BuildContext context, SessionController session) =>
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripListPage(session: session)),
    );

void _openRoutes(BuildContext context, SessionController session) =>
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RouteListPage(session: session)),
    );

void _openScanner(BuildContext context, SessionController session) =>
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TicketScannerScreen(session: session)),
    );

void _openBooking(BuildContext context, SessionController session) =>
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => CounterBookingPage(session: session)),
    );

void _openRefunds(BuildContext context, SessionController session) =>
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => RefundListPage(session: session)),
    );

void _openCargo(BuildContext context, SessionController session) =>
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => CargoWorklistPage(session: session)),
    );

// HbtResponsive is provided by hbt_responsive.dart (imported above).

/// Responsive grid wrapper — 1 col mobile, 2 tablet, 3 desktop+.
class HbtResponsiveGridWrap extends StatelessWidget {
  const HbtResponsiveGridWrap({super.key, required this.children, this.gap = 16});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    final columns = r.columns;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
