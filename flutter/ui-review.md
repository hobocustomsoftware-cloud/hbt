# Flutter Project — UI Consistency Review

**Reviewed:** All 7 screen files across 5 features
**Screens:** SignInScreen, BusinessHome (+ _DashboardPage), TicketSalesPage, CounterBookingPage, PaymentDecisionPage, CargoWorklistPage, CargoAcceptancePage

---

## 1. Inconsistent Spacing

### 1.1 Section Headers vs. Content Spacing

Every screen uses `SizedBox` for vertical spacing, but the values vary arbitrarily:

| Screen | Header→Content | Between Fields | Before Button | Before Next Section |
|--------|---------------|---------------|---------------|-------------------|
| SignInScreen | 32 | 16 | 20 | — |
| CounterBookingPage | 16 | 12 | 20 | 16 |
| CargoAcceptancePage | — | 12 | 20 | 12 |
| PaymentDecisionPage | — | 12 | 16 | — |
| TicketSalesPage | — | — | — | 12 / 20 |
| DashboardPage | — | 12 | — | 8 / 12 |

**Issues:**
- `SignInScreen` uses `SizedBox(height: 32)` between subtitle and first input. `CounterBookingPage` uses `SizedBox(height: 16)` after section titles. These should be a shared constant.
- Before the primary action button: SignIn uses `20`, PaymentDecision uses `16`, CargoAcceptance uses `20`, CounterBooking uses `20`. Inconsistency between `20` and `16`.
- Between `titleMedium` section headers and their content: `CounterBookingPage` uses `8px` (implicit in `Wrap`), `16`, and `12`. Same pattern — three different values in one screen.
- Between list items (bookings/tickets/shipments): `Card` wrapping with `ListView` means zero spacing between cards unless explicitly added. CargoWorklist relies on card stacking; TicketSalesPage relies on `..._bookings.map()` inside `ListView` — no inter-item gap.

### 1.2 ListView Padding

All screens use `padding: const EdgeInsets.all(16)` on their `ListView` — this is the one consistent value.

**Exception:** `PaymentDecisionPage`'s `build()` — the outer `ListView` has `padding: const EdgeInsets.all(16)` but the `Card` for the quoted fare has no inner padding, relying on `ListTile` internal insets. This is correct for ListTile-based cards but inconsistent with error cards that use explicit `Padding(padding: const EdgeInsets.all(12))`.

### 1.3 Vertical Rhythm

There is no defined vertical rhythm. Every spacing value is a raw literal:
- `SizedBox(height: 8)` — appears in `_DashboardPage`
- `SizedBox(height: 12)` — appears in SignInScreen, DashboardPage, CounterBookingPage (×4), CargoAcceptancePage (×6), CargoWorklistPage, PaymentDecisionPage (×2)
- `SizedBox(height: 16)` — appears in SignInScreen, CounterBookingPage (×3), PaymentDecisionPage
- `SizedBox(height: 20)` — appears in SignInScreen, CounterBookingPage, CargoAcceptancePage, PaymentDecisionPage

These should be a design token set (e.g., `Spacing.xs = 4`, `Spacing.sm = 8`, `Spacing.md = 12`, `Spacing.lg = 16`, `Spacing.xl = 20`, `Spacing.xxl = 32`).

---

## 2. Inconsistent Colors

### 2.1 Seed Color (Single Reference)

The only color definition in the entire app:

```dart
// hbt_business_app.dart, line 31
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff00695c)),
```

This is correct architecture — use one seed and let Material 3 generate the palette. However, there is **no explicit use of this color anywhere else**. Every hardcoded color below contradicts the theme.

### 2.2 Hardcoded Colors in Screens

| Location | Color | Issue |
|----------|-------|-------|
| SignInScreen, bus icon | `Color(0xff00695c)` | Duplicates the seed color value — should use `Theme.of(context).colorScheme.primary` |
| Error cards (5 screens) | `Theme.of(context).colorScheme.errorContainer` | Correct pattern ✅ |
| No hardcoded backgrounds or text colors elsewhere | (none found) | This is good — the theme is respected for material widgets |

**Verdict:** Only one hardcoded color violation. The theme architecture is sound. The bus icon color should use the theme's primary color instead of a literal.

---

## 3. Inconsistent Typography

### 3.1 Text Style Usage

| Intent | Screens Using It | Style |
|--------|-----------------|-------|
| App title | SignInScreen | `textTheme.headlineMedium` |
| Section title | CounterBookingPage, TicketSalesPage, PaymentDecisionPage | `textTheme.titleMedium` |
| Section title | CargoAcceptancePage _(informal label)_ | `InputDecoration(labelText: ...)` — no title style |
| Subtitle/label | DashboardPage _(section header)_ | Plain `Text('အမြန်လုပ်ဆောင်ရန်')` — no style applied |
| Empty state | CounterBookingPage, TicketSalesPage, CargoWorklistPage, BusinessHome | `Text('...')` — no style |
| Error message | All screens with errors | `Text(_error!)` — no style |

