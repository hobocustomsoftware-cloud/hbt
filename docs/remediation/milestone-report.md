# Milestone Report — M5c-002 (F-26: trip-search discovery caching)

**Date:** 2026-08-01 · **Status:** ✅ Complete

## Task ID
**M5c-002** — F-26: N+1 trip search — cache route-discovery fan-out

## Objective
Passenger trip search fired ~30 uncached calls per search: organizations →
routes-per-org → stops-per-route (the audit's "34 sequential calls"). M4b
already cached search *results*; the discovery fan-out stayed uncached.
Fix: TTL-aware caching of the static discovery data (terminals, orgs,
routes, stops) so repeat searches hit cache, and network failures fall back
to stale data instead of empty results.

## Files Changed
| File | Change |
|------|--------|
| `lib/shared/repositories/trip_repository.dart` | `terminals()`, `organizations()`, `orgRoutes()`, `routeStops()` now cache for `_discoveryTtl` (default 24h, injectable); new `_freshDiscovery()` / `_staleDiscoveryOrErr()` / `_staleDiscoveryList()` helpers; stale fallback preferred over empty-list on failure |
| `test/shared/discovery_cache_test.dart` | NEW — 5 tests |

## Tests Added
- 5 new tests: fresh cache skips network (terminals + orgRoutes), stale cache
  served after TTL on failure, stale cache beats empty list on failure,
  per-route cache keys
- Passenger suite: **51 → 56, all OK**; `flutter analyze` clean

## Breaking Changes
**None.** Repository constructor gained an optional `discoveryTtl` param
(default unchanged). Screen call sites unchanged (same method signatures,
same Result semantics). No backend changes.

## Rollback
`git revert <commit>` restores the pre-cache repository (screens fall back to
network-only discovery).

## Remaining Tasks
- **M5c-003** — F-25: localization (EN baseline + MM strings)
- **F-24 (part 2)** — cargo/trip-detail/routes screen widget tests
- **F-23b** — `features/business` rename (deferred, style-only)
- **F-18b / F-09b** — vendor crash SDK (needs DSN) / cert pinning (needs build infra)
- Final: production audit → `docs/review/final_production_audit.md`

## Production Readiness Score
**~71/100** (up from ~70; search latency + offline resilience improved)

| Area | Score | Note |
|------|-------|------|
| Booking integrity | 75 | Unchanged |
| Offline | **68** | +3 — discovery data now cached (offline route search after first load) |
| Security | 72 | Unchanged |
| Ops | 78 | Unchanged |
| Performance | **62** | +4 — repeat searches skip ~30 calls |
| **Overall** | **~71** | |

*Estimates based on milestone completion against the three original audits.*
