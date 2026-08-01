# HBT — Dashboard Gap Analysis (Runtime vs Blueprint)

**Date:** 2026-08-01
**Author:** Product Designer / UX Researcher / Enterprise Dashboard Architect
**Method:** Backend live (`127.0.0.1:8000`) + Flutter web (`127.0.0.1:8081`) launched;
browser walk as an Owner (Mandalay Star Express, +959751234604) through sign-in →
post-login home → module screens. Each screen scored 0–100 against
`docs/hbt_dashboard_design.md`. No code was changed during this review.
**Evidence:** `docs/review/screenshots/dashboard-gap/current-home.png`,
`current-routes.png`; console log excerpted below.

---

## 1. Screen scores

| Screen | Blueprint ref | Score /100 | Verdict |
|--------|---------------|:----------:|---------|
| Sign-in | (onboarding flow, approved) | **78** | Functionally complete, pre-design-system |
| Post-login Home | O-1 Owner Dashboard | **12** | Not a dashboard — an action list |
| Routes list | O-4/O-5 module pattern | **30** | Generic CRUD; no KPIs/performance |
| Trips / Ticket / Cargo / Finance / HR / Reports | O-2…O-10 | **0** | Not yet present in the running app |
| Settings / Users & Roles / Approvals | O-10…O-12 | **0** | Not yet present in the running app |

**Current running UI ≠ the design blueprint.** The design system
(`docs/design_system.md`, validated at all breakpoints) exists but has **not been
adopted** by the running app; the post-login Home is the pre-design-system shell.

---

## 2. Post-login Home vs blueprint (the critical screen)

**What the running app shows (walked live):**
- App bar: "Switch organization Mandalay Star Express" · Trips · Routes · QR Scanner ·
  Refunds · Sign out
- Banner: "No Active Shift — Open a counter to start selling."
- "Quick Actions": Manage Trips · Manage Routes · Scan Ticket · New Booking · Refunds ·
  Pending Payments · Expenses · Profit & Loss
- Bottom tabs: Home · Ticket · Cargo · Sync

### Missing KPIs (18/18 absent)
Ticket Revenue · Cargo Revenue · Expenses · Net Profit · Running Trips · Delayed Trips ·
Cancelled Trips · Passengers Today · Cargo Today · Cash in Counters · Bank Balance ·
Pending Refunds · Pending Approvals · Branch Performance · Top Routes · Top Staff ·
Vehicle Status · Driver Attendance.

### Missing charts
Revenue trend · Trip status mix · Branch performance · Top routes · (all 0 charts).

### Missing actions
Approve (n) · New Trip · New Route · Export PDF/Excel · Manage Branding · Shift-aware
sell flow. The "Quick Actions" grid is generic CRUD, not role-based operations.

### Missing navigation
No sidebar/rail (mobile-style tabs only on desktop) · no global search · no
notification center · no breadcrumbs · no branch switcher in a command bar · no
Reports/Settings/Users/Roles/Fleet/Finance/HR destinations for Owner.

### Missing reports & feeds
No recent-activity feed · no alerts (delayed/cancelled/cash-diff) · no time-range
control (Day/Week/Month/Year) · no report hub · no export.

### Role-based UI
None — every user sees the same menu (known runtime gap; blueprint requires
permission-computed menus with hidden items).

---

## 3. Console errors observed (runtime quality)

| Endpoint | Status | Cause | Severity |
|---|---|---|---|
| `/api/v1/auth/me/` | 401 | Session restore before login (noisy) | P2 |
| `/api/v1/auth/refresh/` | 404 | Refresh endpoint missing/renamed | P1 |
| `/api/v1/me/devices/` | 400 | Device registration payload rejected | P1 |
| `/api/v1/organizations//shifts/active/` | 400 | **Empty org slug in URL** — org context not resolved post-login | **P1** |
| `/api/v1/organizations//branches/` | 400 | Same empty-slug issue | **P1** |

The empty-slug calls mean the Home cannot load shifts/branches — the "No Active Shift"
state is partly an artifact of a broken request, not an accurate empty state.

---

## 4. P0 / P1 / P2 register (design-phase)

| Level | Item |
|-------|------|
| **P0** | None (app runs; no data loss) |
| **P1** | 1. Owner Dashboard (O-1) does not exist — 18/18 KPIs missing. 2. Role-based navigation absent — all users see the same menu. 3. Org slug not resolved post-login (`organizations//` 400s) blocks shift/branch data. 4. `auth/refresh/` 404 breaks token refresh. 5. `me/devices/` 400 blocks device tracking. |
| **P2** | 1. 401 noise on session restore. 2. Pre-design-system visual shell (teal; not brand). 3. Generic CRUD "Quick Actions" not role-based. 4. No global search/notifications/breadcrumbs. 5. No time-range control. 6. No export. 7. No activity/alerts feeds. |

---

## 5. Implementation order (when approved)

Per `docs/design_principles.md` §19 (12 phases) and `docs/hbt_dashboard_design.md` §9
validation gate (**0 P0, 0 P1, ≤3 P2 per screen** after adoption walkthrough):

1. **Design System** — adopt HbtTheme (#AA0000/#151515) + HbtAdaptiveScaffold in the
   real app shell (foundation already validated at all breakpoints).
2. **Company Setup Wizard** — 17-step flow per charter §3 (Company→…→Branding→Finish).
3. **Branding Engine** — OrganizationBranding → theme/tickets/receipts/PDF/websites.
4. **Owner Dashboard** — zones A–H (18 KPI cards + charts + rankings + P&L + exports);
   new backend aggregation endpoints required for most KPIs.
5. **Role Navigation** — permission → menu config; hidden not disabled; 12 role homes.
6. **Users & Roles** — user list + role/permission matrix (Owner-only).
7. **Branch Management** — branches/terminals/counters; tenant chain.
8. **Vehicle & Seat Designer** — vehicle lifecycle + seat layout designer.
9. **Route Wizard** — route→stops→boarding/drop-off→fare→schedule→crew→calendar.
10. **Counter** — Shift Dashboard; sell ≤3 taps; cargo; online-booking approval;
    printer; cash verify; refund*; shift lifecycle.
11. **Conductor** — Assigned Trip Dashboard; offline queue; boarding; QR; settlement.
12. **Passenger** — search→book→pay→QR→history; branding from operator.

**Runtime P1 fixes folded into phases 1–5:** org-slug resolution (`organizations//`
400s), `auth/refresh/` 404, `me/devices/` 400.

Each phase: walk every journey (browser, all breakpoints) → screenshots → update this
document with post-fix scores. Target: Home ≥ 90.
