# Flutter TODO / Technical Debt Report

**Generated:** 2026-07-29
**Scanner:** Full text scan of all `.dart`, `.yaml`, `.md`, `.json`, `.cfg` files

---

## Result: Zero TODO/FIXME/HACK/XXX Markers Found

The scan searched for patterns `TODO:`, `FIXME:`, `HACK:`, and `XXX:` across:
- All 13 `.dart` source files in `lib/`
- `pubspec.yaml`, `analysis_options.yaml`
- `README.md`
- `widget_test.dart`

**No markers were found.**

---

## Implications

This is unexpected for an active codebase. Possible explanations:

1. **Codebase is very early-stage.** The Flutter client was generated/scaffolded and then ~4 feature screens were added. Not enough time has passed for technical debt to accumulate in comments.

2. **Developer discipline.** All TODOs are tracked elsewhere (task system, GitHub Issues, backlog). The code reflects only production intent.

3. **TODO markers may exist in generated files.** Files under `android/`, `ios/`, `windows/`, `linux/`, `macos/` were excluded from scan scope, but these are platform-specific generated files unlikely to contain HBT TODOs.

---

## But the Code Has Implicit TODOs

While not in comment form, the following are effectively work-in-progress markers:

| Location | Implicit Issue | Priority |
|----------|---------------|----------|
| `business_home.dart` | `_QuickAction` has no `onTap` — 3 cards are visual-only placeholders | High — renders non-functional UI |
| `business_home.dart` | "Offline outbox နှင့် sync UI ကို နောက်အဆင့်တွင် ချိတ်မည်" (will connect in next phase) — literal text on Dashboard | High — explicit unfinished feature |
| `business_home.dart` | Tab 4 (Sync) shows `_PlaceholderPage` | High — empty tab |
| `payment_decision_page.dart` | File evidence upload + manual payment → ticket issuing — entire flow works but `payment.confirm` and `ticket.issue` permissions are checked against session | Medium — no error handling for partial permission sets |
| `cargo_worklist_page.dart` | Cargo status transitions are hardcoded as strings: `'assigned' → 'loaded' → 'in_transit' → 'arrived' → 'ready_pickup'` | Medium — not data-driven |
| `counter_booking_page.dart` | Booking → FareQuote → LockQuote is a 3-step API chain with no rollback on failure | Medium — orphaned objects possible |
| `SessionController` | Single controller handles auth, organizations, permissions, and session persistence | Low — SRP violation, no current bugs but will block growth |
| `hbt_business_app.dart` | Colors come from one `seedColor` but the bus icon in SignInScreen hardcodes `0xff00695c` | Low — theme inconsistency |
| `api_client.dart` | `_request` and `_requestList` are 95% duplicated | Low — DRY violation, maintenance risk |

---

## Recommendation

Since explicit TODO markers don't exist, the highest-value action is to **add an `_implicit_todo.md` reference doc** in the codebase that tracks these known gaps so they don't get lost in review reports. This is better than adding `// TODO` comments because:
- All 7 screens have the same `_loading`/`_error`/try/catch/finally pattern — adding a TODO to every one creates noise
- The offline-first gap is a sprint-level decision, not a code-level fix
