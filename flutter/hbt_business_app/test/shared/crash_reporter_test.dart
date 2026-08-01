import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/crash_reporter.dart';

void main() {
  group('CrashReporter', () {
    test('disabled by default (no DSN in test builds)', () {
      expect(CrashReporter.instance.enabled, isFalse);
    });

    test('recordError is a no-op when disabled', () {
      CrashReporter.instance.recordError(
        StateError('boom'),
        StackTrace.current,
        context: 'test',
      );
    });

    test('enabled reflects a configured DSN', () {
      expect(CrashReporter.dsn, isEmpty);
      expect(CrashReporter.instance.enabled, CrashReporter.dsn.isNotEmpty);
    });
  });
}
