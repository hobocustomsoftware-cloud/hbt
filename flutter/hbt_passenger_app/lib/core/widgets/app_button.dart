import 'package:flutter/material.dart';

/// A [FilledButton] that shows a [CircularProgressIndicator] while [busy]
/// is true. Disables itself when [busy] or when [onPressed] is null.
///
/// Eliminates the inline busy/spinner pattern repeated in every form screen.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.expanded = true,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Widget? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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
      return SizedBox(width: double.infinity, height: height, child: button);
    }
    return SizedBox(height: height, child: button);
  }
}

/// A [FilledButton.icon] variant with consistent sizing.
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

/// A row of a secondary [OutlinedButton] on the left and a primary
/// [FilledButton] on the right, each taking equal width.
///
/// Used in confirm/reject, home/tickets, and similar binary-action layouts.
class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({
    super.key,
    required this.primaryLabel,
    required this.primaryOnPressed,
    this.secondaryLabel,
    this.secondaryOnPressed,
    this.primaryBusy = false,
  });

  final String primaryLabel;
  final VoidCallback? primaryOnPressed;
  final String? secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final bool primaryBusy;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: secondaryOnPressed,
                child: Text(secondaryLabel!),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: primaryBusy ? null : primaryOnPressed,
              child: primaryBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ],
      );
}

/// A rectangular action chip used for per-row operations (e.g. status
/// transitions in trip list, cargo worklist actions).
class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: icon != null ? Icon(icon, size: 18) : null,
        label: Text(label),
        onPressed: onPressed,
      );
}
