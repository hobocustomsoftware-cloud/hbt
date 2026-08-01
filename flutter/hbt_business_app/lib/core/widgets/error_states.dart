import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  ERROR & STATUS STATE WIDGETS
// =============================================================================

/// Full-screen error display with icon, message, and retry button.
///
/// Replaces the 12-line error UI block identical in 7+ screens.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
    this.icon,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? Icons.error_outline,
                size: AppTheme.iconLg,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.dataValueStyle(context),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
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
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline,
                size: AppTheme.iconSm,
                color: cs.onErrorContainer),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: cs.onErrorContainer),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onErrorContainer,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An inline warning card for non-critical issues.
class WarningCard extends StatelessWidget {
  const WarningCard({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: AppTheme.iconSm,
                color: cs.onTertiaryContainer),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: cs.onTertiaryContainer),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onTertiaryContainer,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A snackbar/toast helper for showing messages at the bottom of the screen.
///
/// Usage:
/// ```dart
/// Toast.error(context, 'Something went wrong');
/// Toast.success(context, 'Done!');
/// Toast.info(context, 'Note saved');
/// ```
class Toast {
  Toast._();

  /// Show an error snackbar.
  static void error(BuildContext context, String message) {
    _show(context, message,
        color: Theme.of(context).colorScheme.error);
  }

  /// Show a success snackbar.
  static void success(BuildContext context, String message) {
    _show(context, message,
        color: Theme.of(context).colorScheme.primary);
  }

  /// Show an info snackbar.
  static void info(BuildContext context, String message) {
    _show(context, message);
  }

  /// Show a warning snackbar.
  static void warning(BuildContext context, String message) {
    _show(context, message,
        color: Theme.of(context).colorScheme.tertiary);
  }

  static void _show(
    BuildContext context,
    String message, {
    Color? color,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: color,
      ),
    );
  }
}

/// An error banner placed at the top of a form/page body.
///
/// Unlike [ErrorCard], this is a full-width banner with a dismiss action.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: cs.errorContainer,
      content: Text(
        message,
        style: TextStyle(color: cs.onErrorContainer),
      ),
      leading: Icon(Icons.error_outline, color: cs.onErrorContainer),
      actions: [
        if (onDismiss != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: cs.onErrorContainer,
            ),
            onPressed: onDismiss,
            child: const Text('DISMISS'),
          ),
      ],
    );
  }
}

/// Inline validation error text to show below a form field.
class ValidationError extends StatelessWidget {
  const ValidationError({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: AppTheme.spacingMd,
          top: AppTheme.spacingXs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: AppTheme.iconSm - 2,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
}

/// A retry button shown after a failed operation.
class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    required this.onRetry,
    this.label = 'ထပ်မံကြိုးစားရန်',
    this.busy = false,
  });

  final VoidCallback onRetry;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: busy ? null : onRetry,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(label),
      );
}
