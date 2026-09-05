# HoBo Transport Backend — MVP Production Readiness

## Scope

This hardening track targets the Backend MVP only. Flutter is out of scope.

Auto Payment is intentionally out of MVP. Payment remains manual (cash/bank transfer/wallet QR with evidence and staff verification) until a later licensed/provider-backed phase.

## P0 — Release blockers

- [ ] Offline sync end-to-end: device authorization snapshot → operation queue → server validation → applied/rejected/conflict → retry/idempotency.
- [ ] Tenant isolation tests across organizations, branches, counters, agents and conductors.
- [ ] RBAC/action/scope security tests for view/create/update/delete/approve/cancel/export/close/settle.
- [ ] Booking → manual payment verification → ticket → boarding integration flow.
- [ ] Cargo acceptance → assignment → loading → transit → unloading → handover integration flow.
- [ ] Duplicate operation/idempotency protection and conflict handling verified.

## P1 — Operational hardening

- [ ] Cashier closing and reconciliation.
- [ ] Agent commission and settlement.
- [ ] Trip lifecycle and stop operation hardening.
- [ ] Seat allocation and segment reuse regression tests.
- [ ] QR boarding validation and duplicate scan handling.
- [ ] Production printing tests for ticket/payment/cargo/manifest outputs.
- [ ] Subscription manual payment/verification lifecycle.
- [ ] Basic operational and financial reports.
- [ ] Management/operational dashboard checks.

## P2 — Production hardening

- [ ] API error contract and idempotency conventions.
- [ ] Production logging and monitoring.
- [ ] Backup and restore verification.
- [ ] Full regression suite.
- [ ] Production deployment checklist and rollback procedure.

## Explicitly deferred

Auto Payment Gateway, webhook-based automatic verification, automatic reconciliation and automatic refund are post-MVP enhancements.

## Go / No-Go

MVP production release requires all P0 items to pass. P1 critical operational flows must be verified before real customer operations. P2 items must have an explicit operational owner and rollback/recovery procedure.
