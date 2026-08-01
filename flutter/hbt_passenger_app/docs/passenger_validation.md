# Passenger App Validation — Real Issues

**App:** hbt_passenger_app (19 source files)
**Analysis:** Code review + static analysis (`flutter analyze` passed with 0 issues)
**Scope:** Real issues only — not style preferences, not what-ifs
**Date:** 2026-07-30

---

## 1. Navigation

### 1.1 Null route argument crashes

**Severity:** 🔴 Crash
**File:** `app/passenger_app.dart` (lines 78-89, 94-106)
**Description:** Both `/trip-detail` and `/booking` routes return `null` when their required `trip` argument is missing. Flutter's `Navigator` throws when `onGenerateRoute` returns `null` — `onUnknownRoute` is NOT called for null returns.

```dart
case '/trip-detail':
  final args = settings.arguments as Map<String, dynamic>?;
  final trip = args?['trip'] as Map<String, dynamic>?;
  if (trip != null) { return MaterialPageRoute(...); }
  return null;  // ← CRASH if trip is null
```

**Reproduction:** Navigate to `/trip-detail` without arguments (e.g., deep link, programmatic navigation bug). The app crashes with "Navigator.onGenerateRoute returned null."

**Fix:** Return a fallback route (e.g., 404 screen) instead of `null`.

### 1.2 Splash screen adds latency

**Severity:** 🟡 Performance
**File:** `features/splash/presentation/splash_screen.dart` (line 26)
**Description:** `SplashScreen._init()` adds an unconditional 600ms delay:

```dart
await Future.delayed(const Duration(milliseconds: 600));
```

`PassengerApp._init()` already called `tryRestore()` before the splash rendered. By the time the splash screen mounts, auth state is already known. The 600ms delay is decorative but adds real startup latency. On repeated cold starts, the user waits 600ms of unnecessary blank screen.

### 1.3 PushReplacementNamed with disposed context

**Severity:** 🟡 Reliability
**File:** `features/splash/presentation/splash_screen.dart` (lines 30, 37)
**Description:** The splash uses `pushReplacementNamed` after an async delay. The `if (!mounted) return;` check at line 29 handles dispose before routing. However, between lines 29-30 and 36-37, the widget could unmount (e.g., back gesture). The second `if (mounted)` at line 36 uses a separate conditional from the first check — adding another opportunity for the build context to become invalid between the check and the navigation call.

## 2. Theme Consistency

### 2.1 Duplicate ColorScheme computation

**Severity:** 🟢 Minor
**File:** `core/theme/app_theme.dart` (line 39)
**Description:** `ColorScheme.fromSeed(...)` is called twice — once in the outer `ThemeData` and once inside `CardThemeData` solely to get `outlineVariant`:

```dart
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff00695c)),
// ...
cardTheme: CardThemeData(
  side: BorderSide(
    color: ColorScheme.fromSeed(seedColor: const Color(0xff00695c)).outlineVariant,
  ),
)
```

This creates two separate color scheme instances. The colours will be identical since the seed is the same, but the duplicate computation is wasteful. The `ThemeData`'s color scheme is accessible via context in child widgets, but not at theme build time.

### 2.2 Hardcoded white spinner colour

**Severity:** 🟡 Theming
**File:** `core/widgets/app_button.dart` (line 31)
**Description:** `BusyButton` hardcodes `color: Colors.white` for the progress indicator. If the `FilledButton` theme changes `onPrimary` colour, the spinner colour will mismatch. Should use `Theme.of(context).colorScheme.onPrimary`.

```dart
child: const SizedBox(
  width: 20, height: 20,
  child: CircularProgressIndicator(
    strokeWidth: 2,
    color: Colors.white,  // ← hardcoded
  ),
)
```

Same issue exists in `BusyButtonIcon`, `ActionButtonRow`, and `TripSearchScreen`'s inline `FilledButton.icon`.

