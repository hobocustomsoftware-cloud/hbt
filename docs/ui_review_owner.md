# UI Review — Owner (Phase 1, Part 1: Company Creation)

**Date:** 2026-08-01
**Reviewer:** CPO / UX Director
**Method:** Implement → launch backend + Flutter web → browser walkthrough → screenshots →
compare vs `docs/ui_master_blueprint.md` → list differences → fix → repeat.
**Scope of this review:** the Owner **first-run onboarding flow** (Create Company wizard).
The Owner Business Dashboard (KPI cards, charts, exports) is the next sub-phase.

---

## 1. What was built and verified live

### 1.1 Backend (committed `5ff9269`)
`POST /api/v1/onboarding/company/` — atomic creation of:
Tenant (language/timezone/currency) → Organization → OrganizationBranding (colors,
name_my/name_en, auto-uniquified slug) → Owner user → active membership + company-owner
role (93 permissions incl. `access.role.manage`, `access.membership.invite`,
`organization.update`).
- 4 tests (full flow, duplicate phone, slug collision, required fields) — **all pass**
- Verified live: create 201 → owner login 200 → org visible with owner permissions

### 1.2 Flutter wizard (committed `6e3360f` + `8e61cf3`)
8-step wizard matching the mandated flow:

| # | Screen (Myanmar) | Verified in browser |
|---|------------------|---------------------|
| 1 | ကုမ္ပဏီ ဖန်တီးရန် (Create Company) | ✅ company name field + example |
| 2 | ကုမ္ပဏီ အချက်အလက် (Company Information) | ✅ legal name/phone/email (optional) |
| 3 | လိုဂို တင်ရန် (Upload Logo) | ✅ picker + "can skip" |
| 4 | လုပ်ငန်းအမျိုးအစား (Business Type) | ✅ 4 large option cards |
| 5 | မူရင်းဘာသာစကား (Default Language — မြန်မာ default) | ✅ (widget-tested) |
| 6 | အချိန်ဇုန် (Timezone — Asia/Yangon default) | ✅ (widget-tested) |
| 7 | ငွေကြေး (Currency — MMK default) | ✅ (widget-tested) |
| 8 | ပိုင်ရှင်အကောင့် ဖန်တီးရန် (Create Owner Account) | ✅ phone/password/name |
| Done | ပြီးပါပြီ။ (Done) | ✅ **E2E success** |

### 1.3 E2E result (live browser, screenshots in `docs/review/screenshots/owner/`)
1. Sign-in screen → "ကုမ္ပဏီ အသစ် ဖန်တီးမလား။" → wizard.
2. Entered "Mandalay Star Express" → advanced step-by-step.
3. Filled owner account → submitted.
4. **Done screen rendered** ("ပြီးပါပြီ။").
5. Backend verified: org "Mandalay Star Express" created, slug
   `mandalay-star-express-3` (auto-uniquified), owner `lang: my`.
6. "Go to Owner Dashboard" → popped to post-login home (auto-login confirmed).

---

## 2. Blueprint compliance check

| Blueprint requirement | Status | Evidence |
|------------------------|--------|----------|
| Myanmar is default | ✅ | All wizard labels Myanmar-first; default language step preselected `my`; owner created with `preferred_language=my` |
| One-hand operation | ✅ | Content top, single primary button bottom (thumb zone), 56px height |
| Large touch targets | ✅ | 56px primary button, 48px+ fields, 18px+ option cards |
| High contrast | ✅ | FilledButton primary, clear labels |
| Simple language | ✅ | Short Myanmar phrases with examples |
| Max 3 taps for common ops | ✅ | Each step = 1 tap; advance = 1 tap; complete = 1 tap |
| Branding captured at onboarding | ✅ | Name (my/en), colors, logo slot (skip allowed) |
| Locale fields (language/timezone/currency) | ✅ | Explicit steps, sensible Myanmar defaults |
| Owner account created with company-owner role | ✅ | 93 perms incl. role/membership management |
| Auto-login after creation | ✅ | Verified: lands on post-login home |
| Step progress indicator | ✅ | 8-segment bar at top |

---

## 3. Differences found vs blueprint (P0/P1/P2) — and fixes applied

### Fixed during this review
| # | Severity | Difference | Fix |
|---|----------|-----------|-----|
| D-1 | **P0** | Submitting sent a client-generated `public_slug`; company names with special chars produced an invalid slug → raw English API error `[Enter a valid "slug"…]` surfaced in the wizard (broken happy path for some names) | **Fixed:** client no longer sends `public_slug`; backend auto-generates + auto-uniquifies (verified: `mandalay-star-express-3`) |
| D-2 | **P1** | API errors shown raw in English (violates "Myanmar default" + "simple language") | **Fixed:** `_localizeError()` maps common errors (dup phone, invalid phone/password) to Myanmar |
| D-3 | **P1** | Done-screen button was a no-op (`onPressed: () {}`) — user stuck on Done | **Fixed:** button pops to the post-login home (verified live) |

### Remaining (accepted for next sub-phase)
| # | Severity | Difference | Note |
|---|----------|-----------|------|
| D-4 | **P1** | Owner lands on the generic post-login home ("Trips" with "No trips found"), NOT the Owner Business Dashboard | The dashboard (KPI cards/charts/exports) is the next Owner sub-phase; the role-based home routing comes with it |
| D-5 | **P2** | Browser autofill injected stale values into wizard fields during the walkthrough | Autofill is a browser behavior; add `autofillHints`/`TextInputType` tuning in polish pass |
| D-6 | **P2** | Logo upload shows file name + checkmark (no image preview) | Preview requires decoding base64 locally; polish pass |
| D-7 | **P2** | Step indicator is a segmented bar (no step numbers/labels) | Acceptable; labels add clutter on small screens |

---

## 4. Scorecard

| Criterion | Result |
|-----------|--------|
| P0 remaining | **0** |
| P1 remaining | **1** (D-4 — Owner Dashboard, scheduled next sub-phase) |
| P2 remaining | **3** (D-5, D-6, D-7) |
| E2E happy path | ✅ works in browser |
| Tests | Backend 4 onboarding tests pass; Flutter 4 wizard tests pass; full suites green (business 86, backend tenancy/branding/identity 23) |
| Analyze | Clean |

**Verdict: onboarding flow is production-quality for the first-run journey.
Proceed to the Owner Business Dashboard sub-phase (KPI cards, charts, exports,
role-based home) — that is the remaining P1 for the Owner role.**

---

## 5. Next steps (Owner phase remaining)
1. **Owner Business Dashboard** — 8+8 KPI cards, charts (revenue trend, sales by
   route/branch, top staff), period control, PDF/Excel export (blueprint §3).
2. **Role-based navigation** — Owner sees Dashboard/Finance/Reports/Fleet/Users/
   Settings; others see only their permitted menus (blueprint §2.2, §5).
3. **Users/Roles/Permissions admin screens** (Owner-only).
4. Re-walk the full Owner journey in the browser; screenshot; review doc update.

*Screenshots: `docs/review/screenshots/owner/` (signin, step1-4, done).*
