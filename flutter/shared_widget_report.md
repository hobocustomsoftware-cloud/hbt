# Shared Widget Report

**Generated:** 2026-07-29
**Scope:** All 18 Dart files (13 library, 1 test, 4 config/generated)

---

## Current Widget Inventory

The codebase has **7 screens** across **5 features**, plus the app shell. Every screen builds its own widgets inline. Zero widgets are shared between screens.

## Widgets That Should Become Reusable

### Priority P0 — Duplicated 5+ times

| Proposed Widget | Current Count | Usage Pattern | Key Properties |
|----------------|---------------|--------------|----------------|
| `ErrorCard` | 5 | Error display in `Card` with `errorContainer` color | `String message`, `VoidCallback? onRetry` |
| `LoadingIndicator` | 7 | `const Center(child: CircularProgressIndicator())` | `double? size`, `String? message` |
| `EmptyStateCard` | 3 | `const Card(child: ListTile(title: Text('...')))` | `String message`, `IconData icon`, `Widget? action` |
| `SectionHeader` | 5 | Section title `Text('...', style: textTheme.titleMedium)` | `String label`, `Widget? action` |

### Priority P1 — Duplicated 3+ times

| Proposed Widget | Current Count | Usage Pattern | Key Properties |
|----------------|--------------|--------------|----------------|
| `DataCard<T>` | 6+ | `Card(child: ListTile(leading/title/subtitle/trailing))` for bookings, tickets, shipments, contacts, payment accounts | `IconData icon`, `T data`, `String Function(T) title`, `String Function(T) subtitle`, `Widget? trailing` |
| `DynamicDropdown<T>` | 8+ | `DropdownButtonFormField<Map<String, dynamic>>` with identical decoration | `List<T> items`, `String Function(T) label`, `T? value`, `ValueChanged<T?> onChanged`, `String labelText` |
| `PermissionGuard` | 8+ | `widget.session.hasPermission('x') ? widget : fallback` | `Set<String> permissions`, `Widget child`, `Widget? fallback` |
| `ApiButton` | 6 | `FilledButton(onPressed: _submitting ? null : _action)` with disabled state during API call | `String label`, `String loadingLabel`, `VoidCallback onPressed`, `bool loading` |

### Priority P2 — Duplicated 2+ times

| Proposed Widget | Current Count | Usage Pattern | Key Properties |
|----------------|--------------|--------------|----------------|
| `ContactPicker` | 2 | Row with dropdown + add button for passenger/contact selection | `String label`, `List<C> contacts`, `C? value`, `ValueChanged<C?> onChanged`, `VoidCallback onCreate` |
| `EntityDialog` | 3 | `showDialog` with editable fields for creating a new entity | `String title`, `List<EntityField> fields`, `Future<T> Function(Map<String, dynamic>) onSubmit` |
| `LoadingListItem` | 3 | `Card(child: ListTile(title: Text('...')))` for loading states within lists | `String message` |
| `RetryButton` | 3 | "ပြန်လည်စမ်းသပ်ရန်" or "ထပ်မံကြိုးစားရန်" retry buttons | `VoidCallback onRetry`, `String? label` |
| `AppBusIcon` | 1 (should be reusable) | Bus icon at SignInScreen | `double size` |

### Priority P3 — Architecture-level (infrastructure, not visual)

| Proposed Abstraction | Current Count | Usage Pattern |
|---------------------|--------------|--------------|
| `AsyncState<T>` | 15+ | The `_loading`/`_error`/try/catch/finally boilerplate |
| `Result<T>` | — | Typed return value for API calls (Success<T> | Failure<T>) |
| `Repository<T>` | — | Data access abstraction over `ApiClient` |

---

## Current Duplication Map

```
main.dart → HbtBusinessApp.start()
                                      \
                                        → HbtBusinessApp
hbt_business_app.dart → LoadingIndicator [1]
                      → AnimatedBuilder(ThemeData.fromSeed(0xff00695c))
                      → SignInScreen / BusinessHome

sign_in_screen.dart   → SizedBox(32, 16, 20, 12) [raw values]
                      → FilledButton(Padding(14)) [unique padding]
                      → bus Icon(0xff00695c) [hardcoded color]

business_home.dart    → LoadingIndicator [2]
                      → _BusinessContextBody: ErrorCard [1], SizedBox(24)
                      → _DashboardPage: QuickActionCard [3], SizedBox(12, 8)
                      → _PlaceholderPage

ticket_sales_page.dart → LoadingIndicator [3]
                       → ErrorCard [2]
                       → EmptyStateCard [2] (bookings + tickets)
                       → DataCard [N] (booking list + ticket list)

counter_booking_page.dart → LoadingIndicator [4]
                          → ErrorCard [3]
                          → DynamicDropdown [5] (passenger, trip, stop, stop)
                          → ChoiceChip grid (seats)
                          → EntityDialog [1] (create passenger)

payment_decision_page.dart → ErrorCard [4]
                           → DynamicDropdown [2] (method, account)
                           → OutlinedButton.icon (file upload)
                           → DataCard [N] (payment status, tickets)

cargo_worklist_page.dart  → LoadingIndicator [5]
                          → ErrorCard [5]
                          → DynamicDropdown [1] (trip select in SimpleDialog)
                          → EmptyStateCard [1]
                          → DataCard [N] (shipment list)
                          → EntityDialog [2] (handover)

cargo_acceptance_page.dart → LoadingIndicator [6]
                           → ErrorCard [6]
                           → ContactPicker [2] (sender, receiver)
                           → DynamicDropdown [2] (origin, destination)
                           → EntityDialog [3] (create contact)
```

---

## Recommended Extraction Order

1. **`ErrorCard`** — 5 minutes, removes 5 copies. Highest immediate value.
2. **`LoadingIndicator`** — 2 minutes, removes 7 copies.
3. **`SectionHeader`** — 3 minutes, standardizes 5 copies and fixes the DashboardPage typography issue.
4. **`ApiButton`** — 5 minutes, standardizes loading states across all action buttons.
5. **`EmptyStateCard`** — 3 minutes, removes 3 copies.
6. **`DynamicDropdown<T>`** — 10 minutes, removes 8+ copies and fixes the `key: ValueKey` inconsistency.
