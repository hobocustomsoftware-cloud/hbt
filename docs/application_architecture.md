# HBT Transport Platform — Application Architecture

**Version:** 1.0 · **Date:** 2026-08-01
**Author:** Enterprise Solution Architect
**Purpose:** Target architecture for the integrated transport operating platform.
Complements docs/business_operation_blueprint.md (business spec) and
docs/runtime_gap_analysis.md (current-build measurement).

---

## 1. System context

```
                    ┌─────────────────────────────────────────────┐
                    │              HBT PLATFORM                   │
                    │                                             │
  Public users ───► │  Booking Website        Passenger App      │
  Passengers        │  (web)                  (Flutter)          │
                    │                                             │
  Staff ──────────► │  Business App (Flutter, role-driven UI)    │
  (all roles)       │  └── Counter · Conductor · Driver · Gate   │
                    │      Finance · Fleet · HR · Mechanic ·     │
                    │      Manager · Owner                       │
                    │                                             │
  Corporate ──────► │  Corporate Website (marketing)             │
                    │                                             │
  Public ─────────► │  Media channels (FB/TikTok/TG/Viber/YT/    │
                    │                Email/SMS/Push)             │
                    └──────────────┬──────────────────────────────┘
                                   │ HTTPS (REST/JSON)
                    ┌──────────────▼──────────────────────────────┐
                    │         API GATEWAY + AUTH                  │
                    │   JWT · RBAC · Rate limit · Audit           │
                    └──────────────┬──────────────────────────────┘
                    ┌──────────────▼──────────────────────────────┐
                    │          CORE SERVICES (Django)             │
                    │  Identity · Tenancy · Scheduling · Network  │
                    │  Ticketing · Bookings · Payments · Cargo    │
                    │  Fleet · Workforce · Operations · Offline   │
                    └──────────────┬──────────────────────────────┘
                    ┌──────────────▼──────────────────────────────┐
                    │  DATA: PostgreSQL · Redis cache · Object    │
                    │  storage (evidence/QR) · Message queue      │
                    └─────────────────────────────────────────────┘
```

---

## 2. Client architecture

### 2.1 Business App (single Flutter app, role-driven)

```
lib/
├── app/                  # shell: session, offline bootstrap, role router
├── core/
│   ├── auth/             # AuthController, session
│   ├── network/          # ApiClient (401 refresh, offline queue)
│   ├── theme/            # M3 design system
│   └── widgets/          # shared UI kit
├── shared/
│   ├── models/           # typed DTOs
│   ├── repositories/     # per-domain repositories (Result<T>)
│   └── services/         # crash reporter, idle timeout, audit
├── infrastructure/
│   ├── database/         # local SQLCipher store (offline working set)
│   ├── offline/          # sync manager, queue, conflict resolver
│   └── connectivity/     # reachability monitor
├── features/
│   ├── role_navigation/  # ROLE-DRIVEN menu (the key difference)
│   ├── booking/          # counter booking, seat map, locks
│   ├── conductor/        # waybill, onboard sales, QR, settlement
│   ├── driver/           # trip sheet, inspection, fuel, breakdown
│   ├── gate/             # manifest, validate, dispatch
│   ├── cargo/            # shipments, pricing, claims
│   ├── finance/          # settlement, bank, P&L, payroll
│   ├── fleet/            # vehicles, maintenance, fuel
│   ├── hr/               # staff, rosters, attendance
│   ├── owner/            # dashboard, users, roles, settings
│   └── reports/          # shared reporting
└── routing/              # named routes + role guards
```

**Key design decision:** role-driven navigation is **configuration**, not code.
`RoleMenuConfig` maps (role × permission) → visible menu items. Owner edits roles →
menu changes instantly. No separate apps.

### 2.2 Passenger App
Trip search (cached), booking + seat locks, payment (cash/transfer/online), QR e-ticket,
history, profile, notifications, offline ticket storage.

### 2.3 Booking Website (web)
Same backend; server-rendered or Flutter web; public search without login; booking with
login; ticket verification page.

---

## 3. Backend architecture

### 3.1 Domain modules (current + target)

| Domain | Current | Target additions |
|--------|---------|------------------|
| identity | users, auth, privacy | MFA, device trust |
| tenancy | org, membership, roles, permissions | configurable RBAC UI |
| scheduling | schedules, trips, lifecycle | templates, seasonal plans |
| network | routes, stops, segments | per-route capacity |
| bookings | booking, seat locks, corporate | group booking |
| ticketing | issue, validate, reissue | QR e-ticket payload |
| payments | accounts, records, refunds, connectors | bank deposit rec, GL |
| cargo | shipments, pricing, claims statuses | COD, ID/photo, claims payouts |
| fleet | vehicles, layouts, assignments | maintenance, fuel, docs |
| workforce | staff, drivers, conductors | rosters, attendance, payroll |
| operations | printing, settlement, dashboards | cash handover, cash counts |
| offline | device, sync push/pull | write queue, conflict UI |
| notifications | in-app, pending work | SMS/Viber/email/push providers |
| boarding | boarding records, validate | manifest, headcount, dispatch confirm |
| hr (new) | — | attendance, documents, payroll |
| maintenance (new) | — | work orders, parts |

### 3.2 Service layer & transactions
- All money writes in `@transaction.atomic` with row locks (already the pattern).
- Saga/compensation for multi-step (booking → payment → ticket).
- Idempotency keys on all client-initiated writes.

### 3.3 Sync & offline protocol
- **Cursor-based pull** (current) + **idempotent push queue** (target for writes).
- Conflict policy: seat conflict → suggest; cash dispute → manual review; version conflict
  → LWW with audit.
- Devices register, hold working set (org, routes, trips, seats), sync deltas.

---

## 4. Security architecture
- JWT short-lived access + rotating refresh (current).
- RBAC: permission → role → membership scope (current, needs Owner config UI).
- Field-level encryption for NRC/payment credentials (current).
- Audit trail on all money/approval transitions (current, extend coverage).
- Rate limiting, CSP/HSTS (current).
- Certificate pinning (target), MFA (target), biometrics (target).

---

## 5. Integration architecture
- **Payment connectors:** KBZ Pay, Wave Pay, bank transfer, card — webhook pattern (current
  scaffold) + settlement reports (target).
- **SMS/Viber gateway:** provider adapters (target).
- **Accounting export:** GL/journal CSV or API (target).
- **Media:** scheduled publishing + content calendar (target).

---

## 6. Data architecture
- PostgreSQL system of record; encrypted fields.
- Redis: rate limits, hot cache (routes/stops).
- Object storage: payment evidence, cargo photos, waybill scans.
- Local device DB: SQLCipher (business), plain SQLite (passenger cache).
- Retention policy + privacy (GDPR-style data export exists).

---

## 7. Observability & operations
- Health/live/ready probes (current).
- Structured JSON logging (current).
- Crash reporting via env-gated hook (current; vendor SDK pending DSN).
- Metrics: counters per domain, KPI service (target).
- CI/CD: GitHub Actions (current), staging promotion (target).

---

## 8. Deployment topology (target)
- Regionally close hosting; static assets via CDN.
- API behind load balancer; horizontal app servers; managed Postgres with replicas for
  reporting.
- Device-first design: web apps are deployment targets, mobile is the primary surface.

---

*Architecture decisions recorded for convergence; runtime review measures the delta
(current build vs this target).*
