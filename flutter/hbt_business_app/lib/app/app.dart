import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app/app_config.dart';
import '../shared/services/api_client.dart';
import '../features/auth/controllers/session_controller.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/business/screens/business_home.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/offline/connectivity_monitor.dart';
import '../infrastructure/offline/device_registry.dart';
import '../infrastructure/offline/sync_manager.dart';

/// Installs the app-wide friendly error widget. Called from [main] so the
/// real app gets the boundary; tests that pump the widget directly are not
/// affected (flutter_test asserts ErrorWidget.builder is untouched).
void configureFriendlyErrorWidget() {
  ErrorWidget.builder = (details) {
    debugPrint('HBT_BUSINESS widget error: ${details.exception}');
    return _FriendlyErrorWidget(details: details);
  };
}

/// Friendly replacement for the default red/grey error widget.
class _FriendlyErrorWidget extends StatelessWidget {
  const _FriendlyErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The error has been recorded. Please restart the app and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class HbtBusinessApp extends StatefulWidget {
  const HbtBusinessApp({super.key, this.restoreSession = true});

  final bool restoreSession;

  static void start() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const HbtBusinessApp());
  }

  @override
  State<HbtBusinessApp> createState() => _HbtBusinessAppState();
}

class _HbtBusinessAppState extends State<HbtBusinessApp> {
  final _session = SessionController(
    api: ApiClient(baseUrl: AppConfig.apiBaseUrl),
    storage: const FlutterSecureStorage(),
  );

  late final DeviceRegistry _registry;
  late final ConnectivityMonitor _monitor;
  SyncManager? _syncManager;

  @override
  void initState() {
    super.initState();
    _registry = DeviceRegistry(api: _session.api);
    _monitor = ConnectivityMonitor(baseUrl: AppConfig.apiBaseUrl);
    _session.addListener(_onSessionChanged);
    _bootstrapOffline();
    if (widget.restoreSession) {
      _session.restore();
    } else {
      _session.loading = false;
    }
  }

  /// Activate the offline infrastructure (previously 100% dead code):
  /// device identity, encrypted local database, sync manager, connectivity.
  Future<void> _bootstrapOffline() async {
    try {
      await _registry.initialize();
      // Opening the encrypted DB is best-effort: the app must still work
      // if secure storage or the filesystem is unavailable.
      await AppDatabase.instance.initialize();
      _syncManager = SyncManager(
        api: _session.api,
        database: AppDatabase.instance,
        device: _registry,
      );
      debugPrint('HBT_BUSINESS offline bootstrap complete');
    } catch (e) {
      debugPrint('HBT_BUSINESS offline bootstrap failed: $e');
    }
  }

  void _onSessionChanged() {
    // Register the device with the backend once the user is authenticated.
    if (_session.authenticated && !_registry.registered) {
      _registry.register(
        platform: _platformName(),
        appVersion: '1.0.0',
        deviceName: null,
      );
    }
    if (!_session.authenticated && _registry.registered) {
      _registry.clear();
    }
    if (mounted) setState(() {});
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'android';
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _monitor.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _session,
    builder: (context, _) => MaterialApp(
      title: 'HBT Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff00695c)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Offline banner across the whole app.
        return Column(
          children: [
            AnimatedBuilder(
              animation: _monitor,
              builder: (context, _) => _monitor.isOnline
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      color: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: const Text(
                        'Offline — data may be out of date',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            Expanded(child: child!),
          ],
        );
      },
      home: _session.loading
          ? const _LoadingScreen()
          : _session.authenticated
          ? BusinessHome(
              session: _session,
              registry: _registry,
              monitor: _monitor,
              syncManager: _syncManager,
            )
          : SignInScreen(session: _session),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
