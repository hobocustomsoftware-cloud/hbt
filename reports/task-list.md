# HBT Release Task List
## Priority ဖြင့် ကျန်ရှိသည့်အလုပ်များ

**ရည်ရွယ်ချက်:** API, Super Admin, Business App, Passenger App တို့ကို real-data pilot နှင့် production သို့ တဖြည်းဖြည်းရွှေ့နိုင်ရန် လိုအပ်သည့် task များကို စုစည်းခြင်း။  
**ရေးသားသူ:** Manus AI  
**Source rule:** Source code မပြင်ဘဲ audit finding အဖြစ်သာ ပြုစုထားသည်။

## Critical Tasks

| ID | ခေါင်းစဉ် | ဖော်ပြချက် / အကြောင်းရင်း | အကြံပြု source area | Effort | Dependencies | Acceptance Criteria |
|---|---|---|---|---|---|---|
| C-01 | Production secrets and runtime dependencies | PostgreSQL, Redis seat-lock, channel Redis, real secret, Sentry/Crash DSN, object storage, HTTPS နှင့် backup ကို staging/prod တွင် provision လုပ်ရန်။ Missing env ကြောင့် local validation settings load မဖြစ်ခဲ့သည်။ | `backend/config/settings.py`, `.env.production.example`, deploy/runbooks | 1–2 days | Ops credentials, vendor decision | `manage.py check`, migration check, health/readiness check နှင့် smoke test များ clean; secrets source control ထဲမပါ |
| C-02 | Seat-lock and booking concurrency E2E | Passenger/counter booking တွင် overlapping segment reservation ကို concurrent clients ဖြင့် စမ်းသပ်ပြီး duplicate booking မဖြစ်ကြောင်း အတည်ပြုရန်။ | `backend/apps/bookings`, Flutter booking/counter screens, integration tests | 2–4 days | PostgreSQL + Redis | Concurrent test တွင် one winner only, lock expiry/release verified, audit trail ရှိ |
| C-03 | Offline business mutation architecture | Encrypted local DB, authorization snapshot, durable outbox, retry/cursor, conflict UI နှင့် idempotency ကို Business App တွင် အပြီးသတ်ရန်။ Network outage တွင် counter/gate/cargo workflow မရပ်ရ။ | `flutter/hbt_business_app/infrastructure/offline`, sync APIs | 1–2 weeks | Device registry, sync contract, conflict policy | Offline sale/cargo/boarding action ကို queue လုပ်နိုင်; reconnect ပြီး server reconciliation; duplicate မဖြစ် |
| C-04 | Gate/conductor operational workflow | Dedicated manifest, gate role, passenger boarding, roadside/onboard sales, waybill, trip exception/breakdown flow ကို ဖြည့်ရန်။ လက်ရှိ revenue/safety gap အကြီးဆုံးဖြစ်သည်။ | Backend operations/boarding, Flutter business features | 2–4 weeks | Product workflow sign-off, device/camera | Conductor/gate user သည် assigned trip manifest ကို offline/online ကြည့်ပြီး validate/board လုပ်နိုင်; supervisor audit ရှိ |
| C-05 | Passenger security and session resilience | Passenger API client တွင် 401 interceptor, single-flight token refresh/retry, idle timeout, certificate pinning decision/rotation plan နှင့် input validation ထည့်ရန်။ | `flutter/hbt_passenger_app/core/network`, auth, config | 3–5 days | Auth contract, cert artifacts, vendor/ops policy | Expired access token သည် re-login မလိုဘဲ refresh; refresh fail သည် safe sign-out; cert rotation test ဖြတ် |

## High Tasks

