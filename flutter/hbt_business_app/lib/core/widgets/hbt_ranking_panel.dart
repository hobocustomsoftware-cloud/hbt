import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Design-system ranking panel (component library: Branch/Routes/Vehicles).
///
/// A titled card listing ranked rows (name · revenue · trips) with a share
/// bar, e.g. Top Routes, Top Vehicles, Branch Performance.
class HbtRankingPanel extends StatelessWidget {
  const HbtRankingPanel({
    super.key,
    required this.title,
    required this.rows,
    this.icon,
    this.emptyMessage = 'No data for this period',
  });

  final String title;
  final IconData? icon;

  /// Ranked rows with a numeric value (revenue) + optional secondary count.
  final List<HbtRankingRow> rows;
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
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: HbtIconSize.sm, color: cs.primary),
                  const SizedBox(width: HbtSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: HbtTypography.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HbtSpacing.md),
            if (rows.isEmpty)
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
              for (var i = 0; i < rows.length; i++) ...[
                _RankingRowView(row: rows[i], rank: i + 1),
                if (i != rows.length - 1)
                  Divider(height: HbtSpacing.md + 4, color: cs.outlineVariant),
              ],
          ],
        ),
      ),
    );
  }
}

class _RankingRowView extends StatelessWidget {
  const _RankingRowView({required this.row, required this.rank});

  final HbtRankingRow row;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: HbtTypography.caption.copyWith(
              color: rank <= 3 ? cs.primary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: HbtSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.name,
                style: HbtTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (row.secondary != null)
                Text(
                  row.secondary!,
                  style: HbtTypography.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          row.value,
          style: HbtTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Row view model — decoupled from the API model so this widget is reusable.
class HbtRankingRow {
  const HbtRankingRow({
    required this.name,
    required this.value,
    this.secondary,
  });

  final String name;
  final String value;
  final String? secondary;
}