### 2.3 StatusChip hardcoded white text

**Severity:** 🟢 Minor
**File:** `core/widgets/status_chip.dart` (line 82)
**Description:** `StatusChip` uses `color: Colors.white` for label text regardless of the chip background colour. If the background is a light colour (e.g., `Colors.amber`, `Colors.orange`), the white text has poor contrast.

## 3. Loading States

### 3.1 TripSearchScreen mixed state management

**Severity:** 🟡 Reliability
**File:** `features/trip/presentation/trip_search_screen.dart`
**Description:** The screen uses `AsyncState` for terminal loading but two separate booleans (`_searching`, `_loadingRoutes`) for route/trip loading. This means:

- Route search errors go into `_state.error` (from `AsyncState`) but `_loadingRoutes` is a separate boolean
- Trip search errors also go into `_state.error`, which conflicts with route errors
- If a route search fails, then a trip search fails with a different error, the second error overwrites the first — the user sees the most recent error, not both

```dart
// Two independent button loading states
bool _searching = false;
bool _loadingRoutes = false;
// ... but errors share a single field
String? error  // from AsyncState
```

### 3.2 BookingScreen loading race condition

**Severity:** 🟡 Reliability
**File:** `features/booking/presentation/booking_screen.dart` (line 80)
**Description:** `_loadInitialData` uses `Future.wait` for seats and travelers, but the loading state check uses:

```dart
if (_state.loading && _seats == null) return const LoadingView();
```

