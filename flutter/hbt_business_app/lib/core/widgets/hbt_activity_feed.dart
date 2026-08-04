import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Design-system activity feed (component library §3.2).
///
/// Reverse-chronological one-line entries: icon · text · time.
class HbtActivityFeed extends StatelessWidget {
  const HbtActivityFeed({
    super.key,
    required this.title,
    required this.entries,
    this.emptyMessage = 'No recent activity',
  });

  final String title;
  final List<HbtActivityEntry> entries;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: HbtSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: HbtTypography.bodyStrong),
            const SizedBox(height: HbtSpacing.md),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: HbtSpacing.xl),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: HbtTypography.caption.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                _ActivityRow(entry: entries[i]),
                if (i != entries.length - 1)
                  Divider(height: HbtSpacing.md + 4, color: cs.outlineVariant),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final HbtActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HbtSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.color?.withValues(alpha: 0.12) ??
                  cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(HbtRadius.sm),
            ),
            child: Icon(
              entry.icon,
              size: 16,
              color: entry.color ?? cs.primary,
            ),
          ),
          const SizedBox(width: HbtSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: HbtTypography.body.copyWith(fontSize: 13.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.time != null)
                  Text(
                    entry.time!,
                    style: HbtTypography.caption.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HbtActivityEntry {
  const HbtActivityEntry({
    required this.icon,
    required this.text,
    this.time,
    this.color,
  });

  final IconData icon;
  final String text;
  final String? time;
  final Color? color;
}
