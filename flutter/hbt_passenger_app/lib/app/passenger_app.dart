import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/registration_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/trip/presentation/trip_detail_screen.dart';
import '../features/booking/presentation/booking_screen.dart';

/// Friendly replacement for the default red/grey error widget.
/// Installs the app-wide friendly error widget. Called from [main] so the
/// real app gets the boundary; tests that pump the widget directly are not
/// affected (flutter_test asserts ErrorWidget.builder is untouched).
void configureFriendlyErrorWidget() {
  ErrorWidget.builder = (details) {
    debugPrint('HBT_PASSENGER widget error: ${details.exception}');
    return _FriendlyErrorWidget(details: details);
  };
}

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

/// HBT Passenger self-service app widget.
class PassengerApp extends StatefulWidget {
  const PassengerApp({super.key, required this.auth});

  final AuthController auth;

  @override
  State<PassengerApp> createState() => _PassengerAppState();
}

class _PassengerAppState extends State<PassengerApp> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _init();
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await widget.auth.tryRestore();
    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HBT Passenger',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => child!,
        initialRoute: '/splash',
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => _buildHome(),
        ),
      );

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final auth = widget.auth;

    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(
          builder: (_) => SplashScreen(auth: auth),
        );

      case '/login':
        return MaterialPageRoute(
          builder: (_) => LoginScreen(auth: auth),
        );

      case '/register':
        return MaterialPageRoute(
          builder: (_) => RegistrationScreen(auth: auth),
        );

      case '/home':
        return MaterialPageRoute(
          builder: (_) => HomeScreen(auth: auth),
        );

      case '/tickets':
        return MaterialPageRoute(
          builder: (_) => HomeScreen(auth: auth, initialTab: 1),
        );

      case '/trip-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final trip = args?['trip'] as Map<String, dynamic>?;
        final pickupStopId = args?['pickup_stop'] as String?;
        final dropoffStopId = args?['dropoff_stop'] as String?;
        if (trip != null) {
          return MaterialPageRoute(
            builder: (_) => TripDetailScreen(
              auth: auth,
              trip: trip,
              pickupStopId: pickupStopId,
              dropoffStopId: dropoffStopId,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => _buildHome(),
        );

      case '/booking':
        final args = settings.arguments as Map<String, dynamic>?;
        final trip = args?['trip'] as Map<String, dynamic>?;
        final pickupStopId = args?['pickup_stop'] as String?;
        final dropoffStopId = args?['dropoff_stop'] as String?;
        if (trip != null) {
          return MaterialPageRoute(
            builder: (_) => BookingScreen(
              auth: auth,
              trip: trip,
              pickupStopId: pickupStopId,
              dropoffStopId: dropoffStopId,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => _buildHome(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => _buildHome(),
        );
    }
  }

  Widget _buildHome() {
    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.auth.authenticated) {
      return HomeScreen(auth: widget.auth);
    }
    return RegistrationScreen(auth: widget.auth);
  }
}
