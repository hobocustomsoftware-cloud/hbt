# Flutter Dependency Report

**Generated:** 2026-07-29
**Source:** `F:\hbt\flutter\hbt_business_app\pubspec.yaml`
**SDK:** Dart ^3.10.4
**Flutter:** Bundled (not version-pinned in pubspec)

---

## Dependency Inventory

### Runtime Dependencies

| Package | Version | Size (approx) | Status | Replacement |
|---------|---------|--------------|--------|-------------|
| `flutter` | SDK | — | ✅ Core framework | — |
| `cupertino_icons` | ^1.0.8 | ~100 KB | ❌ **Unused** | Remove |
| `flutter_secure_storage` | ^9.2.4 | ~200 KB | ✅ Used by `SessionController` | — |
| `http` | ^1.3.0 | ~200 KB | ✅ Used by `ApiClient` | — |
| `file_picker` | ^8.1.2 | ~500 KB | ✅ Used by `PaymentDecisionPage` | — |
| `mobile_scanner` | ^6.0.2 | ~2 MB | ❌ **Unused** | Remove (add when implementing) |
| `path` | ^1.9.1 | ~50 KB | ❌ **Unused** | Remove |
| `sqflite_sqlcipher` | ^3.3.0 | ~2 MB | ❌ **Unused** | Remove (add when implementing offline) |
| `uuid` | ^4.5.1 | ~50 KB | ❌ **Unused** | Remove (add when implementing idempotency) |

### Dev Dependencies

| Package | Version | Status | Notes |
|---------|---------|--------|-------|
| `flutter_test` | SDK | ✅ Used | Framework test runner |
| `flutter_lints` | ^6.0.0 | ✅ Used via analysis_options.yaml | Not directly imported |

---

## Unused Packages

| Package | Cost | Cleanup |
|---------|------|---------|
| `cupertino_icons` | Adds ~100 KB but more importantly adds a dependency that pulls in Cupertino icon font assets | Remove from `dependencies:` |
| `mobile_scanner` | ~2 MB binary size, Google MLKit dependency via native side | Remove. Add when scanner feature is actively built |
| `path` | Small, but zero reason to keep if unused | Remove |
| `sqflite_sqlcipher` | ~2 MB, SQLCipher native library per platform | Remove. Add when offline sync is implemented. The SQLite + encryption dependency should be revisited at that point — `drift` (formerly moor) may be a better choice |
| `uuid` | Small. No transitive weight | Remove |

---

## Heavy Packages (Cost Analysis)

| Package | Estimated Size | Notes |
|---------|---------------|-------|
| `mobile_scanner` | ~2 MB compiled | MLKit + camera adapter. Reasonable if scanning is used, wasteful if not. |
| `sqflite_sqlcipher` | ~2 MB compiled | SQLCipher + native crypto. Reasonable for offline storage, wasteful if not. |
| `file_picker` | ~500 KB | Platform-native file picker channel. Acceptable for its feature. |
| `flutter_secure_storage` | ~200 KB | Keychain/Keystore wrapper. Acceptable. |

**Binary size estimate:** Current unused packages add ~4-5 MB to the compiled binary with zero benefit.

---

## Alternative Recommendations

| Current | Alternative | Reason |
|---------|------------|--------|
| `http` (raw) | `dio` | `http` is fine for simple use. `dio` adds interceptors (for JWT refresh), retry, cancellation, multipart built-in (`postMultipart` becomes a one-liner), and timeout config. Not urgent — only worth switching when the retry/interceptor requirements grow. |
| `mobile_scanner` | `mobile_scanner` is the right choice | Already the best Flutter barcode scanner. Decision is correct. |
| `sqflite_sqlcipher` | `drift_sqlcipher` | When offline storage is built, `drift` (formerly moor) provides type-safe queries, auto-migrations, and a reactive stream API. `sqflite_sqlcipher` is the low-level driver — fine but `drift` is more productive. |
| `flutter_lints` | — | Already using the recommended set. Could be upgraded to a stricter rule set. |

---

## Version Conflict Analysis

No version conflicts detected. All dependencies are recent major versions:
- Flutter/Dart are current (Dart ^3.10.4, Flutter 3.x)
- All 3rd-party packages resolve against the current SDK
- `flutter_secure_storage: ^9.2.4` requires Android API 18+ (targeting 21+ is standard)
- `sqflite_sqlcipher: ^3.3.0` is compatible with Dart 3.x

**No version conflicts. No resolution issues.**

---

## Action Summary

| Package | Action | Reason |
|---------|--------|--------|
| `cupertino_icons` | Remove | Unused. Zero CupertinoIcons usage. |
| `mobile_scanner` | Remove | Unused. Re-add when scanning feature is built. |
| `path` | Remove | Unused. |
| `sqflite_sqlcipher` | Remove | Unused. Re-evaluate `drift_sqlcipher` when offline sync is built. |
| `uuid` | Remove | Unused. Re-add when idempotency keys are needed. |

**Cleanup removes 5 dependencies with zero functional impact.**
