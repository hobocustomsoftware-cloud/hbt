import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/core/theme/app_theme.dart';
import 'package:hbt_business_app/core/theme/hbt_theme.dart';
import 'package:hbt_business_app/core/theme/hbt_tokens.dart';
import 'package:hbt_business_app/core/widgets/async_views.dart';
import 'package:hbt_business_app/core/widgets/hbt_chart.dart';
import 'package:hbt_business_app/core/widgets/hbt_adaptive_scaffold.dart';
import 'package:hbt_business_app/core/widgets/status_chip.dart';

void main() {
  group('HbtTheme (W1-001)', () {
    testWidgets('light theme uses official brand primary', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: HbtTheme.light(), home: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(Theme.of(ctx).colorScheme.primary, HbtColors.primary);
    });

    testWidgets('dark theme renders', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: HbtTheme.dark(), home: const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    test('AppTheme shim delegates to tokens (no teal)', () {
      expect(AppTheme.spacingMd, HbtSpacing.md);
      expect(AppTheme.radiusMd, HbtRadius.md);
      expect(AppTheme.minButtonHeight, HbtSize.minButtonHeight);
    });
  });

  group('StatusChip (design system)', () {
    testWidgets('renders label and semantic color', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusChip(status: 'delayed')),
      ));
      expect(find.text('delayed'), findsOneWidget);
      // Semantic danger tint, not a random color.
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, HbtColors.danger.withValues(alpha: 0.12));
    });

    testWidgets('unknown status falls back to neutral', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusChip(status: 'weird_state')),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, HbtColors.neutral.withValues(alpha: 0.12));
    });
  });

  group('State components (design system)', () {
    testWidgets('EmptyView shows message + action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyView(
            icon: Icons.route_outlined,
            message: 'No routes yet.',
            actionLabel: 'Create Route',
            onAction: () => tapped = true,
          ),
        ),
      ));
      expect(find.text('No routes yet.'), findsOneWidget);
      await tester.tap(find.text('Create Route'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorView shows retry and fires callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorView(message: 'Failed', onRetry: () => retried = true),
        ),
      ));
      expect(find.text('Failed'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('SkeletonLine renders without exception', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SkeletonLoader(itemCount: 2, itemBuilder: (_) => const SkeletonLine(width: 100))),
      ));
      expect(find.byType(SkeletonLine), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('Chart components (design system)', () {
    testWidgets('HbtChartCard renders title and drill link', (tester) async {
      var drilled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HbtChartCard(
            title: 'Revenue trend',
            drillLabel: 'View report',
            onDrill: () => drilled = true,
            child: const HbtSparkline(values: [1, 3, 2, 4, 3, 5]),
          ),
        ),
      ));
      expect(find.text('Revenue trend'), findsOneWidget);
      await tester.tap(find.text('View report'));
      expect(drilled, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HbtMiniBars renders label + value rows', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HbtMiniBars(items: const [('YGN→MDY', 42), ('YGN→BAG', 18)]),
        ),
      ));
      expect(find.text('YGN→MDY'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HbtAdaptiveScaffold (W1-001)', () {
    testWidgets('desktop: dark sidebar (#151515) + trailing actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: HbtTheme.light(),
        home: HbtAdaptiveScaffold(
          navItems: const [
            HbtNavItem(id: 'home', label: 'Home', icon: Icons.home),
          ],
          currentNavId: 'home',
          onNavSelected: (_) {},
          trailingActions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () {},
            ),
          ],
          body: const SizedBox(),
        ),
      ));
      expect(find.text('HBT Business'), findsOneWidget);
      expect(find.byTooltip('Sign out'), findsOneWidget);
      final sidebarMaterial = tester.widget<Material>(
        find.ancestor(
          of: find.text('HBT Business'),
          matching: find.byType(Material),
        ).first,
      );
      expect(sidebarMaterial.color, HbtColors.secondary);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile: bottom nav + drawer footer', (tester) async {
      tester.view.physicalSize = const Size(375, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: HbtTheme.light(),
        home: HbtAdaptiveScaffold(
          navItems: const [
            HbtNavItem(id: 'home', label: 'Home', icon: Icons.home),
            HbtNavItem(id: 'ticket', label: 'Ticket', icon: Icons.confirmation_number),
            HbtNavItem(id: 'cargo', label: 'Cargo', icon: Icons.inventory_2),
            HbtNavItem(id: 'sync', label: 'Sync', icon: Icons.sync),
          ],
          currentNavId: 'home',
          onNavSelected: (_) {},
          drawerFooter: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {},
            ),
          ],
          body: const SizedBox(),
        ),
      ));
      expect(find.byType(NavigationBar), findsOneWidget);
      // Drawer footer reachable via the Menu button.
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
