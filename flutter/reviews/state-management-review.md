# State Management & Duplicate State Review

**Date:** 2026-07-29  
**Scope:** `hbt_business_app` (13 screens) + `hbt_passenger_app` (6 screens) + core  
**Pattern:** `StatefulWidget` + `setState` + `ChangeNotifier`  
**Policy:** No business logic changes. UI/state layer only.

---

## Assessment

The apps use **hand-rolled MV-ish** with `StatfulWidget` managing per-screen state and `ChangeNotifier` for cross-cutting concerns (`SessionController`, `AuthController`). This works correctly but has heavy duplication — the same loading/error/data/response-parsing boilerplate is copy-pasted across 18 presentation files.

No migration to Riverpod or Provider is recommended at this stage. The measurable duplication can be eliminated with shared utilities and widgets without touching business logic or screen architecture.

---

## 1. Duplicate Pattern Inventory

### 1A — Loading / Error / Action Booleans (12+ screens)

Every data-fetching screen defines the same 2–3 booleans independently:

| Screen | Loading | Error | Action |
|---|---|---|---|
| `sign_in_screen.dart` | `_submitting` | `SnackBar` | — |
| `route_list_page.dart` | `_loading` | `_error` | — |
| `route_detail_page.dart` | `_saving` | `SnackBar` | — |
| `trip_list_page.dart` | `_loading` | `_error` | — |
| `trip_detail_page.dart` | `_acting` | `_error` | — |
| `ticket_sales_page.dart` | `_loading` | `_error` | — |
| `counter_booking_page.dart` | `_loading` + `_submitting` | `_error` | — |
| `payment_decision_page.dart` | `_busy` | `_error` | — |
| `cargo_worklist_page.dart` | `_loading` | `_error` | — |
| `cargo_acceptance_page.dart` | `_loading` + `_saving` | `_error` | — |
| `ticket_list_screen.dart` | `_loading` | `_error` | — |
| `booking_screen.dart` | `_loadingSeats` + `_booking` | `_error` | — |
| `trip_search_screen.dart` | 5 separate booleans | `_error` | — |

**Variations:**
- `_submitting` / `_acting` / `_busy` / `_booking` / `_saving` — all mean "action in progress"
- `_searching` / `_loadingRoutes` / `_loadingSeats` / `_loadingTerminals` — all mean "data fetch in progress"
- Turnaround time: **5 distinct authors would each name these differently** (they did)

### 1B — Duplicate Response-Parsing Helpers (5 implementations)

```dart
// hbt_business_app:
// counter_booking_page.dart, cargo_acceptance_page.dart — `_maps(List<dynamic>)`
List<Map<String, dynamic>> _maps(List<dynamic> values) =>
    values.whereType<Map<String, dynamic>>().toList();

// hbt_passenger_app:
// trip_search_screen.dart — `_extractList()` + `_toMapList()`
List<dynamic> _extractList(dynamic response) { /* handles List and {results:...} */ }
List<Map<String, dynamic>> _toMapList(List<dynamic> list) { /* same as _maps */ }

// booking_screen.dart — `_extractMaps()`
List<Map<String, dynamic>> _extractMaps(dynamic response) { /* handles List and {results:...} */ }

// ticket_list_screen.dart — inline raw cast
list = data['results'] as List<dynamic>;
```

**Business logic duplication:** The `api_client` `_requestList()` already unwraps `{results: [...]}`. Most callers don't need to re-unwrap — they can use `api.getList()` directly. Only `RouteListPage`, `TripListPage`, `TripSearchScreen`, `TicketListScreen` call `api.get()` and unwrap manually. Some do, some don't — inconsistent.

### 1C — Duplicate Error-State UI (7+ screens)

Identical pattern repeated:

```dart
Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('Retry')),
      ],
    ),
  ),
);
```

Found in: `route_list_page.dart`, `trip_list_page.dart`, `ticket_list_screen.dart`, `booking_screen.dart`, `trip_search_screen.dart`, `counter_booking_page.dart`, `cargo_worklist_page.dart`.

Minor variations: error text color, icon size, retry button text. Identical structure.

### 1D — Duplicate Empty-State UI (4+ screens)

```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.route_outlined, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('No routes yet.'),
      const SizedBox(height: 12),
      FilledButton.icon(..., onPressed: _createRoute, ...),
    ],
  ),
);
```

Found in: `route_list_page.dart`, `trip_list_page.dart`, `ticket_list_screen.dart`, `ticket_sales_page.dart`.

### 1E — Duplicate `_statusColor` Lookups (4 screens)

Each screen defines its own mapping:

