import 'package:flutter/material.dart';

import '../../auth/controllers/session_controller.dart';
import '../../cargo/screens/cargo_worklist_page.dart';
import '../../expense/controllers/expense_controller.dart';
import '../../expense/screens/expense_create_screen.dart';
import '../../expense/screens/expense_list_screen.dart';
import '../../finance/controllers/profit_loss_controller.dart';
import '../../finance/screens/profit_loss_screen.dart';
import '../../refund/screens/refund_list_page.dart';
import '../../routes/screens/route_list_page.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../shift/screens/shift_active_card.dart';
import '../../shift/screens/shift_close_screen.dart';
import '../../shift/screens/shift_open_screen.dart';
import '../../ticket_sales/screens/counter_booking_page.dart';
import '../../ticket_sales/screens/ticket_sales_page.dart';
import '../../ticket_sales/screens/ticket_scanner_screen.dart';
import '../../trip/screens/trip_list_page.dart';
import '../../../shared/models/shift_models.dart';
import '../../../infrastructure/offline/connectivity_monitor.dart';
import '../../../infrastructure/offline/device_registry.dart';
import '../../../infrastructure/offline/sync_manager.dart';
import 'sync_status_page.dart';

class BusinessHome extends StatefulWidget {
  const BusinessHome({
    super.key,
    required this.session,
    this.registry,
    this.monitor,
    this.syncManager,
  });

  final SessionController session;

  /// Offline infrastructure (optional for tests/standalone usage).
  final DeviceRegistry? registry;
  final ConnectivityMonitor? monitor;
  final SyncManager? syncManager;

  /// Expose tab switching for child widgets via the build context.
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_BusinessHomeState>();
    state?._setTab(index);
  }

  @override
  State<BusinessHome> createState() => _BusinessHomeState();
}

class _BusinessHomeState extends State<BusinessHome> {
  late final ShiftController _shiftCtrl;
  late final ExpenseController _expenseCtrl;
  late final ProfitLossController _profitLossCtrl;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _shiftCtrl = ShiftController(session: widget.session);
    _shiftCtrl.addListener(_onShiftChanged);
    _shiftCtrl.loadActiveShift();

    _expenseCtrl = ExpenseController(session: widget.session);
    _expenseCtrl.addListener(_onShiftChanged);

    _profitLossCtrl = ProfitLossController(session: widget.session);
    _profitLossCtrl.addListener(_onShiftChanged);
  }

  @override
  void dispose() {
    _shiftCtrl.removeListener(_onShiftChanged);
    _shiftCtrl.dispose();
    _expenseCtrl.removeListener(_onShiftChanged);
    _expenseCtrl.dispose();
    _profitLossCtrl.removeListener(_onShiftChanged);
    _profitLossCtrl.dispose();
    super.dispose();
  }

  void _onShiftChanged() {
    if (mounted) setState(() {});
  }

  Shift _previousShiftState = Shift(
    branchId: '',
    counterId: '',
    staffUserId: '',
    organizationId: '',
    openingCash: 0,
    createdAt: '',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCounterIdentity();
  }

  void _syncCounterIdentity() {
    final shift = _shiftCtrl.activeShift;
    if (shift == null) {
      // Shift went from active → null (closed or no shift)
      if (_previousShiftState.id != null ||
          _previousShiftState.openingCash > 0) {
        widget.session.clearCounter();
        widget.session.shiftId = null;
      }
      _previousShiftState = Shift(
        branchId: '',
        counterId: '',
        staffUserId: '',
        organizationId: '',
        openingCash: 0,
        createdAt: '',
      );
    } else if (_previousShiftState.id != shift.id ||
        _previousShiftState.status != shift.status) {
      // New shift opened
      final branch = _shiftCtrl.branches
          .where((b) => b.id == shift.branchId)
          .firstOrNull;
      final counter = _shiftCtrl.counters
          .where((c) => c.id == shift.counterId)
          .firstOrNull;
      widget.session.shiftId = shift.id;
      widget.session.setActiveCounter(
        branchId: shift.branchId,
        branchName: branch?.name ?? shift.branchId,
        counterId: shift.counterId,
        counterName: counter?.displayName ?? counter?.code ?? shift.counterId,
      );
      _previousShiftState = shift;
    }
  }

  void _setTab(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() => _index = index);
    }
  }

  static const _titles = ['Home', 'Ticket', 'Cargo', 'Sync'];

  Widget get _page => switch (_index) {
    0 => _DashboardPage(
      session: widget.session,
      shiftCtrl: _shiftCtrl,
      expenseCtrl: _expenseCtrl,
      profitLossCtrl: _profitLossCtrl,
    ),
    1 => TicketSalesPage(
      key: ValueKey(widget.session.activeOrganization?.organization.id),
      session: widget.session,
    ),
    2 => CargoWorklistPage(session: widget.session),
    _ => SyncStatusPage(
      session: widget.session,
      registry: widget.registry ?? DeviceRegistry(api: widget.session.api),
      monitor: widget.monitor ?? ConnectivityMonitor(baseUrl: ''),
      syncManager: widget.syncManager,
    ),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_titles[_index]),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Switch organization',
          enabled: !widget.session.contextLoading &&
              widget.session.organizations.isNotEmpty,
          onSelected: (organizationId) =>
              widget.session.loadOrganizationContext(
            organizationId: organizationId,
          ),
          itemBuilder: (context) => widget.session.organizations
              .map(
                (organization) => PopupMenuItem(
                  value: organization.id,
                  child: Text(organization.displayName),
                ),
              )
              .toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.business_outlined),
                const SizedBox(width: 6),
                Text(widget.session.activeOrganization?.organization.displayName ??
                    'Select Org'),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Trips',
          icon: const Icon(Icons.directions_bus_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripListPage(session: widget.session),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Routes',
          icon: const Icon(Icons.route_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteListPage(session: widget.session),
            ),
          ),
        ),
        IconButton(
          tooltip: 'QR Scanner',
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketScannerScreen(session: widget.session),
            ),
          ),
        ),
        if (widget.session.hasPermission('refund.view'))
          IconButton(
            tooltip: 'Refunds',
            icon: const Icon(Icons.replay_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RefundListPage(session: widget.session),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: widget.session.signOut,
        ),
      ],
    ),
    body: _BusinessContextBody(
      session: widget.session,
      child: _page,
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number),
          label: 'Ticket',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Cargo',
        ),
        NavigationDestination(
          icon: Icon(Icons.sync_outlined),
          selectedIcon: Icon(Icons.sync),
          label: 'Sync',
        ),
      ],
    ),
  );
}

