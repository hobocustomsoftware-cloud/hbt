import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';
import 'hbt_responsive.dart';

/// A navigation destination in the adaptive shell.
class HbtNavItem {
  const HbtNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badge;
}

/// Adaptive app shell.
///
/// - Desktop (1024+): collapsible sidebar + top bar with quick search,
///   notification center, profile menu, breadcrumb.
/// - Tablet (600-1023): navigation rail + top bar.
/// - Mobile (<600): bottom navigation + drawer; top bar simplified.
///
/// Content is provided via [body]; the shell handles navigation mode,
/// overflow safety and per-breakpoint layout independently.
class HbtAdaptiveScaffold extends StatefulWidget {
  const HbtAdaptiveScaffold({
    super.key,
    required this.navItems,
    required this.currentNavId,
    required this.onNavSelected,
    required this.body,
    this.breadcrumbs = const [],
    this.onSearch,
    this.notificationCount = 0,
    this.onNotificationsTap,
    this.userName,
    this.userAvatar,
    this.onProfileTap,
    this.sidebarCollapsed,
    this.onSidebarCollapsedChanged,
    this.leading,
  });

  final List<HbtNavItem> navItems;
  final String currentNavId;
  final ValueChanged<String> onNavSelected;
  final Widget body;
  final List<String> breadcrumbs;
  final ValueChanged<String>? onSearch;
  final int notificationCount;
  final VoidCallback? onNotificationsTap;
  final String? userName;
  final Widget? userAvatar;
  final VoidCallback? onProfileTap;
  final bool? sidebarCollapsed;
  final ValueChanged<bool>? onSidebarCollapsedChanged;
  final Widget? leading;

  @override
  State<HbtAdaptiveScaffold> createState() => _HbtAdaptiveScaffoldState();
}

