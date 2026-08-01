# Milestone Report — M5b-003 (F-23: dead code removal)

**Date:** 2026-08-01 · **Status:** ✅ Complete

## Task ID
**M5b-003** — F-23 (part 1): dead shared widgets + unused `routes.dart` (business app)

## Objective
Remove the audit-flagged dead code surface (F-23): 12/22 core widgets had zero
consumers, and `routing/routes.dart` was never imported. Verification
(fresh, not audit-stale) found **6 files** with zero external references —
not 12 — and the unused routes file.

## Files Changed
| File | Change |
|------|--------|
| `lib/core/widgets/data_table.dart` | DELETED (0 external refs) |
| `lib/core/widgets/search_field.dart` | DELETED (0 external refs) |
| `lib/core/widgets/permission_guard.dart` | DELETED (0 external refs) |
| `lib/core/widgets/printer_dialog.dart` | DELETED (0 external refs) |
| `lib/core/widgets/section_header.dart` | DELETED (0 external refs, empty file) |
| `lib/core/widgets/widgets.dart` | DELETED (barrel — never imported) |
| `lib/routing/routes.dart` + `lib/routing/` | DELETED (0 imports; screens use `Navigator.push`) |

## Tests Added
- None new required: pure deletion of zero-consumer files. Regression guard =
  full suite green + analyze clean after removal (71/71, no issues).

## Breaking Changes
**None.** All 7 files were verified to have **zero importers/references**
across `lib/` and `test/` before deletion. No public API removed.

## Rollback
`git revert <commit>` restores all 7 files.

## Remaining Tasks
- **F-23b** — `features/business` → `features/shell` rename: **deferred**
  (style-only, breaks import paths across ~10+ files; rules 1/8 — revisit in a
  dedicated task if desired)
- **M5c-001** — F-24: business-app test coverage expansion
- **M5c-002** — F-26: trip-search optimization
- **M5c-003** — F-25: localization
- **F-18b / F-09b** — vendor crash SDK (needs DSN) / cert pinning (needs build infra)
- Documented debt: duplicate error/loading widgets (`async_views.dart` vs
  `error_states.dart`/`loading.dart` — both imported, consolidation is a
  breaking refactor, parked)
- Final: production audit → `docs/review/final_production_audit.md`

## Production Readiness Score
**~69/100** (up from ~68; dead-code surface reduced, maintainability up)

| Area | Score | Note |
|------|-------|------|
| Booking integrity | 75 | Unchanged |
| Offline | 65 | Unchanged |
| Security | 72 | Unchanged |
| Ops | 78 | Unchanged |
| Maintainability | **58** | +3 — 7 dead files removed (was 12/22 dead widgets) |
| **Overall** | **~69** | |

*Estimates based on milestone completion against the three original audits.*
