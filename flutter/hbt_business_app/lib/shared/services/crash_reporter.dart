import 'package:flutter/foundation.dart';

/// Env-gated crash reporting hook.
///
/// When `HBT_CRASH_REPORTING_DSN` is provided at build time (`--dart-define`),
/// runtime errors are forwarded to the configured reporter. When absent (the
/// default), [recordError] is a no-op and the app behaves exactly as before —
/// existing logging in `main()` is preserved unchanged.
///
/// The transport is intentionally swappable: wiring Sentry/Crashlytics (F-18b)
/// is a one-file change once a DSN is provisioned.
class CrashReporter {
  CrashReporter._();

  static final CrashReporter instance = CrashReporter._();

  /// DSN from `--dart-define` (empty string = reporting disabled).
  static const String dsn = String.fromEnvironment('HBT_CRASH_REPORTING_DSN');

  /// Whether crash reporting is enabled for this build.
  bool get enabled => dsn.isNotEmpty;

  /// Record an unhandled error.
  ///
  /// No-op when [enabled] is false. When enabled, forwards to the vendor
  /// transport (currently logs; F-18b replaces this with the SDK call).
  void recordError(Object error, StackTrace stack, {String? context}) {
    if (!enabled) return;
    // TODO(F-18b): forward to Sentry/Crashlytics SDK here once DSN provisioned.
    debugPrint(
      'HBT crash (DSN configured${context == null ? '' : ', $context'}): '
      '$error\n$stack',
    );
  }
}
