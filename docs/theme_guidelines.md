# HBT — Theme Guidelines (Wave 0)

**Date:** 2026-08-01
**Author:** Design Director / Senior UI Architect
**Status:** Wave 0 deliverable. Implementation follows `docs/design_system.md` +
`docs/theme_specification.md`, extended here.
**Rule:** one consistent design language. **No random colors.**

---

## 1. Default theme (light)

| Role | Token | Value |
|---|---|---|
| Primary | `HbtColors.primary` | `#AA0000` |
| Secondary | `HbtColors.secondary` | `#151515` |
| Background | `HbtColors.backgroundLight` | `#F8F8F8` |
| Cards / surfaces | `surfaceLight` | `#FFFFFF` |
| **Sidebar** | **`#151515`** (always dark) | text `#F5F5F5`, active `#AA0000` pill |
| Text primary | `textPrimaryLight` | `#151515` |
| Text secondary | `textSecondaryLight` | `#5A5A5A` |
| Borders/dividers | `surfaceContainerLight` | `#EFEFEF` |
| Accent | `brandGradient` | `#AA0000 → #151515` |

### Dark theme
Background `#101010` · surfaces `#1A1A1A` · containers `#242424` · text `#F5F5F5` /
`#B0B0B0`. Sidebar stays `#151515` (slightly lighter than bg — keeps separation).
Primary/secondary/status colors shared across modes.

---

## 2. Sidebar (#151515) usage

- Rail/sidebar surface is always the dark brand secondary — on both themes.
- Text `#F5F5F5` (≈16:1 contrast), secondary items `#B0B0B0`, hover `#FFFFFF` +
  `#FFFFFF14` bg.
- **Active item:** `#AA0000` pill, white text, radius 10; badge counts (Approvals)
  white-on-primary.
- Brand mark row: logo on gradient chip or white glyph on transparent.
- Collapse: 248px ↔ 72px icons-only; tooltip on collapse.

## 3. Gradients & overlays (transparent, purposeful)

| Use | Spec |
|---|---|
| Icon chips (KPI) | `brandGradient` 40×40, radius 12, white icon |
| Hero KPI (Net Profit) | gradient header strip (16px) under value |
| Empty-state illustration | gradient blob at 8–25% opacity |
| Chart area | primary at 8–25% alpha fills |
| Active nav pill | primary solid (not gradient) for AA contrast |
| Page backgrounds | never gradient — flat `#F8F8F8`/`#101010` |

Never use gradients on body text, buttons (solid primary instead), or whole pages.

## 4. Semantic colors (only these)

| Meaning | Light | Dark |
|---|---|---|
| Success | `#1B7F3B` | `#4CAF6A` |
| Warning | `#B26A00` | `#E0A33C` |
| Danger | `#B3261E` | `#F07167` |
| Info | `#0B5FA5` | `#66AEE8` |

Status chips: colored dot + label, tinted container (color at 10–14% alpha), never
full-saturation backgrounds for whole cards.

## 5. Typography & numbers

- Myanmar first (Noto Sans Myanmar), Latin fallback Inter.
- Money always tabular numerals; Myanmar digits in `my` locale (KPI, receipts, PDF).
- Sizes: Display 40 · Headline 28 · Title 20 · Body 16 · Caption 13 · Button 16 ·
  KPI value 32 · KPI label 13. Weights ≤3 per screen.

## 6. Elevation & radius

- Elevation: xs 4 / sm 8 / md 16 / lg 28 blur, low alpha black.
- Radius: cards/buttons 14, inputs 12, chips 999, dialogs/sheets 28.
- Shadows subtle — hover raises one level only.

## 7. Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| Use tokens for every color/spacing | Hex literals in widgets |
| Status = semantic color only | Rainbow KPIs, random accents |
| Dark sidebar in both themes | Light sidebar with dark top bar mix |
| Gradient only on chips/hero/empty states | Gradient buttons or body text |
| White cards on `#F8F8F8` | Grey-on-grey cards |
| Contrast-checked text (AA) | `#999` caption on white |

## 8. Company branding override

`HbtTheme.fromBrand(primary, secondary)` re-derives the palette; sidebar remains dark
secondary from branding; gradient = brand primary → brand secondary. Branding engine
(Wave 1) feeds this per company.

## 9. Motion (from component library)

fast 120 · normal 220 · slow 380 · skeleton 1.2s; reduced-motion disables all.
