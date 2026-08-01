import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/core/theme/hbt_tokens.dart';
import 'package:hbt_business_app/core/widgets/hbt_responsive.dart';

void main() {
  group('HbtBreakpoints', () {
    test('classifies widths correctly', () {
      expect(HbtBreakpoints.isMobile(320), isTrue);
      expect(HbtBreakpoints.isMobile(599), isTrue);
      expect(HbtBreakpoints.isTablet(600), isTrue);
      expect(HbtBreakpoints.isTablet(1023), isTrue);
      expect(HbtBreakpoints.isDesktop(1024), isTrue);
      expect(HbtBreakpoints.isDesktop(1439), isTrue);
      expect(HbtBreakpoints.isWide(1440), isTrue);
      expect(HbtBreakpoints.isWide(2560), isTrue);
    });

    test('columns follow breakpoints', () {
      expect(HbtBreakpoints.columnsFor(375), 1);
      expect(HbtBreakpoints.columnsFor(768), 2);
      expect(HbtBreakpoints.columnsFor(1280), 3);
      expect(HbtBreakpoints.columnsFor(1920), 4);
    });
  });

  group('HbtKpiGrid', () {
    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: HbtKpiGrid(
              children: List.generate(8, (i) => const SizedBox(height: 80)),
            ),
          ),
        ),
      );
    }

    testWidgets('mobile: 2 KPI columns (no overflow)', (tester) async {
      await pumpAt(tester, 375);
      final row = tester.getTopLeft(find.byType(Wrap).first);
      expect(row.dx, 0);
      // No overflow errors reported by the framework.
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide: 4 KPI columns (no overflow)', (tester) async {
      await pumpAt(tester, 1920);
      expect(tester.takeException(), isNull);
    });
  });

  group('HbtAdaptiveTable', () {
    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: HbtAdaptiveTable<String>(
              items: const ['a', 'b'],
              headers: const ['Col'],
              rowBuilder: (context, item) => DataRow(
                cells: [DataCell(Text(item))],
              ),
              cardBuilder: (context, item) => Card(child: Text('card-$item')),
            ),
          ),
        ),
      );
    }

    testWidgets('mobile: renders cards, not a table', (tester) async {
      await pumpAt(tester, 375);
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('card-a'), findsOneWidget);
      expect(find.text('card-b'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop: renders a real table', (tester) async {
      await pumpAt(tester, 1280);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('card-a'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
