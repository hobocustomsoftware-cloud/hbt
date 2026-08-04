import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Design-system alert banner (component library §2 — color-alerted strips).
///
/// Severity drives the icon + tint: danger (red) / warning (amber) / info.
/// Used for delayed trips, cancelled trips, cargo exceptions, refunds.
class HbtAlertBanner extends StatelessWidget {
  const HbtAlertBanner({
    super.key,
    required this.message,
    this.severity = HbtAlertSeverity.info,
    this.onTap,
  });

  final String message;
  final HbtAlertSeverity severity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (severity) {
      HbtAlertSeverity.danger => HbtColors.danger,
      HbtAlertSeverity.warning => HbtColors.warning,
      HbtAlertSeverity.info => HbtColors.info,
    };
    final icon = switch (severity) {
      HbtAlertSeverity.danger => Icons.error_outline,
      HbtAlertSeverity.warning => Icons.warning_amber_rounded,
      HbtAlertSeverity.info => Icons.info_outline,
    };
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(HbtRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HbtRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HbtSpacing.md,
            vertical: HbtSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(icon, size: HbtIconSize.sm, color: color),
              const SizedBox(width: HbtSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: HbtTypography.caption.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum HbtAlertSeverity { danger, warning, info }
