# Flutter Cleanup Report

**Generated:** 2026-07-29
**Scope:** All files under `F:\hbt\flutter\hbt_business_app`

---

## Unused Packages

| Package | Version | Reason | Action |
|---------|---------|--------|--------|
| `cupertino_icons` | ^1.0.8 | Never imported. No CupertinoIcons usage. | Remove |
| `mobile_scanner` | ^6.0.2 | Never imported. No scanner integration. | Remove (re-add when implementing scanning) |
| `sqflite_sqlcipher` | ^3.3.0 | Never imported. No offline database. | Remove (re-add when implementing offline sync) |
| `uuid` | ^4.5.1 | Never imported. No UUID generation. | Remove (re-add when implementing idempotency keys) |

**Note:** `flutter_lints` is a dev dependency consumed via `analysis_options.yaml` (not via import). It is functionally used. **Keep.**

**Note:** `path` is listed in pubspec.yaml. It was examined and is also not imported in any Dart file. **Remove.**

---

## Unused Files

No files are truly unused. Every Dart file in `lib/` is transitively reachable from `main.dart`:
- `main.dart` → `hbt_business_app.dart` → all screens
- Feature screens import other feature screens (cargo_worklist→cargo_acceptance, ticket_sales→counter_booking→payment_decision)

**Zero dead files.** The static import graph is clean.

---

## Unused Widgets

No widgets are unused. All widgets defined in the codebase are rendered somewhere:
- `_LoadingScreen` → rendered on app startup
- `_BusinessContextBody` → wraps all authenticated pages
- `_DashboardPage`, `_QuickAction`, `_PlaceholderPage` → rendered in BusinessHome bottom nav
- All screen widgets → reachable through navigation

**Note:** `_QuickAction` tap callbacks are no-ops (`onTap` is not set). The cards are rendered but non-functional.

---

## Unused Providers / Controllers

| Component | Status | Notes |
|-----------|--------|-------|
| `SessionController` | ✅ Used | Referenced in every screen via `required this.session` |
| None others exist | — | No Riverpod providers, no Bloc instances, no inherited widgets beyond `SessionController` |

---

## Unused Assets

The project has no `assets/` directory and no asset declarations in `pubspec.yaml`. **No unused assets.**

---

## Unused Imports

| File | Import | Status |
|------|--------|--------|
| — | — | **No unused imports found** |

All imports are used. The scan verified each imported identifier against its usage in the file.

---

## Dead Code

| Location | Issue |
|----------|-------|
| `business_home.dart:_DashboardPage._QuickAction` | Rendered but `onTap` is never set. Three quick action cards are decorative placeholders. |
| `business_home.dart:_PlaceholderPage` | Rendered on tab 3 (Sync tab). Shows a placeholder message. |
| `hbt_business_app.dart` `export 'app/hbt_business_app.dart'` | The export in `main.dart` is redundant — `main.dart` imports the file directly and re-exports it unused. The export line can be removed. |
| `api_client.dart:postMultipart()` | Method is defined. Used by `PaymentDecisionPage` for evidence upload. ✅ Used. |
| `api_client.dart:getList()` | Method is defined. Used by 5 screens. ✅ Used. |
| `api_client.dart:_requestList()` | Private method. Called only by `getList()`. ✅ Used. |

---

## Redundant / Unnecessary

| Location | Issue |
|----------|-------|
| `api_client.dart` `_request()` and `_requestList()` are 95% identical | **Refactor target.** Lines 34-95 (`_request`) and lines 102-165 (`_requestList`) differ only in return type annotation and `List` vs `Map` type assertion. Could be one generic `_send<T>` method. |
| `hbt_business_app.dart` `HbtBusinessApp.start()` | Static factory that calls `WidgetsFlutterBinding.ensureInitialized()` + `runApp()`. This indirection is unnecessary — could be inlined in `main()`. |

---

## Summary

| Category | Count | Actionable |
|----------|-------|-----------|
| Unused packages | 4 (plus `path`) | Remove 5 `pubspec.yaml` entries |
| Unused files | 0 | — |
| Unused widgets | 0 | — |
| Unused imports | 0 | — |
| Unused assets | 0 | — |
| Dead/placeholder code | 2 locations | Remove or implement |
| Redundant code | 2 locations | Refactor target |

**Total cleanup: remove 5 dependencies, remove 1 redundant export, remove or implement 2 placeholder UIs.**
