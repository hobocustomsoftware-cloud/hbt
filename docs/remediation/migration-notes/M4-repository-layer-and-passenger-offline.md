# M4 Migration Note — Repository Layer + Passenger Offline

**Author:** OpenClaw Manager
**Date:** 2026-08-01
**Status:** Design (pre-implementation) — per working rules, committed BEFORE code changes.
**Milestone:** M4 (roadmap `merged_audit_findings_roadmap.md`)

## 1. Scope

M4 covers four findings. This note defines the design, sequencing, and risk controls.

| Finding | Title | Priority |
|---------|-------|----------|
| F-20 | No repository layer — screens call HTTP directly | E (but prerequisite for F-13) |
| F-13 | Passenger app has zero offline capability | C (market-critical) |
| F-21 | ~800 LOC duplicated between the two apps | E |
| F-22 | No DI; `SessionController` god class | E |

## 2. Sequencing & dependencies (rule 7: prerequisites first)

```
M4a  F-20 repository layer (passenger app)     → unblocks F-13
M4b  F-13 passenger offline cache + queue      → business value, Priority C
M4c  F-22 lightweight DI                        → enables testability of F-20/F-13
M4d  F-21 shared package extraction            → LAST, highest breakage risk, zero
                                                 user-visible impact
```

- F-21 (shared package) is **deferred within M4**: it is a mechanical move of
  duplicated files into a new package, touches both apps' imports and pubspecs,
  and provides no user-visible value. Per rules 1 & 8 it is done only after
  F-20/F-13 land and are green.
- F-22 in its full form (GetIt/Provider) is **not required** for F-13. M4c uses
  the minimal pattern already present (constructor injection) plus a small
  `RepositoryProvider` scope where needed. No DI framework dependency is added.

## 3. Design — F-20 repository layer (passenger app)

### 3.1 Principle

**Additive, non-breaking.** Repositories are new files wrapping the existing
`ApiClient`. Screens are migrated one at a time; between migrations the app
compiles and runs (old direct calls remain valid until migrated). No screen
signature changes beyond swapping `widget.auth.api` for the repository.

### 3.2 Structure

```
lib/shared/repositories/
├── result.dart                 # Result<T> (success/error) — new, shared
├── trip_repository.dart        # searchTrips(), tripDetail(), routes(), stops()
├── booking_repository.dart     # availability(), acquireLock(), releaseLock(),
│                               #   extendLock(), createBooking()
└── ticket_repository.dart      # myTickets(), ticketDetail()
```

- Each repository takes `ApiClient` via constructor (matches existing style).
- All methods return `Future<Result<T>>` — error type carries user-facing
  message + `ApiException` details; mirrors backend `Result` semantics.
- No caching in M4a (pure passthrough). Cache is added in M4b.

### 3.3 Type-safety

Introduce lightweight DTOs for the passenger flows that M4b will cache:
`TripSummary`, `TripDetail`, `SeatInfo`, `BookingConfirmation`, `TicketSummary`
in `lib/shared/models/`. Parsing moves out of screens into repositories
(validated with `_extractMaps`-style guards already proven in the app).

## 4. Design — F-13 passenger offline (cache + queue)

### 4.1 Goal (scoped)

Offline **read** for trip search results and **queued write** for seat-lock
release is out of scope (lock protocol is server-authoritative by design).
Concretely:

1. **Read cache:** last successful `searchTrips()` response (and trip detail +
   seat map) persisted to local storage; served when offline with a stale flag.
2. **Graceful degraded mode:** offline banner (mirrors business app) + cached
   data marked "offline/stale" in UI; booking attempt while offline shows a
   clear error ("connect to book") — booking stays online-only (data integrity,
   per M0 seat-lock design).

### 4.2 Storage

- Add `sqflite` (plain, not sqlcipher — no PII cached: trips/routes/stops are
  public schedule data) as a passenger-app dependency.
- `AppDatabase` with tables: `trip_search_cache` (payload JSON + fetched_at),
  `trip_detail_cache`, `meta` (schema version).

### 4.3 Connectivity

- Add `ConnectivityMonitor` (copy of business app's proven 15s `/health/` ping)
  in `lib/core/network/`; expose `ValueNotifier<bool> isOnline`.
- Offline banner widget in `passenger_app.dart` MaterialApp builder (same
  pattern as business app).

### 4.4 Behavior matrix

| Action | Online | Offline |
|--------|--------|---------|
| Trip search | hit API, refresh cache | serve cache + "stale data" indicator |
| Trip detail / seats | hit API, refresh cache | serve cache |
| Acquire/release lock | API | blocked with clear error |
| Create booking | API | blocked with clear error |
| My tickets | hit API | serve cache (may be stale) |

## 5. Tests (rule 6 — added with each critical fix, before moving on)

| Component | Test file | Coverage |
|-----------|-----------|----------|
| `Result<T>` | `test/shared/repositories/result_test.dart` | success/error/helpers |
| TripRepository | `test/shared/repositories/trip_repository_test.dart` | parse + error mapping + cache refresh (M4b) |
| BookingRepository | `test/shared/repositories/booking_repository_test.dart` | lock calls + booking + error mapping |
| TicketRepository | `test/shared/repositories/ticket_repository_test.dart` | list parse + error mapping |
| AppDatabase | `test/infrastructure/database/app_database_test.dart` | cache write/read/clear |
| Offline flow | `test/features/trip/trip_search_offline_test.dart` | offline serve + stale flag |
| Error boundary | existing `test/widgets_test.dart` | remains green |

## 6. Migration steps (each = one commit, app runnable after each)

1. **M4a-1** — `result.dart` + DTO models + unit tests. (No behavior change.)
2. **M4a-2** — repositories (passthrough) + repository tests. No screen changes.
3. **M4a-3** — migrate screens one at a time: trip_search → trip_detail →
   booking → ticket_list; each commit keeps analyze + tests green.
4. **M4b-1** — add `sqflite`, `AppDatabase`, cache layer behind repositories.
5. **M4b-2** — `ConnectivityMonitor` + offline banner + stale flags.
6. **M4b-3** — offline widget tests.
7. **M4c** — DI scope (only if needed; constructor injection likely suffices).
8. **M4d** — shared package extraction (separate note to follow).

## 7. Rollback

Each step is a separate commit on `master`. Rollback = `git revert <commit>`.
No schema changes on the backend; no migration beyond adding cache tables to a
new local DB (drop-and-recreate safe — cache only).

## 8. Out of scope for M4

- Business-app repository migration (its screens stay on direct API calls;
  offline sync already active via M2). Revisit after passenger app proves the
  pattern.
- Multi-passenger booking, refund policy UI, manifests (product backlog).
- Certificate pinning, idle timeout, Sentry (M5).
