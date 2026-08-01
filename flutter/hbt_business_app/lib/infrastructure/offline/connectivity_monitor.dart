import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Monitors backend reachability and exposes online/offline state.
///
/// Pings the unauthenticated `/health/` endpoint on an interval. This
/// measures actual API reachability (not just the radio state), which is
/// what matters for a server-dependent booking app.
class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor({required this.baseUrl});

  final String baseUrl;

  static const _interval = Duration(seconds: 15);
  static const _timeout = Duration(seconds: 5);

  Timer? _timer;
  bool _online = true;
  bool _checking = false;

  /// Whether the backend was reachable on the last check.
  bool get isOnline => _online;

  /// Whether a check is currently in flight.
  bool get checking => _checking;

  /// Start periodic checks. Idempotent.
  void start() {
    _timer ??= Timer.periodic(_interval, (_) => check());
    check();
  }

  /// Stop periodic checks.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Run a single reachability check.
  Future<bool> check() async {
    if (_checking) return _online;
    _checking = true;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health/'))
          .timeout(_timeout);
      _setOnline(response.statusCode == 200);
    } catch (_) {
      _setOnline(false);
    } finally {
      _checking = false;
      notifyListeners();
    }
    return _online;
  }

  void _setOnline(bool value) {
    if (_online != value) {
      _online = value;
      debugPrint('HBT_BUSINESS connectivity: ${value ? "online" : "offline"}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
