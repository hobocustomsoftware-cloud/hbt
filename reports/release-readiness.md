# HBT Release Readiness Decision

**Review date:** 2026-08-22  
**Author:** Manus AI  
**Decision:** **NOT READY FOR PRODUCTION**  
**Conditional path:** **READY FOR CONTROLLED STAGING / PILOT PREPARATION**, not live nationwide operation.

## 1. Decision rationale

HBT ၏ backend တွင် core revenue spine နှင့် domain API များ အတော်ပြည့်စုံပြီး Business App တွင် counter booking, fare quote lock, manual payment decision, ticket issue, cargo custody နှင့် owner real-data dashboard အခြေခံများ ရှိသည်။ Owner Dashboard Phase 1 သည် fake/seed data မသုံးဘဲ existing models မှ real aggregates ကို အသုံးပြုထားသည် [1](#references).

သို့သော် production go-live အတွက် သတ်မှတ်ထားသည့် အောက်ပါ conditions များသည် မပြည့်စုံသေးပါ။ Passenger App ၏ review baseline overall score 38/100 နှင့် Business/Backend full audit ၏ production verdict “Not production-ready” သည် အထူးသဖြင့် offline, testing, observability, security နှင့် operational workflow gaps များကို ဖော်ပြထားသည် [2](#references) [3](#references).

## 2. Go / No-Go matrix

| Gate | ဆုံးဖြတ်ချက် | Evidence / လိုအပ်ချက် |
|---|---|---|
| Backend API contract | **Conditional GO** | Broad endpoint catalog and OpenAPI exist; contract tests and deployment smoke still required |
| Database production readiness | **NO-GO** | PostgreSQL is intended, but real staging migration and integrity evidence required |
| Seat-lock integrity | **Conditional GO** | Segment-aware API and Redis mutex contract exist; concurrent PostgreSQL/Redis E2E required |
| Authentication/authorization | **Conditional GO** | Tenant context and server permissions exist; production secret/refresh/device policy must be verified |
| Payment | **NO-GO for automatic live money** | Manual confirmation path exists; provider automation, reconciliation, refund/tax/GL incomplete |
| Business App core pilot | **Conditional GO** | Online core flow exists; device, printer, PostgreSQL E2E and operational training evidence pending |
| Passenger App public launch | **NO-GO** | Test baseline, token refresh/retry, QR, status/notification, localization and security gaps |
| Offline operations | **NO-GO** | Durable encrypted DB/outbox/conflict handling not complete for real mutations |
| Printing/boarding | **NO-GO until device evidence** | Print payload and boarding contracts exist; real printer/camera/device tests pending |
| Cargo safety/legal | **NO-GO nationwide** | NRC/identity, photo proof, capacity, COD, claims and roadside cash controls incomplete |
| Super Admin operations | **NO-GO** | Dedicated Super Admin frontend/dashboard not identified in repository |
| Monitoring/crash response | **NO-GO** | DSN/vendor and production observability evidence not complete |
| CI/CD release gates | **Conditional** | Workflow files exist; successful protected-branch/staging artifact evidence required |
| Backup/restore/rollback | **NO-GO until drill** | Must complete restore drill, migration rollback, and incident runbook test |

## 3. Minimum release gates before 1–3 terminal pilot

Pilot မစတင်မီ production-like staging environment တစ်ခုတွင် PostgreSQL, Redis, object storage, HTTPS, secrets, Sentry/Crashlytics, backups နှင့် monitoring ကို အတည်ပြုရမည်။ Operator-approved master data ဖြင့် terminals, routes/stops, fares, vehicles/layouts, staff, schedules, payment accounts, cargo pricing နှင့် printer profiles ကို load လုပ်ပြီး data integrity checks ဖြတ်ရမည်။

ထို့နောက် counter booking → seat lock → fare quote → manual payment decision → ticket issue → print → boarding validate → trip lifecycle → close/settlement ကို real device နှင့် အဆုံးမှအဆုံး စမ်းသပ်ရမည်။ Test evidence တွင် concurrent seat conflict, payment duplicate/idempotency, permission-denied, printer failure/retry, camera permission, network loss/reconnect နှင့် rollback ပါရမည်။

Passenger App အတွက် public customer launch မလုပ်မီ at least token refresh/retry, booking-flow tests, QR ticket/gate contract, payment pending/rejected status, Burmese localization, retry/error/empty states နှင့် crash capture ကို ဖြည့်ရမည်။

## 4. Nationwide production gates

Nationwide rollout ကို အောက်ပါအချက်များပြီးမှသာ စဉ်းစားသင့်သည်။

| Category | Nationwide requirement |
|---|---|
| Offline | Counter, cargo, conductor/gate mutation queue; encrypted local DB; retry/cursor; conflict resolution |
| Gate/crew | Dedicated manifest, boarding, onboard/roadside sales, waybill, breakdown/exception workflow |
| Finance | Cash float/handover, bank deposit reconciliation, connector settlement, expense approval, tax and GL export |
| Cargo | NRC/identity and photo evidence, COD, claims, parcel tracking, weight/volume/capacity limits |
| Passenger | QR boarding, delay/cancel push/SMS, rebooking/refund status, support channel, group booking |
| Platform admin | Super Admin UI, tenant lifecycle, support grants, subscription/billing, global audit/incident controls |
| Operations | SLOs, alerts, structured logs, crash reporting, on-call, backup/restore, staged rollout and kill switch |

## 5. Recommended release labels

| Label | သုံးနိုင်သည့်အခြေအနေ |
|---|---|
| **READY FOR STAGING** | Environment provisioned, migration/checks clean, contract tests pass, no real customer money |
| **READY FOR CONTROLLED PILOT** | 1–3 terminals, manual payment only, trained staff, printer/boarding E2E, rollback and support on call |
| **READY FOR PRODUCTION** | All critical gates, security evidence, offline operational workflows, monitoring and nationwide SOPs complete |
| **Current HBT status** | **Not ready for production; eligible for structured staging/pilot preparation only** |

## References

[1]: ../docs/implementation/14-owner-dashboard.md "Owner Dashboard Phase 1 real-data implementation"  
[2]: ../flutter/hbt_business_app/docs/review/production_audit.md "Full-stack and Flutter production audit"  
[3]: ../flutter/hbt_passenger_app/docs/review/passenger_review.md "Passenger App full code review"  
[4]: ../docs/implementation/13-flutter-business-delivery.md "Business App delivery record"  
[5]: ../docs/review/business_operation_audit.md "Business operations audit"
