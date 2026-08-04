import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

export 'error_states.dart' show ErrorView, ErrorCard;

// =============================================================================
//  FULL-SCREEN STATUS VIEWS (design-system re-skin, W1-001)
// =============================================================================
//
// Canonical home for: LoadingView, EmptyView, EmptyListTileCard, InlineLoading,
// LinearProgressOverlay, SkeletonLoader, SkeletonLine, SkeletonListTile,
// LoadingListItem. ErrorView/ErrorCard re-exported from error_states.dart so
// every async_views consumer keeps working without importing two files.
// The duplicate LoadingView/ErrorView/ErrorCard definitions (old loading.dart /
// async_views.dart) are removed — one definition per widget.

/// A centered [CircularProgressIndicator] wrapped in a [SizedBox].
///
/// Replaces `const Center(child: CircularProgressIndicator())` — 12+
/// occurrences across screens.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Full-screen empty state with icon, message, and optional action button.
///
/// Replaces the 8-line empty-state blocks in 4+ screens.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(HbtSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: HbtIconSize.xl, color: HbtColors.primary.withValues(alpha: 0.35)),
              const SizedBox(height: HbtSpacing.md),
              Text(
                message,
                style: HbtTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: HbtSpacing.md),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

/// An inline empty-state card for use inside scrollable forms.
///
/// Replaces `Card(child: ListTile(title: Text('No items.')))`.
class EmptyListTileCard extends StatelessWidget {
  const EmptyListTileCard({
    super.key,
    this.message = 'No items yet.',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(
            message,
            style: HbtTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
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
        padding: const EdgeInsets.all(HbtSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message != null) ...[
              const SizedBox(width: HbtSpacing.md),
              Text(
                message!,
                style: HbtTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
          padding: const EdgeInsets.only(top: HbtSpacing.xs),
          child: Text(
            label!,
            style: HbtTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _SkeletonScope(
            progress: _controller.value,
            child: Column(
              children: [
                for (var i = 0; i < widget.itemCount; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: HbtSpacing.md),
                    child: widget.itemBuilder(i),
                  ),
              ],
            ),
          ),
        ),
      );
}

/// Inherited shimmer progress (0..1) for [SkeletonLine] inside a
/// [SkeletonLoader]. Falls back to 0 (static tint) when absent.
class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.progress, required super.child});

  final double progress;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_SkeletonScope>();
    return scope?.progress ?? 0.0;
  }

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) =>
      oldWidget.progress != progress;
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
    final base = cs.surfaceContainerHighest;
    final shimmer = HbtColors.primary.withValues(alpha: 0.10);
    final t = _SkeletonScope.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(base, shimmer, t),
        borderRadius: BorderRadius.circular(
          borderRadius ?? HbtRadius.sm,
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
          padding: HbtSpacing.cardPadding,
          child: Row(
            children: [
              const SkeletonLine(
                width: 24,
                height: 24,
                borderRadius: 12,
              ),
              const SizedBox(width: HbtSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLine(width: 160, height: 14),
                    SizedBox(height: HbtSpacing.sm),
                    SkeletonLine(width: 240, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: HbtSpacing.md),
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
