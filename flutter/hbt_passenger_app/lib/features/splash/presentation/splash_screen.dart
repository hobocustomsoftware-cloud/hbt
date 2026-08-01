import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';

/// Splash screen shown while the app initialises and attempts to restore
/// a previous session.
///
/// ## Flow
/// 1. Show branding logo + loading spinner
/// 2. `AuthController.tryRestore()` runs
/// 3. Route to:
///    - `/home` if authenticated
///    - `/login` if registration screen is preferred flow
///      (passenger app routes unauthenticated users to RegistrationScreen
///       from PassengerApp; this screen navigates accordingly)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Give the splash a moment to render before starting work
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (widget.auth.authenticated || widget.auth.user != null) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    // tryRestore was already called in PassengerApp._init() before
    // the splash was shown. If not authenticated after restore, go to
    // the registration/login flow.
    if (mounted) {
      // The passenger app's buildHome() already routes unauthenticated
      // users to RegistrationScreen — so we just navigate to the root
      Navigator.of(context).pushReplacementNamed('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'HBT Passenger',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bus ticketing made simple',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 48),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
