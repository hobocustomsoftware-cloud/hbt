# Flutter Test Repair Report

**Task:** FL-001 — Repair all tests after folder restructuring
**Date:** 2026-07-30
**Status:** ✅ All 40 tests passing (0 failures)

---

## What broke

The folder restructure (FL-002) moved 26 source files to new locations. All 9 test files referenced old import paths that no longer existed.

### Broken imports per file

| Test file | Broken imports | Fixed to |
|-----------|---------------|----------|
| `test/helpers/test_helpers.dart` | 3 | `shared/services/api_client.dart`, `features/auth/controllers/session_controller.dart`, `shared/models/organization_context.dart` |
| `test/features/auth/sign_in_widget_test.dart` | 3 | `shared/services/api_client.dart`, `features/auth/screens/sign_in_screen.dart`, `features/auth/controllers/session_controller.dart` |
| `test/features/booking/counter_booking_widget_test.dart` | 2 | `shared/services/api_client.dart`, `features/ticket_sales/screens/counter_booking_page.dart` |
| `test/features/booking/booking_integration_test.dart` | 1 | `shared/services/api_client.dart` |
| `test/features/payment/payment_integration_test.dart` | 1 | `shared/services/api_client.dart` |
| `test/features/refund/refund_full_flow_test.dart` | 2 | `shared/services/api_client.dart`, `shared/services/refund_service.dart` |
| `test/features/refund/refund_list_widget_test.dart` | 3 | `shared/services/api_client.dart`, `features/refund/screens/refund_list_page.dart`, `features/auth/controllers/session_controller.dart` |
| `test/features/refund/refund_service_test.dart` | 2 | `shared/services/api_client.dart`, `shared/services/refund_service.dart` |
| `test/features/trip/trip_list_widget_test.dart` | 2 | `shared/services/api_client.dart`, `features/trip/screens/trip_list_page.dart` |
| `test/widget_test.dart` | 0 | `main.dart` re-exports from `app/app.dart` — already updated |

---

## Issues found beyond imports

### 1. Missing `wrapInApp` helper

All widget tests referenced `wrapInApp()` which was not defined anywhere. Added to `test/helpers/test_helpers.dart`:

```dart
Widget wrapInApp(Widget child) => MaterialApp(
      home: child,
      theme: ThemeData(useMaterial3: true),
    );
```

### 2. Timer leak from `_HangingApi` classes

3 test files used `Future.delayed(Duration(hours: 1))` in mock API classes to simulate a hanging request. This left a pending timer when the test ended, causing:

```
A Timer is still pending even after the widget tree was disposed.
Failed assertion: line 1617 pos 12: '!timersPending'
```

**Fix:** Replaced `Future.delayed(...)` with `Completer().future` which creates a pending future without scheduling a real timer. The future never completes, which is fine since these tests only check the loading state before `pumpAndSettle`.

Files fixed:
- `sign_in_widget_test.dart` (`_DelayedApi`)
- `counter_booking_widget_test.dart` (`_HangingApi`)
- `refund_list_widget_test.dart` (`_HangingApi`)
- `trip_list_widget_test.dart` (`_DelayedTripsApi`)

### 3. TripListPage uses `api.get()`, not `api.getList()`

The TripListPage source calls `widget.session.api.get(...)` which returns `Map<String, dynamic>` (paginated: `{'results': [...]}`). But the mock classes overrode `getList()`, not `get()`.

**Fix:** Rewrote all mock API subclasses in `trip_list_widget_test.dart` to override `get()` returning `{'results': [...]}` instead of `getList()` returning `[...]`.

### 4. Missing `activeOrganization` in widget test setup

Some widget tests created a `SessionController` without setting `activeOrganization`. Screens like `CounterBookingPage` and `RefundListPage` access `widget.session.activeOrganization!` when loading data. Without it, the async load crashes.

**Fix:** Added a `_buildPage()` factory in counter_booking and refund_list widget tests that sets up a fully configured session with `OrganizationContext`.

### 5. CounterBookingPage shows `ErrorCard`, not `ErrorView`

The counter booking page displays errors inline as `ErrorCard` (not full-screen `ErrorView`). The test expected `ErrorView`.

**Fix:** Changed assertion to find `ErrorCard` instead.

---

## Final test results

```
00:27 +40: All tests passed!
```

| Group | Tests | Passed |
|-------|-------|--------|
| `SignInScreen` | 4 | ✅ 4/4 |
| `CounterBookingPage — loading state` | 3 | ✅ 3/3 |
| `Booking Integration — booking → quote → lock` | 3 | ✅ 3/3 |
| `Payment Integration — record → decide → ticket` | 5 | ✅ 5/5 |
| `Refund Integration — full lifecycle` | 5 | ✅ 5/5 |
| `RefundListPage` | 5 | ✅ 5/5 |
| `RefundService` | 10 | ✅ 10/10 |
| `TripListPage` | 4 | ✅ 4/4 |
| `Default (smoke test)` | 1 | ✅ 1/1 |
| **Total** | **40** | **✅ 40/40** |

---

## Files modified

| File | Change |
|------|--------|
| `test/helpers/test_helpers.dart` | Fixed 3 imports + added `wrapInApp()` |
| `test/features/auth/sign_in_widget_test.dart` | Fixed 3 imports + `_DelayedApi` uses `Completer` |
| `test/features/booking/counter_booking_widget_test.dart` | Fixed 2 imports + `_HangingApi` uses `Completer` + `ErrorCard` assertion |
| `test/features/booking/booking_integration_test.dart` | Fixed 1 import |
| `test/features/payment/payment_integration_test.dart` | Fixed 1 import |
| `test/features/refund/refund_full_flow_test.dart` | Fixed 2 imports |
| `test/features/refund/refund_list_widget_test.dart` | Fixed 3 imports + `_HangingApi` uses `Completer` |
| `test/features/refund/refund_service_test.dart` | Fixed 2 imports |
| `test/features/trip/trip_list_widget_test.dart` | Fixed 2 imports + `get()` overrides + `Completer` |
| `test/widget_test.dart` | No changes needed |

**Total: 9 test files + 1 helper file repaired. 0 source files changed.**