class _BusinessContextBody extends StatelessWidget {
  const _BusinessContextBody({required this.session, required this.child});

  final SessionController session;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (session.contextLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session.contextError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(session.contextError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: session.loadOrganizationContext,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (session.activeOrganization == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No organization available.'),
        ),
      );
    }
    return child;
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.session,
    required this.shiftCtrl,
    required this.expenseCtrl,
    required this.profitLossCtrl,
  });

  final SessionController session;
  final ShiftController shiftCtrl;
  final ExpenseController expenseCtrl;
  final ProfitLossController profitLossCtrl;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // ── Shift status ──────────────────────────────────────
      if (shiftCtrl.hasActiveShift)
        ActiveShiftCard(
          controller: shiftCtrl,
          onRefresh: () => shiftCtrl.refreshMetrics(),
          onRecordExpense: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpenseCreateScreen(controller: expenseCtrl),
            ),
          ),
          onCloseShift: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShiftCloseScreen(controller: shiftCtrl),
            ),
          ),
        )
      else
        Card(
          child: ListTile(
            leading: const Icon(Icons.timer_off_outlined),
            title: const Text('No Active Shift'),
            subtitle: const Text('Open a counter to start selling.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShiftOpenScreen(controller: shiftCtrl),
              ),
            ),
          ),
        ),
      const SizedBox(height: 16),

      // ── Quick Actions ──────────────────────────────────────
      const Text('Quick Actions'),
      const SizedBox(height: 8),
      _QuickAction(
        icon: Icons.directions_bus,
        label: 'Manage Trips',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripListPage(session: session),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.route,
        label: 'Manage Routes',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RouteListPage(session: session),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.qr_code_scanner,
        label: 'Scan Ticket',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TicketScannerScreen(session: session),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.add_shopping_cart,
        label: 'New Booking',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CounterBookingPage(session: session),
          ),
        ),
      ),
      if (session.hasPermission('refund.view'))
        _QuickAction(
          icon: Icons.replay_outlined,
          label: 'Refunds',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RefundListPage(session: session),
            ),
          ),
        ),
      _QuickAction(
        icon: Icons.payments_outlined,
        label: 'Pending Payments',
        onTap: () => BusinessHome.switchTab(context, 1),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Expenses',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExpenseListScreen(controller: expenseCtrl),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.assessment,
        label: 'Profit & Loss',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ProfitLossScreen(controller: profitLossCtrl),
          ),
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}


