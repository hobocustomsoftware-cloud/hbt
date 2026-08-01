# HBT Design System

**Version:** 1.0 · **Date:** 2026-08-01
**Author:** Design Director / Senior Flutter UI Architect
**Status:** Foundation built (tokens + M3 theme + adaptive framework); feature adoption pending approval.
**Source of truth (code):** `lib/core/theme/hbt_tokens.dart`, `lib/core/theme/hbt_theme.dart`,
`lib/core/widgets/hbt_responsive.dart`, `lib/core/widgets/hbt_adaptive_scaffold.dart`.

---

## 1. Brand identity

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#AA0000` | Brand red — CTAs, active nav, accents, gradient start |
| Secondary | `#151515` | Near-black — text on light, surfaces on dark, gradient end |
| Background light | `#F8F8F8` | App canvas (light mode) |
| Background dark | `#101010` | App canvas (dark mode) |
| Surface light | `#FFFFFF` | Cards, sheets, dialogs (light) |
| Surface dark | `#1A1A1A` | Cards, sheets, dialogs (dark) |
| Container light | `#EFEFEF` | Inputs, chips, table headers (light) |
| Container dark | `#242424` | Inputs, chips, table headers (dark) |

**Gradient:** `#AA0000 → #151515` (brandGradient) for hero elements, brand mark,
empty states, loading skeletons. Transparent overlays: `primary.withValues(alpha: 0.08–0.25)`
for chart areas and selected states.

**Rule:** no random colors. Status colors are semantic only:
success `#1B7F3B`, warning `#B26A00`, danger `#B3261E`, info `#0B5FA5`.

---

## 2. Design style

- **Modern / minimal / premium / corporate** — Material 3 baseline.
- **Glassmorphism** only where appropriate: floating action surfaces over dense content
  (bottom sheets, notification center); never as a page background.
- **Subtle shadows** — 4-tier elevation scale (xs/sm/md/lg), soft, low opacity.
- **Rounded corners** — 6/10/14/20/28 + pill; cards 14, buttons 14, dialogs 28.
- **Consistent spacing** — 2/4/8/12/16/20/24/32/48/64 scale; no raw literals.
- **Large touch targets** — buttons min 48×52, fields 48+, nav items 44–56.

---

## 3. Typography (Myanmar default)

Font stack: **Noto Sans Myanmar** (Myanmar glyphs) → **Inter** (Latin).

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 40 | 700 | Splash, empty states |
| Headline | 28 | 700 | Screen titles, dashboard headers |
| Title | 20 | 600 | Cards, sections, app bar |
| Body | 16 | 400 | Primary content |
| BodyStrong | 16 | 600 | Emphasis |
| Caption | 13 | 400 | Meta, timestamps, helper |
| Button | 16 | 600 | Buttons, actions |
| KPI value | 32 | 800 | Dashboard KPI numbers |
| KPI label | 13 | 500 | Dashboard KPI captions |

Line heights: display 1.15, headline 1.2, title 1.25, body 1.45, caption 1.35.
Myanmar numerals are used in KPIs/counts where locale = my.

---

## 4. Spacing & radius

| Spacing | Value |
|---------|-------|
| xxs … huge | 2 · 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48 · 64 |

| Radius | Value | Use |
|--------|-------|-----|
| xs | 6 | chips, tooltips |
| sm | 10 | inputs, small cards |
| md | 14 | cards, buttons |
| lg | 20 | large cards, images |
| xl | 28 | dialogs, sheets |
| pill | 999 | badges, tags |

---

## 5. Elevation (subtle shadows)

| Level | Blur | Offset | Use |
|-------|------|--------|-----|
| xs | 4 | 0,1 | hover states |
| sm | 8 | 0,2 | raised cards |
| md | 16 | 0,4 | popovers, sheets |
| lg | 28 | 0,8 | dialogs, drawers |

---

## 6. Motion

| Token | Value | Use |
|-------|-------|-----|
| fast | 120 ms | hover, press, icon transitions |
| normal | 220 ms | sidebar collapse, sheet open, page transitions |
| slow | 380 ms | hero animations, seat selection |
| ease | easeOutCubic / easeInOutCubic | standard curves |

---

## 7. Breakpoints (device-agnostic widths)

| Range | Name | Layout |
|-------|------|--------|
| 0–599 | Mobile | single column, bottom nav + drawer |
| 600–1023 | Tablet | two columns, navigation rail |
| 1024–1439 | Desktop | three columns, collapsible sidebar |
| 1440+ | Wide | four columns, sidebar + max content 1680 |

Rules: no stretching; each breakpoint is designed independently. Tables become cards
below 600. Sidebars collapse. Charts rearrange (KPI grid 2→2→4→4).

---

## 8. Adaptive framework (code)

- `HbtResponsive` — breakpoint context (never raw `MediaQuery` checks in widgets).
- `HbtResponsiveGrid` — column-count grid per breakpoint.
- `HbtKpiGrid` — 2-up mobile, 4-up desktop+.
- `HbtAdaptiveTable` — DataTable on ≥600, card list on <600.
- `HbtAdaptiveScaffold` — sidebar (desktop) / rail (tablet) / bottom-nav + drawer (mobile);
  top bar with quick search, notification center, profile, breadcrumb.

---

## 9. Navigation

| Breakpoint | Primary | Secondary |
|------------|---------|-----------|
| Desktop | collapsible sidebar (72 ↔ 248px) | top bar |
| Tablet | navigation rail | top bar |
| Mobile | bottom navigation (≤5) | drawer (overflow + profile) |

Top bar: breadcrumb · quick search (desktop/tablet) · notifications (badge) · profile.

---

## 10. Company branding injection

`HbtTheme.fromBrand(brightness, primary, secondary)` re-themes the whole app from
the backend branding (logo, colors). Tickets/receipts/PDFs share the same brand via
the template engine (Owner phase). The passenger app and booking website consume the
same branding endpoint — one brand, everywhere.

---

## 11. Validation status

- Design tokens/theme/adaptive framework: **built + unit-tested** (6 responsive tests).
- Showcase target: `main_design_system.dart` → validates all surfaces at all breakpoints.
- Live browser validation: see `docs/responsive_review.md`.
- **Pending:** design system approval before feature screens adopt it.
