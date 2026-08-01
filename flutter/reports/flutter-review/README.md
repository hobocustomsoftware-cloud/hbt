# Flutter Architecture Review Process

**Owner:** Flutter Architecture Reviewer
**Scope:** All `.dart` files under `lib/`, `test/`, `pubspec.yaml`
**Trigger:** Every commit, every new screen, every dependency change
**Output:** `reports/flutter-review/YYYY-MM-DD-review.md`

---

## Review Priorities (in order)

1. **Architecture** — Clean Architecture compliance, dependency direction, layer isolation
2. **Maintainability** — Duplicate code, reusable widget extraction, complexity
3. **Performance** — Widget rebuilds, list performance, image/memory, async patterns
4. **UI Consistency** — Spacing tokens, color usage, typography, component reuse

---

## Review Checklist

### 1. Architecture (blocking)
- [ ] New files placed in correct feature layer? (`domain/`, `data/`, `application/`, `presentation/`)
- [ ] Presentation depends on Application, not directly on Data/Network?
- [ ] No business logic in widget `build()` methods?
- [ ] No direct `ApiClient` access from presentation widgets?
- [ ] State management follows the established pattern (or documented deviation)?
- [ ] Feature is self-contained? No cross-feature imports from presentation layer?
- [ ] Repository layer used for data access?

### 2. Maintainability
- [ ] No new code duplication with existing widgets?
- [ ] Widget longer than 200 lines? (refactoring candidate)
- [ ] Duplicated loading/error/empty patterns extracted?
- [ ] Magic numbers/spacing values extracted to constants?
- [ ] Complexity score acceptable? (nested conditionals, switch cases)

### 3. Naming
- [ ] Files: `snake_case.dart`
- [ ] Classes: `PascalCase`
- [ ] Functions/variables: `camelCase`
- [ ] Private members: `_prefix`
- [ ] File name matches primary class?
- [ ] Folder `snake_case` matches feature name?

### 4. State Management
- [ ] State lives in a controller/notifier, not in `StatefulWidget` state?
- [ ] No `_loading`, `_error`, try/catch/finally boilerplate duplicated? (should use shared abstraction)
- [ ] Async state uses `Result<T>` or equivalent?
- [ ] `dispose()` properly cleans up controllers/subscriptions?

### 5. UI Consistency
- [ ] Spacing uses design tokens (not raw `SizedBox(X)` literals)?
- [ ] Colors reference `Theme.of(context).colorScheme` (not hardcoded)?
- [ ] Text styles reference `textTheme.*` (not plain `Text`)?
- [ ] Error states use `ErrorCard` widget?
- [ ] Loading states use `LoadingIndicator` widget?
- [ ] Empty states use `EmptyStateCard` widget?

### 6. Dependencies
- [ ] New dependency justified in review?
- [ ] No unused imports?
- [ ] No dead code?

---

## Violation Priority

| Severity | Meaning | Action |
|----------|---------|--------|
| **P0 — BLOCKING** | Architecture violation. Dependency direction wrong. Data layer bypassed. | Report. Do not merge. |
| **P1 — CRITICAL** | New code duplicates existing pattern that should be shared. | Report. Extract before merge. |
| **P2 — WARNING** | Naming inconsistency. Spacing/color deviation. Minor duplication. | Report. Fix within current sprint. |
| **P3 — INFO** | Style preference. Future improvement. Non-blocking. | Report. Document for backlog. |

---

## Report Template

Each review produces a dated markdown file:

```markdown
# Flutter Review — YYYY-MM-DD

## Scope
- Commit range / files reviewed

## Summary
- P0 violations: N
- P1 violations: N
- P2 violations: N
- P3 items: N

## P0 — Architecture Violations
...

## P1 — Maintainability Issues
...

## P2 — UI/Naming Inconsistencies
...

## P3 — Other Observations
...

## Cumulative Trend
- Total P0 violations this sprint: N (delta: +/-N)
- Duplicate widget count: N (delta: +/-N)
- Shared widget count: N (delta: +/-N)
```
