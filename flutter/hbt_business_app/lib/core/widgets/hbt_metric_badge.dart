import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Design-system Metric Badge (component library §1.5).
///
/// A pill (radius 999) with a value/status; colors are semantic only.
class HbtMetricBadge extends StatelessWidget {
  const HbtMetricBadge({
    super.key,
    required this.label,
    this.tone = HbtTone.neutral,
    this.icon,
  });

  final String label;
  final HbtTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      HbtTone.success => HbtColors.success,
      HbtTone.warning => HbtColors.warning,
      HbtTone.danger => HbtColors.danger,
      HbtTone.info => HbtColors.info,
      HbtTone.neutral => HbtColors.neutral,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HbtSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HbtRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: HbtTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum HbtTone { success, warning, danger, info, neutral }
