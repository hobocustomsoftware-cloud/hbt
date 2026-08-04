import 'package:flutter/material.dart';

import '../../../core/widgets/hbt_adaptive_scaffold.dart';
import '../../../features/dashboard/dashboard_controller.dart';
import '../../../features/dashboard/dashboard_repository.dart';
import '../../../features/dashboard/owner_dashboard_screen.dart';
import '../../auth/controllers/session_controller.dart';
import '../../cargo/screens/cargo_worklist_page.dart';
import '../../refund/screens/refund_list_page.dart';
import '../../routes/screens/route_list_page.dart';
import '../../ticket_sales/screens/ticket_sales_page.dart';
import '../../ticket_sales/screens/ticket_scanner_screen.dart';
import '../../trip/screens/trip_list_page.dart';
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
  late final DashboardController _dashboardCtrl;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _dashboardCtrl = DashboardController(
      repository: ApiDashboardRepository(api: widget.session.api),
    );
    _dashboardCtrl.addListener(_onDashboardChanged);
  }

  @override
  void dispose() {
    _dashboardCtrl.removeListener(_onDashboardChanged);
    _dashboardCtrl.dispose();
    super.dispose();
  }

  void _onDashboardChanged() {
    if (mounted) setState(() {});
  }

  void _setTab(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() => _index = index);
    }
  }

  static const _titles = ['Home', 'Ticket', 'Cargo', 'Sync'];

  Widget get _page => switch (_index) {
    0 => OwnerDashboardScreen(
      controller: _dashboardCtrl,
      session: widget.session,
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
  Widget build(BuildContext context) {
    // Map the 4 business tabs into the adaptive shell's nav items.
    const navItems = [
      HbtNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
      HbtNavItem(id: 'ticket', label: 'Ticket', icon: Icons.confirmation_number_outlined, selectedIcon: Icons.confirmation_number),
      HbtNavItem(id: 'cargo', label: 'Cargo', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2),
      HbtNavItem(id: 'sync', label: 'Sync', icon: Icons.sync_outlined, selectedIcon: Icons.sync),
    ];
    const ids = ['home', 'ticket', 'cargo', 'sync'];
    final orgName = widget.session
            .activeOrganization?.organization.displayName ??
        'Business';

    return HbtAdaptiveScaffold(
      navItems: navItems,
      currentNavId: ids[_index],
      onNavSelected: (id) => _setTab(ids.indexOf(id)),
      breadcrumbs: const ['ပင်မ'],
      userName: widget.session.user?['full_name']?.toString(),
      trailingActions: [
        // ── Switch organization ──────────────────────────────────
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
                Text(orgName),
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
      ],
      drawerFooter: [
        // Mobile: sign out lives in the drawer (desktop keeps the icon).
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: widget.session.signOut,
        ),
      ],
      body: _BusinessContextBody(
        session: widget.session,
        child: _page,
      ),
    );
  }
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


