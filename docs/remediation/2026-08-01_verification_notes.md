# 2026-08-01 — Post-disconnect verification & fixes

## Drive recovery
- External drive remounted as `H:` (was `F:`). `F:\hbt` → `H:\hbt`.
- `.git/` was **empty** (git metadata lost in the 2026-07-31 unclean disconnect).
- Re-initialized git: `git init` + root commit `b04ede8` (1029 files, working tree intact).
- No `F:\hbt` references in source (only in `.dart_tool` build caches, regenerable).

## Verification runs (all green)
| Suite | Result |
|-------|--------|
| Backend `manage.py test` | **118/118 OK** (493s) |
| Business app `flutter analyze` | No issues |
| Business app `flutter test` | **57/57** |
| Passenger app `flutter analyze` | No issues |
| Passenger app `flutter test` | **9/9** |

## Fixes applied today (analyze/test hygiene + error-boundary architecture)
1. Removed unused `_PlaceholderPage` from `business_home.dart`.
2. Removed unused `session` local in `sign_in_widget_test.dart`.
3. Renamed `_buildPage` → `buildPage` (no_leading_underscores) in 3 test files
   (counter_booking, refund_list, trip_list widget tests).
4. Removed unused `quoteId` in `payment_integration_test.dart`.
5. **Error boundary refactor (both apps):** `ErrorWidget.builder` was being set inside
   the MaterialApp `builder:` callback, which trips flutter_test's
   `_verifyErrorWidgetBuilderUnset` guard (addTearDown is too late — verify runs
   before teardown). Moved the assignment into a public
   `configureFriendlyErrorWidget()` called from `main()` only. Production behavior
   unchanged; tests pumping the widget directly no longer mutate global state.
   - `hbt_business_app/lib/app/app.dart` + `lib/main.dart`
   - `hbt_passenger_app/lib/app/passenger_app.dart` + `lib/main.dart`
6. Removed 2 unnecessary `flutter/foundation.dart` imports (passenger app).

## Roadmap status
- M0 Booking integrity: DONE (verified in code: SeatLock model, partial unique index,
  sweep command, create_booking enforcement, TicketValidateActionView, seat APIs with
  active_lock, pagination contract).
- M1 Security: DONE (passenger token refresh, validators, error boundary).
- M2 Offline: DONE (DeviceRegistry/AppDatabase/SyncManager init, connectivity monitor,
  offline banner, sync tab).
- M3 Ops: DONE (health probes, JSON logging, global pagination, CI matrix).
- M4/M5: pending — explicitly not started (user directive: no low-impact cleanup before
  critical items resolved).

## Recommendations
- Run `chkdsk H: /f` at next idle window (dirty volume from 7/31 disconnect).
- Copy repo to C:/D: to remove single-point-of-failure (external USB).
- Consider adding a remote (no remote URL found in README/repo).