| Screen | Map source |
|---|---|
| `route_list_page.dart` | `active→green, draft→grey, approved→blue, …` |
| `trip_list_page.dart` | `planned→grey, ready→blue, boarding→orange, …` |
| `trip_detail_page.dart` | `planned→grey, ready→blue, boarding→orange, …` (identical to trip_list) |
| `ticket_list_screen.dart` | `issued→blue, validated→green, boarded→teal, …` |

The trip screens duplicate the same 10-entry color map. This is particularly wasteful — it will inevitably drift.

### 1F — Duplicate `mounted` Guard Pattern (every screen)

Every async callback (22 occurrences) follows:
```dart
if (mounted) setState(() { ... });
```

This is inherent to `StatefulWidget` async patterns. Not fixable per-screen. A shared state wrapper could eliminate it.

### 1G — Duplicate `ApiClient` + `ApiException` (both apps)

`hbt_business_app/lib/core/network/api_client.dart` (190 lines)  
`hbt_passenger_app/lib/core/network/api_client.dart` (160 lines)

Contents are ~95% identical. The passenger variant has `_requestList` and `_request` with the same logic, just minor differences in error message strings (`မမှန်ပါ` vs `Invalid`).

The apps share the same backend at the same URL. This is pure copy-paste.

---

## 2. Recommended Standardizations

No architectural migration. These are surgical extractions that eliminate duplication without touching business logic.

### 2A — Shared `AsyncState` Helper Class

**File:** `hbt_business_app/lib/core/state/async_state.dart`  
**Scope:** Replaces `_loading`/`_error`/`_busy`/`_acting`/`_saving`/`_submitting` across every screen.

```dart
class AsyncState {
  bool loading = true;
  bool actionInProgress = false;
  String? error;

  void startLoading() {
    loading = true;
    error = null;
  }
  void doneLoading() {
    loading = false;
  }
  void fail(String message) {
    error = message;
    loading = false;
  }
  void startAction() {
    actionInProgress = true;
    error = null;
  }
  void doneAction() {
    actionInProgress = false;
  }
  void reset() {
    loading = true;
    actionInProgress = false;
    error = null;
  }
}
```

**Usage per screen (from ~15 lines → 1 line):**
```dart
// Before:
bool _loading = true;
bool _acting = false;
String? _error;

// After:
final _state = AsyncState();
```

**Impact:** Eliminates ~50 variable declarations across the project.  
**Business logic change:** Zero — replaces a struct of independent booleans with a struct of the same booleans.

### 2B — Shared `ResponseParser` Helper

**File:** `hbt_business_app/lib/core/network/response_parser.dart`  
**Scope:** Replaces `_maps()`, `_toMapList()`, `_extractList()`, `_extractMaps()`, inline `['results']` checks.

```dart
class ResponseParser {
  /// Extract typed list from raw API response (handles List and {results: List}).
  static List<Map<String, dynamic>> asMaps(dynamic response) {
    final raw = response is List<dynamic>
        ? response
        : (response['results'] as List<dynamic>?) ?? <dynamic>[];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  /// Extract dynamic list from raw API response.
  static List<dynamic> asList(dynamic response) {
    if (response is List<dynamic>) return response;
    if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List<dynamic>) return results;
    }
    return <dynamic>[];
  }

  /// Convert List<dynamic> to List<Map<String, dynamic>>.
  static List<Map<String, dynamic>> filterMaps(List<dynamic> list) =>
      list.whereType<Map<String, dynamic>>().toList();
}
```

**Usage:**
```dart
// Before (3 different patterns in different files):
_trips = _maps(results);             // counter_booking
final list = _toMapList(_extractList(data));  // trip_search
final out = _extractMaps(data);      // booking_screen

// After (one consistent pattern):
_trips = ResponseParser.asMaps(results);
final list = ResponseParser.asMaps(data);
```

**Impact:** Eliminates 5 duplicate implementations. Single source of truth.  
**Business logic change:** Zero — pure extraction.

### 2C — Reusable Error/Loading/Empty Widgets

**File:** `hbt_business_app/lib/core/widgets/async_views.dart`

```dart
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}
```

**Usage:**
```dart
// Before (in _buildBody):
if (_loading) return const Center(child: CircularProgressIndicator());
if (_error != null) { return Center(/* 10-line error card */); }
if (items.isEmpty) { return Center(/* 8-line empty state */); }

// After:
if (_state.loading) return const LoadingView();
if (_state.error != null) return ErrorView(message: _state.error!, onRetry: _load);
if (items.isEmpty) return EmptyView(icon: ..., message: ..., actionLabel: ..., onAction: ...);
```

**Impact:** 7+ error states → 1 widget. 4+ empty states → 1 widget.  
**Business logic change:** Zero — visual extraction only.

