# HBT — Runtime Gap Analysis (Blueprint vs Running Application)

**Date:** 2026-08-01
**Method:** Compare the running applications (walked live in a browser) against
`docs/business_operation_blueprint.md` (master business spec). Every gap is classified:

- **P0** — blocks the business (revenue, safety, or the app cannot function)
- **P1** — major capability missing or broken; must be in the next release
- **P2** — enhancement/experience; scheduled

Evidence: `docs/runtime_ui_review.md` + screenshots in `docs/review/screenshots/`.
No code was modified during this review (the two P0 environment issues were worked
around at runtime via documented configuration only).

---

## 1. P0 — Blocks the business

| ID | Gap | Blueprint ref | Runtime evidence |
|----|-----|---------------|------------------|
| **P0-1** | **CORS blocks all Flutter-web API calls by default.** The dev CORS fallback regex never matches loopback origins; any web deployment is dead on arrival without manually setting `DJANGO_CORS_ALLOWED_ORIGINS`. | Blueprint §2 (booking website + web apps) | Console: "blocked by CORS policy: No 'Access-Control-Allow-Origin' header"; verified header absent; works only after env override |
| **P0-2** | **Passenger app is broken on web: offline cache DB not initialized.** `AppCacheDatabase` (sqflite) has no web init path; user-visible "databaseFactory not initialized" error breaks trip search (terminals never load) despite API 200. | Blueprint §2.2 (Passenger App), offline-first §9 | UI shows raw sqflite error in Search screen; network log shows GET /terminals/ 200 |
| **P0-3** | **Conductor has no system at all.** Onboard ticket sales (a major share of trip revenue in Myanmar), waybill, boarding per stop, trip-end cash handover — none exist in the running app. Revenue is invisible and un-auditable. | Blueprint §4.4 (Conductor), §7 cash spine | No conductor screens/roles in business app; only conductor *records* exist server-side |
| **P0-4** | **Driver has no system at all.** No trip sheet (legally required), no pre-trip inspection, no fuel log, no breakdown reporting, no duty-hours control. | Blueprint §4.5 (Driver) | No driver screens/roles in business app |
| **P0-5** | **No role-based UI.** Every user (owner 93 perms, counter 40 perms) sees the identical menu: Trips, Routes, QR Scanner, Refunds, + Home/Ticket/Cargo/Sync tabs + same quick actions. No owner dashboard, no finance, no users/settings. Contradicts the platform's core requirement. | Blueprint §2.1 (role-driven UI), §3 | Verified live: owner and counter sessions show identical Home |

---

## 2. P1 — Major capability missing or broken (next release)

| ID | Gap | Blueprint ref | Runtime evidence / note |
|----|-----|---------------|--------------------------|
| **P1-1** | **Cash chain incomplete.** Shift open/close exists ("No Active Shift" gate works), but no cashier handover, no bank deposit reconciliation, no denomination cash count, no per-cashier sales attribution across relief shifts. | Blueprint §4.3, §7 cash spine | Shift banner present; no handover/deposit UI |
| **P1-2** | **Settlement is trip-level only, no conductor cash settlement.** Settlement endpoints exist (verify/approve) but the conductor side (who holds the cash) has no flow to submit. | Blueprint §4.4 (settlement) | Conductor role absent entirely |
| **P1-3** | **No approval hierarchy UI.** Refund/payment decisions exist as screens, but no configurable approval chain, no escalation, no SLA, no separation-of-duties enforcement. | Blueprint §3.3 approval hierarchy | Refunds/Pending Payments actions exist; approval config absent |
| **P1-4** | **Passenger service recovery absent.** No delay/cancellation notification to booked passengers, no rebooking/transfer, no refund status self-service. | Blueprint §5 (journeys), §6 (channels) | Passenger app: history/tickets only; notifications not surfaced |
| **P1-5** | **No QR e-ticket for passengers.** Tickets exist server-side and scanner validates, but the passenger has no scannable pass in-app; boarding is counter-mediated. | Blueprint §2.2 (QR Ticket), user journeys §7 | Passenger ticket list renders statuses; no QR payload |
| **P1-6** | **Gate/dispatch incomplete.** Trip lifecycle (ready/boarding/depart/en-route/arrive) exists, but no manifest screen, no headcount confirmation, no no-show handling at the gate. | Blueprint §4.7 (Gate) | Shared app has Scan Ticket; no manifest/dispatch UI |
| **P1-7** | **Cargo missing COD, ID/photo capture, claims.** Shipment statuses + pricing + acceptance exist; cash-on-delivery, NRC/photo evidence, claims/payout flow do not. | Blueprint §4.8 (Cargo) | Cargo acceptance screen renders; no COD/claims UI |
| **P1-8** | **Finance reporting shallow.** Profit & Loss quick action exists; no bank reconciliation, no receivables aging, no tax/GL export, no payroll. | Blueprint §4.6 (Finance) | P&L action present; finance role has no distinct UI |
| **P1-9** | **Fleet/HR/mechanic absent.** Vehicles/layouts exist server-side; no maintenance, fuel, rosters, attendance, documents, work orders in the app. | Blueprint §4.9–4.11 | No such screens |
| **P1-10** | **Offline write capability absent.** Offline is read-cache only (passenger) + device sync skeleton (business); counter cannot sell offline, conductor/driver/gate have nothing. | Blueprint §4.3 (offline behaviour), §9 | Connectivity monitor + banner exist; queued writes not delivered |
| **P1-11** | **Localization inconsistent.** Business app is Burmese-first; passenger app is English-first; no language switching. | Blueprint §9 (localization) | Verified: business "ဝင်မည်" vs passenger "Create Account" |
| **P1-12** | **Raw data leaks in UI.** Trip detail shows route as raw UUID; passenger search shows raw sqflite exception text. | Blueprint §9 (quality) | Verified live |

