import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  RESPONSIVE DATA TABLE
// =============================================================================

/// A responsive data table with Material 3 styling.
///
/// On wider screens it renders as a [DataTable]. On narrow screens it
/// renders each row as a [Card] with [TableRowBuilder] for the detail layout.
///
/// Usage:
/// ```dart
/// ResponsiveDataTable(
///   columns: const ['#', 'Name', 'Status', 'Amount'],
///   rows: items,
///   rowBuilder: (item, index) => [
///     Text('${index + 1}'),
///     Text(item.name),
///     StatusChip(status: item.status),
///     Text('${item.amount}'),
///   ],
///   detailCard: (item, index) => Column(
///     children: [
///       Text(item.name, style: titleMedium),
///       Text(item.description),
///     ],
///   ),
/// )
/// ```
class ResponsiveDataTable<T> extends StatelessWidget {
  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowBuilder,
    this.detailCard,
    this.onRowTap,
    this.striped = true,
    this.emptyMessage = 'No data.',
    this.narrowBreakpoint = 600,
  });

  final List<String> columns;
  final List<T> rows;
  final List<Widget> Function(T item, int index) rowBuilder;
  final Widget Function(T item, int index)? detailCard;
  final void Function(T item)? onRowTap;
  final bool striped;
  final String emptyMessage;
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXxl),
          child: Text(
            emptyMessage,
            style: AppTheme.sectionSubtitleStyle(context),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < narrowBreakpoint;

    if (isNarrow && detailCard != null) {
      return _buildCardList(context);
    }

    return _buildDataTable(context);
  }

  Widget _buildDataTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
        border: TableBorder(
          horizontalInside: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        columns: [
          for (final col in columns)
            DataColumn(
              label: Text(
                col,
                style: AppTheme.dataLabelStyle(context),
              ),
            ),
        ],
        rows: [
          for (var i = 0; i < rows.length; i++)
            DataRow(
              color: striped && i.isOdd
                  ? WidgetStateProperty.all(cs.surfaceContainerLow)
                  : null,
              onSelectChanged: onRowTap != null
                  ? (_) => onRowTap!(rows[i])
                  : null,
              cells: [
                for (final widget in rowBuilder(rows[i], i))
                DataCell(widget),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    final detailBuilder = detailCard!;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, i) {
        final item = rows[i];
        final cells = rowBuilder(item, i);
        final detail = detailBuilder(item, i);

        return Card(
          child: InkWell(
            onTap: onRowTap != null ? () => onRowTap!(item) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: AppTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detail,
                  const Divider(),
                  // Show a compact summary row from first few cell values
                  if (cells.length >= 2)
                    Row(
                      children: [
                        Expanded(flex: 2, child: cells[0]),
                        Expanded(flex: 3, child: cells[1]),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A simple two-column info table (label : value) for detail screens.
///
/// Usage:
/// ```dart
/// InfoTable(rows: [
///   InfoTableRow(label: 'Name', value: 'John'),
///   InfoTableRow(label: 'Phone', value: '09...'),
/// ])
/// ```
class InfoTable extends StatelessWidget {
  const InfoTable({
    super.key,
    required this.rows,
    this.labelWidth = 140,
    this.divider = true,
  });

  final List<InfoTableRow> rows;
  final double labelWidth;
  final bool divider;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (divider && i > 0)
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(
                      rows[i].label,
                      style: AppTheme.dataLabelStyle(context),
                    ),
                  ),
                  Expanded(
                    child: rows[i].valueWidget ??
                        Text(
                          rows[i].value,
                          style: AppTheme.dataValueStyle(context),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

/// A single row for [InfoTable].
class InfoTableRow {
  const InfoTableRow({
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
}
