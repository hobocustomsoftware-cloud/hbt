import 'package:flutter/material.dart';

import '../../core/theme/hbt_tokens.dart';
import '../../core/widgets/hbt_adaptive_scaffold.dart';
import '../../core/widgets/hbt_responsive.dart';

/// Design System Showcase — used for responsive validation only.
///
/// Exercises every design-system surface at every breakpoint:
/// KPIs, charts (placeholder), adaptive table → cards, sidebar/rail/
/// bottom-nav. NOT feature logic.
class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  String _currentNav = 'dashboard';
  bool _sidebarCollapsed = false;

  static const _navItems = [
    HbtNavItem(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
    HbtNavItem(id: 'finance', label: 'Finance', icon: Icons.account_balance_outlined),
    HbtNavItem(id: 'reports', label: 'Reports', icon: Icons.insert_chart_outlined, badge: 3),
    HbtNavItem(id: 'fleet', label: 'Fleet', icon: Icons.directions_bus_outlined),
    HbtNavItem(id: 'users', label: 'Users', icon: Icons.people_outlined),
    HbtNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return HbtAdaptiveScaffold(
      navItems: _navItems,
      currentNavId: _currentNav,
      onNavSelected: (id) => setState(() => _currentNav = id),
      breadcrumbs: const ['ပင်မ', 'Dashboard'],
      onSearch: (_) {},
      notificationCount: 3,
      userName: 'U Aung Owner',
      sidebarCollapsed: _sidebarCollapsed,
      onSidebarCollapsedChanged: (v) => setState(() => _sidebarCollapsed = v),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final r = HbtResponsive.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth ?? double.infinity),
          child: Padding(
            padding: r.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ဒီဇိုင်းစနစ် စမ်းသပ်ချက်', style: HbtTypography.headline),
                const SizedBox(height: 4),
                Text(
                  'Design System Validation — breakpoint ${r.width.round()}px',
                  style: HbtTypography.caption
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: HbtSpacing.xxl),

                // ── KPI grid ─────────────────────────────────────────
                HbtKpiGrid(
                  children: [
                    _kpi('ယနေ့ လက်မှတ်ရောင်းရငွေ', '၃၂,၄၅၀,၀၀၀ ကျပ်', Icons.confirmation_number),
                    _kpi('ယနေ့ ကုန်တင်ဝင်ငွေ', '၈,၂၀၀,၀၀၀ ကျပ်', Icons.inventory_2_outlined),
                    _kpi('အသားတင်အမြတ်', '၁၅,၈၀၀,၀၀၀ ကျပ်', Icons.trending_up),
                    _kpi('ယနေ့ အသုံးစရိတ်', '၄,၅၀၀,၀၀၀ ကျပ်', Icons.receipt_long_outlined),
                    _kpi('ပြေးဆွဲနေသော ခရီးစဉ်', '၂၄', Icons.directions_bus_outlined),
                    _kpi('ပြီးဆုံးသော ခရီးစဉ်', '၁၈', Icons.check_circle_outline),
                    _kpi('ယနေ့ ခရီးသည်', '၁,၂၄၀', Icons.people_outline),
                    _kpi('ဆိုင်းငံ့ အတည်ပြုချက်', '၇', Icons.pending_actions_outlined),
                  ],
                ),
                const SizedBox(height: HbtSpacing.xxl),

                // ── Charts row (placeholder cards) ───────────────────
                HbtResponsiveGrid(
                  children: [
                    _chartCard('ဝင်ငွေလမ်းကြောင်း', Icons.show_chart),
                    _chartCard('လမ်းကြောင်းအလိုက် ရောင်းအား', Icons.bar_chart),
                    _chartCard('အကိုင်းအလိုက် ရောင်းအား', Icons.pie_chart_outline),
                  ],
                ),
                const SizedBox(height: HbtSpacing.xxl),

                // ── Adaptive table → cards ───────────────────────────
                Text('လက်မှတ်စာရင်း (Table → Cards)', style: HbtTypography.title),
                const SizedBox(height: HbtSpacing.md),
                HbtAdaptiveTable<_TicketRow>(
                  items: _tickets,
                  headers: const ['လက်မှတ်', 'ခရီးစဉ်', 'ခရီးသည်', 'ထွက်ခွာချိန်', 'ငွေပမာဏ'],
                  rowBuilder: (context, t) => DataRow(cells: [
                    DataCell(Text(t.number)),
                    DataCell(Text(t.trip)),
                    DataCell(Text(t.passenger)),
                    DataCell(Text(t.departure)),
                    DataCell(Text(t.amount)),
                  ]),
                  cardBuilder: (context, t) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(HbtSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.number,
                                  style: HbtTypography.bodyStrong),
                              Text(t.amount,
                                  style: HbtTypography.bodyStrong
                                      .copyWith(color: HbtColors.primary)),
                            ],
                          ),
                          const SizedBox(height: HbtSpacing.xs),
                          Text('${t.trip} • ${t.passenger}',
                              style: HbtTypography.body),
                          const SizedBox(height: HbtSpacing.xs),
                          Text(t.departure, style: HbtTypography.caption),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HbtSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: HbtColors.brandGradient,
                    borderRadius: BorderRadius.circular(HbtRadius.sm + 2),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: HbtSpacing.md),
            Text(value, style: HbtTypography.kpiValue),
            const SizedBox(height: 2),
            Text(
              label,
              style: HbtTypography.kpiLabel.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(String title, IconData icon) {
    return Card(
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(HbtSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: HbtSpacing.sm),
                  Text(title, style: HbtTypography.bodyStrong),
                ],
              ),
              const Spacer(),
              // Chart placeholder: brand gradient area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        HbtColors.primary.withValues(alpha: 0.08),
                        HbtColors.primary.withValues(alpha: 0.25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(HbtRadius.sm),
                  ),
                  child: const Center(
                    child: Icon(Icons.insert_chart_outlined, size: 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketRow {
  const _TicketRow(this.number, this.trip, this.passenger, this.departure, this.amount);
  final String number;
  final String trip;
  final String passenger;
  final String departure;
  final String amount;
}

const _tickets = [
  _TicketRow('TK-1001', 'YM-MORNING-0801', 'Ma Mya', '08:00', '၃၀,၀၀၀'),
  _TicketRow('TK-1002', 'YM-NIGHT-0801', 'U Ko Ko', '21:00', '၃၂,၀၀၀'),
  _TicketRow('TK-1003', 'YT-MORNING-0801', 'Daw Hla', '08:30', '၂၈,၀၀၀'),
  _TicketRow('TK-1004', 'YM-MORNING-0802', 'Ko Zaw', '08:00', '၃၀,၀၀၀'),
  _TicketRow('TK-1005', 'YM-NIGHT-0802', 'Ma Su', '21:00', '၃၂,၀၀၀'),
];
