import 'dart:async';

import 'package:flutter/foundation.dart';

/// Global idle-session timeout guard.
///
/// Locks the app after [timeout] of no user interaction (pointer events
/// reset the timer). This is a UX deterrent for unattended devices — it does
/// NOT wipe tokens or enforce biometrics; re-authentication is handled by the
/// UI overlay and existing token/refresh logic.
///
/// A [timeout] of `Duration.zero` disables the guard entirely (dev builds).
class IdleTimeoutController extends ChangeNotifier {
  IdleTimeoutController({required this.timeout}) {
    if (timeout > Duration.zero) {
      _timer = Timer(timeout, _onTimeout);
    }
  }

  final Duration timeout;

  Timer? _timer;
  bool _locked = false;

  /// Whether the app is currently locked.
  bool get locked => _locked;

  /// Whether the guard is active at all.
  bool get enabled => timeout > Duration.zero;

  /// Called on any user interaction (tap/scroll/type).
  void registerActivity() {
    if (!enabled) return;
    _resetTimer();
  }

  /// Re-authentication succeeded — unlock and restart the idle window.
  void unlock() {
    if (!_locked) return;
    _locked = false;
    _resetTimer();
    notifyListeners();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeout, _onTimeout);
  }

  void _onTimeout() {
    _locked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
