# Blocker Report — Externally-Blocked Remediation Items

**Date:** 2026-08-01
**Author:** Lead Engineer (OpenClaw Manager)

## Summary

Two roadmap items cannot be completed by the engineering workflow alone — each
requires an external input (a credential/artifact or an infrastructure/product
decision). Per the working rules ("If a task cannot be completed, stop
immediately, generate this report, then continue with the next independent
task"), these are documented here and the pipeline continued to completion of
all independent tasks.

## Blocked Items

### B-1: F-18b — Vendor crash-reporting SDK wiring (Sentry/Crashlytics)

**Status:** ⛔ BLOCKED — awaiting DSN

| Field | Detail |
|-------|--------|
| Roadmap | M5a (F-18) — hook delivered; SDK transport deferred as F-18b |
| What's done | `CrashReporter` abstraction (env-gated via `HBT_CRASH_REPORTING_DSN`) wired into `FlutterError.onError` + `runZonedGuarded` in **both** apps; no-op when unset; tests green |
| What's blocked | Choosing + wiring the vendor SDK (`sentry_flutter` / Firebase Crashlytics) requires a **provisioned DSN / Google-services.json** and a vendor choice (Sentry vs Crashlytics vs Bugsnag) |
| External input needed | 1. Vendor decision (product/ops) · 2. DSN or google-services.json for the org's accounts |
| Effort once unblocked | ~1 file per app (replace the `// TODO(F-18b)` debugPrint transport with the SDK call) + dependency add + smoke test |
| Risk of proceeding now | Adding native SDK dependencies without a real DSN adds APK weight and a second crash path before the hook is proven — violates rules 1/8 |

### B-2: F-09b — Certificate pinning (both apps)

**Status:** ⛔ BLOCKED — needs build/release infrastructure + product decision

| Field | Detail |
|-------|--------|
| Roadmap | M5a (F-09) — idle-session timeout delivered; pinning deferred as F-09b |
| What's done | Idle lock (15-min default, `HBT_IDLE_TIMEOUT_MINUTES`) in both apps |
| What's blocked | Pinning requires: (a) pinned certificate/public-key artifacts per environment (prod/staging), (b) release signing setup, (c) a decision on pin strategy (cert vs SPKI pin, rotation policy) — otherwise pinning can hard-lock all clients out during cert rotation |
| External input needed | Ops/infra: certificate bundle + environment matrix + rotation policy; product sign-off |
| Effort once unblocked | `http` package pinning interceptor or platform-level network security config + build-time env for the pin set |
| Risk of proceeding now | Pinning without a rotation plan is a guaranteed production lockout incident — explicitly called out in the M5a migration note §5 |

## Non-blocked items deferred by design (not blockers)

| Item | Why deferred |
|------|--------------|
| F-23b `features/business` → `features/shell` rename | Style-only churn breaking ~10+ import paths; rules 1/8 — can be done any time as a dedicated mechanical task |
| F-24 (part 2) cargo/trip/routes screen widget tests | Coverage task, no blocker; lower priority than the audit itself |
| F-25 localization (M5c-003) | Product decision needed on MM-first vs EN-first and string source; can proceed with EN baseline extraction independently |

## Recommendation

Unblock B-1 and B-2 in this order: (1) provision a Sentry DSN (fastest,
smallest change), (2) produce the cert-pinning bundle + rotation policy during
the next release cycle. Both are ~1–2 hour engineering tasks once the external
inputs arrive.
