import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Design-system Quick Action tile (component library §3.3).
///
/// A large touch tile (≥64px) for the dashboard's next-action grid.
/// Distinct from data cards: icon + label, no chevron, generous target.
class HbtQuickActionTile extends StatelessWidget {
  const HbtQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.badge,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? badge;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HbtSpacing.md,
            vertical: HbtSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(HbtRadius.md),
                ),
                child: Icon(
                  icon,
                  size: HbtIconSize.md,
                  color: enabled ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: HbtSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: HbtTypography.bodyStrong.copyWith(
                    color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null && badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HbtSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: HbtColors.danger,
                    borderRadius: BorderRadius.circular(HbtRadius.pill),
                  ),
                  child: Text(
                    '$badge',
                    style: HbtTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
