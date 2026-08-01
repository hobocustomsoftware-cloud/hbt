# HBT — Runtime UI Review

**Date:** 2026-08-01
**Method:** Launched the real stack and walked the actual UI in a browser
(no source review first).
- Django backend: http://127.0.0.1:8000 (seeded demo company: Shwe Yoke Lay Express,
  users for owner/manager/counter/conductor/driver/finance, 2 routes, 4 terminals,
  1 vehicle, 6 trips, fare rules, cargo)
- Business App (Flutter web): http://127.0.0.1:8081
- Passenger App (Flutter web): http://127.0.0.1:8082
- Review via browser accessibility tree + screenshots (text-only model → a11y tree is
  the primary evidence; screenshots archived in `docs/review/screenshots/`)

**Scope note:** the full multi-role walkthrough (conductor/driver/gate/fleet/HR/mechanic)
is limited by what the current build actually implements — those roles have no UI (see
gap analysis). This review covers what exists: passenger app + business app (counter,
owner/manager-permissioned users).

---

## 1. Passenger App (http://127.0.0.1:8082)

### 1.1 First run — Create Account
- App boots to **Create Account** screen (registration is the default first-run flow).
- Fields: Phone Number (with +95 prefix display), Password (with visibility toggle),
  First Name (optional), Last Name (optional).
- Copy: "Join HBT — Create an account to book bus tickets."
- Buttons: Create Account, "Already have an account? Sign in", Back.

**Evidence (a11y tree):** heading "Create Account" [level=2]; textboxes Phone Number /
Password / First Name / Last Name; buttons Create Account / Sign in.

### 1.2 Registration flow (tested live)
- Typed +959751234598 / Demo-pass-123 / Ko / Phyo → Create Account.
- **Validation works:** password field flagged `[invalid]` with "Password is required."
  when the obscured field interaction didn't register (server-agnostic client validation
  is present and visible).
- Retry → **registration succeeded**: navigated to the **Search Trips** home screen.

### 1.3 Home — Search Trips
- Header: "Search Trips", Back, "Show menu" (hamburger).
- Content: "Where are you going?" with **From** and **To** buttons (terminal pickers).
- Tabs: **Search** (selected) | **My Tickets**.
- **Runtime defect:** the From/To area shows a raw error:
  `Failed to load terminals: Bad state: databaseFactory not initialized … When using
  sqflite_common_ffi you must call databaseFactory = databaseFactoryFfi …`
  → The M4 offline cache (`AppCacheDatabase`, sqflite) is **not initialized on web**;
  the cache failure breaks the terminals fetch even though the API returns 200
  (network log confirms GET /terminals/ → 200). **Passenger search is broken on web.**

### 1.4 API connectivity (verified)
- Network log: `/health/` 200, `/auth/register/` 201, `/auth/login/` 200, `/auth/me/` 200,
  `/passenger/tickets/` 200, `/terminals/` 200. App ↔ backend works once CORS is set.

---

## 2. Business App (http://127.0.0.1:8081)

### 2.1 Sign-in
- "HBT Business" + Burmese subtitle "ကားဂိတ်လုပ်ငန်း စီမံခန့်ခွဲမှု" (bus terminal
  operations management).
- Fields: ဖုန်းနံပါတ် (phone), စကားဝှက် (password), button ဝင်မည် (sign in).
- Footer shows the configured API base URL.
- **Localization note:** business app is Burmese-first; passenger app is English-first
  (inconsistent, see gap analysis).

### 2.2 Counter user (+959751234563, counter-sales role, 40 perms) — after login
Lands directly on **Counter Booking**:
- Group "ခရီးသည်" (passenger): traveler pickers, ခရီးစဉ် (trip) picker,
  contact name/phone fields, button "Booking နှင့် Fare Quote ပြုလုပ်မည်"
  (make booking & fare quote).
- Main home (Ticket tab): menu = **Trips, Routes, QR Scanner, Refunds, Sign out,
  Switch organization**; tabs = **Home | Ticket | Cargo | Sync**.
- Ticket tab: "Counter ticket sale …" CTA, "လတ်တလော Booking များ" (recent bookings,
  empty state "Booking မရှိသေးပါ။"), "ထုတ်ပေးထားသော လက်မှတ်များ" (issued tickets,
  empty state).
- **"No Active Shift — Open a counter to start selling."** banner on Home (shift
  workflow is enforced at the UI level).

### 2.3 Owner user (+959751234561, company-owner role, 93 perms) — after login
**Identical UI to the counter user.** Same Home, same menu (Trips/Routes/QR Scanner/
Refunds/Sign out), same 4 tabs, same "No Active Shift" banner, same quick actions:
Manage Trips, Manage Routes, Scan Ticket, New Booking, Refunds, Pending Payments,
Expenses, Profit & Loss.
→ **No role-based navigation.** Owner sees no dashboard, no finance, no users/settings,
no fleet. The blueprint's core requirement (role-driven UI) is **not implemented**.

