/// HBT Design Tokens — single source of truth for the design system.
///
/// Brand identity:
///   Primary   #AA0000 (crimson — Myanmar express transport, premium red)
///   Secondary #151515 (near-black — corporate, premium)
///   Gradients #AA0000 → #151515 and transparent overlays.
///
/// Every screen uses these tokens. Do NOT use random colors.
library;

import 'package:flutter/material.dart';

class HbtColors {
  HbtColors._();

  // ── Brand core ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFFAA0000);
  static const Color secondary = Color(0xFF151515);

  // ── Surfaces ─────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F8F8);
  static const Color backgroundDark = Color(0xFF101010);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerLight = Color(0xFFEFEFEF);
  static const Color surfaceContainerDark = Color(0xFF242424);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF151515);
  static const Color textSecondaryLight = Color(0xFF5A5A5A);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // ── Status (transport semantics) ─────────────────────────────────────
  static const Color success = Color(0xFF1B7F3B);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF0B5FA5);

  /// Neutral grey for undefined/inactive states (not a random color).
  static const Color neutral = Color(0xFF6B6B6B);

  // ── Brand gradient ───────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient brandGradientSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFAA0000)],
  );
}

class HbtSpacing {
  HbtSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 48;
  static const double huge = 64;

  static const EdgeInsets pageMobile = EdgeInsets.all(lg);
  static const EdgeInsets pageTablet = EdgeInsets.all(xxl);
  static const EdgeInsets pageDesktop = EdgeInsets.all(xxxl);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets sectionGap = EdgeInsets.only(top: xl, bottom: sm);
}

class HbtRadius {
  HbtRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class HbtElevation {
  HbtElevation._();

  static const List<BoxShadow> shadowXs = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x24000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 28, offset: Offset(0, 8)),
  ];
}

class HbtMotion {
  HbtMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
}

/// Standard icon sizes used across the design system.
class HbtIconSize {
  HbtIconSize._();

  static const double sm = 18;
  static const double md = 24;
  static const double lg = 40;
  static const double xl = 56;
}

/// Fixed dimensions shared by components.
class HbtSize {
  HbtSize._();

  /// Minimum touch target height for buttons (WCAG / thumb reach).
  static const double minButtonHeight = 48;
  static const double chipHeight = 32;
  static const double maxFormWidth = 420;
}

/// Responsive breakpoints (Material 3 style, device-agnostic widths).
/// Use [HbtBreakpoints.of] with a LayoutBuilder/MediaQuery — never raw checks
/// scattered in widgets.
class HbtBreakpoints {
  HbtBreakpoints._();

  static const double mobileMax = 599;
  static const double tabletMax = 1023;
  static const double desktopMax = 1439;
  // wide = 1440+

  static bool isMobile(double width) => width <= mobileMax;
  static bool isTablet(double width) =>
      width > mobileMax && width <= tabletMax;
  static bool isDesktop(double width) =>
      width > tabletMax && width <= desktopMax;
  static bool isWide(double width) => width > desktopMax;

  /// Column count for responsive grids.
  static int columnsFor(double width) {
    if (isMobile(width)) return 1;
    if (isTablet(width)) return 2;
    if (isDesktop(width)) return 3;
    return 4;
  }
}

class HbtTypography {
  HbtTypography._();

  /// Myanmar-first font stack. Falls back through Myanmar-supporting fonts.
  static const String fontFamilyMyanmar = 'Noto Sans Myanmar';
  static const String fontFamilyLatin = 'Inter';

  static const TextStyle display = TextStyle(
    fontSize: 40,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle kpiValue = TextStyle(
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle kpiLabel = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
}
