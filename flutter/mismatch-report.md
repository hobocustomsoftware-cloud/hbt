# Architecture vs. Implementation — Mismatch Report

**Generated:** 2026-07-29
**Architecture Sources:** `architecture/`, `docs/` (prompts/specs)
**Implementation:** Flutter `hbt_business_app`

---

## Mismatch 1: Offline First (Critical)

| Source | Spec | Implementation |
|--------|------|---------------|
| `architecture/08-offline-architecture.md` | "Local Storage, Synchronization, Conflict Resolution, Retry Strategy, Queue-based Synchronization, Connectivity Detection" | ❌ **Zero offline capability.** `sqflite_sqlcipher` is declared but never imported. No local database schema. No sync queue. No conflict resolution. No connectivity detection. |
| `docs/implementation/07-notification-offline-sync.md` | "Offline sync bootstrap with bounded delta-download, encrypted local database, durable upload queue, retry state, last successful cursor" | ❌ **Not implemented.** `DashboardPage` explicitly says "Offline outbox နှင့် sync UI ကို နောက်အဆင့်တွင် ချိတ်မည်" (will connect in next phase). |
| `backend/README.md` | "Mobile clients must retain an encrypted local database, durable upload queue, retry state, and last successful sync cursor" | ❌ **No client-side sync infrastructure exists.** |

**Severity:** 🔴 BLOCKING. This is HBT's core architectural principle. The architecture says "Offline First." The code says "Online Only."

---

## Mismatch 2: Permission Architecture (High)

| Source | Spec | Implementation |
|--------|------|---------------|
| `docs/security/04-authorization.md` | "Effective permission set returned by backend. Clients must derive menus, actions, and protected screens from effective permissions. Clients must not treat a role name alone as proof of authority." | ✅ **Partially correct.** `SessionController.hasPermission()` checks server-returned permissions. `TicketSalesPage` and `CargoWorklistPage` use `hasPermission()` for conditional rendering. |
| `docs/security/21-access-control-matrix.md` | Detailed role-permission matrix with clearance levels, approval limits, and scope constraints | ❌ **No client-side permission model.** The `Set<String>` permissions list from the server is treated as a flat list. No hierarchy. No scopes. No approval limits. |
| MVP scope | "Permissions must combine role and scope. Required scopes include tenant-wide, branch, terminal, counter, assigned trip, and self-only." | ❌ **Scope is not modeled client-side.** `PermissionGuard` doesn't exist. Permissions are checked as flat strings like `'booking.view'` with no scope context. |

**Severity:** 🟡 WARNING. Functional for MVP but lacks scope and hierarchy.

---

## Mismatch 3: State Management (High)

| Source | Spec | Implementation |
|--------|------|---------------|
| `architecture/10-technology-stack.md` | Flutter is the approved frontend technology | ✅ **Correct.** |
| Architecture documents | (No explicit state management decision documented) | ⚠️ **No defined state management pattern.** Using raw `ChangeNotifier` + inline widget state. This is an undocumented decision. |
| Common Flutter best practices | Separation of concerns, repository pattern, feature controllers | ❌ **All business logic is in widgets.** No controllers, no repositories, no services layer beyond `SessionController`. |

**Severity:** 🟡 WARNING. No architectural guidance exists for state management. The codebase evolved its own pattern.

---

## Mismatch 4: Error Handling (Medium)

| Source | Spec | Implementation |
|--------|------|---------------|
| `docs/api/07-error-handling.md` | Structured error responses: `{"success": false, "error": {"code": "...", "message": "...", "details": {...}}}` | ⚠️ **Partially matched.** `ApiClient._apiErrorMessage()` tries to extract `detail` or `message` from the response, but it's a flat extractor that doesn't understand the API's structured error format. |
| `apps/core/exceptions.py` | Standardized `ApiException`, `ValidationException`, `NotAuthenticatedException` | ❌ **Client has one exception type.** `ApiException` with a single `message` string. No distinction between network errors, validation errors, auth errors, or server errors. |

**Severity:** 🟢 INFO. Works for MVP but loses type information.

---

## Mismatch 5: API Versioning (Medium)

| Source | Spec | Implementation |
|--------|------|---------------|
| `docs/api/02-api-versioning.md` | "API version MUST be part of URL: `/api/v1/`" | ✅ **Correct.** `ApiClient` uses `/api/v1/...` paths. |
| `docs/api/16-api-lifecycle.md` | Version deprecation, sunset headers, migration support | ❌ **Not implemented.** No version negotiation. No deprecation handling. No graceful fallback. |

**Severity:** 🟢 INFO. Acceptable for MVP.

---

## Mismatch 6: Logging & Observability (Medium)

| Source | Spec | Implementation |
|--------|------|---------------|
| `docs/operations/10-monitoring.md` | Metrics, logs, traces, dashboards, alerting | ❌ **Zero observability on client.** No logging framework. No error reporting to backend. No performance monitoring. No user action tracking. |

**Severity:** 🟢 INFO. Typical for early-stage mobile app.

---

## Mismatch 7: Testing Architecture (Medium)

| Source | Spec | Implementation |
|--------|------|---------------|
| `docs/testing/01-testing-principles.md` | Comprehensive testing pyramid | ❌ **1 test file exists** (default template). |
| `docs/testing/04-test-automation.md` | Automated test suite, CI integration | ❌ **No Flutter tests in CI.** The CI pipeline at `.github/workflows/backend-ci.yml` only tests the backend. |

**Severity:** 🟡 WARNING. No test coverage means regressions are undetectable.

---

## Mismatch 8: Print Architecture (Low)

| Source | Spec | Implementation |
|--------|------|---------------|
| `backend/README.md` | `GET /api/v1/organizations/{org_id}/print-documents/`, `POST /print-documents/{id}/printed/` | ❌ **Not implemented in Flutter.** No print service. No print queue. No Bluetooth thermal printer support. |
| MVP scope | "The business mobile application must support Bluetooth thermal printing" | ❌ **No printing capability.** |

**Severity:** 🟡 WARNING. Printing is an MVP requirement with zero progress.

---

## Mismatch 9: Scanner / Barcode (Low)

| Source | Spec | Implementation |
|--------|------|---------------|
| MVP scope | "QR scanning for ticket validation, cargo handover" | ❌ **`mobile_scanner` declared but never imported.** No scanner integration in any screen. |

**Severity:** 🟡 WARNING. Scanning is an MVP requirement with zero progress.

---

## Summary

| # | Mismatch | Spec Reference | Severity |
|---|----------|---------------|----------|
| 1 | **Offline First** | Architecture core principle, 3 spec docs | 🔴 BLOCKING |
| 2 | Permission scope model | Security architecture | 🟡 WARNING |
| 3 | State management pattern | Undocumented decision | 🟡 WARNING |
| 4 | Error type hierarchy | API error handling spec | 🟢 INFO |
| 5 | API lifecycle management | API versioning spec | 🟢 INFO |
| 6 | Client observability | Operations spec | 🟢 INFO |
| 7 | Test coverage | Testing spec | 🟡 WARNING |
| 8 | Bluetooth printing | MVP scope, backend README | 🟡 WARNING |
| 9 | QR/barcode scanning | MVP scope | 🟡 WARNING |

**3 blocking/warning mismatches** (online-only, no printing, no scanning) are MVP requirements with zero implementation progress. These are not scope decisions — they are explicitly called out as must-have in the product spec.
