import 'package:flutter/material.dart';

import 'hbt_theme.dart';
import 'hbt_tokens.dart';

/// Legacy AppTheme — now a **compatibility shim over the HBT design system**
/// (W1-001). Every value delegates to HbtTokens / HbtTheme so feature screens
/// that still reference `AppTheme.*` instantly adopt the official brand
/// (#AA0000 / #151515) without individual edits.
///
/// New code should use HbtTokens / HbtTypography / HbtTheme directly; this
/// shim exists only to keep older screens compiling and is scheduled for
/// removal once all screens migrate (tracked per wave).
class AppTheme {
  AppTheme._();

  // ── Spacing (delegates to HbtSpacing) ────────────────────────────────
  static const double spacingXxs = HbtSpacing.xxs;
  static const double spacingXs = HbtSpacing.xs;
  static const double spacingSm = HbtSpacing.sm;
  static const double spacingMd = HbtSpacing.md;
  static const double spacingLg = HbtSpacing.lg;
  static const double spacingXl = HbtSpacing.xl;
  static const double spacingXxl = HbtSpacing.xxl;
  static const double spacingXxxl = HbtSpacing.xxxl;
  static const double spacingXxxxl = HbtSpacing.xxxxl;

  // ── Padding helpers ──────────────────────────────────────────────────
  static const EdgeInsets pagePadding = HbtSpacing.pageMobile;
  static const EdgeInsets cardPadding = HbtSpacing.cardPadding;
  static const EdgeInsets listPadding = EdgeInsets.all(HbtSpacing.md);
  static const EdgeInsets formFieldPadding =
      EdgeInsets.symmetric(vertical: HbtSpacing.sm);
  static const EdgeInsets sectionPadding =
      EdgeInsets.only(top: HbtSpacing.xl, bottom: HbtSpacing.sm);

  // ── Border radius (delegates to HbtRadius) ───────────────────────────
  static const double radiusXs = HbtRadius.xs;
  static const double radiusSm = HbtRadius.sm;
  static const double radiusMd = HbtRadius.md;
  static const double radiusLg = HbtRadius.lg;
  static const double radiusXl = HbtRadius.xl;

  // ── Icon sizes ───────────────────────────────────────────────────────
  static const double iconSm = HbtIconSize.sm;
  static const double iconMd = HbtIconSize.md;
  static const double iconLg = HbtIconSize.lg;
  static const double iconXl = HbtIconSize.xl;

  // ── Sizing constraints ───────────────────────────────────────────────
  static const double maxFormWidth = HbtSize.maxFormWidth;
  static const double minButtonHeight = HbtSize.minButtonHeight;
  static const double chipHeight = HbtSize.chipHeight;

  // ── Duration / animation ─────────────────────────────────────────────
  static const Duration fastDuration = HbtMotion.fast;
  static const Duration mediumDuration = HbtMotion.normal;
  static const Duration slowDuration = HbtMotion.slow;

  // ── Typography helpers (design-system styles) ────────────────────────
  static TextStyle sectionHeaderStyle(BuildContext context) =>
      HbtTypography.title;

  static TextStyle sectionSubtitleStyle(BuildContext context) =>
      HbtTypography.caption.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle cardTitleStyle(BuildContext context) =>
      HbtTypography.bodyStrong;

  static TextStyle dataLabelStyle(BuildContext context) =>
      HbtTypography.caption.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle dataValueStyle(BuildContext context) =>
      HbtTypography.bodyStrong;

  static TextStyle monoStyle(BuildContext context) =>
      HbtTypography.caption.copyWith(fontFamily: 'monospace');

  // ── Status colour helper (semantic tokens only — no random colors) ──
  static Color statusColor(BuildContext context, String status) =>
      switch (status) {
        'active' || 'approved' || 'confirmed' || 'completed' || 'arrived' ||
        'handed_over' || 'paid' =>
          HbtColors.success,
        'ready' || 'boarding' || 'issued' || 'validated' || 'boarded' =>
          HbtColors.info,
        'departed' || 'in_progress' || 'in_transit' || 'loaded' ||
        'requested' =>
          HbtColors.warning,
        'draft' || 'planned' => HbtColors.neutral,
        'suspended' || 'delayed' || 'ready_pickup' => HbtColors.warning,
        'retired' || 'archived' || 'cancelled' || 'rejected' =>
          HbtColors.danger,
        _ => HbtColors.neutral,
      };

  // ── Theme builder: now returns the official HBT theme (no teal seed) ──
  static ThemeData buildTheme({Color? seedColor}) =>
      HbtTheme.light(primaryOverride: seedColor);
}

/// App-level typography presets (fallbacks). Colours now come from tokens.
class AppTypography {
  AppTypography._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle label = TextStyle(
    fontWeight: FontWeight.w500,
    color: HbtColors.neutral,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: HbtColors.neutral,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
  );
}
