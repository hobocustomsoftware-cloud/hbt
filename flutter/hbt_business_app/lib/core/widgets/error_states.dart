import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

// =============================================================================
//  ERROR & STATUS STATE WIDGETS (design-system re-skin, W1-001)
// =============================================================================
//
// Canonical error/status components. LoadingView / EmptyView / EmptyListTileCard /
// InlineLoading / skeleton components live in async_views.dart (canonical home);
// this file re-exports are consumed there via `export`.
//
// AppTheme (teal) removed — all styling comes from HbtTokens/HbtTheme.

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
          padding: const EdgeInsets.all(HbtSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? Icons.error_outline,
                size: HbtIconSize.lg,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: HbtSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: HbtTypography.bodyStrong,
              ),
              const SizedBox(height: HbtSpacing.md),
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
        padding: const EdgeInsets.all(HbtSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline,
                size: HbtIconSize.sm,
                color: cs.onErrorContainer),
            const SizedBox(width: HbtSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: cs.onErrorContainer),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: HbtSpacing.sm),
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
        padding: const EdgeInsets.all(HbtSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: HbtIconSize.sm,
                color: cs.onTertiaryContainer),
            const SizedBox(width: HbtSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: cs.onTertiaryContainer),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: HbtSpacing.sm),
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
        backgroundColor: color ?? HbtColors.secondary,
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
          left: HbtSpacing.md,
          top: HbtSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: HbtIconSize.sm - 2,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: HbtSpacing.xs),
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
    this.label = 'ပြန်ကြိုးစားမည်',
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
