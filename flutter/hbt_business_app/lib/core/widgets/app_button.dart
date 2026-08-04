import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

// =============================================================================
//  BUTTON VARIANTS
// =============================================================================

/// A [FilledButton] that shows a [CircularProgressIndicator] while [busy]
/// is true. Disables itself when [busy] or when [onPressed] is null.
///
/// Replaces the inline busy/spinner + label pattern in every form screen.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.expanded = true,
    this.height,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Widget? icon;
  final bool expanded;
  final double? height;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      style: height != null
          ? FilledButton.styleFrom(
              minimumSize: Size.fromHeight(height!),
            )
          : null,
      onPressed: busy ? null : onPressed,
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                if (busyLabel != null) ...[
                  const SizedBox(width: 8),
                  Text(busyLabel!),
                ],
              ],
            )
          : icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                )
              : Text(label),
    );
    if (expanded) {
      return SizedBox(
        width: double.infinity,
        height: height ?? HbtSize.minButtonHeight,
        child: button,
      );
    }
    return SizedBox(
      height: height ?? HbtSize.minButtonHeight,
      child: button,
    );
  }
}

/// A [FilledButton.icon] variant with consistent sizing and busy state.
class BusyButtonIcon extends StatelessWidget {
  const BusyButtonIcon({
    super.key,
    required this.label,
    required this.iconData,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData iconData;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(iconData),
        label: Text(label),
      );
}

/// A pair of [OutlinedButton] (secondary) and [FilledButton] (primary)
/// for binary actions (confirm/reject, approve/deny).
///
/// Each button takes equal width.
class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({
    super.key,
    required this.primaryLabel,
    required this.primaryOnPressed,
    this.secondaryLabel,
    this.secondaryOnPressed,
    this.primaryBusy = false,
    this.secondaryBusy = false,
    this.primaryIcon,
    this.secondaryIcon,
    this.secondaryDanger = false,
    this.spacing = HbtSpacing.md,
  });

  final String primaryLabel;
  final VoidCallback? primaryOnPressed;
  final String? secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final bool primaryBusy;
  final bool secondaryBusy;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final bool secondaryDanger;
  final double spacing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              child: SizedBox(
                height: HbtSize.minButtonHeight,
                child: secondaryDanger
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        onPressed: secondaryBusy ? null : secondaryOnPressed,
                        icon: secondaryBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : secondaryIcon != null
                                ? Icon(secondaryIcon)
                                : null,
                        label: Text(secondaryLabel!),
                      )
                    : OutlinedButton.icon(
                        onPressed: secondaryBusy ? null : secondaryOnPressed,
                        icon: secondaryBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : secondaryIcon != null
                                ? Icon(secondaryIcon)
                                : null,
                        label: Text(secondaryLabel!),
                      ),
              ),
            ),
            SizedBox(width: spacing),
          ],
          Expanded(
            child: SizedBox(
              height: HbtSize.minButtonHeight,
              child: FilledButton.icon(
                onPressed: primaryBusy ? null : primaryOnPressed,
                icon: primaryBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : primaryIcon != null
                        ? Icon(primaryIcon)
                        : null,
                label: Text(primaryLabel),
              ),
            ),
          ),
        ],
      );
}

/// An [ActionChip] styled as a compact inline button for per-row actions
/// (e.g. status transitions, trip actions).
class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: icon != null ? Icon(icon, size: 18) : null,
        label: Text(
          label,
          style: compact
              ? const TextStyle(fontSize: 11)
              : null,
        ),
        onPressed: onPressed,
        backgroundColor: color,
        visualDensity: compact ? VisualDensity.compact : null,
      );
}

/// A permission-gated [FilledButton]. Renders the button only if the
/// session has the required permission.
///
/// When permission is missing:
/// - [fallback] is shown if provided, otherwise [disabledLabel] is shown
///   as a disabled button (or [disabledFallback] if that's not null).
class PermissionedButton extends StatelessWidget {
  const PermissionedButton({
    super.key,
    required this.hasPermission,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expanded = true,
    this.disabledLabel,
    this.fallback,
    this.variant = PermissionedButtonVariant.filled,
  });

  final bool hasPermission;
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool busy;
  final bool expanded;
  final String? disabledLabel;
  final Widget? fallback;
  final PermissionedButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      if (fallback != null) return fallback!;
      if (disabledLabel == null) return const SizedBox.shrink();
      // Render disabled button with fallback label.
      return switch (variant) {
        PermissionedButtonVariant.filled => BusyButton(
            label: disabledLabel!,
            onPressed: null,
            expanded: expanded,
          ),
        PermissionedButtonVariant.outlined => SizedBox(
            width: expanded ? double.infinity : null,
            height: HbtSize.minButtonHeight,
            child: OutlinedButton(
              onPressed: null,
              child: Text(disabledLabel!),
            ),
          ),
        PermissionedButtonVariant.text => TextButton(
            onPressed: null,
            child: Text(disabledLabel!),
          ),
      };
    }
    return switch (variant) {
      PermissionedButtonVariant.filled => BusyButton(
          label: label,
          onPressed: onPressed,
          busy: busy,
          icon: icon,
          expanded: expanded,
        ),
      PermissionedButtonVariant.outlined => SizedBox(
          width: expanded ? double.infinity : null,
          height: HbtSize.minButtonHeight,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onPressed,
            icon: icon,
            label: Text(label),
          ),
        ),
      PermissionedButtonVariant.text => TextButton.icon(
          onPressed: busy ? null : onPressed,
          icon: icon,
          label: Text(label),
        ),
    };
  }
}

enum PermissionedButtonVariant { filled, outlined, text }
