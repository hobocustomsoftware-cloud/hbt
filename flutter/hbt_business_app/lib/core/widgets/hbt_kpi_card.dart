import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';
import 'async_views.dart';

/// Design-system KPI card (component library §1.1).
///
/// Anatomy: icon chip · value (count-up) · label · trend · optional
/// sparkline. Variants:
/// - [HbtKpiCard] default — money/trip KPIs with icon chip + trend.
/// - `hero` — gradient header strip for the headline metric (net revenue).
/// - `compact` — smaller, icon-free card for dense rows.
///
/// Tones: [KpiTone.warning]/[KpiTone.danger] tint the value + border when a
/// metric crosses a threshold (delayed trips, cancelled trips, exceptions).
class HbtKpiCard extends StatelessWidget {
  const HbtKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trendPercent,
    this.trendUpIsGood = true,
    this.sparkline,
    this.tone = KpiTone.normal,
    this.hero = false,
    this.compact = false,
    this.subtitle,
    this.onTap,
    this.loading = false,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Percent change vs previous period (e.g. 12.5). Null hides the trend.
  final double? trendPercent;

  /// When false (e.g. expenses), a decrease is shown as favorable.
  final bool trendUpIsGood;

  final List<double>? sparkline;
  final KpiTone tone;
  final bool hero;
  final bool compact;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const _KpiSkeleton(hero: false, compact: false);
    if (hero) return _HeroKpi(this);
    if (compact) return _CompactKpi(this);
    return _StandardKpi(this);
  }
}

class _StandardKpi extends StatelessWidget {
  const _StandardKpi(this.data);

  final HbtKpiCard data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final toneColor = switch (data.tone) {
      KpiTone.warning => HbtColors.warning,
      KpiTone.danger => HbtColors.danger,
      KpiTone.normal => null,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: HbtSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (data.icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: HbtColors.brandGradient,
                        borderRadius: BorderRadius.circular(HbtRadius.md),
                      ),
                      child: Icon(data.icon,
                          size: HbtIconSize.sm, color: Colors.white),
                    ),
                    const SizedBox(width: HbtSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      data.label,
                      style: HbtTypography.kpiLabel.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HbtSpacing.md),
              Text(
                data.value,
                style: HbtTypography.kpiValue.copyWith(
                  color: toneColor ?? cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              if (data.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  data.subtitle!,
                  style: HbtTypography.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (data.trendPercent != null) ...[
                const SizedBox(height: HbtSpacing.sm),
                _TrendRow(
                  percent: data.trendPercent!,
                  upIsGood: data.trendUpIsGood,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroKpi extends StatelessWidget {
  const _HeroKpi(this.data);

  final HbtKpiCard data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header strip (brand red → near-black).
            Container(
              padding: const EdgeInsets.all(HbtSpacing.lg),
              decoration: const BoxDecoration(gradient: HbtColors.brandGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (data.icon != null) ...[
                        Icon(data.icon, size: HbtIconSize.md, color: Colors.white),
                        const SizedBox(width: HbtSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          data.label,
                          style: HbtTypography.kpiLabel.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HbtSpacing.sm),
                  Text(
                    data.value,
                    style: HbtTypography.kpiValue.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  if (data.trendPercent != null) ...[
                    const SizedBox(height: HbtSpacing.xs),
                    _TrendRow(
                      percent: data.trendPercent!,
                      upIsGood: data.trendUpIsGood,
                      onDark: true,
                    ),
                  ],
                ],
              ),
            ),
            if (data.sparkline != null && data.sparkline!.length >= 2)
              SizedBox(
                height: 44,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    values: data.sparkline!,
                    color: cs.primary,
                  ),
                  size: Size.infinite,
                ),
              ),
            if (data.subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    HbtSpacing.lg, HbtSpacing.sm, HbtSpacing.lg, HbtSpacing.lg),
                child: Text(
                  data.subtitle!,
                  style: HbtTypography.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactKpi extends StatelessWidget {
  const _CompactKpi(this.data);

  final HbtKpiCard data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final toneColor = switch (data.tone) {
      KpiTone.warning => HbtColors.warning,
      KpiTone.danger => HbtColors.danger,
      KpiTone.normal => null,
    };
    return Card(
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(HbtRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(HbtSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.label,
                style: HbtTypography.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: HbtSpacing.xs),
              Text(
                data.value,
                style: HbtTypography.title.copyWith(
                  color: toneColor ?? cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              if (data.trendPercent != null) ...[
                const SizedBox(height: 2),
                _TrendRow(percent: data.trendPercent!, upIsGood: data.trendUpIsGood),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.percent,
    required this.upIsGood,
    this.onDark = false,
  });

  final double percent;
  final bool upIsGood;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    final favorable = up == upIsGood;
    final color = favorable ? HbtColors.success : HbtColors.danger;
    final fg = onDark ? Colors.white : color;
    final bg = onDark ? Colors.white24 : color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HbtRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 2),
          Text(
            '${up ? '+' : ''}${percent.toStringAsFixed(1)}%',
            style: HbtTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton({required this.hero, required this.compact});

  final bool hero;
  final bool compact;

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: HbtSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 96, height: 14),
              SizedBox(height: HbtSpacing.md),
              SkeletonLine(width: 120, height: 28),
              SizedBox(height: HbtSpacing.sm),
              SkeletonLine(width: 64, height: 12),
            ],
          ),
        ),
      );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
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
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
