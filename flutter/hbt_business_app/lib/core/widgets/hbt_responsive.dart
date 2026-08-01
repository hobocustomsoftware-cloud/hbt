import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Adaptive layout context — computed once per LayoutBuilder.
///
/// Use [HbtResponsive.of] instead of raw `MediaQuery.sizeOf(context).width`
/// checks scattered across widgets. Each breakpoint is designed
/// independently; desktop is NOT an enlarged mobile layout.
class HbtResponsive {
  const HbtResponsive({
    required this.width,
    required this.height,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.isWide,
  });

  final double width;
  final double height;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final bool isWide;

  /// Navigation mode per breakpoint.
  HbtNavMode get navMode {
    if (isMobile) return HbtNavMode.bottomNav;
    if (isTablet) return HbtNavMode.rail;
    return HbtNavMode.sidebar;
  }

  /// Page padding per breakpoint (independent, not stretched).
  EdgeInsets get pagePadding {
    if (isMobile) return HbtSpacing.pageMobile;
    if (isTablet) return HbtSpacing.pageTablet;
    return HbtSpacing.pageDesktop;
  }

  /// Content max width on ultra-wide so lines don't become unreadable.
  double? get contentMaxWidth => isWide ? 1680 : null;

  /// Grid column count (1/2/3/4 by breakpoint).
  int get columns {
    if (isMobile) return 1;
    if (isTablet) return 2;
    if (isDesktop) return 3;
    return 4;
  }

  /// Dashboards: KPI cards per row.
  int get kpiColumns {
    if (isMobile) return 2;
    if (isTablet) return 2;
    if (isDesktop) return 4;
    return 4;
  }

  static HbtResponsive of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    return HbtResponsive(
      width: width,
      height: size.height,
      isMobile: HbtBreakpoints.isMobile(width),
      isTablet: HbtBreakpoints.isTablet(width),
      isDesktop: HbtBreakpoints.isDesktop(width),
      isWide: HbtBreakpoints.isWide(width),
    );
  }
}

enum HbtNavMode { sidebar, rail, bottomNav }

/// Responsive grid that adapts column count to breakpoint.
class HbtResponsiveGrid extends StatelessWidget {
  const HbtResponsiveGrid({
    super.key,
    required this.children,
    this.gap = HbtSpacing.lg,
    this.rowGap,
  });

  final List<Widget> children;
  final double gap;
  final double? rowGap;

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = r.isMobile
            ? 1
            : r.isTablet
                ? 2
                : r.isDesktop
                    ? 3
                    : 4;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: rowGap ?? gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// KPI grid: 2-up on mobile, 4-up on desktop+.
class HbtKpiGrid extends StatelessWidget {
  const HbtKpiGrid({
    super.key,
    required this.children,
    this.gap = HbtSpacing.md,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    final columns = r.kpiColumns;
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

/// Data table that becomes cards on small screens.
///
/// Pass a [cardBuilder] to render rows as cards below the tablet breakpoint;
/// pass the table headers + [rowBuilder] for desktop. This keeps every
/// screen functional at every breakpoint — nothing is clipped or hidden.
class HbtAdaptiveTable<T> extends StatelessWidget {
  const HbtAdaptiveTable({
    super.key,
    required this.items,
    required this.headers,
    required this.rowBuilder,
    required this.cardBuilder,
  });

  final List<T> items;
  final List<String> headers;
  final DataRow Function(BuildContext, T) rowBuilder;
  final Widget Function(BuildContext, T) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final r = HbtResponsive.of(context);
    if (r.isMobile) {
      // Mobile: vertical card list (no table).
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: HbtSpacing.md),
        itemBuilder: (context, i) => cardBuilder(context, items[i]),
      );
    }
    // Tablet/desktop: real table.
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: [
            for (final h in headers)
              DataColumn(
                label: Text(
                  h,
                  style: HbtTypography.caption
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
          rows: [
            for (final item in items) rowBuilder(context, item),
          ],
        ),
      ),
    );
  }
}