**Issues:**

- **Section titles are inconsistent.** CounterBookingPage uses `Text('ခရီးသည်', style: Theme.of(context).textTheme.titleMedium)`. TicketSalesPage uses `Text('လတ်တလော Booking များ', style: Theme.of(context).textTheme.titleMedium)`. DashboardPage's `_QuickAction` section header uses plain `Text('အမြန်လုပ်ဆောင်ရန်')` — no style at all. Three screens, three patterns.
- **Empty states have no styling.** "Cargo shipment မရှိသေးပါ။", "Booking မရှိသေးပါ။", "လက်မှတ်မရှိသေးပါ။" — all are plain `Text()` widgets. No `bodyMedium`, no muted color, no centering offset from the ListView body.
- **Error messages have no styling.** Some screens wrap errors in a `Card` with `errorContainer` color (correct). But the `Text` inside has no explicit text style — it inherits the card's default, which is M3 `bodyMedium`. This works but is fragile if nested widget context changes.
- **`_DashboardPage` title "အမြန်လုပ်ဆောင်ရန်"** is a plain `Text` with no style reference. Should be `textTheme.titleSmall` or `titleMedium` to match other screens.

### 3.2 Button Label Style

All `FilledButton` and `FilledButton.icon` instances use default text styling. No overrides. This is correct — the button style comes from the theme.

**Exceptions:**
- `SignInScreen` wraps `FilledButton` text in a `Padding(padding: const EdgeInsets.all(14))` to increase touch target. No other button does this. The padding should be styled globally via `FilledButtonTheme`.

---

## 4. Duplicated Widgets (Identical Patterns)

### 4.1 Loading Spinner

```dart
const Center(child: CircularProgressIndicator())
```

Appears in **7 locations** across 6 screens:
- `_HbtBusinessAppState.build()` — `_LoadingScreen`
- `_BusinessContextBody.build()` — loading state
- `_TicketSalesPageState.build()` — loading state
- `_CounterBookingPageState.build()` — initial loading
- `_CargoWorklistPageState.build()` — loading state
- `_CargoAcceptancePageState.build()` — initial loading

### 4.2 Error Display Card

```dart
if (_error != null)
  Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(_error!),
    ),
  ),
```

Appears in **5 screens**: CounterBookingPage, CargoAcceptancePage, CargoWorklistPage, PaymentDecisionPage, TicketSalesPage. Identical code, five times.

### 4.3 API Call Loading Boilerplate

```
_loading = true; _error = null;
try { ... }
on ApiException catch (error) { _error = error.message; }
finally { _loading = false; ... }
```

This block (with minor variable name variations: `_busy`/`_submitting`/`_loading`, `_saving`/`_busy`) appears in **every screen**, typically 2-3 times per screen.
- SignInScreen: 1 instance (`_signIn`)
- CounterBookingPage: 4 instances (`_loadInitialData`, `_loadSeats`, `_createPassenger`, `_createAndLockQuote`)
- PaymentDecisionPage: 1 wrapper (`_run`) + 3 callers
- CargoWorklistPage: 4 instances (`_load`, `_transition`, `_assignTrip`, `_handover`)
- CargoAcceptancePage: 3 instances (`_load`, `_createContact`, `_accept`)

### 4.4 Empty State List Item

```dart
const Card(child: ListTile(title: Text('...')))
```

Appears in TicketSalesPage (×2: bookings + tickets) and CargoWorklistPage (×1). Each has a different Myanmar text but identical wrapping.

### 4.5 List Items in Cards

The pattern:
```dart
Card(
  child: ListTile(
    leading: const Icon(...),
    title: Text(...),
    subtitle: Text('... • ...'),
  ),
)
```

Appears for bookings, tickets, shipments, contacts, and payment accounts. Same structure. Different icons. Different data sources. Clear candidate for a shared `DataCard<T>` widget.

### 4.6 RefreshIndicator Wrapping

```dart
RefreshIndicator(
  onRefresh: _load,
  child: ListView(...)
)
```

Appears in TicketSalesPage, CounterBookingPage, CargoWorklistPage. Identical.

### 4.7 DropdownButtonFormField Pattern

Every dropdown follows the same pattern with slight variations:
```dart
DropdownButtonFormField<Map<String, dynamic>>(
  key: ValueKey(item?['id']),            // Some screens use this, some don't
  initialValue: item,
  items: list.map((item) => DropdownMenuItem(
    value: item,
    child: Text('${item['label']}'),
  )).toList(),
  onChanged: (value) => setState(() => selected = value),
  decoration: const InputDecoration(
    labelText: '...',
    border: OutlineInputBorder(),
  ),
)
```

CounterBookingPage uses `key: ValueKey(...)` for every dropdown. CargoAcceptancePage uses it for origin/destination but not for contact pickers. PaymentDecisionPage uses `initialValue` but no `key`. Three different approaches to widget identity.

