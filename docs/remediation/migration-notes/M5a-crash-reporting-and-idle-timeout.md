# M5a Migration Note — Crash Reporting Hook + Idle Session Timeout

**Author:** OpenClaw Manager
**Date:** 2026-08-01
**Status:** Design (pre-implementation) — per working rules, committed BEFORE code changes.
**Milestone:** M5a (roadmap `merged_audit_findings_roadmap.md`)

## 1. Scope

First tranche of M5, selected for real production impact (rule 8: no style-only
refactors; these are operational/security gaps, not cleanup):

| Finding | Title | Priority |
|---------|-------|----------|
| F-18 | No crash reporting — production crashes invisible | D |
| F-09 (part) | No idle session timeout — unattended device = full access | B |

F-09's other half — **certificate pinning** — stays deferred: it requires
release/build infrastructure and a product decision (pinned certs per
environment), documented in §5.

## 2. Design — F-18 crash reporting hook (both apps)

### 2.1 Principle

**Env-gated, zero-config safe.** A `CrashReporter` abstraction with a no-op
default. When `HBT_CRASH_REPORTING_DSN` is present at build time (via
`--dart-define`), errors are forwarded; otherwise the app behaves exactly as
today. No DSN → no network calls, no dependency activation.

### 2.2 Structure

```
lib/shared/services/crash_reporter.dart   (business app)
lib/shared/services/crash_reporter.dart   (passenger app — same file content,
                                           pending F-21 shared-package extraction)
```

```dart
class CrashReporter {
  CrashReporter._();
  static final CrashReporter instance = CrashReporter._();

  /// Configured DSN from --dart-define ('' = disabled).
  static const String dsn = String.fromEnvironment('HBT_CRASH_REPORTING_DSN');

  bool get enabled => dsn.isNotEmpty;

  void recordError(Object error, StackTrace stack, {String? context}) {
    if (!enabled) return;
    // TODO(F-18b): forward to Sentry/Crashlytics SDK once DSN is provisioned.
    // The hook is the contract; the transport is intentionally swappable so
    // either vendor can be wired without touching error boundaries.
    debugPrint('HBT crash (DSN configured): $error\n$stack');
  }
}
```

### 2.3 Wiring (no behavior change when disabled)

- `main.dart` (both apps): `FlutterError.onError` and the `runZonedGuarded`
  handler call `CrashReporter.instance.recordError(...)` **in addition to**
  existing `debugPrint`/`presentError`. When `dsn` is empty this is a
  no-op — the current logging behaviour is preserved exactly.
- Error boundary widget (both apps): unchanged.

### 2.4 Why not the vendor SDK yet

Adding `sentry_flutter`/Firebase now would (a) add native dependencies to both
apps, (b) require a DSN/Google-services file that does not exist yet, and
(c) create a second way to crash before the crash reporter is proven. The hook
+ env gate delivers the *contract* with zero risk; wiring a vendor SDK becomes
a one-file change when the DSN is provisioned (tracked as F-18b).

## 3. Design — F-09 idle session timeout (both apps)

### 3.1 Behaviour

- After `HBT_IDLE_TIMEOUT_MINUTES` (default **15**, `--dart-define`)
  of no user interaction, the app locks: shows a full-screen lock overlay
  requiring re-entry of the PIN/password-equivalent — for this MVP,
  **re-authentication via existing login screen** (passenger) / lock screen
  that verifies against the session (business).
- Any tap/scroll/keyboard resets the idle timer.

### 3.2 Structure

```
lib/shared/services/idle_timeout_controller.dart   (both apps, identical)
```

```dart
class IdleTimeoutController extends ChangeNotifier {
  IdleTimeoutController({required this.timeout});
  final Duration timeout;
  Timer? _timer;
  bool _locked = false;

  bool get locked => _locked;
  void registerActivity() { _reset(); if (_locked) _unlockRequested = true; }
  // Timer fires -> _locked = true; notifyListeners();
}
```

- **Listener:** root `MaterialApp` `builder:` wraps the app in a
  `Listener` (pointer events → `registerActivity`) and shows the lock
  overlay when `locked` (mirrors the offline-banner pattern already in
  both apps).
- **Unlock:** overlay offers "Unlock" → navigates to login (passenger) or
  verifies session still valid (business). Both keep tokens; the lock is a
  UX guard, not a token wipe (token expiry already handled by refresh logic).
- **Config:** `AppConfig.idleTimeoutMinutes` from `--dart-define`,
  default 15; `0` disables (dev convenience).

### 3.3 Scope limits

- NOT a security boundary: no token deletion, no biometrics. It is an
  unattended-device deterrent, matching the audit's "device left unattended
  = full access" concern at MVP level.
- No per-screen granularity; one global idle timer.

## 4. Tests (rule 6)

| Component | Test file | Coverage |
|-----------|-----------|----------|
| CrashReporter | `test/shared/crash_reporter_test.dart` (both apps) | disabled → no-op; enabled path with fake DSN forwards (via injectable sink in test) |
| IdleTimeoutController | `test/shared/idle_timeout_test.dart` (both apps) | timer fires → locked; activity resets timer; timeout=0 disables; unlock clears state |
| Widget lock overlay | `test/widgets/lock_overlay_test.dart` (passenger) | overlay appears when locked, dismisses on unlock |

## 5. Deferred within M5a

- **F-09 cert pinning** — needs pinned-cert artifacts per environment +
  release signing setup. Documented here as the follow-up (F-09b), scheduled
  after M5a ships.
- **F-18b vendor SDK wiring** — one-file change when DSN provisioned.

## 6. Migration steps (each = one commit, app runnable after each)

1. M5a-1 — `CrashReporter` + `IdleTimeoutController` + config fields + tests
   (new files only; nothing wired yet).
2. M5a-2 — wire crash reporter into both `main.dart` error paths.
3. M5a-3 — wire idle timeout into both app shells (Listener + lock overlay).
4. M5a-4 — widget tests for overlay; full suite + analyze; docs; report.

## 7. Rollback

Per-step commits; `git revert <commit>` per step. No schema changes; no
backend changes; no new third-party dependencies in this milestone.
