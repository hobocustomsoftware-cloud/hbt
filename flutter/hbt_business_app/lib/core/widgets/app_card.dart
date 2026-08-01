import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  CARD VARIANTS
// =============================================================================

/// A [Card] + [ListTile] in one configurable widget.
///
/// Replaces the `Card(child: ListTile(...))` pattern used everywhere for
/// booking cards, shipment cards, ticket cards, trip cards, quick actions.
class AppListTileCard extends StatelessWidget {
  const AppListTileCard({
    super.key,
    this.leadingIcon,
    this.leadingWidget,
    this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailingIcon,
    this.trailingWidget,
    this.onTap,
    this.color,
    this.margin,
    this.isThreeLine = false,
    this.dense = false,
  });

  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final String? title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData? trailingIcon;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final bool isThreeLine;
  final bool dense;

  @override
  Widget build(BuildContext context) => Card(
        color: color,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          leading: leadingWidget ??
              (leadingIcon != null ? Icon(leadingIcon) : null),
          title: title != null ? Text(title!) : null,
          subtitle: subtitleWidget ??
              (subtitle != null
                  ? subtitle!.contains('\n')
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subtitle!
                              .split('\n')
                              .map((line) => Text(line))
                              .toList(),
                        )
                      : Text(subtitle!)
                  : null),
          trailing: trailingWidget ??
              (trailingIcon != null
                  ? Icon(trailingIcon)
                  : onTap != null
                      ? const Icon(Icons.chevron_right)
                      : null),
          onTap: onTap,
          isThreeLine: isThreeLine,
          dense: dense,
        ),
      );
}

/// A card with a title, optional subtitle, divider, and child widgets.
///
/// Used for entity detail sections (trip info, route info, payment detail).
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.titleColor,
    this.leadingIcon,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Color? titleColor;
  final IconData? leadingIcon;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: padding ?? AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon),
                    const SizedBox(width: AppTheme.spacingSm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: (titleColor != null
                              ? TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                )
                              : null) ??
                          Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  subtitle!,
                  style: AppTheme.sectionSubtitleStyle(context),
                ),
              ],
              const Divider(),
              ...children,
            ],
          ),
        ),
      );
}

/// A label:value row for use inside [InfoCard] children or detail views.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 120,
    this.valueWidget,
  });

  final String label;
  final String value;
  final double labelWidth;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                '$label:',
                style: AppTheme.dataLabelStyle(context),
              ),
            ),
            Expanded(
              child: valueWidget ?? Text(value),
            ),
          ],
        ),
      );
}

/// A dashboard-style quick action card (icon + label + chevron).
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.subtitle,
    this.margin,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? subtitle;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Card(
        margin:
            margin ?? const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

/// A summary/metric card for dashboards (e.g. "Total Bookings", "Revenue").
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = color ?? cs.primaryContainer;
    final fgColor = color != null
        ? cs.onSurface
        : cs.onPrimaryContainer;

    return Card(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: fgColor, size: AppTheme.iconMd),
                const SizedBox(width: AppTheme.spacingMd),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: fgColor,
                          ),
                    ),
                    Text(
                      label,
                      style: AppTheme.dataLabelStyle(context)
                          .copyWith(color: fgColor.withAlpha(200)),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style:
                            AppTheme.sectionSubtitleStyle(context).copyWith(
                              color: fgColor.withAlpha(160),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A timeline event card used in refund/order detail history.
///
/// Renders an icon, label, optional subtitle, and formatted timestamp.
class TimelineEventCard extends StatelessWidget {
  const TimelineEventCard({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.timestamp,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String timestamp;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppTheme.iconSm + 2, color: color),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.cardTitleStyle(context)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: AppTheme.spacingXxs),
                    child: Text(subtitle!,
                        style: AppTheme.sectionSubtitleStyle(context)),
                  ),
              ],
            ),
          ),
          Text(
            _formatTimestamp(timestamp),
            style: AppTheme.sectionSubtitleStyle(context),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
