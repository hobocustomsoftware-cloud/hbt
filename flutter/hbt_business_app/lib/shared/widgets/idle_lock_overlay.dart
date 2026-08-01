import 'package:flutter/material.dart';

import '../services/idle_timeout_controller.dart';

/// Full-screen lock overlay shown after the idle session timeout.
///
/// Displays while [controller].locked is true; tapping Unlock calls
/// [controller].unlock(). The caller is responsible for deciding whether
/// re-authentication is required (e.g. navigating to login when the session
/// was lost while idle).
class IdleLockOverlay extends StatelessWidget {
  const IdleLockOverlay({super.key, required this.controller});

  final IdleTimeoutController controller;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Colors.teal),
                  const SizedBox(height: 12),
                  const Text(
                    'Session idle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: controller.unlock,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
