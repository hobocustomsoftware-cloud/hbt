import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';
import 'hbt_chart.dart';

/// Revenue trend line chart (component library §1.2).
///
/// Renders the period revenue series (ticket + cargo stacked line) inside
/// an [HbtChartCard] with grid hairlines and compact y-axis labels.
/// Pure presentation — values come from the dashboard snapshot.
class HbtRevenueTrendChart extends StatelessWidget {
  const HbtRevenueTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.onDrill,
    this.drillLabel,
    this.height = 220,
  });

  final String title;

  /// Ordered trend points (oldest → newest) with [TrendPointView.total].
  final List<TrendPointView> points;
  final VoidCallback? onDrill;
  final String? drillLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return HbtChartCard(
      title: title,
      subtitle: 'Ticket + cargo revenue',
      onDrill: onDrill,
      drillLabel: drillLabel,
      height: height,
      child: points.length < 2
          ? Center(
              child: Text(
                'No data for this period',
                style: HbtTypography.caption.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : _TrendCanvas(points: points, color: cs.primary),
    );
  }
}

class _TrendCanvas extends StatelessWidget {
  const _TrendCanvas({required this.points, required this.color});

  final List<TrendPointView> points;
  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _TrendPainter(
            points: points,
            color: color,
            gridColor: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.6),
            labelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.labelColor,
  });

  final List<TrendPointView> points;
  final Color color;
  final Color gridColor;
  final Color labelColor;

  static const _padTop = 8.0;
  static const _padBottom = 20.0;
  static const _padLeft = 44.0;
  static const _padRight = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _padLeft - _padRight;
    final chartH = size.height - _padTop - _padBottom;
    if (chartW <= 0 || chartH <= 0) return;

    final values = points.map((p) => p.total).toList();
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    // Leave headroom so the max point isn't glued to the top edge.
    final top = maxV + range * 0.15;
    final bottom = math.max(0, minV - range * 0.15);

    double yFor(double v) =>
        _padTop + (1 - (v - bottom) / (top - bottom)) * chartH;
    double xFor(int i) => points.length == 1
        ? _padLeft + chartW / 2
        : _padLeft + (i / (points.length - 1)) * chartW;

    // Grid hairlines (4) + y labels (compact, e.g. 1.2M).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 9,
      height: 1.0,
    );
    for (var g = 0; g <= 4; g++) {
      final y = _padTop + (g / 4) * chartH;
      canvas.drawLine(
          Offset(_padLeft, y), Offset(_padLeft + chartW, y), gridPaint);
      final v = top - (g / 4) * (top - bottom);
      final tp = TextPainter(
        text: TextSpan(text: _compact(v), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_padLeft - tp.width - 6, y - tp.height / 2));
    }

    // Area + line.
    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      final x = xFor(i);
      final y = yFor(values[i]);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    final areaPath = Path.from(linePath)
      ..lineTo(xFor(points.length - 1), _padTop + chartH)
      ..lineTo(xFor(0), _padTop + chartH)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Last point highlighted (current period).
    final last = points.length - 1;
    canvas.drawCircle(
      Offset(xFor(last), yFor(values[last])),
      3.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(xFor(last), yFor(values[last])),
      6.5,
      Paint()..color = color.withValues(alpha: 0.25),
    );

    // X labels: first, middle, last.
    final labelIndexes = <int>{0, points.length ~/ 2, points.length - 1};
    for (final i in labelIndexes) {
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: labelStyle.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      var x = xFor(i) - tp.width / 2;
      x = x.clamp(_padLeft, _padLeft + chartW - tp.width);
      tp.paint(canvas, Offset(x, _padTop + chartH + 6));
    }
  }

  static String _compact(double v) {
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

/// Minimal view model so the widget stays decoupled from the API model.
class TrendPointView {
  const TrendPointView({required this.label, required this.total});

  final String label;
  final double total;
}
