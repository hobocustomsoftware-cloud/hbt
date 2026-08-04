import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// A colored [Chip] for displaying status labels consistently (W1-001).
///
/// Design-system version: semantic colors ONLY (success/warning/danger/info +
/// neutral), tinted container + colored dot + readable label — no random
/// colors (theme_guidelines §4). Any unrecognised status defaults to neutral.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.customColors,
  });

  final String status;
  final Map<String, Color>? customColors;

  /// Default color map covering trip, route, ticket, and cargo statuses —
  /// mapped to the four semantic tokens + neutral.
  static const Map<String, Color> defaultColors = {
    // Route statuses
    'active': HbtColors.success,
    'draft': HbtColors.neutral,
    'approved': HbtColors.info,
    'suspended': HbtColors.warning,
    'retired': HbtColors.danger,
    'archived': HbtColors.danger,
    // Trip statuses
    'planned': HbtColors.neutral,
    'ready': HbtColors.info,
    'boarding': HbtColors.warning,
    'departed': HbtColors.warning,
    'in_progress': HbtColors.info,
    'delayed': HbtColors.danger,
    'interrupted': HbtColors.danger,
    'arrived': HbtColors.success,
    'completed': HbtColors.success,
    'closed': HbtColors.neutral,
    'cancelled': HbtColors.danger,
    // Ticket statuses
    'issued': HbtColors.info,
    'validated': HbtColors.success,
    'boarded': HbtColors.info,
    'reissued': HbtColors.warning,
    // Cargo statuses
    'accepted': HbtColors.info,
    'assigned': HbtColors.info,
    'loaded': HbtColors.warning,
    'in_transit': HbtColors.info,
    'ready_pickup': HbtColors.warning,
    'handed_over': HbtColors.success,
    // Shift / settlement
    'open': HbtColors.success,
    'closed_ok': HbtColors.success,
    'difference': HbtColors.warning,
  };

  Color get _color => (customColors ?? defaultColors)[status] ?? HbtColors.neutral;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HbtSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HbtRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A [CircleAvatar] colored by status, used as leading icon in list tiles.
class StatusAvatar extends StatelessWidget {
  const StatusAvatar({
    super.key,
    required this.status,
    required this.icon,
    this.customColors,
  });

  final String status;
  final IconData icon;
  final Map<String, Color>? customColors;

  Color get _color =>
      (customColors ?? StatusChip.defaultColors)[status] ?? HbtColors.neutral;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color),
    );
  }
}
