import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'shared/services/crash_reporter.dart';

export 'app/app.dart';

/// Entry point with a global error boundary.
///
/// - [FlutterError.onError]: catches framework/render exceptions.
/// - `runZonedGuarded`: catches unhandled async errors.
///
/// Both log the error and (once a crash-reporting DSN is configured)
/// forward it to the crash reporter. The app shows a friendly error
/// screen instead of a white screen of death.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureFriendlyErrorWidget();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReporter.instance.recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'framework',
    );
    debugPrint('HBT_BUSINESS unhandled framework error: '
        '${details.exception}');
  };

  await runZonedGuarded(() async {
    HbtBusinessApp.start();
  }, (error, stack) {
    CrashReporter.instance.recordError(error, stack, context: 'async');
    debugPrint('HBT_BUSINESS unhandled async error: $error\n$stack');
  });
}
