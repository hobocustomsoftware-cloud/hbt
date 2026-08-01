import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_passenger_app/core/widgets/app_button.dart';
import 'package:hbt_passenger_app/core/widgets/status_chip.dart';

void main() {
  group('BusyButton', () {
    testWidgets('renders label and fires onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusyButton(
              label: 'Confirm Booking',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Confirm Booking'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });

    testWidgets('disables while busy and shows spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusyButton(label: 'Save', busy: true, onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('StatusChip', () {
    testWidgets('renders status label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusChip(status: 'planned')),
        ),
      );

      expect(find.text('planned'), findsOneWidget);
    });
  });
}
