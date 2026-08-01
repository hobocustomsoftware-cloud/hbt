import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  LOADING INDICATORS
// =============================================================================

/// A full-screen centered [CircularProgressIndicator].
///
/// Replaces `const Center(child: CircularProgressIndicator())` — 12+ occurrences.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Inline [CircularProgressIndicator] with an optional message, used inside
/// lists or forms where a full-screen loader would be too much.
class InlineLoading extends StatelessWidget {
  const InlineLoading({
    super.key,
    this.message,
    this.size = 24,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message != null) ...[
              const SizedBox(width: AppTheme.spacingMd),
              Text(message!, style: AppTheme.sectionSubtitleStyle(context)),
            ],
          ],
        ),
      );
}

/// A linear progress bar at the top, useful for overlay / sync progress.
///
/// Shows an optional label + percentage below the bar.
class LinearProgressOverlay extends StatelessWidget {
  const LinearProgressOverlay({
    super.key,
    this.progress,
    this.label,
    this.backgroundColor,
  });

  /// 0.0 – 1.0, or null for indeterminate.
  final double? progress;
  final String? label;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bar = progress != null
        ? LinearProgressIndicator(value: progress)
        : const LinearProgressIndicator();

    if (label == null) return bar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingXs),
          child: Text(
            label!,
            style: AppTheme.sectionSubtitleStyle(context),
          ),
        ),
      ],
    );
  }
}

/// Skeleton/shimmer placeholder for content that is loading.
///
/// Shows a series of animated placeholder boxes that simulate content layout.
/// Usage:
/// ```dart
/// SkeletonLoader(
///   itemCount: 5,
///   itemBuilder: (index) => Column(
///     children: [
///       SkeletonLine(width: 200),
///       SkeletonLine(width: double.infinity),
///     ],
///   ),
/// )
/// ```
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.itemCount = 1,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.slowDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            children: [
              for (var i = 0; i < widget.itemCount; i++)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: widget.itemBuilder(i),
                ),
            ],
          ),
        ),
      );
}

/// A shimmer-like animated placeholder line.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  final double width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusSm,
        ),
      ),
    );
  }
}

/// A skeleton card that mimics [AppListTileCard] layout.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: [
              const SkeletonLine(
                width: 24,
                height: 24,
                borderRadius: 12,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLine(width: 160, height: 14),
                    SizedBox(height: AppTheme.spacingSm),
                    SkeletonLine(width: 240, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              const SkeletonLine(width: 20, height: 20, borderRadius: 10),
            ],
          ),
        ),
      );

  static Widget card() => const SkeletonListTile();
}

/// A loading state for list items — a Card with a placeholder message.
///
/// Replaces `Card(child: ListTile(title: Text('...')))` for loading states
/// within lists (used in ticket_sales_page, cargo_worklist_page).
class LoadingListItem extends StatelessWidget {
  const LoadingListItem({
    super.key,
    this.message = 'Loading…',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text(message),
        ),
      );
}
