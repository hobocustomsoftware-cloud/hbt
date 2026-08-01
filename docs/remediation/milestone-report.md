# Milestone Report — M5b-001 (F-19: Composite query indexes)

**Date:** 2026-08-01 · **Status:** ✅ Complete
**Commits:** (single commit, see below)

## Task ID
**M5b-001** — F-19 (part 1): composite indexes for org+status+date query patterns (backend)

## Objective
Eliminate full-table scans on the two org-scoped hot models that had **no**
composite indexes, closing the F-19 audit finding. Verification showed most
models (Booking, Trip, CargoShipment, Route, Schedule, Vehicle, Branch,
Feedback, SyncOperation) already had composite indexes from prior work; the
audit claim was **partially stale** — only `Ticket` and `PaymentRecord` were
genuinely missing them.

## Files Changed
| File | Change |
|------|--------|
| `backend/apps/ticketing/models.py` | Added `ticket_org_status_issued_idx` (organization, status, issued_at) to `Ticket.Meta.indexes` |
| `backend/apps/ticketing/migrations/0003_ticket_ticket_org_status_issued_idx.py` | NEW — index migration |
| `backend/apps/payments/models.py` | Added `payment_org_status_date_idx` (organization, status, created_at) to `PaymentRecord.Meta.indexes` |
| `backend/apps/payments/migrations/0007_paymentrecord_payment_org_status_date_idx.py` | NEW — index migration |
| `backend/apps/ticketing/tests/__init__.py` | NEW — test package marker (was missing; also fixes discovery for future ticketing tests) |
| `backend/apps/ticketing/tests/test_composite_indexes.py` | NEW — 6 schema-contract tests |

## Tests Added
- 6 new tests (`apps/ticketing/tests/test_composite_indexes.py`):
  - Ticket model declares the index; index columns exist in the DB (SQLite/PG-aware)
  - Ticket org+status query pattern executes
  - PaymentRecord model declares the index; index columns exist in the DB
  - PaymentRecord org+status query pattern executes
- Backend suite: **118 → 124, all OK** (index migrations apply cleanly)

## Breaking Changes
**None.** Indexes are additive schema changes; no column/table/API/behavior
changes. Django generates forward-only index migrations.

## Rollback
`git revert <commit>` — reverts both index migrations and the model changes.
Indexes can also be dropped independently:
`python manage.py migrate ticketing 0002` + `migrate payments 0006`.

## Remaining Tasks
- **M5b-002** — F-19 (part 2): pagination on cargo/route/refund lists (Flutter business app)
- **M5b-003** — F-23: dead shared widgets / unused routes.dart / features/business rename
- **M5c-001** — F-24: business-app test coverage expansion
- **M5c-002** — F-26: trip-search optimization (server-side filtering)
- **M5c-003** — F-25: localization (EN baseline + MM)
- **F-18b / F-09b** — vendor crash SDK (needs DSN) / cert pinning (needs build infra) — externally blocked
- Final: full production audit → `docs/review/final_production_audit.md`

## Production Readiness Score
**~67/100** (up from ~65; backend query-path hardening adds +2)

| Area | Score | Note |
|------|-------|------|
| Booking integrity | 75 | Unchanged (M0) |
| Offline | 65 | Unchanged (M2+M4) |
| Security | 72 | Unchanged (M5a idle guard; pinning still open) |
| Ops | **77** | +2 — hot org+status+date queries now indexed |
| Architecture | 55 | Unchanged |
| **Overall** | **~67** | |

*Note: scores are estimates based on milestone completion against the three
original audits, not a fresh audit.*
