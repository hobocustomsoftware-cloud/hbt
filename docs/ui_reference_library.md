# HBT — UI/UX Reference Library (Wave 0)

**Date:** 2026-08-01
**Author:** Product Designer / UX Researcher / Enterprise Dashboard Architect
**Status:** Wave 0 deliverable — no UI implementation until approved.
**Basis:** `docs/dashboard_research.md` (category studies) + expert analysis of modern
enterprise products. Proven patterns only; nothing invented; nothing copied.

---

## 1. Method

Studied 9 dashboard categories, extracted patterns across 17 UI areas, then adapted
each to HBT's transport operations. A pattern is only adopted if it (a) appears
repeatedly in premium products and (b) serves a real HBT operational need.

| Category | Reference systems |
|---|---|
| Executive Dashboard | Stripe Home, HubSpot Dashboard, Notion Home |
| ERP Dashboard | SAP Fiori, Odoo, NetSuite |
| Fleet Management | Samsara, Fleetio, Geotab |
| Transport Management | FourKites, Project44 |
| Financial Dashboard | QuickBooks, Xero, Stripe Balance |
| Business Intelligence | Tableau, Power BI, Looker |
| POS Dashboard | Square, Lightspeed, Toast |
| Logistics Dashboard | Transporeon, project44 OTP |
| CRM Dashboard | Salesforce, Pipedrive, HubSpot Sales |

---

## 2. Patterns by UI area (extracted → HBT adaptation)

### 2.1 Layout
- **Extracted:** F/Z importance-first; structured zones (header → KPI row → primary
  chart → secondary panels → feed); hero number; content ≤1680px; everything drills.
- **HBT:** Owner Executive layout (zone map in `hbt_dashboard_design.md` §2–§3);
  role layouts in `docs/dashboard_wireframes.md`.

### 2.2 Spacing
- **Extracted:** consistent 4pt/8pt scale; 16–24px gutters; 24px section rhythm;
  cards separated by whitespace, not borders.
- **HBT:** `HbtSpacing` (2–64 scale, tokens); KPI grid gaps 16/20; section gap 24;
  page padding responsive (16 mobile → 24 tablet → 32 desktop).

### 2.3 Typography
- **Extracted:** tabular numerals for money; size = hierarchy (display > KPI > title >
  body > caption); ≤3 weights per screen; dense but legible.
- **HBT:** `HbtTypography` Myanmar-first (Noto Sans Myanmar + Inter); KPI values 32/800
  tabular; labels 13/500; Myanmar numerals in KPIs for `my` locale.

### 2.4 Card hierarchy
- **Extracted:** elevation + emphasis tiers (hero card > standard card > quiet tile);
  consistent radius; one accent per card.
- **HBT:** 4 tiers — Hero (gradient header), Standard (white, radius 14, shadow-sm),
  Quiet (container bg), Status tile (colored edge/icon). Cards never nest more than
  one level.

### 2.5 Charts
- **Extracted:** one chart type per question; trend lines with period context; donut
  for share; bars for comparison; drill-down + tooltip; ≤3 charts on home.
- **HBT:** Revenue trend (line, Day/Week/Month/Year toggle), Expense donut, Branch
  comparison (bars), Trip status (donut), Top routes/vehicles (horizontal bars),
  heatmap (branch × weekday, Owner only).

### 2.6 Tables
- **Extracted:** sort/filter/search mandatory; hover row actions; status chips;
  table→cards below 600px; saved views for power users.
- **HBT:** `HbtAdaptiveTable`; status chips (running/delayed/cancelled/maintenance…);
  row hover → inline actions; saved filters per user (Owner/Finance/HR).

### 2.7 Sidebar
- **Extracted:** dark or neutral rail; icons+labels, collapse to icons; groups
  (≤5 groups, ≤7 items visible); active state always visible.
- **HBT:** **Sidebar #151515** (dark, brand secondary) with #F5F5F5 text; active item
  #AA0000 pill + white text; 4 groups (Operate/Manage/Insight/Admin); 72↔248px
  collapse; badge counts on Approvals.