### 2.4 Trips list (owner session, verified)
- "Trips" screen lists all 6 seeded trips with status filter:
  YM-MORNING-0801, YM-NIGHT-0801, YT-MORNING-0801 (Aug 1); same three for Aug 2 — all
  `planned`, each row with a status checkbox.

### 2.5 Trip detail (verified)
- Trip YM-MORNING-0801: service date, departure 07:00+06:30, arrival 15:00+06:30.
- **UI defect:** route displayed as a raw UUID (`Route: 2048cd87-eb87-…`) — no route
  name resolution.
- Actions: Operations Notes (optional), "Mark Ready" checkbox, "New Booking for this Trip".

### 2.6 Counter Booking flow (verified)
- "New Booking for this Trip" → Counter Booking with trip pre-selected
  ("YM-MORNING-0801 • 2026-08-01T07:00:00+06:30").
- Pickup (စတင်မှတ်တိုင်) / dropoff (ဆင်းမည့်မှတ်တိုင်) stop pickers, contact fields,
  booking CTA. Seat map appears after stop selection (not exercised — would require
  completing a booking; the pickers need valid stop IDs which the trip seed provides).

### 2.7 Navigation observation
- During the walkthrough, refs indicated navigation through Edit Route and Cargo
  Acceptance from the counter home — **the counter UI exposes route management**
  (a scheduling/admin function) at the menu level. API-level permission checks still
  apply (403 without permission), but the menu is not permission-filtered.

---

## 3. Environment / runtime issues found while bringing the stack up

1. **CORS blocks web apps by default (P0, config-level).** The dev CORS fallback regex
   in settings (`r"^http://(localhost|127\\.0\\.0\\.1):[0-9]+$"`) does not match
   `127.0.0.1:<port>` origins — as a raw string, `\\.` is a literal backslash in the
   regex, so the origin never matches. Browser console: "Access to fetch …
   blocked by CORS policy: No 'Access-Control-Allow-Origin' header". Resolved for this
   review by running the backend with `DJANGO_CORS_ALLOWED_ORIGINS` (the documented
   production path). **Any Flutter-web deployment would be dead on arrival without it.**
2. **Passenger app sqflite web break (P0).** `AppCacheDatabase` (sqflite) has no web
   initialization path; the repository cache layer surfaces
   "databaseFactory not initialized" as a user-visible error and breaks search.
   (Works on mobile; web is a supported build target per `flutter build web`.)
3. **Background server lifecycle:** local `python -m http.server` sessions were killed
   by session cleanup (SIGKILL) — needed `Start-Process` detached servers. Deployment
   note, not a product bug.

---

## 4. What works (verified live)

| Area | Status | Evidence |
|------|--------|----------|
| Passenger registration + login | ✅ | 201/200, navigates to Search |
| Passenger client validation | ✅ | "Password is required." inline |
| Passenger API connectivity | ✅ | me/tickets/terminals 200 |
| Business sign-in (Burmese) | ✅ | counter + owner sessions |
| Business trips list + filter | ✅ | 6 trips, status filter |
| Business trip detail + Mark Ready | ✅ | render + actions |
| Counter booking screen (pre-trip) | ✅ | trip pre-selected, stops/contact |
| Shift gating ("No Active Shift") | ✅ | counter cannot sell without shift |
| Cargo acceptance screen | ✅ | renders (shipment/party/terminal/amount) |
| Offline infra presence (mobile) | ✅ | DeviceRegistry/AppDatabase/SyncManager bootstrap (verified earlier) |

---

## 5. What does not exist in the UI (verified absent by walking the actual screens)

- **No conductor UI** (no Assigned Trip / Waybill / Onboard sales / Settlement screens).
- **No driver UI** (no Trip Sheet / Inspection / Fuel / Breakdown).
- **No gate UI** (no manifest / dispatch screen; only QR scan in the shared app).
- **No finance UI** (no Settlement / Bank / Payroll; Profit & Loss exists as a quick
  action but no role separation).
- **No fleet/HR/mechanic UI.**
- **No role-based menu.** All users see the same menu set.
- **No owner dashboard / users / settings screens** in the app.
- **No booking website, no corporate website** in this repo (separate products).
- **No media-channel integration** in the apps (backend has notification + media
  campaign scaffolding).

*Screenshots archived at `docs/review/screenshots/` (passenger-initial, passenger-register,
passenger-search-home, business-owner-home, business-counter-booking).*