If seats load first (fast API call) but travelers are still pending, `_seats` becomes non-null while `_state.loading` is still true (because `_state.doneLoading()` hasn't been called yet). The condition `_state.loading && _seats == null` evaluates to `true && false = false`, so the loading view hides and the seat grid renders before travelers are available. When `_bookSeat` is called and tries to use `_travelers`, it might crash if `_travelers` is still null.

### 3.3 TripSearchScreen error visibility

**Severity:** 🟡 UX
**File:** `features/trip/presentation/trip_search_screen.dart` (line 258)
**Description:** Error text is rendered at the **very bottom** of `_buildSearchForm()`:

```dart
// Error
if (_state.error != null)
  Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(_state.error!, style: ...),
  ),
```

This is below the date picker, the "Search Trips" button, and the empty routes card. If the form is long (multiple dropdowns, date picker visible), the user must scroll past all form fields to see the error.

### 3.4 TripSearchScreen silent route failures

**Severity:** 🟡 Reliability
**File:** `features/trip/presentation/trip_search_screen.dart` (lines 99-103)
**Description:** Per-org/per-route API failures are silently swallowed:

```dart
try {
  // ... route/stop API calls ...
} on ApiException {
  continue;  // ← silent: no error logged, no user feedback
}
```

If all orgs fail (e.g., network error), `matchedRoutes` is empty, and the screen shows "No routes found between these cities" instead of an error state. The user doesn't know the API failed.

## 4. Empty States

### 4.1 Ticket list empty state lacks action

**Severity:** 🟡 UX
**File:** `features/ticket/presentation/ticket_list_screen.dart` (lines 54-67)
**Description:** The empty ticket state shows icons and text but no actionable button:

```dart
const Text('No tickets yet.'),
const SizedBox(height: 8),
const Text('Search and book a trip to get started.'),
```

The text tells the user to "Search and book" but provides no button to navigate to the search tab. Users must discover the bottom navigation bar on their own. The `EmptyView` widget (which has `actionLabel`/`onAction` parameters) is not used here.

### 4.2 Trip search empty routes lacks icon

**Severity:** 🟢 Minor
**File:** `features/trip/presentation/trip_search_screen.dart` (lines 244-251)
**Description:** The "No routes found" empty state is a plain `Card` with text only — no icon to visually distinguish it from an error:

```dart
const Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('No routes found between these cities.'),
  ),
),
```

Compare with the "No trips found" state which uses `search_off` icon (line 278).

## 5. Error States

### 5.1 Hardcoded red error text colour

**Severity:** 🟡 Theming
**File:** `features/auth/presentation/login_screen.dart` (line 145), `registration_screen.dart` (line 190)
**Description:** Error messages use `style: const TextStyle(color: Colors.red)` instead of `Theme.of(context).colorScheme.error`. Same issue in `TripSearchScreen` (line 258).

```dart
Text(
  widget.auth.error!,
  style: const TextStyle(color: Colors.red),  // ← hardcoded
)
```

### 5.2 TicketListScreen unsafe cast fallback

**Severity:** 🔴 Crash
**File:** `features/ticket/presentation/ticket_list_screen.dart` (lines 36-38)
**Description:** When the API response doesn't have a `results` key, the fallback uses `data.values.toList()`:

```dart
if (data.containsKey('results')) {
  list = data['results'] as List<dynamic>;
} else {
  list = data.values.toList();  // ← UNSAFE
}
setState(() {
  _tickets = list.cast<Map<String, dynamic>>();  // ← CRASH if non-Map values exist
});
```

`data.values` returns all values in the `Map<String, dynamic>`. If the API response is `{'count': 5, 'next': null, ...}`, the values include integers, nulls, etc. The `cast<Map<String, dynamic>>()` will throw `TypeError` at runtime.

**Reproduction:** API returns `{"count": 0, "next": null, "previous": null, "results": []}` without a `results` key. The fallback kicks in and crashes.

### 5.3 ErrorCard not announced by screen readers

**Severity:** 🟡 Accessibility
**File:** `core/widgets/async_views.dart` (`ErrorCard`)
**Description:** `ErrorCard` wraps an error message in a `Card` without any accessibility attributes. Screen readers don't announce it as an error. It should use `Semantics` with `liveRegion` or `role: 'alert'`.

## 6. API Integration

### 6.1 N+1 route search API calls

**Severity:** 🔴 Performance
**File:** `features/trip/presentation/trip_search_screen.dart` (lines 70-113)
**Description:** Finding routes between two terminals makes N+1 API calls:

```
1  GET /me/organizations/
N  GET /organizations/{id}/routes/          (per org)
N×R GET /organizations/{id}/routes/{id}/stops/ (per route)
```

For 3 orgs × 10 routes = **34 API calls** on a single "Find Routes" tap. Over a mobile connection with typical 200-500ms latency, this takes 7-17 seconds. The UI blocks during this time (`_loadingRoutes = true`, no timeout).

**Reproduction:** Tap "Find Routes" with 3 orgs containing 5+ routes each. Count 10-20 seconds of loading.

### 6.2 Booking screen uses `_result!['seat']` without confirmation

**Severity:** 🟡 Reliability
**File:** `features/booking/presentation/booking_screen.dart` (line 360)
**Description:** The success view displays `_result!['seat']` but the server response format may not include a `seat` field at the top level:

```dart
if (_result!['seat'] != null)
  _checkRow('Seat', '${_result!['seat']}'),
```

The server might nest seat info inside `_result['passenger_seats'][0]['seat_position']` or not include it at all. The null check catches absences, but the data binding assumes a flat `seat` key.

### 6.3 API client `.post()` signature divergence

**Severity:** 🟢 Minor
**File:** `core/network/api_client.dart` (line 17)
**Description:** The passenger app's `ApiClient.post()` uses an optional positional parameter for the body:

```dart
Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]);
```

The business app's `ApiClient.post()` uses a named parameter:

```dart
Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
```

This means the two `ApiClient` implementations are not interchangeable. Any shared widget or service code needs to handle both calling conventions.

## 7. Accessibility

### 7.1 Seat grid lacks semantic labels

**Severity:** 🟡 Accessibility
**File:** `features/booking/presentation/booking_screen.dart` (lines 218-253)
**Description:** Each seat in the grid is rendered as a `GestureDetector` with no `Semantics` wrapper:

```dart
return GestureDetector(
  onTap: available ? () => setState(...) : null,
  child: Container(...),
);
```

Screen reader users cannot navigate the seat grid. There's no `semanticLabel` indicating seat number, availability, or state.

### 7.2 No `Semantics` on touch targets throughout

**Severity:** 🟡 Accessibility
**File:** Multiple screens
**Description:** Several tappable elements lack semantic labels:
- Trip search result cards (tappable but no `semanticLabel`)
- Seat grid (as above)
- Info icons in trip detail (`_infoRow` icons are decorative but not excluded from semantics)
- Action buttons have understandable text labels, so this is acceptable for buttons.

### 7.3 Empty/error text not in `Semantics` container

**Severity:** 🟢 Minor
**File:** `core/widgets/async_views.dart`
**Description:** `EmptyView` and `ErrorView` render text without a `Semantics` container. The text is visible, but screen readers don't get semantic hints about the nature of these states (empty vs. error).

## 8. Offline Behaviour

### 8.1 No connectivity monitoring

**Severity:** 🟡 UX
**File:** `core/network/api_client.dart`, all screens
**Description:** The app has no `connectivity_plus` package and no network state listener. When offline, every API call throws `ApiException('No internet connection. Please try again.')`. Screens catch this and show an error view or card — but the user sees it as a generic failure, not an "offline" state.

The app cannot distinguish between:
- Device is offline (no connectivity)
- Device is online but server is down (5xx)
- Device is online but request timed out

All three cases render the same error UI. No offline banner or reconnection UI is shown.

### 8.2 No local cache or offline read support

**Severity: N/A** (expected for MVP — listed for completeness)
**Description:** Every screen makes a fresh API call on mount. There is no local database, no repository layer, no offline queue. When offline, the app shows zero data — even data that was previously loaded in the same session.

### 8.3 tryRestore with expired token + no internet

**Severity:** 🟡 UX
**File:** `core/auth/auth_controller.dart` (lines 41-64)
**Description:** `tryRestore()` attempts a token refresh when the access token is expired. If the device is offline:

```dart
try {
  final result = await api.post('/auth/token/refresh/', ...);
  // ...
} on ApiException {
  await _clearTokens();  // ← clears tokens AND sets authenticated=false
  return false;
}
```

The network error from the refresh attempt is caught as `ApiException`, tokens are cleared, and the user is sent to the registration screen. If they had valid credentials but were temporarily offline, they lose their session and must re-authenticate when connectivity returns.

## 9. Code Quality

### 9.1 Corrupted comment characters

**Severity:** 🟢 Minor
**File:** `features/trip/presentation/trip_search_screen.dart` (lines 62, 63, 65, 114, 266)
**Description:** Comment separator lines use corrupted Unicode characters instead of ASCII `───`:

```
// ── Terminal loading ─────────────────────────────────
```

The `─` characters render correctly on most editors but may appear as `â”€` on terminals or code review tools. This suggests the file was edited with a tool that mangled the original `// ----` comment separators.

---

## Summary

| Category | Issues | 🔴 Crash | 🟡 Reliability/UX | 🟢 Minor |
|----------|--------|----------|-------------------|----------|
| Navigation | 3 | 1 | 2 | 0 |
| Theme | 3 | 0 | 1 | 2 |
| Loading states | 4 | 0 | 4 | 0 |
| Empty states | 2 | 0 | 1 | 1 |
| Error states | 3 | 1 | 1 | 1 |
| API integration | 3 | 1 | 1 | 1 |
| Accessibility | 3 | 0 | 2 | 1 |
| Offline | 2 | 0 | 2 | 0 |
| Code quality | 1 | 0 | 0 | 1 |

**Total: 24 issues (3 crashes, 14 reliability/UX, 7 minor)**