class _HbtAdaptiveScaffoldState extends State<HbtAdaptiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    switch (r.navMode) {
      case HbtNavMode.sidebar:
        return _buildDesktop(context, r);
      case HbtNavMode.rail:
        return _buildTablet(context, r);
      case HbtNavMode.bottomNav:
        return _buildMobile(context, r);
    }
  }

  // ── Desktop: collapsible sidebar + top bar ──────────────────────────
  Widget _buildDesktop(BuildContext context, HbtResponsive r) {
    final collapsed = widget.sidebarCollapsed ?? false;
    final sidebarWidth = collapsed ? 72.0 : 248.0;
    return Row(
      children: [
        AnimatedContainer(
          duration: HbtMotion.normal,
          curve: HbtMotion.easeInOut,
          width: sidebarWidth,
          child: _Sidebar(
            items: widget.navItems,
            currentId: widget.currentNavId,
            onSelect: widget.onNavSelected,
            collapsed: collapsed,
            onToggleCollapse: () => widget.onSidebarCollapsedChanged
                ?.call(!collapsed),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _TopBar(
                r: r,
                breadcrumbs: widget.breadcrumbs,
                onSearch: widget.onSearch,
                notificationCount: widget.notificationCount,
                onNotificationsTap: widget.onNotificationsTap,
                userName: widget.userName,
                userAvatar: widget.userAvatar,
                onProfileTap: widget.onProfileTap,
              ),
              Expanded(child: widget.body),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tablet: navigation rail ─────────────────────────────────────────
  Widget _buildTablet(BuildContext context, HbtResponsive r) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: widget.navItems
              .indexWhere((item) => item.id == widget.currentNavId),
          onDestinationSelected: (index) =>
              widget.onNavSelected(widget.navItems[index].id),
          labelType: NavigationRailLabelType.all,
          leading: widget.leading,
          destinations: [
            for (final item in widget.navItems)
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: (item.badge ?? 0) > 0,
                  label: Text('${item.badge ?? 0}'),
                  child: Icon(item.icon),
                ),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _TopBar(
                r: r,
                breadcrumbs: widget.breadcrumbs,
                onSearch: widget.onSearch,
                notificationCount: widget.notificationCount,
                onNotificationsTap: widget.onNotificationsTap,
                userName: widget.userName,
                userAvatar: widget.userAvatar,
                onProfileTap: widget.onProfileTap,
              ),
              Expanded(child: widget.body),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile: bottom nav + drawer ─────────────────────────────────────
  Widget _buildMobile(BuildContext context, HbtResponsive r) {
    final selectedIndex = widget.navItems
        .indexWhere((item) => item.id == widget.currentNavId);
    // Show at most 5 in the bottom bar; overflow goes to the drawer.
    final bottomItems = widget.navItems.take(5).toList();
    final drawerItems = widget.navItems.skip(5).toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(breadcrumbTitle(widget.breadcrumbs)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (widget.onSearch != null)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {},
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: widget.notificationCount > 0,
              label: Text('${widget.notificationCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: widget.onNotificationsTap,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: HbtColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.userName ?? 'HBT',
                    style: HbtTypography.title.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ကားဂိတ်လုပ်ငန်း စီမံခန့်ခွဲမှု',
                    style: HbtTypography.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            for (final item in drawerItems)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: item.id == widget.currentNavId,
                onTap: () => widget.onNavSelected(item.id),
              ),
          ],
        ),
      ),
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, bottomItems.length - 1),
        onDestinationSelected: (index) =>
            widget.onNavSelected(bottomItems[index].id),
        destinations: [
          for (final item in bottomItems)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: (item.badge ?? 0) > 0,
                label: Text('${item.badge ?? 0}'),
                child: Icon(item.icon),
              ),
              selectedIcon: Icon(item.selectedIcon ?? item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

String breadcrumbTitle(List<String> breadcrumbs) =>
    breadcrumbs.isEmpty ? 'HBT' : breadcrumbs.last;

// ── Sidebar (desktop) ─────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.currentId,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final List<HbtNavItem> items;
  final String currentId;
  final ValueChanged<String> onSelect;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Brand mark
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  const SizedBox(width: HbtSpacing.lg),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: HbtColors.brandGradient,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: const Icon(Icons.directions_bus,
                        color: Colors.white, size: 20),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: HbtSpacing.md),
                    Expanded(
                      child: Text(
                        'HBT Business',
                        style: HbtTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: HbtSpacing.sm, vertical: HbtSpacing.sm),
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _SidebarItem(
                        item: item,
                        selected: item.id == currentId,
                        collapsed: collapsed,
                        onTap: () => onSelect(item.id),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            // Collapse toggle
            IconButton(
              tooltip: collapsed ? 'Expand' : 'Collapse',
              onPressed: onToggleCollapse,
              icon: Icon(
                collapsed
                    ? Icons.chevron_right
                    : Icons.chevron_left,
              ),
            ),
            const SizedBox(height: HbtSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final HbtNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: collapsed ? item.label : '',
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(HbtRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(HbtRadius.sm),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : HbtSpacing.md),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  item.selectedIcon ?? item.icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: 22,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: HbtSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: HbtTypography.body.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((item.badge ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(HbtRadius.pill),
                      ),
                      child: Text(
                        '${item.badge}',
                        style: HbtTypography.caption
                            .copyWith(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.r,
    required this.breadcrumbs,
    required this.onSearch,
    required this.notificationCount,
    required this.onNotificationsTap,
    required this.userName,
    required this.userAvatar,
    required this.onProfileTap,
  });

  final HbtResponsive r;
  final List<String> breadcrumbs;
  final ValueChanged<String>? onSearch;
  final int notificationCount;
  final VoidCallback? onNotificationsTap;
  final String? userName;
  final Widget? userAvatar;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: HbtSpacing.lg),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Breadcrumb
            if (breadcrumbs.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < breadcrumbs.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: HbtSpacing.xs),
                            child: Icon(Icons.chevron_right, size: 16),
                          ),
                        Text(
                          breadcrumbs[i],
                          style: HbtTypography.body.copyWith(
                            color: i == breadcrumbs.length - 1
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: i == breadcrumbs.length - 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              const Spacer(),
            // Quick search (desktop only — mobile uses the app bar icon)
            if (!r.isMobile && onSearch != null)
              Container(
                width: 260,
                height: 40,
                margin: const EdgeInsets.only(right: HbtSpacing.lg),
                child: TextField(
                  onSubmitted: onSearch,
                  decoration: InputDecoration(
                    hintText: 'ရှာရန်…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                  ),
                ),
              ),
            // Notifications
            IconButton(
              tooltip: 'Notifications',
              onPressed: onNotificationsTap,
              icon: Badge(
                isLabelVisible: notificationCount > 0,
                label: Text('$notificationCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(width: HbtSpacing.xs),
            // Profile
            InkWell(
              borderRadius: BorderRadius.circular(HbtRadius.sm),
              onTap: onProfileTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: HbtSpacing.sm),
                child: Row(
                  children: [
                    userAvatar ??
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 18),
                        ),
                    if (!r.isMobile) ...[
                      const SizedBox(width: HbtSpacing.sm),
                      Text(
                        userName ?? '',
                        style: HbtTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: HbtSpacing.xs),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