---

## 3. P2 — Enhancements / experience

| ID | Gap | Note |
|----|-----|------|
| P2-1 | Multi-passenger (group) booking in one transaction | Counter + passenger |
| P2-2 | Split payments (cash + transfer) per booking | Common in market |
| P2-3 | SMS/Viber booking confirmation + delay alerts | Channel matrix exists in blueprint §6 |
| P2-4 | Ticket reprint flow after printer jam | Reissue API exists; no clear UI flow |
| P2-5 | Public parcel tracking page | QR resolve exists server-side |
| P2-6 | Booking website + corporate website (separate products) | Not in this repo |
| P2-7 | Media-channel content calendar / publishing integration | Backend campaign scaffolding only |
| P2-8 | Seat preferences (window/aisle/deck) | Passenger UX |
| P2-9 | Passenger feedback/complaint with resolution status | Feedback endpoints exist; passenger UX absent |
| P2-10 | Owner exception feed + KPI dashboard | Dashboard endpoints exist server-side; no UI |
| P2-11 | Fares: promo codes at checkout | Promotions API exists; not surfaced in booking UI |
| P2-12 | Demo-data hygiene: trip list shows planned-only trips with UUID route labels | Seed/UX polish |

---

## 4. Blueprint coverage summary

| Blueprint area | Coverage in running app |
|----------------|--------------------------|
| Passenger self-service (register/login/search/book) | ⚠️ Partially — works until search (P0-2 web), booking flow exists server-side |
| Counter booking + seat locks + shift gate | ✅ Core works (mobile-oriented; web verified to booking screen) |
| Trip lifecycle (planned→…→closed) | ✅ Server + business app (detail, ready, notes) |
| Cargo acceptance + statuses + pricing | ✅ Core (no COD/claims/ID/photo) |
| Refunds + payments (record/verify/decide) | ✅ Core (no approval hierarchy) |
| Conductor / Driver | ❌ Absent |
| Gate manifest/dispatch | ❌ Absent (QR scan only) |
| Finance (settlement/bank/payroll) | ⚠️ Partial (P&L only) |
| Fleet / HR / Mechanic | ❌ Absent |
| Role-based UI | ❌ Absent (same menu for all) |
| Owner dashboard / users / settings | ❌ Absent in app (server endpoints exist) |
| Offline write path | ❌ Absent (read-cache only) |
| Booking/corporate websites | ❌ Not in repo |
| Media channels | ❌ Scaffolding only |

---

## 5. Recommended execution order (from this analysis)

1. **P0-1 + P0-2** — fix CORS config default and sqflite web init (both are small,
   high-blast-radius fixes; the apps literally cannot run on web without them).
2. **P0-5** — role-based navigation (the blueprint's #1 requirement; menu from role
   config; gate admin screens behind permissions).
3. **P0-3 + P0-4** — conductor and driver workflows (the revenue + safety spine).
4. **P1-1/P1-2** — cash handover + conductor settlement (closes the cash loop).
5. **P1-6** — gate manifest/dispatch.
6. **P1-3** — approval hierarchy engine (configurable, with SLA/escalation).
7. **P1-4/P1-5** — passenger notifications, rebooking, QR e-ticket.
8. **P1-7** — cargo COD/claims/evidence.
9. **P1-8/P1-9** — finance depth + fleet/HR/mechanic apps.
10. **P2 backlog** — experience items.

*This is the master business specification's gap register. Each P0/P1 item should be
turned into an epic with the milestone discipline already in place (tests, docs,
separate commits) once approved.*
