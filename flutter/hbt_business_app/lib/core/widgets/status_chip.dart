import 'package:flutter/material.dart';

/// A colored [Chip] for displaying status labels consistently.
///
/// Merges the 4 separate `_statusColor()` maps into one shared truth.
///
/// Colors are mapped from status string → color. Any unrecognised status
/// defaults to grey.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.customColors,
  });

  final String status;
  final Map<String, Color>? customColors;

  /// Default color map covering trip, route, ticket, and cargo statuses.
  static const Map<String, Color> defaultColors = {
    // Route statuses
    'active': Colors.green,
    'draft': Colors.grey,
    'approved': Colors.blue,
    'suspended': Colors.orange,
    'retired': Colors.red,
    'archived': Colors.red,
    // Trip statuses
    'planned': Colors.grey,
    'ready': Colors.blue,
    'boarding': Colors.orange,
    'departed': Colors.amber,
    'in_progress': Colors.teal,
    'delayed': Colors.red,
    'interrupted': Colors.deepOrange,
    'arrived': Colors.green,
    'completed': Colors.green,
    'closed': Colors.grey,
    'cancelled': Colors.red,
    // Ticket statuses
    'issued': Colors.blue,
    'validated': Colors.green,
    'boarded': Colors.teal,
    'reissued': Colors.orange,
    // Cargo statuses
    'accepted': Colors.blue,
    'assigned': Colors.indigo,
    'loaded': Colors.amber,
    'in_transit': Colors.teal,
    'ready_pickup': Colors.orange,
    'handed_over': Colors.green,
  };

  Color get _color => (customColors ?? defaultColors)[status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(
          status.replaceAll('_', ' '),
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
        backgroundColor: _color,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
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
      (customColors ?? StatusChip.defaultColors)[status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        backgroundColor: _color.withAlpha(40),
        child: Icon(icon, color: _color),
      );
}
