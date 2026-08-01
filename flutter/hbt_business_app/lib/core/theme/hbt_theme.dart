import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hbt_tokens.dart';

/// HBT Material 3 theme — light + dark, built entirely from [HbtColors]
/// and [HbtTypography]. The active company branding (primary color from the
/// backend) can be injected via [HbtTheme.fromBrand] so the whole app
/// re-themes automatically.
class HbtTheme {
  HbtTheme._();

  static ThemeData light({Color? primaryOverride}) => _build(
        brightness: Brightness.light,
        primary: primaryOverride ?? HbtColors.primary,
        background: HbtColors.backgroundLight,
        surface: HbtColors.surfaceLight,
        container: HbtColors.surfaceContainerLight,
        textPrimary: HbtColors.textPrimaryLight,
        textSecondary: HbtColors.textSecondaryLight,
      );

  static ThemeData dark({Color? primaryOverride}) => _build(
        brightness: Brightness.dark,
        primary: primaryOverride ?? HbtColors.primary,
        background: HbtColors.backgroundDark,
        surface: HbtColors.surfaceDark,
        container: HbtColors.surfaceContainerDark,
        textPrimary: HbtColors.textPrimaryDark,
        textSecondary: HbtColors.textSecondaryDark,
      );

  /// Theme from company branding (primary color + secondary color).
  static ThemeData fromBrand({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
  }) =>
      _build(
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        background: brightness == Brightness.light
            ? HbtColors.backgroundLight
            : HbtColors.backgroundDark,
        surface: brightness == Brightness.light
            ? HbtColors.surfaceLight
            : HbtColors.surfaceDark,
        container: brightness == Brightness.light
            ? HbtColors.surfaceContainerLight
            : HbtColors.surfaceContainerDark,
        textPrimary: brightness == Brightness.light
            ? HbtColors.textPrimaryLight
            : HbtColors.textPrimaryDark,
        textSecondary: brightness == Brightness.light
            ? HbtColors.textSecondaryLight
            : HbtColors.textSecondaryDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    Color secondary = HbtColors.secondary,
    required Color background,
    required Color surface,
    required Color container,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
    ).copyWith(
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerHighest: container,
      outlineVariant: container,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
            fontFamily: HbtTypography.fontFamilyLatin,
          )
          .copyWith(
            displayLarge: HbtTypography.display,
            headlineLarge: HbtTypography.headline,
            titleLarge: HbtTypography.title,
            bodyLarge: HbtTypography.body,
            bodyMedium: HbtTypography.body,
            bodySmall: HbtTypography.caption,
            labelLarge: HbtTypography.button,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: HbtTypography.title.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HbtRadius.md),
          side: BorderSide(color: container, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HbtRadius.md),
          ),
          textStyle: HbtTypography.button,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HbtRadius.md),
          ),
          textStyle: HbtTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          textStyle: HbtTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: scheme.outlineVariant),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HbtRadius.md),
          ),
          textStyle: HbtTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: container,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HbtSpacing.lg,
          vertical: HbtSpacing.md + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HbtRadius.sm + 2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HbtRadius.sm + 2),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HbtRadius.sm + 2),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: HbtTypography.body.copyWith(color: textSecondary),
        hintStyle: HbtTypography.body.copyWith(color: textSecondary),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        indicatorColor: primary.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: primary),
        selectedLabelTextStyle:
            HbtTypography.caption.copyWith(color: primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle:
            HbtTypography.caption.copyWith(color: textSecondary),
      ),
      dividerTheme: DividerThemeData(
        color: container,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: secondary,
        contentTextStyle: HbtTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HbtRadius.sm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HbtRadius.lg),
        ),
        titleTextStyle: HbtTypography.title,
        contentTextStyle: HbtTypography.body,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HbtRadius.lg)),
        ),
        showDragHandle: true,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: secondary,
          borderRadius: BorderRadius.circular(HbtRadius.xs),
        ),
        textStyle: HbtTypography.caption.copyWith(color: Colors.white),
      ),
    );
  }
}
