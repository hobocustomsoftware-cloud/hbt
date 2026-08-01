import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_passenger_app/shared/services/idle_timeout_controller.dart';
import 'package:hbt_passenger_app/shared/widgets/idle_lock_overlay.dart';

void main() {
  testWidgets('IdleLockOverlay shows lock UI and unlocks on tap', (tester) async {
    final controller = IdleTimeoutController(
      timeout: const Duration(milliseconds: 50),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            const Scaffold(body: Text('app content')),
            IdleLockOverlay(controller: controller),
          ],
        ),
      ),
    );

    // Not locked yet — overlay still renders its card; verify content.
    expect(find.text('Session idle'), findsOneWidget);
    expect(find.text('Unlock to continue.'), findsOneWidget);

    // Lock the controller, then verify the overlay unlocks it.
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.locked, isTrue);

    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(controller.locked, isFalse);

    // Let the restarted idle timer fire so no timers are pending at teardown.
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.locked, isTrue);
  });
}
