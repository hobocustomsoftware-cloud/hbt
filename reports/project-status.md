# HBT Myanmar Express Bus Gate Operation System & Passenger App
## လက်ရှိ Project Status Report

**အစီရင်ခံစာရက်စွဲ:** 2026-08-22  
**ရေးသားသူ:** Manus AI  
**စစ်ဆေးမှုအမျိုးအစား:** Repository/source audit, implementation-note cross-check, non-mutating validation review  
**အဓိကဆုံးဖြတ်ချက်:** **လက်ရှိအခြေအနေသည် Pilot အတွက် အခြေခံ revenue spine ရှိသော်လည်း Production သို့မဟုတ် nationwide rollout အတွက် မအတည်ပြုနိုင်သေးပါ။**

> ဤ report သည် source code ကို ပြင်ဆင်ခြင်း၊ commit ပြုလုပ်ခြင်း မရှိဘဲ လက်ရှိ repository၊ implementation notes နှင့် ရှိပြီးသား review records များပေါ်တွင် အခြေခံထားပါသည်။ Project-level review rule အရ အောက်ပါ findings များကို source files မပြင်ဘဲ report/task အဖြစ်သာ မှတ်တမ်းတင်ထားပါသည်။

## 1. Executive Summary

HBT တွင် Django backend နှင့် Flutter Business/Passenger applications ၏ core အစိတ်အပိုင်းများ ရှိပြီးဖြစ်သည်။ Backend တွင် authentication, multi-tenant organization, route/stop, fleet/workforce, schedule/trip, booking, fare quote, payment decision, ticketing, boarding, cargo, settlement, printing, reporting နှင့် sync contract အထိ domain များကို ဖွဲ့စည်းထားသည်။ Backend README အရ အဓိက API surface တွင် health/auth, organization context, locations, route network, fleet/workforce, schedules/trips, booking/boarding, passenger self-service, cargo/payment/printing/settlement/reporting/sync endpoint များ ပါဝင်သည် [1](#references).

Owner Dashboard Phase 1 သည် demo/seed/fake data မသုံးဘဲ ရှိပြီးသား database model များမှ real aggregate များကို အသုံးပြုထားသည်။ Ticket နှင့် cargo revenue, trip operation status, bookings, confirmed cash/pending refunds, fleet/driver, revenue trend, route/vehicle/branch rankings နှင့် audit/notification pulse များကို real-data အဖြစ် ပြနိုင်သည့်အခြေအနေရှိသည် [2](#references).

သို့သော် **Super Admin အတွက် standalone frontend/dashboard implementation မတွေ့ရပါ**။ Repository တွင် `admin/` နှင့် `api/` အောက်၌ tracked application source မရှိဘဲ backend တွင် Django admin registrations နှင့် identity/platform-access logic များသာ ရှိနေသည်။ ထို့ကြောင့် Super Admin အပိုင်းကို “backend administrative capability ရှိသော်လည်း dedicated Super Admin Dashboard UI မပြီးသေး” ဟု သတ်မှတ်ရမည်။

Business App သည် organization context/permission, ticket worklist, counter booking + locked fare quote, manual payment decision + ticket issue, cargo acceptance/assignment/custody နှင့် owner dashboard တို့တွင် implementation ရှိသော်လည်း seat picker, printing, QR, offline write/outbox, device-scope နှင့် real-device/PostgreSQL evidence များ အပြည့်အဝ မပြီးသေးပါ [3](#references).

Passenger App သည် register/login → trip search → trip detail → seat selection → booking → ticket list/cancel အထိ MVP flow ရှိသော်လည်း current review အရ architecture score 45/100, security 35/100, testing 0/100, offline 10/100 နှင့် overall 38/100 ဖြစ်ပြီး pre-alpha အဆင့်ဖြစ်သည် [4](#references). အထူးသဖြင့် API-level token refresh, QR e-ticket, payment status visibility, notifications, localization, retry/error boundary နှင့် test coverage တို့ကို release မတိုင်မီ ဖြည့်စွက်ရမည်။

## 2. Repository နှင့် Validation Snapshot

| အချက် | လက်ရှိတွေ့ရှိချက် | အဓိပ္ပါယ် |
|---|---|---|
| Backend source tree | `backend/` အောက်တွင် Django project နှင့် app domains များ ရှိ | API/domain foundation ကျယ်ပြန့် |
| Flutter Business source | `flutter/hbt_business_app/` | Business/Counter/Owner workflow foundation ရှိ |
| Flutter Passenger source | `flutter/hbt_passenger_app/` | Passenger MVP flow ရှိ |
| OpenAPI | `backend/openapi.yaml` တွင် `/api/` path entries 186 ခု တိုင်းတာရရှိ | API contract surface အတော်ကျယ် |
| CI workflow files | backend CI, backend coverage, container scan, Flutter CI, Flutter UI smoke ရှိ | Automation foundation ရှိသော်လည်း successful run evidence မစစ်နိုင်သေး |
| Current working tree | Existing tracked modifications နှင့် untracked localization/telegram/backend files တွေ့ | Release မတိုင်မီ change ownership နှင့် review/commit boundary သတ်မှတ်ရန်လို |
| Backend local validation | Default environment တွင် `SEAT_LOCK_REDIS_URL` မသတ်မှတ်ထားသောကြောင့် settings load မအောင်မြင်; ထပ်မံ isolated run တွင် `SENTRY_DSN` production gate တွင် ရပ်တန့် | Environment/secret provisioning မပြီးသေးဟု သက်သေပြ |
| Source-change rule | Review skill အရ source code မပြင်ရန် သတ်မှတ် | ဤ report သည် audit only ဖြစ်ပြီး code fix မပါ |

### Validation Interpretation

Local validation failure ကို code defect ဟု တိုက်ရိုက်မသတ်မှတ်သင့်ပါ။ လက်ရှိ backend settings သည် non-debug mode တွင် `SEAT_LOCK_REDIS_URL` နှင့် `SENTRY_DSN` ကဲ့သို့ production dependencies များကို enforce လုပ်ထားသည်။ ဤ enforcement သည် multi-gate seat-lock integrity နှင့် crash observability အတွက် မှန်ကန်သော်လည်း staging/CI secret injection နှင့် documented test profile မရှိလျှင် developer validation မပြည့်စုံနိုင်ပါ။

## 3. API လက်ရှိအခြေအနေ

### 3.1 ရှိပြီးသား API capability

| Domain | လက်ရှိ API coverage | Real data readiness |
|---|---|---|
| Health/Auth | Health, register, login, refresh, logout, me | **Partial** — endpoint contract ရှိသော်လည်း deployed health/readiness evidence နှင့် environment checks လို |
| Tenant/Authorization | Organization context, memberships, roles, permissions, role assignment | **Ready for controlled pilot** — server-calculated permission context နှင့် server-side mutation authorization ရှိ |
| Locations/Network | Terminals, branches, terminal operations, counters, routes, stops, segments | **Ready after master-data import** |
| Fleet/Workforce | Vehicles, seat layouts/positions, layout assignment, staff, drivers, conductors | **Ready after operational master data and validation rules** |
| Scheduling/Trips | Schedules, trip generation, trip CRUD, vehicle/driver/conductor assignment, lifecycle events | **Ready for pilot with operations sign-off** |
| Booking/Fares | Passenger CRUD, booking, segment-aware seats, fare quote create/lock, confirm/cancel | **Core flow ready; concurrency and end-to-end evidence required** |
| Payment/Ticket | Payment record, authorized decision, ticket issue, ticket view, boarding validation/board | **Manual-payment pilot ready; automatic provider/refund automation incomplete** |
| Cargo | Contact, shipment, assignment, transitions, cargo reporting | **Core workflow present; identity/photo/COD/capacity/claims gaps** |
| Printing | Immutable print-document payload and printed callback | **Contract present; device/printer integration evidence pending** |
| Settlement/Reporting | Trip close, settlement actions, owner dashboard, cargo summary/export | **Real aggregates present; accounting reconciliation gaps** |
| Sync | Bounded bootstrap delta contract | **Contract only; client encrypted DB/outbox/retry/cursor required** |
| Passenger self-service | Traveler, trip search, seat availability, bookings, tickets | **MVP online flow; mobile security/UX/reliability gaps** |

### 3.2 Payment and real-money boundary

Backend README တွင် automatic payment-provider processing နှင့် refunds မပြီးသေးကြောင်း တိတိကျကျ ဖော်ပြထားသည်။ Manual cash, wallet QR နှင့် bank transfer record များသည် authorized confirmation decision လိုအပ်ပြီး booking confirmation သည် manual/external authorization reference ကို traceability အတွက် သိမ်းထားသည် [1](#references). ထို့ကြောင့် **လက်ရှိ real data ဖြင့် စတင်နိုင်သည့် payment mode သည် manual-confirmed pilot model** ဖြစ်ပြီး live automatic gateway settlement ကို production-ready ဟု မသတ်မှတ်ရသေးပါ။

### 3.3 API မပြီးသေးသည့်အပိုင်းများ

API layer ၏ အဓိက gap များမှာ payment provider automation/refund automation, bank settlement reconciliation, tax/GL export, stronger pagination/query optimization, passenger rebooking/transfer, passenger-facing refund status, notification subscription, cargo COD/claims/identity evidence, conductor manifest နှင့် gate-specific operational API/UI တို့ ဖြစ်သည်။ Business operation audit သည် core revenue spine ကို 1–3 terminal pilot အတွက် support လုပ်နိုင်သော်လည်း nationwide system မဖြစ်သေးကြောင်း သတ်မှတ်ထားသည် [5](#references).

## 4. Super Admin Dashboard အခြေအနေ

### 4.1 လက်ရှိရှိသည်ဟု အတည်ပြုနိုင်သည့် backend capabilities

Backend identity/tenancy/admin registrations နှင့် platform access grant logic များ ရှိသည်။ Organization boundaries, memberships, roles, permissions နှင့် time-limited tenant support access ကဲ့သို့ authorization foundation များကို backend README က ဖော်ပြထားသည် [1](#references). Django admin registrations များကို domain apps အများအပြားတွင် တွေ့ရသည်။

### 4.2 မတွေ့ရသေးသည့် dedicated UI

Repository inventory အရ `admin/` နှင့် `api/` အောက်တွင် tracked frontend source မရှိပါ။ ထို့ကြောင့် အောက်ပါတို့ကို **မပြီးသေး/မအတည်ပြုရသေး** ဟု မှတ်ယူရမည်။

| Super Admin capability | Status | လိုအပ်သည့်အလုပ် |
|---|---|---|
| Platform-level web dashboard | **မတွေ့ရသေး** | Separate frontend shell, routing, auth, responsive UI |
| Tenant/org create, suspend, plan control | Backend capability တချို့ရှိနိုင်; UI မအတည်ပြုနိုင် | Admin workflows, confirmation, audit log |
| Cross-tenant KPI and health view | **မပြီးသေး** | Multi-tenant aggregate API နှင့် dashboard |
| Platform user/support access management | Backend grant model ရှိ | UI, expiry, reason, approval/audit flow |
| Global incident/alert center | **မပြီးသေး** | Central observability/alert API and UI |
| Subscription/billing operations | Domain/API surface ရှိ | Super Admin workflow and reconciliation UI |
| Audit/compliance export | Audit model/reporting foundation ရှိ | Filter, export, retention, accountant format |
| Feature flag / kill switch | **မပြီးသေး** | Feature flag service and emergency disable controls |

**အရေးကြီးသောခွဲခြားချက်:** Owner Dashboard ကို Super Admin Dashboard နှင့် မရောထွေးရပါ။ Owner Dashboard သည် organization/owner အဆင့် real aggregates ကိုပြသသည့် Business App feature ဖြစ်ပြီး platform-wide tenant administration မဟုတ်ပါ [2](#references).

## 5. Business App အခြေအနေ

Business App delivery record သည် application structure, secure token storage, organization context, permission-aware UI, ticket worklist, counter booking, fare quote lock, manual payment decision, ticket issue နှင့် cargo worklist/custody operations ကို delivered increments အဖြစ် မှတ်တမ်းတင်ထားသည် [3](#references).

| Feature | Status | Real-data အသုံးပြုနိုင်မှု | ကျန်ရှိသည့်အချက် |
|---|---|---|---|
| Sign-in/session/org selection | Implemented foundation | **Yes, controlled pilot** | Device/session security, full evidence |
| Ticket worklist | Read-only implementation | **Yes, online** | Write actions and offline queue |
| Counter booking | Implemented chain | **Conditional** | Server-backed seat picker, PostgreSQL E2E, rollback/idempotency |
| Fare quote lock | Implemented | **Yes after valid trip/stops/seats** | Failure recovery and evidence |
| Payment decision | Implemented manual flow | **Yes for authorized staff** | requester/approver separation, duplicate/idempotency, device evidence |
| Ticket issue | Implemented server-driven result | **Conditional** | Print/reprint/device integration, audit proof |
| Cargo acceptance/custody | Implemented online transitions | **Conditional** | QR camera, identity evidence, photo, COD, offline, real device |
| Owner Dashboard | Phase 1 real aggregates | **Yes for existing model domains** | Expenses, shifts, bank balance, P&L completeness, multi-terminal rollup |
| Scanner/boarding | Backend contract and app surface | **Pilot evidence required** | Camera permissions/error handling and validation state update |
| Offline/sync | Design/contracts and partial UI | **No for real offline mutations** | Encrypted DB, durable outbox, conflict resolution, cursor/retry |
| Printing | Backend immutable payload contract | **Not yet proven** | Bluetooth printer profiles, retry/reprint, device test |

Business App delivery note အရ Flutter analyzer/Dart analysis နှင့် focused backend checks အချို့ ဖြတ်သန်းထားသော်လည်း widget/device/PostgreSQL end-to-end evidence များသည် environment responsiveness မပြည့်စုံမှုကြောင့် pending ဖြစ်သည် [3](#references). ထို့ကြောင့် “code path ရှိသည်” နှင့် “production device မှာ အတည်ပြုပြီး” ကို သီးခြားထားရမည်။

## 6. Passenger App အခြေအနေ

Passenger App တွင် core online booking journey ရှိသော်လည်း current review ၏ overall score သည် 38/100 ဖြစ်သည်။ Review မှာ zero test coverage, passenger API client တွင် normal-use 401 အတွက် automatic token refresh/retry မရှိခြင်း, typed DTO/repository မရှိခြင်း, hardcoded English strings, unsafe booking-ID substring, zero offline capability နှင့် duplicated shared code ~800 lines ခန့်ကို ဖော်ပြထားသည် [4](#references).

| Area | လက်ရှိအခြေအနေ | Real data ဖြင့် readiness |
|---|---|---|
| Register/Login | Phone + password, secure storage, restore | **MVP online only** |
| Trip search | Terminal/route/stop/date search | **Online pilot after master data** |
| Seat selection | Search/detail/seat booking flow ရှိ | **Concurrency and server lock evidence required** |
| Booking | Passenger booking flow ရှိ | **Online only; failure recovery needed** |
| Payment | Evidence upload/manual record path | **Pending verification UX; not automatic payment** |
| Ticket list | Issued tickets display | **Online only; no QR boarding pass** |
| Cancellation | Cancel booking path | **Refund/rebooking visibility incomplete** |
| Notifications | No complete booked-trip delay/cancel subscription flow | **Not ready** |
| Localization | Current review တွင် English hardcoded; uncommitted localization files လည်းတွေ့ | **Needs verification and completion** |
| Testing | Review baseline 0 tests | **Not release-ready** |
| Offline | Review baseline 10/100; no local DB/outbox/connectivity monitor | **Not ready** |

### Passenger release blockers

Passenger side တွင် automatic token refresh/401 retry, booking ID safety fix, automated unit/widget/integration tests, Burmese localization, retry and empty/error states, e-ticket QR, payment pending/status, delay/cancel notification, refund/rebooking, secure network policy and idle timeout တို့ကို အနည်းဆုံး release gate အဖြစ် သတ်မှတ်သင့်သည်။ Myanmar network condition ကို ထည့်သွင်းစဉ်းစားလျှင် offline read cache သာရှိပြီး write queue မရှိခြင်းသည် nationwide rollout အတွက် အရေးကြီးသော blocker ဖြစ်သည် [4](#references) [5](#references).

## 7. Owner Dashboard နှင့် Real Data Readiness

Owner Dashboard Phase 1 သည် existing models မှ real aggregate များကို အသုံးပြုထားပြီး fake data မထည့်ထားခြင်းက အားသာချက်ဖြစ်သည်။ လက်ရှိရနိုင်သည့် data zone များမှာ ticket/cargo/total revenue, trip status/on-time metric, passenger/cargo counts, booking status, confirmed cash/pending refunds, fleet/driver, revenue trend, route/vehicle/branch ranking, audit activity နှင့် notification pulse ဖြစ်သည် [2](#references).

အောက်ပါ dashboard zones များသည် backend domain model မရှိသေးသဖြင့် intentionally omitted ဖြစ်သည်။

| Omitted zone | လိုအပ်သည့် backend model/အလုပ် |
|---|---|
| Expenses / expense breakdown | `Expense` model + endpoint + approval/ledger semantics |
| Shifts / cash difference / counter performance | `Shift` model + opening/closing/handover workflow |
| Bank balance | Bank/ledger/reconciliation model |
| Net profit / complete P&L | Revenue + expense + tax + allocation model |
| Approval action cards | Existing decision endpoint ကို dashboard action UX နှင့် ချိတ်ရန် |
| Multi-terminal/network rollup | Multi-branch aggregate queries and permissions |

ထို့ကြောင့် dashboard card တစ်ခုတွင် 0 သို့မဟုတ် “No data” ပြခြင်းသည် fake data မထည့်ဘဲ domain မရှိသေးခြင်းကို ဖော်ပြခြင်းဖြစ်နိုင်ပြီး bug ဟု တိုက်ရိုက်မသတ်မှတ်သင့်ပါ။

## 8. End-to-End Real Data လုပ်ရန် အဆင့်လိုက်လိုအပ်ချက်

### Phase A — Staging data and environment readiness

ပထမအဆင့်တွင် PostgreSQL, Redis seat-lock mutex, channel-layer Redis, object/private media storage, real secret injection, Sentry/Crashlytics vendor decision and DSN, HTTPS certificate, allowed hosts, backups နှင့် monitoring ကို staging environment တွင် ပြင်ဆင်ရမည်။ Current local run က required `SEAT_LOCK_REDIS_URL` နှင့် `SENTRY_DSN` မရှိလျှင် settings load မဖြစ်ကြောင်း ပြသထားသဖြင့် environment checklist ကို release gate အဖြစ် ထားရမည်။

### Phase B — Master data import

Organization/company, terminals/branches/counters, route/stops/segments, fare rules/promotions, vehicles/seat layouts, staff/driver/conductor, schedules and service dates, payment receiving accounts, cargo categories/pricing နှင့် printer profiles များကို verified operational data ဖြင့် seed/import လုပ်ရမည်။ Seed data သည် demo-only မဟုတ်ဘဲ operator-approved staging dataset ဖြစ်ရမည်။

### Phase C — Controlled pilot workflows

1–3 terminals အတွက် counter booking → fare quote lock → manual payment decision → ticket issue/print → boarding validation → trip lifecycle → close/settlement ကို PostgreSQL နှင့် real devices ဖြင့် အဆုံးမှအဆုံး စမ်းသပ်ရမည်။ Passenger side တွင် register → search → seat → booking → payment pending → ticket view/cancel ကို အမှန်တကယ် test accounts နှင့် စမ်းသပ်ရမည်။

### Phase D — Nationwide blockers

Nationwide rollout မတိုင်မီ offline mutation/outbox, conductor/gate app, passenger QR boarding, delay notifications, cash chain/reconciliation, maintenance/document expiry, cargo identity/photo/COD/capacity/claims, finance/tax/GL integration, Super Admin UI နှင့် observability/incident response များ ပြီးစီးရမည်။

## 9. Overall Conclusion

**လက်ရှိ release decision: NOT READY FOR PRODUCTION.** သို့သော် backend revenue spine နှင့် Business App core operations သည် **controlled pilot at 1–3 terminals** အတွက် အခြေခံကောင်းရှိသည်။ Pilot အတွက်လည်း real PostgreSQL/device evidence, manual payment controls, printer/boarding verification, staff training, rollback and incident plan မရှိဘဲ live money operation မဖွင့်သင့်ပါ။

Passenger App ကို current review baseline အတိုင်း **pre-alpha / online MVP** အဖြစ်သာ သတ်မှတ်ပြီး public launch မပြုသင့်သေးပါ။ Super Admin Dashboard ကို dedicated frontend အဖြစ် မတွေ့ရှိသေးသောကြောင့် platform operations အတွက် အရေးကြီးဆုံးကျန်ရှိသည့် product area တစ်ခု ဖြစ်သည်။

## References

[1]: ../backend/README.md "HBT Backend README — API catalog and implementation boundaries"  
[2]: ../docs/implementation/14-owner-dashboard.md "Owner Dashboard — Implementation Notes (Phase 1)"  
[3]: ../docs/implementation/13-flutter-business-delivery.md "Flutter Business Delivery Record"  
[4]: ../flutter/hbt_passenger_app/docs/review/passenger_review.md "HBT Passenger App — Full Code Review"  
[5]: ../docs/review/business_operation_audit.md "HBT Platform — Business Operations Audit"


## 10. 2026-08-22 implementation update

User-approved implementation changes were applied without committing the repository. The project `SKILL.md` now permits safe source/config/test/documentation changes while preserving tenant isolation, auditability, fail-closed production secrets, manual-payment boundaries, and explicit standalone/SaaS deployment rules.

Automatic payment-provider charging is now explicitly controlled by `HBT_AUTOMATIC_PAYMENTS_ENABLED` and defaults to `false`. The production environment template also sets this value to `false`. Provider-initiation tests opt in only for isolated sandbox tests, and a regression test confirms that provider initiation is rejected when the flag is disabled. Manual payment remains the supported production baseline.

Three payment runtime import defects were corrected: UUID generation in the payment model, SHA-256 hashing in payment services, and Django validation-error conversion in payment serializers. Both Flutter apps now pass `flutter analyze --no-pub --no-fatal-infos` with no issues. The backend payment suite passes 20/20 tests in isolated SQLite/debug mode.

The full backend suite discovered six realtime notification errors when Redis is unavailable in the attached environment; this is an infrastructure test dependency and is not evidence of a clean production run. Flutter test execution was blocked by the attached Windows environment reporting a missing `%PROGRAMFILES(X86)%` variable. These two facts remain release evidence gaps and must be rerun in Docker/staging with PostgreSQL, Redis, and a supported Flutter CI/device environment.

New UAT and deployment documents were added under `docs/uat/`, `docs/deployment/standalone-saas.md`, and `docs/release/production-checklist.md`. Production is still not declared ready until the external environment, UAT sign-off, backup/restore, TLS/domain, private storage, printer/camera, and monitoring evidence are attached.
