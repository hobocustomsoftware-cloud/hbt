# QA, UAT, Security and SRE Plan / QA၊ UAT၊ Security နှင့် SRE အစီအစဉ်

**Status:** Approved working plan; production evidence pending  
**Applications:** HBT Passenger, HBT Business, API and background workers

---

# မြန်မာဘာသာ

## ၁။ QA test layers

| Layer | စစ်ဆေးရမည့်အရာ | Release evidence |
|---|---|---|
| Unit | Pricing၊ lifecycle၊ permission၊ calculation | Automated test result |
| API contract | Schema၊ validation၊ errors၊ idempotency | Endpoint contract report |
| Integration | PostgreSQL၊ file၊ notification၊ payment adapter | Integration suite |
| Concurrency | Seat၊ payment၊ invoice၊ cargo၊ sync replay | Parallel request result |
| Security abuse | SQLi၊ IDOR၊ mass assignment၊ upload၊ JWT၊ webhook | Finding/retest report |
| Offline | Queue၊ snapshot expiry၊ conflict၊ reconnect | Device/network matrix |
| Recovery | DB/provider/worker failure | Recovery time and data proof |
| UI/device | Myanmar text၊ printer၊ low bandwidth | Supported-device matrix |

QA test case တိုင်းတွင် ID၊ requirement၊ precondition၊ role/scope၊ steps၊
expected result၊ actual result၊ evidence၊ severity နှင့် retest ပါရမည်။

## ၂။ UAT

UAT persona များ—

- Passenger
- Company booking requester/approver
- Counter sales
- Conductor/vehicle assistant
- Driver
- Dispatcher
- Finance
- Terminal manager
- Owner

အဓိက scenario များ—

1. Account ဖွင့်ပြီး trip ရှာ၊ လူများစွာ booking၊ payment evidence၊ e-ticket share။
2. Counter မှ ticket ရောင်း၊ print၊ cash record၊ reprint။
3. Company quote ကြည့်၊ approver approve၊ invoice issue/void။
4. Cargo customer ပြန်ရွေး၊ manual/kg pricing၊ print၊ custody၊ handover။
5. Conductor offline ticket/cargo/boarding ပြီး reconnect/sync။
6. Trip ready မှ closing/settlement/report။
7. Owner feedback ကြည့်၊ priority/status/response ပြောင်း။

Pilot exit target အဖြစ် primary task completion ≥ ၉၀%၊ critical task data-loss
၀၊ tenant leakage ၀၊ unresolved critical defect ၀ ကို recommended baseline
ထားသည်။ User research ဖြင့် final target အတည်ပြုရမည်။

## ၃။ Penetration testing

Production မဟုတ်သော authorized staging သာပထမစမ်းရမည်။ Scope တွင် base URL၊
IP၊ test accounts၊ time window၊ excluded systems၊ data handling၊ emergency
contact နှင့် stop condition ပါရမည်။

ကိုယ်တိုင်စစ်နိုင်သောအရာ—

- OWASP ZAP/Burp authenticated crawl
- Passenger token ဖြင့် Business API IDOR
- Tenant A token ဖြင့် Tenant B UUID access
- SQL injection strings in search/login/filter
- Mass assignment of status/role/amount
- JWT expiry/refresh/revocation
- File type/signature/size/path traversal
- Webhook invalid signature/replay/amount mismatch
- Offline duplicate/conflicting operation IDs
- Rate-limit and login abuse
- Sensitive data in logs/QR/errors

Independent pentest သည် သီးခြားအဖွဲ့/လူက scope အတိုင်းစမ်းပြီး signed report
ထုတ်ရမည်။ Developer self-test ကို independent အဖြစ်မသတ်မှတ်ရ။

## ၄။ SRE dashboard

### Service overview

- Availability
- Request rate
- p50/p95/p99 latency
- HTTP 4xx/5xx
- Active tenants/devices

### Business reliability

- Booking success/expiry/conflict
- Seat double-sale prevention
- Payment pending/confirmed/rejected
- Webhook invalid/quarantined/backlog
- Ticket issue/validation failures
- Cargo custody exceptions
- Trip closing/settlement backlog

### Offline and workers

- Sync push/pull rate
- Oldest outbox age
- Conflict/rejection rate
- Expired authorization snapshots
- Push queue depth/oldest item
- Worker heartbeat/retry/dead-letter

### Infrastructure

- PostgreSQL connections/locks/slow query/storage
- CPU/memory/disk
- Backup age and restore-test result
- File storage usage/errors
- Certificate expiry

Recommended alert baseline—

- API 5xx > 2% for 5 minutes: Critical
- p95 > 2 seconds for 10 minutes: Warning
- Readiness failure: Critical
- Payment webhook backlog oldest > 5 minutes: Critical
- Offline sync backlog oldest > 30 minutes: Warning
- Backup age > 24 hours: Critical
- Certificate expiry < 14 days: Warning

Targets များကို pilot measurement ပြီးပြန်ညှိရမည်။

---

# English

## QA

QA combines unit, API-contract, PostgreSQL integration, concurrency, security
abuse, offline/reconnect, recovery and real-device testing. Every case records
an ID, requirement, role/scope, precondition, steps, expected and actual result,
evidence, severity and retest result.

## UAT

UAT uses passenger, corporate requester/approver, counter, conductor, driver,
dispatcher, finance, manager and owner personas. It covers the complete
booking-payment-ticket, corporate quote-approval-invoice, Cargo Lite,
offline/reconnect, trip-close/settlement and feedback journeys. Recommended
pilot gates are at least 90% primary-task completion, zero data-loss events,
zero tenant leakage and zero unresolved critical defects.

## Penetration testing

Testing begins only on an explicitly authorized staging environment with
fictional data, documented scope and stop conditions. Self-testing covers
OWASP-style IDOR, SQL injection, mass assignment, authentication, upload,
webhook, offline replay, rate-limit and sensitive-data cases. Independent
sign-off requires a separate tester and signed report.

## SRE monitoring

Dashboards cover service traffic/latency/errors, business success and conflict
rates, payment and push queues, offline age/conflicts, worker heartbeats,
PostgreSQL health, resource usage, backup restore evidence and certificate
expiry. Alerts use explicit thresholds and are recalibrated with pilot data.

