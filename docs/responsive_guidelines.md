# HBT — Responsive Guidelines (Wave 0)

**Date:** 2026-08-01
**Author:** Senior Flutter UI Architect / Design Director
**Status:** Wave 0 deliverable. Extends `docs/design_system.md` §7–8 and the validation
in `docs/responsive_review.md`.
**Rule:** Desktop = enterprise SaaS · Tablet = adaptive grid · Mobile = native feel.
**Desktop must NOT look like a stretched mobile app.**

---

## 1. Breakpoints & intent

| Range | Class | Layout intent |
|---|---|---|
| 0–599 | Mobile | one column; bottom nav ≤5; cards; thumb-reach primary action |
| 600–1023 | Tablet | two columns; navigation rail; table→cards at <600 only |
| 1024–1439 | Desktop | three columns; collapsible sidebar 248↔72; top bar |
| 1440+ | Wide/Ultra | four columns; content ≤1680 centered; no stretching |

Breakpoint = **layout change**, never just a font change. Every breakpoint designed
independently (GWS/Stripe/Linear model).

---

## 2. Desktop (enterprise SaaS bar)

- Dark sidebar (#151515) + top bar (global search ⌘K, bell, profile, breadcrumbs).
- KPI rows 4 + 6 + 4 + 4; charts 2–3 across; rankings 3-up; feeds bottom-right.
- Dense but legible: body 16, tables full density, hover row actions.
- Keyboard path: ⌘K search, ⌘1–9 nav, G→T go-to-Trips (power users).
- Multi-pane priority collapse: sidebar → content → feeds (drop feeds below 1200).

## 3. Tablet (600–1023)

- NavigationRail (icons + labels); top bar keeps search + bell.
- KPI grid 2-col (money quartet 2×2); charts 1–2 col; rankings stack.
- Tables stay tables (≥600) with horizontal-safe columns; wide tables become
  card lists below 600 only.
- Bottom sheet for overflow actions; no drawer nav.

## 4. Mobile (0–599)

- Bottom nav (5 max) + drawer for the rest; money quartet 2×2 compact.
- Everything below KPIs becomes a **drill card list** (summary → tap → detail).
- Exception strip (delayed/cancelled/cash-diff/approvals) pinned under KPIs.
- Primary action bottom-anchored (thumb reach); touch targets ≥48px (64px for
  quick actions).
- **No horizontal scroll ever** — tables become cards; charts reflow; dialogs
  full-width with 28px top radius.

## 5. Component behavior

| Component | <600 | 600–1023 | ≥1024 |
|---|---|---|---|
| KPI grid | 2-col | 2-col | 4-col |
| Chart row | 1-up stack | 2-up | 3-up |
| Table | cards | table (safe cols) | table + hover actions |
| Sidebar | — (drawer) | rail | 248↔72 collapse |
| Global filter | chips row, horizontal-wrap | bar | bar + time toggle |
| Approval card | stacked | 2-up | list w/ inline actions |
| Activity feed | top under KPIs (short) | right column | bottom-right |
| Dialogs | full-width bottom sheet | centered 480 | centered 520–640 |

## 6. Anti-patterns (never)

- Stretched mobile UI on desktop (no max-width, no columns).
- Tables with horizontal scroll on mobile.
- Sidebar + hamburger on desktop.
- Fonts scaling instead of layout changing.
- Hidden functionality at any breakpoint (clipped charts, cut tables).

## 7. Validation gate (per screen, per wave)

Launch → resize continuously 320/375/768/1024/1366/1920/2560 → verify: no overflow,
no clipping, no horizontal scroll, charts/tables/dialogs intact → screenshots →
**0 P0, 0 P1, ≤3 P2** → update `docs/responsive_review.md` + gap analysis.
