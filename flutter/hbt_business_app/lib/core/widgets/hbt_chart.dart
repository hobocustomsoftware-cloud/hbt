import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

// =============================================================================
//  CHART COMPONENTS (W1-001 — design system, no data wiring)
// =============================================================================
//
// Chart primitives for dashboards. One chart type per question
// (ui_reference_library §2.5): line = trend, bars = comparison.
// Data wiring arrives with the Owner Dashboard (Wave 2).

/// A titled card that hosts a chart (component library §1.2).
///
/// Anatomy: title + optional period label · chart canvas · optional drill link.
class HbtChartCard extends StatelessWidget {
  const HbtChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.onDrill,
    this.drillLabel,
    this.height = 200,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final VoidCallback? onDrill;
  final String? drillLabel;
  final double height;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: HbtSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: HbtTypography.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: HbtSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: HbtTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: HbtSpacing.md),
              SizedBox(height: height, width: double.infinity, child: child),
              if (onDrill != null && drillLabel != null) ...[
                const SizedBox(height: HbtSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onDrill,
                    child: Text(drillLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

/// A lightweight sparkline (polyline) — trend at a glance.
class HbtSparkline extends StatelessWidget {
  const HbtSparkline({
    super.key,
    required this.values,
    this.color,
    this.strokeWidth = 2,
    this.fill = true,
  });

  /// Y values; rendered left→right, normalised to the box height.
  final List<double> values;
  final Color? color;
  final double strokeWidth;
  final bool fill;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color ?? Theme.of(context).colorScheme.primary,
          strokeWidth: strokeWidth,
          fill: fill,
        ),
        size: Size.infinite,
      );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.fill,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Horizontal mini-bars for comparisons (top routes / branches).
class HbtMiniBars extends StatelessWidget {
  const HbtMiniBars({
    super.key,
    required this.items,
    this.barColor,
    this.maxValue,
  });

  /// Pairs of (label, value) — value normalised against [maxValue].
  final List<(String, double)> items;
  final Color? barColor;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    final maxV = maxValue ??
        items.fold<double>(0, (acc, item) => math.max(acc, item.$2));
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final color = barColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    item.$1,
                    style: HbtTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: HbtSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(HbtRadius.xs),
                    child: LinearProgressIndicator(
                      value: (item.$2 / safeMax).clamp(0.0, 1.0),
                      minHeight: 10,
                      color: color,
                      backgroundColor:
                          color.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                const SizedBox(width: HbtSpacing.sm),
                Text(
                  item.$2.toStringAsFixed(0),
                  style: HbtTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
