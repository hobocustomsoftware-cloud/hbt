import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_passenger_app/shared/services/idle_timeout_controller.dart';

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
      // Register activity just before the timeout would fire.
      await Future<void>.delayed(const Duration(milliseconds: 40));
      controller.registerActivity();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(controller.locked, isFalse);
      // Now let it expire.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.locked, isTrue);
      controller.dispose();
    });

    test('zero timeout disables the guard', () async {
      final controller = IdleTimeoutController(timeout: Duration.zero);
      expect(controller.enabled, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.locked, isFalse);
      controller.registerActivity(); // must not throw
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

      // Locked again after a fresh full window.
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
