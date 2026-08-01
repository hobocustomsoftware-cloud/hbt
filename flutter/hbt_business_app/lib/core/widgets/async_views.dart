import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  FULL-SCREEN STATUS VIEWS
// =============================================================================

/// A centered [CircularProgressIndicator] wrapped in a [SizedBox].
///
/// Replaces `const Center(child: CircularProgressIndicator())` — 12+
/// occurrences across screens.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Full-screen error display with icon, message, and retry button.
///
/// Replaces the 12-line error UI block identical in 7+ screens.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

/// Full-screen empty state with icon, message, and optional action button.
///
/// Replaces the 8-line empty-state blocks in 4+ screens.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppTheme.iconXl, color: Colors.grey),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                message,
                style: AppTheme.sectionSubtitleStyle(context),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppTheme.spacingMd),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

/// An inline error card (not full-screen) for use inside scrollable forms.
///
/// Replaces the `Card(color: errorContainer, child: Text(_error!))` pattern
/// used in payment_decision, counter_booking, cargo_worklist, cargo_acceptance.
class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
}

/// An inline empty-state card for use inside scrollable forms.
///
/// Replaces `Card(child: ListTile(title: Text('No items.')))`.
class EmptyListTileCard extends StatelessWidget {
  const EmptyListTileCard({
    super.key,
    this.message = 'No items yet.',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(
            message,
            style: AppTheme.sectionSubtitleStyle(context),
          ),
        ),
      );
}
