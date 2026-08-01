import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/idle_timeout_controller.dart';

void main() {
  group('IdleTimeoutController', () {
    test('locks after timeout', () async {
      final controller = IdleTimeoutController(
        timeout: const Duration(milliseconds: 50),
      );
      expect(controller.locked, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(controller.locked, isTrue);
      controller.dispose();
    });

    test('activity resets the timer', () async {
      final controller = IdleTimeoutController(
        timeout: const Duration(milliseconds: 60),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      controller.registerActivity();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(controller.locked, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.locked, isTrue);
      controller.dispose();
    });

    test('zero timeout disables the guard', () async {
      final controller = IdleTimeoutController(timeout: Duration.zero);
      expect(controller.enabled, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.locked, isFalse);
      controller.registerActivity();
      controller.dispose();
    });

    test('unlock clears the locked state and restarts the window', () async {
      final controller = IdleTimeoutController(
        timeout: const Duration(milliseconds: 50),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(controller.locked, isTrue);

      controller.unlock();
      expect(controller.locked, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(controller.locked, isTrue);
      controller.dispose();
    });

    test('unlock when not locked is a no-op', () async {
      final controller = IdleTimeoutController(
        timeout: const Duration(milliseconds: 50),
      );
      controller.unlock();
      expect(controller.locked, isFalse);
      controller.dispose();
    });
  });
}
