# HoBo Transport Backend — MVP Production Readiness

## Scope

This hardening track targets the Backend MVP only. Flutter is out of scope for this backend release gate.

Auto Payment is intentionally out of MVP. Payment remains manual (cash/bank transfer/wallet QR with evidence and staff verification) until a later licensed/provider-backed phase.

## P0 — Release blockers

- [x] Offline sync end-to-end: device authorization snapshot → operation queue → server validation → applied/rejected/conflict → retry/idempotency.
- [x] Tenant isolation tests across organizations, branches, counters, agents and conductors.
- [x] RBAC/action/scope security tests for view/create/update/delete/approve/cancel/export/close/settle.
- [x] Booking → manual payment verification → ticket → boarding integration flow.
- [x] Cargo acceptance → assignment → loading → transit → unloading → handover integration flow.
- [x] Duplicate operation/idempotency protection and conflict handling verified.

P0 is backed by the production-hardening test suite and CI history. The current branch must still pass its final PR CI gate before merge.

## P1 — Operational hardening

- [x] Cashier closing and reconciliation.
- [x] Agent commission and settlement.
- [x] Trip lifecycle and stop operation hardening.
- [x] Seat allocation and segment reuse regression tests.
- [x] QR boarding validation and duplicate scan handling.
- [x] Production printing tests for ticket/payment/cargo/manifest outputs.
- [x] Subscription manual payment/verification lifecycle.
- [x] Basic operational and financial reports.
- [x] Management/operational dashboard checks.
- [ ] Final endpoint-by-endpoint operational scope audit and API-level IDOR/BOLA regression coverage.
- [ ] Final sustained-production performance pass: high-volume query/index review, N+1 verification, bounded/paginated workloads, concurrency review and operational metrics.
- [ ] Final report/export leakage and large-workload verification.
- [ ] Final security threat-detection/incident-response implementation and infrastructure restore drill where the deployment environment permits.

## Production security baseline

The branch includes centralized scope hardening, cross-organization regression coverage, authorization-denial audit telemetry, sensitive-field redaction, security scans, and production security/threat-model/runbook documentation. These controls are release gates, not a substitute for infrastructure-level controls such as WAF, database backups, secret management, network isolation and alerting.

See:

- `docs/production_scope_matrix.md`
- `docs/security/threat_model.md`
- `docs/security/incident_response_runbook.md`

## Explicitly deferred

Auto Payment Gateway, webhook-based automatic verification, automatic reconciliation and automatic refund are post-MVP enhancements.

## Go / No-Go

MVP production release requires all P0 items to pass. P1 critical operational flows must be verified before real customer operations. The backend is not marked production-ready solely by code completion: final release requires green CI, completed scope/performance/security gates, a tested backup/recovery procedure, operational monitoring, secrets/configuration review, and a rollback plan for the actual deployment environment.
