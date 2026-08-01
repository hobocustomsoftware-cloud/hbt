# Flutter Reviewer's Cheat Sheet

**Quick-reference for reviewing Flutter commits against HEOS standards.**

---

## 1. File Placement Rules

```
lib/features/<feature>/
    domain/          ← Entities, value objects (NO flutter imports)
    data/            ← Repositories, DTOs, API clients (NO presentation imports)
    application/     ← Controllers, notifiers, use-cases (imports domain + data)
    presentation/    ← Screens, widgets (imports application only)
```

**Violations:**
- `presentation/` imports `data/` directly? → **P0** (bypasses application layer)
- `presentation/` calls `ApiClient` directly? → **P0** (same)
- `domain/` imports Flutter? → **P0** (domain must be pure Dart)
- Cross-feature import from `presentation/`? → **P1** (Feature A presentation imports Feature B presentation)

## 2. Dependency Direction

```
Correct:   Screen → Controller → Repository → ApiClient
Violation: Screen → ApiClient
Violation: Controller → Screen
```

## 3. State Management Patterns

| Look For | Verdict |
|----------|---------|
| `_loading`, `_error` in StatefulWidget | **P1** — should be in controller |
| `setState(() {...})` for API responses | **P1** — should use ChangeNotifier/Bloc |
| try/catch/finally in widget | **P2** — should use shared `_run()` pattern |
| `StatefulWidget` >200 lines | **P2** — extract controller |
| `ChangeNotifier` handles >2 concerns | **P1** — SRP violation |

## 4. API Access

| Pattern | Verdict |
|---------|---------|
| `widget.session.api.get(...)` in build() | **P0** |
| `widget.session.api.get(...)` in initState() | **P0** |
| `widget.session.api.post(...)` in callback | **P0** |
| `widget.session.api` exposed publicly | **P1** — SessionController leaks transport |

## 5. UI Consistency Quick-Check

| Pattern | Should Be |
|---------|-----------|
| `SizedBox(height: 8\|12\|16\|20\|24\|32)` | `Spacing.sm\|md\|lg\|xl\|xxl` |
| `Color(0xff.....)` | `Theme.of(context).colorScheme.*` |
| `Text('...')` (no style) for title | `textTheme.titleMedium` |
| `Text('...')` (no style) for body | `textTheme.bodyMedium` |
| `CircularProgressIndicator()` | `LoadingIndicator()` |
| `ErrorCard(...)` | Not extracted yet — should be |
| `Card(child: ListTile(...))` | Consider `DataCard<T>` |

## 6. Common Violations to Flag

| Pattern | Violation |
|---------|-----------|
| `DropdownButtonFormField<Map<String, dynamic>>` | **P1** — should be `DynamicDropdown<T>` |
| `if (_error != null) Card(color: errorContainer...)` | **P1** — should be `ErrorCard` |
| `const Center(child: CircularProgressIndicator())` | **P1** — should be `LoadingIndicator` |
| `if (!session.hasPermission('x')) return fallback` | **P2** — should be `PermissionGuard` |
| Hardcoded `String` status transitions | P3 — prefer data-driven |

## 7. Naming Rules

| Element | Convention | Example |
|---------|-----------|---------|
| File name | `snake_case.dart` | `sign_in_screen.dart` |
| Class | `PascalCase` | `SessionController` |
| Method/variable | `camelCase` | `_loadData()` |
| Private | `_prefix` | `_loading` |
| Constants | `camelCase` or `SCREAMING_SNAKE` | `kDefaultPadding` or `DEFAULT_PADDING` |
| Directory | `snake_case` | `ticket_sales/` |
| Widget file | `*_page.dart` or `*_screen.dart` | `ticket_sales_page.dart` |

## 8. PR Blocking Conditions

A commit MUST NOT merge if:
- [ ] Presentation imports data/network layer
- [ ] Business logic exists in widget build() method
- [ ] New code duplicates existing widget/pattern without extraction
- [ ] New dependency added without justification comment
- [ ] Feature name doesn't match directory name
- [ ] Any P0 violation exists
- [ ] CI pipeline fails (Flutter test)

## 9. Approval Gates

| Gate | Required | For |
|------|----------|-----|
| ✅ Approved | No P0, ≤2 P1 | Merge any time |
| ⚠️ Conditional | P0 fixed, P1 acknowledged | Merge with plan to fix P1 next sprint |
| ❌ Blocked | Any P0 | Merge forbidden |