### 2D — Reusable `StatusChip` Widget

**File:** `hbt_business_app/lib/core/widgets/status_chip.dart`

```dart
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.colorMap,
  });

  final String status;
  final Map<String, Color>? colorMap;

  static const Map<String, Color> _defaultColors = {
    'active': Colors.green, 'draft': Colors.grey,
    'planned': Colors.grey, 'ready': Colors.blue,
    'boarding': Colors.orange, 'departed': Colors.amber,
    'in_progress': Colors.teal, 'delayed': Colors.red,
    'interrupted': Colors.deepOrange, 'arrived': Colors.green,
    'completed': Colors.green, 'closed': Colors.grey,
    'cancelled': Colors.red,
    'issued': Colors.blue, 'validated': Colors.green,
    'boarded': Colors.teal, 'reissued': Colors.orange,
  };

  Color get _color => (colorMap ?? _defaultColors)[status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      status.replaceAll('_', ' '),
      style: const TextStyle(fontSize: 11, color: Colors.white),
    ),
    backgroundColor: _color,
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
  );
}
```

**Usage:**
```dart
// Before (4 different implementations):
Chip(
  label: Text(status, style: const TextStyle(fontSize: 12, color: Colors.white)),
  backgroundColor: _statusColor(status),
  ...  // different padding/visualDensity per file
)

// After:
StatusChip(status: status)
```

**Impact:** 4 implementations → 1 (including trip color map deduplication).  
**Business logic change:** Zero — the color values stay identical.

### 2E — Share `ApiClient` Between Apps

**Move `ApiClient` + `ApiException` to a shared package.**

Both apps import from `package:http/http.dart`. The two copies of `ApiClient` have:
- Same `_request` and `_requestList` logic
- Same `_apiErrorMessage` logic
- Same multipart upload logic
- Same error messages (just localized differently)

**Option A — Symlink (quickest):**  
Replace the passenger app's `api_client.dart` with a re-export of the business app's:
```dart
// hbt_passenger_app/lib/core/network/api_client.dart
export '../../../../hbt_business_app/lib/core/network/api_client.dart';
```

**Option B — Shared package:**  
Create `hbt_shared/pubspec.yaml` → `package:hbt_shared/api_client.dart`.

---

## 3. Summary Table

| Issue | Instances | Impact | Fix |
|---|---|---|---|
| Loading/error/action booleans | 13 screens, ~50 vars | High — every screen has nearly identical fields | `AsyncState` helper |
| Response parsing helpers | 5 implementations | Medium — scattered, drifts, hard to audit | `ResponseParser` utility |
| Error-state UI duplication | 7 screens, ~12 lines each | Medium — 80+ lines of identical markup | `ErrorView` widget |
| Empty-state UI duplication | 4 screens | Low — fewer instances but still duplicated | `EmptyView` widget |
| `_statusColor` maps | 4 screens (trip duplicated) | Medium — trip colors copied; will drift | `StatusChip` widget |
| `mounted` guards | 22+ occurrences | Low — inherent to `StatefulWidget` | Accept or adopt ChangeNotifier+Consumer |
| `ApiClient` + `ApiException` | 2 near-identical copies | Low now, high risk — will diverge | Share via export or package |
| Naming inconsistency (`_busy`/`_saving`/`_acting`/etc.) | 6 variations | Low — cosmetic | Standardize to `actionInProgress` via `AsyncState` |

---

## 4. Not Recommended

- **Riverpod / Provider migration** — Would require rewriting every screen. The current `StatefulWidget` + `ChangeNotifier` pattern is stable and proven for MVP. Standardizing the existing pattern is cheaper, safer, and gets 90% of the benefit.
- **Auto-dispose / lifecycle state** — Not appropriate until the app has streaming data or WebSocket connections.
- **StatefulWidget → StatelessWidget + Consumer** — Would mix architectural approaches. Recommend keeping one pattern.

---

## 5. Recommended Progression

```
Phase 1: Create shared utilities (no screen changes)
  └─ response_parser.dart ✓
  └─ async_state.dart ✓

Phase 2: Create shared widgets (no business logic changes)  
  └─ LoadingView, ErrorView, EmptyView
  └─ StatusChip

Phase 3: Migrate screens (one per commit, mechanical replacement)
  └─ Replace _loading/_error → AsyncState
  └─ Replace inline error/empty UIs → shared widgets
  └─ Replace _statusColor + Chip → StatusChip
  └─ Replace _maps/_extractMaps → ResponseParser

Phase 4: Share ApiClient between both apps
  └─ Option A: export from business app
  └─ Option B: shared package
```

Each screen migration in Phase 3 is a pure mechanical substitution — no business logic touched, no behavior changed, zero regression risk.