### 2.8 Navigation
- **Extracted:** ≤7 top destinations; breadcrumbs at depth>1; rail on tablet; bottom
  nav ≤5 on mobile; role-computed menu.
- **HBT:** 12 role menus computed from permissions (hidden, never disabled);
  breadcrumbs on desktop; rail/bottom-nav from `HbtAdaptiveScaffold`.

### 2.9 Filters
- **Extracted:** filter bar above tables/charts (date, branch, route, status);
  global time-range drives all widgets; filters are visible, not buried.
- **HBT:** Global filter (date range + branch + route) on every list + dashboard;
  one time-range control (Today/Week/Month/Year) drives all dashboard widgets.

### 2.10 Search
- **Extracted:** global command search (Stripe `/`, Linear ⌘K); entity results +
  quick actions.
- **HBT:** top-bar search over 11 entity types (charter §18), tenant-scoped, ⌘K on
  desktop; results grouped by type.

### 2.11 Notifications
- **Extracted:** bell + unread badge; grouped (today/earlier); actionable; exception
  loud, success silent.
- **HBT:** approval + exception alerts (delayed/cancelled/cash-diff/expiry);
  announcements feed; each notification has a primary action.

### 2.12 Responsive behavior
- **Extracted:** breakpoint = layout change not font change; priority collapse
  (Gmail model); no horizontal scroll; desktop designed first.
- **HBT:** `docs/responsive_guidelines.md` (Wave 0); validated 320–2560 in
  `docs/responsive_review.md`.

### 2.13 Loading states
- **Extracted:** skeleton screens (not spinners) for data areas; shimmer on cards;
  first paint shows layout so users see structure.
- **HBT:** `SkeletonCard`/`SkeletonTable` components (shimmer, 1.2s, brand-tinted
  grey); skeleton on every KPI group/chart/table; spinners only for full-screen
  transitions.

### 2.14 Empty states
- **Extracted:** empty state = explanation + next action + optional illustration;
  never a bare "No data".
- **HBT:** every list/dashboard area has a named empty state with primary action
  ("No vehicles yet → Create Vehicle" from the readiness dashboard), icon, and
  Myanmar-first copy.

### 2.15 Error states
- **Extracted:** inline error + retry; destructive action confirm; offline banner
  distinct from errors; error messages human, not stack traces.
- **HBT:** inline field errors (bilingual), toast for transient failures, offline
  banner (built), full-screen error with Retry + Contact Support (built via
  `configureFriendlyErrorWidget`).

### 2.16 Accessibility
- **Extracted:** WCAG AA contrast; touch ≥48px; focus rings; semantic labels;
  keyboard navigation; reduced-motion respect.
- **HBT:** contrast-checked tokens (primary on white 7.5:1; #F5F5F5 on #151515
  ~16:1); 48px+ targets; `Semantics` labels on all custom widgets; full keyboard
  path on desktop; `MediaQuery.disableAnimations` → motion off.

### 2.17 Animations
- **Extracted:** subtle and purposeful — hover lift, page transitions ≤220ms,
  animated counters/charts, skeleton shimmer; never decorative loops.
- **HBT:** `HbtMotion` (fast 120 / normal 220 / slow 380); card hover elevation;
  KPI counter animation (count-up on load, 600ms); chart draw-in; page fade/slide
  220ms; reduced-motion disables all.

---

## 3. The "worth paying for" bar

- Premium ≠ decoration: premium = **restraint, hierarchy, density control, and
  consistency** (Stripe, Linear).
- If a screen looks like a free admin template (rainbow charts, stock icons soup,
  unused whitespace, 8 cards in a row), it is redesigned.
- First impression must communicate: professionalism, trust, speed, business
  intelligence.

---

## 4. Cross-references

- Research: `docs/dashboard_research.md` · Components: `docs/dashboard_component_library.md`
- Theme: `docs/theme_guidelines.md` · Wireframes: `docs/dashboard_wireframes.md`
- Responsive: `docs/responsive_guidelines.md` · System: `docs/design_system.md`
