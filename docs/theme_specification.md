# HBT Theme Specification

**Version:** 1.0 · **Date:** 2026-08-01
**Author:** Senior Flutter UI Architect
**Applies to:** Business App, Passenger App, Booking Website, Corporate Website (shared spec).

---

## 1. Color tokens (light)

| Role | Token | Value |
|------|-------|-------|
| Primary | `HbtColors.primary` | `#AA0000` |
| On primary | — | `#FFFFFF` |
| Secondary | `HbtColors.secondary` | `#151515` |
| On secondary | — | `#FFFFFF` |
| Background | `HbtColors.backgroundLight` | `#F8F8F8` |
| Surface | `HbtColors.surfaceLight` | `#FFFFFF` |
| Surface container | `HbtColors.surfaceContainerLight` | `#EFEFEF` |
| On surface | `HbtColors.textPrimaryLight` | `#151515` |
| On surface variant | `HbtColors.textSecondaryLight` | `#5A5A5A` |
| Success / Warning / Danger / Info | — | `#1B7F3B` `#B26A00` `#B3261E` `#0B5FA5` |

## 2. Color tokens (dark)

| Role | Token | Value |
|------|-------|-------|
| Background | `backgroundDark` | `#101010` |
| Surface | `surfaceDark` | `#1A1A1A` |
| Surface container | `surfaceContainerDark` | `#242424` |
| On surface | `textPrimaryDark` | `#F5F5F5` |
| On surface variant | `textSecondaryDark` | `#B0B0B0` |

Primary/secondary/status colors are shared across modes (brand consistency).

## 3. Component theming (Material 3)

| Component | Light spec |
|-----------|-----------|
| AppBar | bg background, elevation 0, scrolledUnder 1, title Title style |
| Card | bg surface, radius 14, 1px container border, elevation 0 + shadow scale |
| Filled/Elevated button | bg primary, fg white, min 48×52, radius 14, label Button |
| Text button | fg primary, min 48×48 |
| Outlined button | fg primary, container border, min 48×52, radius 14 |
| Input | filled container, radius 12, no border → container border → 2px primary focus |
| NavigationRail | bg background, indicator primary 14% alpha, selected label primary/600 |
| SnackBar | floating, bg secondary, white text, radius 10 |
| Dialog | bg surface, radius 28 |
| BottomSheet | bg surface, radius 28 top, drag handle |
| Tooltip | bg secondary, white text, radius 6 |
| Divider | container color, 1px |

## 4. Typography mapping

`ThemeData.textTheme` is derived from `HbtTypography`:

| Flutter slot | HBT style |
|--------------|-----------|
| displayLarge | Display (40/700) |
| headlineLarge | Headline (28/700) |
| titleLarge | Title (20/600) |
| bodyLarge / bodyMedium | Body (16/400) |
| bodySmall | Caption (13/400) |
| labelLarge | Button (16/600) |

Base font family: Inter (Latin) with Noto Sans Myanmar for Myanmar text runs.

## 5. Branding injection

```dart
ThemeData HbtTheme.fromBrand({
  required Brightness brightness,
  required Color primary,   // company primary color
  required Color secondary, // company secondary color
})
```

- `ColorScheme.fromSeed(primary, brightness)` derives the full tonal palette.
- The active org's branding (from `OrganizationBranding`) is fetched at session start
  and passed here → the whole app re-themes instantly on org switch.
- Passenger app uses neutral chrome + per-operator branding on trip screens.

## 6. Shape & elevation

- Cards: radius 14, elevation 0 with shadow-md on emphasis.
- Buttons: radius 14.
- Dialogs/sheets: radius 28.
- Shadows: xs/sm/md/lg (blur 4/8/16/28).

## 7. Iconography

- Material Symbols (outlined default, filled for selected).
- 20–24px standard, 28px in large touch nav, 32–40px in empty states.
- Brand mark: bus glyph on the `#AA0000→#151515` gradient chip.

## 8. Validation

- Theme builds cleanly (`flutter analyze`), all widget tests pass (92 business).
- Runtime verification across breakpoints in `docs/responsive_review.md`.
