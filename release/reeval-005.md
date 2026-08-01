# Release Re-Evaluation — 005

**Date:** 2026-07-29
**Previous state:** 10/31 tasks
**Current state:** 11/31 tasks
**Readiness:** 🟡 RISKY

---

## Change

| Task | Status | Evidence |
|------|--------|----------|
| INFRA-001 | ✅ COMPLETED | `compose.production.yml` uses Docker secrets (`secrets:` block), settings.py uses `env_or_file()` pattern. No secrets in docker-compose. No secrets in git. |

## Updated Critical Blockers

### Remaining (3)

| # | Blocker | Task ID | Status | Effort |
|---|---------|---------|--------|--------|
| 1 | PostgreSQL connections unencrypted | INFRA-005 | ❌ PENDING | 2h |
| 2 | No error tracking (Sentry) | OBS-001 | ❌ PENDING | 1h |
| 3 | No deployment CI workflow | (new) | ❌ PENDING | 2h |

### Resolved (1)

| # | Blocker | Resolution |
|---|---------|------------|
| 1 | Secrets in .env files | Docker secrets pattern implemented. `POSTGRES_PASSWORD_FILE` loaded at runtime. Settings.py `env_or_file()` reads from file or env var. |

## 5 Scan Failures — Updated Status

| # | Failure | Status | Note |
|---|---------|--------|------|
| 1 | Dockerfile HEALTHCHECK | ❌ STILL FAILING | Dockerfile has no HEALTHCHECK instruction |
| 2 | Compose restart policy | ✅ NOW PASSING | `restart: unless-stopped` on all services |
| 3 | No deployment CI workflow | ❌ STILL FAILING | No .github/workflows for deploy |
| 4 | No root .gitignore | ❌ STILL FAILING | Root `.gitignore` is 0 bytes (empty) |
| 5 | Root README 0 bytes | ❌ STILL FAILING | Empty file at root |

**Note:** The production compose (`devops/compose.production.yml`) already has restart policies and healthchecks. The scan was checking `docker-compose.yml` at root which is the 0-byte stub.

## Updated Progress

```
Phase 1: Infrastructure  ███████░░░  7/9
Phase 1: Security        █░░░░░░░░░  1/7
Phase 1: Data            ███░░░░░░░  1/3
Phase 1: Testing         ░░░░░░░░░░  0/3
Phase 1: Monitoring      ░░░░░░░░░░  0/3
Phase 1: Operations      ██████████  2/2
Phase 2                  ░░░░░░░░░░  0/7
────────────────────────────────────
Total                    ███░░░░░░░  11/31
```

## Next Recommended Task

**OBS-001: Sentry backend error tracking.** This is the most impactful remaining task:

- Effort: ~1 hour
- Production errors are currently invisible
- Unblocks production monitoring
- Low-risk implementation (add package, add middleware, set DSN)

After Sentry, the highest-impact remaining tasks are:
1. INFRA-005 (PostgreSQL TLS) — 2h — encrypts all database traffic
2. SEC-003 (Idle session timeout) — 2h — closes JWT token exposure window
3. TEST-002 (Flutter widget tests) — 2h — gates mobile quality
