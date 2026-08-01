import 'package:flutter/material.dart';

// =============================================================================
//  PERMISSION GUARD
// =============================================================================

/// Wraps a child widget and conditionally renders it based on the user's
/// permission set.
///
/// ## Variants
///
/// ### [hide] variant (default)
/// When the permission check fails, the child is not rendered at all.
///
/// ```dart
/// PermissionGuard(
///   hasPermission: session.hasPermission('booking.manage'),
///   child: BusyButton(label: 'Create Booking', ...),
/// )
/// ```
///
/// ### [disable] variant
/// When the permission check fails, the child is rendered disabled
/// (wrapped in an [AbsorbPointer]) with reduced opacity.
///
/// ```dart
/// PermissionGuard(
///   hasPermission: session.hasPermission('booking.manage'),
///   variant: PermissionGuardVariant.disable,
///   child: BusyButton(label: 'Create Booking', ...),
/// )
/// ```
///
/// ### [fallback] variant
/// When the permission check fails, [fallback] is shown instead.
///
/// ```dart
/// PermissionGuard(
///   hasPermission: session.hasPermission('booking.manage'),
///   variant: PermissionGuardVariant.fallback,
///   fallback: Text('No permission'),
///   child: BusyButton(label: 'Create Booking', ...),
/// )
/// ```
class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.hasPermission,
    required this.child,
    this.variant = PermissionGuardVariant.hide,
    this.fallback,
    this.opacity = 0.4,
  });

  final bool hasPermission;
  final Widget child;
  final PermissionGuardVariant variant;
  final Widget? fallback;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (hasPermission) return child;

    return switch (variant) {
      PermissionGuardVariant.hide => const SizedBox.shrink(),
      PermissionGuardVariant.disable => Opacity(
          opacity: opacity,
          child: AbsorbPointer(child: child),
        ),
      PermissionGuardVariant.fallback =>
        fallback ?? const SizedBox.shrink(),
    };
  }
}

enum PermissionGuardVariant { hide, disable, fallback }

/// Conditionally shows a list of items based on permissions.
///
/// Usage:
/// ```dart
/// PermissionedList(
///   permissions: session,
///   items: [
///     PermissionedItem(
///       permission: 'trip.view',
///       builder: (context) => _QuickAction(...),
///     ),
///     PermissionedItem(
///       permission: 'cargo.view',
///       builder: (context) => _QuickAction(...),
///     ),
///   ],
/// )
/// ```
class PermissionedList extends StatelessWidget {
  const PermissionedList({
    super.key,
    required this.items,
  });

  final List<PermissionedItem> items;

  @override
  Widget build(BuildContext context) => Column(
        children: items
            .where((item) => item.show)
            .map((item) => item.builder(context))
            .toList(),
      );
}

class PermissionedItem {
  const PermissionedItem({
    required this.show,
    required this.builder,
  });

  final bool show;
  final Widget Function(BuildContext context) builder;
}
