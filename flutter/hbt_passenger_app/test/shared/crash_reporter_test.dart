import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_passenger_app/shared/services/crash_reporter.dart';

void main() {
  group('CrashReporter', () {
    test('disabled by default (no DSN in test builds)', () {
      expect(CrashReporter.instance.enabled, isFalse);
    });

    test('recordError is a no-op when disabled', () {
      // Must not throw; nothing to assert beyond that.
      CrashReporter.instance.recordError(
        StateError('boom'),
        StackTrace.current,
        context: 'test',
      );
    });

    test('enabled reflects a configured DSN', () {
      // In test builds HBT_CRASH_REPORTING_DSN is unset, so this confirms the
      // getter reads the environment define correctly when empty.
      expect(CrashReporter.dsn, isEmpty);
      expect(CrashReporter.instance.enabled, CrashReporter.dsn.isNotEmpty);
    });
  });
}
