import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

/// Design-system time-range control (component library §3.5).
///
/// One control drives every dashboard widget: Day / Week / Month / Year.
/// Material 3 [SegmentedButton] styled with brand tokens.
class HbtTimeRangeSelector extends StatelessWidget {
  const HbtTimeRangeSelector({
    super.key,
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  final List<DashboardPeriodSegment> periods;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SegmentedButton<String>(
      segments: [
        for (final p in periods)
          ButtonSegment(
            value: p.value,
            label: Text(p.label),
            icon: p.icon != null ? Icon(p.icon, size: 16) : null,
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          HbtTypography.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? cs.primary
              : cs.onSurfaceVariant,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: cs.outlineVariant),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
      ),
    );
  }
}

class DashboardPeriodSegment {
  const DashboardPeriodSegment({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final IconData? icon;
}
