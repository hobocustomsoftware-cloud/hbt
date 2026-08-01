import 'package:flutter/material.dart';

/// Centralised design tokens and theme configuration for the HBT Business App.
///
/// ## Usage
/// ```dart
/// AppTheme.spacingMd                   // 12.0
/// AppTheme.radiusMd                     // 12.0
/// AppTheme.sectionHeaderStyle(context)  // themed titleMedium
/// ```
///
/// All spacing values should come from here — no raw literals.
class AppTheme {
  AppTheme._();

  // ── Spacing ──────────────────────────────────────────────────────
  static const double spacingXxs = 2;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;
  static const double spacingXxxl = 32;
  static const double spacingXxxxl = 48;

  // ── Padding helpers ──────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.all(spacingLg);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingLg);
  static const EdgeInsets listPadding = EdgeInsets.all(spacingMd);
  static const EdgeInsets formFieldPadding =
      EdgeInsets.symmetric(vertical: spacingSm);
  static const EdgeInsets sectionPadding =
      EdgeInsets.only(top: spacingXl, bottom: spacingSm);

  // ── Border radius ────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ── Icon sizes ───────────────────────────────────────────────────
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 48;
  static const double iconXl = 64;

  // ── Sizing constraints ───────────────────────────────────────────
  static const double maxFormWidth = 420;
  static const double minButtonHeight = 48;
  static const double chipHeight = 32;

  // ── Duration / animation ─────────────────────────────────────────
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 600);

  // ── Typography helpers ───────────────────────────────────────────
  static TextStyle sectionHeaderStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium ??
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle sectionSubtitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall ??
      const TextStyle(fontSize: 12, color: Colors.grey);

  static TextStyle cardTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall ??
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle dataLabelStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ) ??
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  static TextStyle dataValueStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium ??
      const TextStyle(fontSize: 14);

  static TextStyle monoStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
          ) ??
      const TextStyle(fontSize: 12, fontFamily: 'monospace');

  // ── Status colour helpers ────────────────────────────────────────

  /// Returns a colour for the given status string based on M3 colour tokens.
  static Color statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      'active' || 'approved' || 'confirmed' || 'completed' || 'arrived' ||
      'handed_over' =>
        cs.primary,
      'ready' || 'boarding' || 'issued' || 'validated' || 'boarded' =>
        cs.tertiary,
      'departed' || 'in_progress' || 'in_transit' || 'loaded' =>
        cs.secondary,
      'draft' || 'planned' => cs.outline,
      'suspended' || 'delayed' || 'ready_pickup' => cs.errorContainer,
      'retired' || 'archived' || 'cancelled' || 'rejected' =>
        cs.error.withAlpha(180),
      'requested' => cs.tertiaryContainer,
      'paid' => cs.primaryContainer,
      _ => cs.outline,
    };
  }

  // ── Build a Material 3 ThemeData from seed ───────────────────────

  static ThemeData buildTheme({Color? seedColor}) {
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor ?? const Color(0xff00695c),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      // ── Component theme defaults ───────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, minButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, minButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: spacingMd, vertical: 14),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 1,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: spacingLg,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }
}

/// App-level typography presets for headings, labels, and mono text.
///
/// These are fallback styles for when theme-based styles are not sufficient.
/// Prefer `Theme.of(context).textTheme.*` where possible.
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
    color: Colors.grey,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
  );
}