### 4.8 Dialog for Creating New Entities

Two nearly identical `showDialog` patterns:
- `counter_booking_page.dart:_createPassenger()` — 3 `TextField`s, TextButton + FilledButton
- `cargo_acceptance_page.dart:_createContact()` — 3 `TextField`s, TextButton + FilledButton
- `cargo_worklist_page.dart:_handover()` — 2 `TextField`s, TextButton + FilledButton
- `cargo_worklist_page.dart:_assignTrip()` — `SimpleDialog` with options

These are 80% identical code with different field labels and API endpoints.

### 4.9 Permission-Guarded Action Button

```dart
widget.session.hasPermission('permission.name')
    ? FilledButton(...)
    : null  // or FilledButton(onPressed: null)
```

Appears with every action button across TicketSalesPage (×1), PaymentDecisionPage (×2), CargoWorklistPage (×4), CounterBookingPage (×1). The pattern varies: some use conditional rendering (`if`), some use `null` onPressed, some combine both.

---

## 5. Reusable Components (Should Exist But Don't)

### 5.1 Design Token Constants

No shared spacing, color, or typography constants exist. All spacing values are raw `SizedBox(height: X)` literals. A `lib/core/theme/spacing.dart` with named spacing tokens would eliminate this entirely.

### 5.2 ErrorCard

The error display card pattern is duplicated 5 times. Should be:
```dart
class ErrorCard extends StatelessWidget {
  const ErrorCard(this.message, {super.key});
  final String message;
  // ...
}
```

### 5.3 LoadingIndicator

Loading spinner is duplicated 7 times. Should be a shared `LoadingIndicator()` widget.

### 5.4 EmptyStateCard

Empty list message inside a Card+ListTile is duplicated 3 times.

### 5.5 AsyncDataLoader Mixin or Base Class

The `_loading`/`_error`/try/catch/finally boilerplate appears 15+ times. A `AsyncState<T>` base class or mixin would reduce this to one line per API call:
```dart
class _MyState extends AsyncState<MyData> {
  // _loading, _error, _run() inherited
}
```

### 5.6 PermissionGuard

The permission check pattern (`if (hasPermission('x')) widget else null`) appears 8+ times. A `PermissionGuard` widget:
```dart
PermissionGuard(
  permission: 'cargo.view',
  session: session,
  child: CargoList(...),
)
```

### 5.7 SectionHeader

Section titles — `Text('Title', style: textTheme.titleMedium)` — appear 5+ times across screens. Should be:
```dart
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});
  final String label;
  @override Widget build(BuildContext context) =>
      Padding(padding: /* standard */, child: Text(label, style: Theme.of(context).textTheme.titleMedium));
}
```

### 5.8 DropdownField / DynamicDropdown

The `DropdownButtonFormField<Map<String, dynamic>>` pattern appears 8+ times with identical decoration, differing only in label, data source, and change handler. A typed generic widget:
```dart
DynamicDropdown<T>(
  label: 'Passenger',
  items: passengers,
  itemLabel: (p) => p.fullName,
  value: selected,
  onChanged: (v) => setState(() => selected = v),
)
```

---

## 6. Summary

| Category | Score | Key Issues |
|----------|-------|-----------|
| **Spacing Consistency** | 2/10 | 6 different SizedBox values used arbitrarily across 7 screens. `16`, `12`, `20`, `8`, `32`, `24` — no design token system. Same pattern in same screen sometimes uses different values. |
| **Color Consistency** | 8/10 | One hardcoded color violation (bus icon). Everything else uses theme. The theme is well-designed (single seed color, M3). |
| **Typography Consistency** | 4/10 | Section titles use different styles. Some use `titleMedium`, some use plain `Text`. Empty states and error messages have no explicit style. Button label padding varies. |
| **Duplication** | 2/10 | 7 identical loading spinners. 5 identical error cards. 3 identical empty state cards. 15+ copies of the same API call pattern. 8+ copies of the same dropdown pattern. 4 nearly identical entity-creation dialogs. |
| **Reusability** | 1/10 | Zero shared widgets extracted from the above duplication. No design token file. No shared error/loading/empty-state components. |

### Immediate Wins (in priority order)

1. **Extract `ErrorCard` widget** — removes 5 duplications in 5 minutes
2. **Extract `LoadingIndicator` widget** — removes 7 duplications in 2 minutes
3. **Create `lib/core/theme/spacing.dart`** — defines `Spacing.sm`, `.md`, `.lg`, `.xl`, `.xxl` as named constants. Apply across all screens.
4. **Replace hardcoded bus-icon color** — use `Theme.of(context).colorScheme.primary` instead of `Color(0xff00695c)`
5. **Unify empty state messages** — extract `EmptyStateCard` widget
6. **Add `bodyMedium` style to error/empty text** — ensure all status text has an explicit theme reference
7. **Standardize `titleMedium` for all section headers** — fix `_DashboardPage` section title to use themed style