| ID | ခေါင်းစဉ် | ဖော်ပြချက် / အကြောင်းရင်း | အကြံပြု source area | Effort | Dependencies | Acceptance Criteria |
|---|---|---|---|---|---|---|
| H-01 | Super Admin Dashboard frontend | Platform-level tenant, user, support grant, subscription, incident, audit နှင့် cross-tenant KPI UI မရှိသေး။ | New admin frontend; identity/tenancy/subscription/reporting APIs | 2–4 weeks | Admin RBAC and UX sign-off | Super Admin login, tenant lifecycle, support access expiry, audit export, global health view working |
| H-02 | Passenger automated test baseline | Current review baseline တွင် test file မရှိ။ Core auth/search/seat/booking/ticket paths အတွက် unit/widget/integration tests လို။ | `flutter/hbt_passenger_app/test/` | 1 week | Mock API/repository boundary | CI တွင် tests run; critical paths and error cases covered; no unsafe substring regression |
| H-03 | Passenger e-ticket QR and booking status | Passenger သည် ticket details ရှိသော်လည်း boarding QR၊ payment pending/rejected status၊ cancellation/refund status မပြည့်စုံ။ | Passenger ticket/booking screens; boarding API | 1–2 weeks | QR payload/security policy, gate scanner contract | Valid QR generated, one-time/anti-replay policy verified, status updates visible |
| H-04 | Passenger delay/cancellation notifications | Booked passenger ကို trip delay/cancel ပြောင်းလဲမှု မရောက်သေး။ | Notification/subscription backend and passenger UI | 1–2 weeks | Push/SMS provider and event model | Booked trip status change triggers notification; opt-out and delivery failure logged |
| H-05 | Printing and reprint workflow | Backend print payload ရှိသော်လည်း Bluetooth printer/retry/reprint device evidence မပြည့်။ | Business printing screens/services, printer profiles | 1–2 weeks | Android/iOS device, supported printers | Issue, print, retry, reprint, printed callback and audit log all verified |
| H-06 | Cargo legal and safety controls | Handover NRC/identity evidence, photos/signature, COD, claim/loss, volumetric weight and vehicle capacity checks မရှိသေး။ | Cargo models/API, Business cargo flow | 2–4 weeks | Legal/product policy, storage | Acceptance and handover evidence retrievable; capacity violation blocked; COD/claim ledger reconciles |
| H-07 | Cash and finance reconciliation | Bank deposit, float/handover, denomination count, expense approval, connector settlement, tax and GL export မရှိ။ Cash leakage risk မြင့်။ | Payments, settlements, shifts, reporting | 2–4 weeks | Finance policy/account mapping | Shift close reconciles cash/transfer/bank; differences require reason/approval; export ties to source records |
| H-08 | Master-data import and operational validation | Real terminals, routes, stops, fares, fleets, staff, schedules, payment accounts, cargo prices and printers ကို verified data ဖြင့် loadရန်။ | Management commands/import scripts/admin workflows | 3–5 days | Operator-approved dataset | Staging has complete approved dataset; invalid references and duplicate master records rejected |

## Medium Tasks

| ID | ခေါင်းစဉ် | ဖော်ပြချက် / အကြောင်းရင်း | အကြံပြု source area | Effort | Dependencies | Acceptance Criteria |
|---|---|---|---|---|---|---|
| M-01 | Shared Flutter package/repository layer | Passenger/Business တွင် ~800 LOC ခန့် duplication နှင့် direct HTTP calls ရှိ။ Fix drift နှင့် testability ပြဿနာ။ | New shared package; repositories/DTOs | 1–2 weeks | Architecture decision | Shared API/config/widgets versioned; screens no longer own raw HTTP for migrated flows |
| M-02 | Pagination, query optimization, caching | Large lists, nested serializers, repeated trip discovery calls များအတွက် pagination/prefetch/cache လို။ | DRF settings/serializers, Flutter repositories | 1 week | API contract compatibility | Bounded list responses, query count measured, cache invalidation documented |
| M-03 | Passenger Burmese localization | Current passenger review အရ strings hardcoded English; Myanmar market launch အတွက် MM/EN language support လို။ | Passenger `l10n`, localization resources | 3–5 days | Product language decision | All user-facing strings localized; language switch or locale policy tested |
| M-04 | Retry, empty state, error boundary | Passenger/Business screens တွင် retry/empty states နှင့် global exception handling မပြည့်။ | App shells, async views, API clients | 3–5 days | Shared error taxonomy | 4xx/5xx/network/empty cases render actionable UI; crash captured |
| M-05 | Owner Dashboard expansion | Expenses, shifts, bank balance, full P&L, multi-terminal rollup, exception feed မရှိ။ လက်ရှိ Phase 1 သည် existing model aggregates သာပြ။ | `apps/operations/dashboard.py`, models, Flutter dashboard | 2–3 weeks | Finance/shift model design | New widgets use real aggregates only; no fake fallback; permissions and period filters tested |
| M-06 | CI/CD and release evidence | Workflow files ရှိသော်လည်း current review တွင် release evidence မပြည့်။ Staging build, migrations, tests, security scan, device smoke ကို enforceရန်။ | `.github/workflows`, release checklist | 1 week | Secrets and test devices | Protected branch gates; artifacts retained; staging deploy rollback tested |
| M-07 | Observability and incident response | Crash SDK, structured logs, metrics, alerting, readiness/liveness နှင့် runbook လို။ | Backend logging/health, Flutter crash reporter, SRE runbooks | 1–2 weeks | Sentry/monitoring credentials | Alert fires from synthetic failure; traceable request/user/org correlation; on-call runbook tested |

