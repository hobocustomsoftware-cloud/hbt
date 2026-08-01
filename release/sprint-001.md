# Sprint 001 — Foundation Unblocking

**Date:** 2026-07-29
**Duration:** 1 day (max 5 tasks, ~6.5 hours total)
**Goal:** Remove the highest-leverage blockers that gate the most future work

---

## Task Selection Logic

Every task was chosen because it **unblocks multiple downstream tasks**. The sprint prioritizes enabling future work over doing the work itself.

```
Current blockers                    After Sprint 001
══════════════════                  ══════════════════
INFRA-001 Secrets      ✅ done      Deploy CI    ← unblocked by Sentry + Postgres TLS
INFRA-005 Postgres TLS              Coverage     ← unblocked by baseline
OBS-001    Sentry                    Widget tests ← unblocked by CI confidence
┌─────────────────────┐             More features ← unblocked by test safety
│ Everything else     │             
│ is blocked without  │             
│ monitoring + safety │             
└─────────────────────┘
```

---

## Task 1: OBS-001 — Sentry Backend Error Tracking

**Effort:** 1 hour
**Unblocks:** Production deployment, incident response, deploy validation, performance tracking

**Why this task:**
- Without error tracking, every production error is invisible. You cannot know if a deploy succeeded or failed.
- Sentry is the foundation for: deploy validation (verify 0 new errors after deploy), incident response (get stack traces automatically), and performance monitoring (trace slow endpoints).
- Every other monitoring/observability task (OBS-002 Prometheus, OBS-003 JSON logging) is additive — Sentry is the minimum viable monitoring.

**What it enables:**
- INFRA-new (deploy CI) — can validate deploys by checking Sentry
- OBS-003 (JSON logging) — log correlation with Sentry event IDs
- All future releases — deploy confidence

**Acceptance:** Django errors appear in Sentry dashboard. DRF exceptions captured. Performance tracing optional.

---

## Task 2: INFRA-005 — PostgreSQL TLS Configuration

**Effort:** 2 hours
**Unblocks:** Production deployment security gate, data-in-transit compliance

**Why this task:**
- Database traffic is currently unencrypted. Credentials are sent in plaintext over the network.
- Any network-level attacker can intercept all database traffic, read credentials, and exfiltrate data.
- This is a hard security gate — no production system should operate without encrypted database connections.

**What it enables:**
- Security compliance (GDPR, SOC 2 readiness)
- Secure multi-tenant data isolation
- Production deployment with confidence

**Acceptance:** `ssl=on` in postgres.conf. `hostssl` only in pg_hba.conf. SCRAM-SHA-256 password encryption. App connects via TLS. Non-TLS connections rejected.

---

## Task 3: TEST-001 — Backend Coverage Baseline

**Effort:** 1 hour
**Unblocks:** CI coverage gates, quality tracking, identifying untested code

**Why this task:**
- The backend has ~1,047 test functions but nobody knows what's tested vs untested.
- Without a coverage baseline, you cannot: set a coverage target, block regressions in CI, or prioritize test writing.
- A coverage report takes 1-2 commands and immediately shows where the gaps are.

**What it enables:**
- CI coverage gate (fail PRs that reduce coverage)
- Targeted test writing (focus on untested modules)
- Quality trends over time

**Acceptance:** `coverage run && coverage report` executed. Gaps documented. Baseline percentage recorded.

---

## Task 4: TEST-002 — Flutter Widget Tests

**Effort:** 2 hours
**Unblocks:** Mobile CI quality gate, confident Flutter changes, regression prevention

**Why this task:**
- Currently 1 stub test file in the entire Flutter app. Zero meaningful tests.
- Without tests: every Flutter change risks breaking existing screens, regressions go undetected, CI doesn't protect mobile code.
- Writing tests for the 3 most important screens (SignIn, Booking, Cargo list) covers the critical user paths.

**What it enables:**
- Flutter CI gate (fail PRs that break existing tests)
- Safe refactoring (extract shared widgets without fear)
- Future feature work with regression protection

**Acceptance:** 5+ widget tests passing in CI covering: SignInScreen renders/validates/authenticates, BusinessHome shows org context, CargoWorklistPage loads shipments.

---

## Task 5: Root README + .gitignore

**Effort:** 30 minutes
**Unblocks:** Contributor onboarding, git hygiene, fixing 2 of 5 scan failures

**Why this task:**
- The root README is 0 bytes and .gitignore is 0 bytes. These are the first things people see.
- Without a meaningful README: nobody knows what the project is, how to contribute, or where to start.
- Without a proper .gitignore: `.env` files, `__pycache__`, IDE configs, and `node_modules` can accidentally be committed.

**What it enables:**
- New contributor onboarding (README)
- Prevention of accidental secret commits (.gitignore)
- Fixes 2 of the 5 scan failures

**Acceptance:** README.md has project overview, setup instructions, and architecture links. .gitignore covers Python, Flutter, IDE, and OS files.

---

## Sprint Summary

| # | Task | Area | Effort | Unblocks |
|---|------|------|--------|----------|
| 1 | OBS-001 Sentry backend | Monitoring | 1h | Production deploy, incident response, deploy validation |
| 2 | INFRA-005 PostgreSQL TLS | Infrastructure | 2h | Security compliance, production deploy |
| 3 | TEST-001 Coverage baseline | Testing | 1h | CI quality gates, targeted testing |
| 4 | TEST-002 Flutter widget tests | Testing | 2h | Mobile CI gate, safe refactoring |
| 5 | Root README + .gitignore | Foundation | 30m | Contributor onboarding, git hygiene |
| | **Total** | | **6.5 hours** | |

## Readiness Impact

```
Before Sprint:             After Sprint:
  INFRA  ███████░░░  7/9     INFRA  █████████░  8/9
  SEC    █░░░░░░░░░  1/7     SEC    █░░░░░░░░░  1/7   (unchanged)
  DATA   ███░░░░░░░  1/3     DATA   ███░░░░░░░  1/3   (unchanged)
  TEST   ░░░░░░░░░░  0/3     TEST   ███████░░░  2/3
  MON    ░░░░░░░░░░  0/3     MON    █████░░░░░  1/3
  OPS    ██████████  2/2     OPS    ██████████  2/2   (unchanged)
  PH2    ░░░░░░░░░░  0/7     PH2    ░░░░░░░░░░  0/7   (unchanged)
  ───────────────────        ───────────────────
         11/31                        16/31
        
  Readiness: 🟡 RISKY      ⇨    🟡 RISKY (approaching 🟢 CONDITIONAL)
```

After these 5 tasks, the remaining blockers reduce from 3 critical to 1 (deploy CI). Test infrastructure is in place. Monitoring is operational. Database is secured.