## Low / Deferred Tasks

| ID | ခေါင်းစဉ် | ဖော်ပြချက် | Effort | Acceptance Criteria |
|---|---|---|---|---|
| L-01 | Rename `features/business` to `features/shell` | Naming consistency; style-only change and import churn။ | 1 day | All imports/build/tests clean |
| L-02 | Unified date/format helpers | Passenger code တွင် formatter မျိုးစုံကြောင့် display inconsistency။ | 1–2 days | One locale-aware formatter used |
| L-03 | Quick actions and Sync tab completion | Business Home quick-action cards တချို့ visual-only နှင့် Sync tab placeholder ဖြစ်နေ။ | 2–4 days | Every action navigates to usable screen; sync state visible |
| L-04 | Passenger deep links/support/history | External booking links, support/lost-found, passenger history and saved travelers တိုးချဲ့ရန်။ | 1–2 weeks | Product flows and analytics accepted |

## Recommended execution order

ပထမဦးစွာ C-01, C-02, C-05 နှင့် H-08 ကို ပြီးစီးစေပြီး controlled pilot ကို ချထားရမည်။ ထို့နောက် H-05, H-03, H-04, H-06, H-07 ကို operational evidence နှင့်အတူ ဖြည့်ရမည်။ Nationwide rollout မတိုင်မီ C-03 နှင့် C-04 ကို မဖြစ်မနေ ပြီးစီးစေရမည်။ H-01 Super Admin Dashboard သည် platform operations အတွက် independent product stream အဖြစ် စတင်နိုင်သည်။

## Source references

[1]: ../backend/README.md "Backend API catalog"  
[2]: ../docs/implementation/13-flutter-business-delivery.md "Business App delivery record"  
[3]: ../docs/implementation/14-owner-dashboard.md "Owner Dashboard real-data implementation"  
[4]: ../flutter/hbt_passenger_app/docs/review/passenger_review.md "Passenger App full review"  
[5]: ../docs/review/business_operation_audit.md "Business operations audit"


## 2026-08-22 Completed in this task

| ID | Completed work | Evidence |
|---|---|---|
| C-01 (partial) | Updated repository release-engineering rule and documented secret/deployment gates; did not add real secrets | `SKILL.md`, `docs/deployment/standalone-saas.md` |
| C-05 (partial) | Added explicit `HBT_AUTOMATIC_PAYMENTS_ENABLED=false` production default and provider-service guard; automatic payment remains opt-in | `backend/config/settings.py`, `backend/apps/payments/services.py`, `backend/.env.production.example` |
| H-02 (partial) | Fixed Business/Passenger analyzer defects and async retry warnings | Both apps `flutter analyze --no-pub --no-fatal-infos`: no issues |
| H-08 (documentation) | Added standalone/SaaS deployment procedure and master-data prerequisites | `docs/deployment/standalone-saas.md` |
| UAT-01 | Added UAT plan, roles, entry/exit criteria, evidence and sign-off framework | `docs/uat/uat-plan.md` |
| UAT-02 | Added executable UAT cases for auth, tenancy, booking, manual payment, ticket, boarding, cargo, settlement, Docker and recovery | `docs/uat/uat-test-cases.md` |
| R-01 | Added production release checklist and updated readiness addendum | `docs/release/production-checklist.md`, `docs/release-readiness.md` |

### Verification results

Backend payment tests pass **20/20** in isolated SQLite/debug mode. Standalone/SaaS middleware and platform access tests pass **5/5**. Django system check passes with no issues in the isolated test profile. Business and Passenger Flutter analyzers both pass with no issues. Full backend test execution reaches 216 tests but has six realtime notification failures when Redis is unavailable; Flutter test execution is blocked by the attached Windows environment because `%PROGRAMFILES(X86)%` is missing. Docker Compose validation is blocked until a real/non-secret `backend/.env.production` and deployment secret file are supplied; no placeholder secret was retained.

### Remaining release blockers

The remaining blockers are external or require additional implementation: PostgreSQL+Redis staging evidence, real secret store, TLS/domain and certificate rotation, private storage, backup/restore drill, printer/camera devices, operator master data, UAT execution/sign-off, realtime Redis service, full Flutter test environment, offline mutation/outbox, dedicated Super Admin UI, and nationwide conductor/gate/cargo/finance workflows. Automatic payment is intentionally excluded from this baseline.
