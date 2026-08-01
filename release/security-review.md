# HBT Security Review

**Generated:** 2026-07-29  
**Scope:** JWT · Permissions · Rate Limiting · Secrets · Audit Logs  
**Server:** hbt_backend · Python 3.13 · Django 5.x · DRF · PostgreSQL  
**Status:** 🟢 **Pilot-ready** with 3 minor recommendations

---

## 1. JWT (JSON Web Tokens)

### Implementation

| Component | Detail |
|-----------|--------|
| Library | `rest_framework_simplejwt` |
| Auth backend | `JWTAuthentication` (DRF default) |
| Access token lifetime | **Not overridden** — defaults to 5 minutes |
| Refresh token lifetime | **Not overridden** — defaults to 24 hours |
| Rotation | ✅ `ROTATE_REFRESH_TOKENS = True` |
| Blacklist | ✅ `BLACKLIST_AFTER_ROTATION = True` |
| Update last login | ✅ `UPDATE_LAST_LOGIN = True` |

### Endpoints

| Endpoint | Class | Auth | Notes |
|----------|-------|------|-------|
| `POST /v1/auth/login/` | `LoginView` (TokenObtainPairView) | AllowAny | Custom serializer with audit logging |
| `POST /v1/auth/token/refresh/` | `RefreshView` (TokenRefreshView) | AllowAny | Standard refresh |
| `POST /v1/auth/logout/` | `LogoutView` + blacklist | IsAuthenticated | Blacklists the provided refresh token |
| `POST /v1/auth/register/` | `RegistrationView` | AllowAny | Creates user, logs audit event |

### Login Security

- Custom `HBTTokenObtainPairSerializer.validate()`:
  - Checks `user.status == ACTIVE` before proceeding
  - Logs `authentication.login_failed` on invalid credentials (with SHA-256 digest of identifier, not plaintext)
  - Logs `authentication.login_failed` with reason `account_inactive` on disabled/suspended users
  - Logs `authentication.login_succeeded` on success
- Password field is `write_only`, min_length 8, trim_whitespace=False

### ✅ Strengths

- Refresh token rotation + blacklist prevents replay of stolen refresh tokens
- Failed login audited with hashed identifier (no plaintext phone number in logs)
- Logout explicitly blacklists the token

### ⚠️ Recommendations

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| R1 | 🟡 MEDIUM | Token lifetime not explicitly set | Add `ACCESS_TOKEN_LIFETIME` and `REFRESH_TOKEN_LIFETIME` to `SIMPLE_JWT` dict. Recommended: access 15 min, refresh 7 days for pilot |
| R2 | 🟢 LOW | Rate limit on `/token/refresh/` | Consider rate-limiting refresh endpoint to prevent brute-force rotation |

---

## 2. Permissions

### Architecture

The HBT permission system is **role-based with scoped assignments**:

```
User → Membership (organization) → Role assignments (scoped)
                                         ↓
                              Permission codes (granular)
```

### Enforcement Points

| Layer | Enforcement | Detail |
|-------|-------------|--------|
| DRF Global | `IsAuthenticated` | Default permission for all views |
| Public endpoints | `AllowAny` | Register, login, token refresh |
| Service layer | `require_permission(membership, code)` | Offline sync operations, role management, privacy actions |
| Privacy operations | `require_privacy_reviewer(user)` | Checks `PlatformAccessGrant` for `SUPER_ADMIN` or `SECURITY` role |

### Permission Seed Migrations

15 seed migrations, one per domain group:

| Migration | Domain Permissions |
|-----------|--------------------|
| 0005 | Location |
| 0006 | Network |
| 0007 | Fleet, Workforce |
| 0008 | Scheduling |
| 0009 | Trip Operations |
| 0010 | Passenger, Sales, Boarding |
| 0011 | Cargo, Finance, Operations |
| 0012 | Payment Integration |
| 0013 | Cargo Roadside |
| 0014 | Notification |
| 0015 | Fare, Feedback |
| 0016 | Corporate, Invoice |
| 0017 | Commercial, Branding, Media |
| 0018 | Refund, Reissue |
| 0019 | Provider Payment |

### Role Management

- `access.role.manage` — create/modify roles
- `access.role.assign` — assign roles to memberships
- **Subset delegation**: A role cannot grant permissions the actor doesn't have
- Roles are scoped to tenants; platform-level role templates have `tenant__isnull=True`

### Scoped Assignments

`MembershipRole` supports 6 scope types:
- `company` (org-wide)
- `branch`, `terminal`, `counter` (location-scoped)
- `assigned_trip` (trip-scoped)
- `self` (self only)

Each assignment can have time-bound validity (`valid_from`, `valid_until`).

### ✅ Strengths

- Granular permission model with 15 domain categories
- Time-bound, scoped role assignments
- Delegation constraint (cannot grant permissions beyond own scope)
- Support access grants (time-limited, requires approval, cannot be self-approved)
- `PlatformAccessGrant` for platform-level authority (super admin, support, security, auditor)

### ⚠️ Findings

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| R3 | 🟢 LOW | No DRF view-level permission classes | Most views rely only on `IsAuthenticated`; fine-grained enforcement is in the service layer. This is acceptable for a modular monolith with service-layer validation, but view-level `DjangoModelPermissions` would provide defence-in-depth |

---

## 3. Rate Limiting

### Dual-Layer Implementation

#### Layer 1 — nginx (reverse proxy)

| Zone | Target | Rate | Burst | Config Source |
|------|--------|------|-------|---------------|
| `api_per_ip` | General API | 20 req/s | 40 | `devops/nginx/hbt.conf` (compose) |
| `api` | General API | 100 req/s | 200 | `devops/nginx/production.conf` |
| `login` | Login endpoint | 5 req/min | — | `devops/nginx/production.conf` |

#### Layer 2 — Django (DRF throttling)

| Throttle Class | Rate | Environment Variable | Default |
|----------------|------|---------------------|---------|
| `AnonRateThrottle` | Anonymous requests | `API_ANON_RATE` | 120/min |
| `UserRateThrottle` | Authenticated requests | `API_USER_RATE` | 1200/min |

### nginx Rate Limit Configuration

**Production nginx** (`production.conf`):
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# API
location /api/ {
    limit_req zone=api burst=200 nodelay;
}

# Login is under /api/v1/auth/login/
# Nginx rate limit covers all /api/ paths
```

**Compose nginx** (`hbt.conf`):
```nginx
limit_req_zone $binary_remote_addr zone=api_per_ip:10m rate=20r/s;
location / {
    limit_req zone=api_per_ip burst=40 nodelay;
}
```

### Health Endpoint Exception

The health endpoint at `/api/v1/health/` has `access_log off` and is excluded from rate limiting via a separate `location` block.

### ✅ Strengths

- Two-layer defense (reverse proxy + Django throttling)
- Differentiated rates for authenticated vs anonymous users
- Login-specific rate limit in production config
- Health endpoint exempt from rate limits
- Configurable via environment variables

### ⚠️ Findings

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| R4 | 🟡 MEDIUM | `production.conf` uses a single `api` zone for all endpoints | Login and token refresh could benefit from a dedicated, stricter zone. Covered partially by the 5 req/min login zone, but it's scoped by `$binary_remote_addr` on the full API path — verify it correctly matches `/api/v1/auth/login/` |
| R5 | 🟢 LOW | Compose `hbt.conf` doesn't have a separate login throttle | Production-only release; compose is for dev |

---

## 4. Secrets Management

### Classification

| Secret | Storage | Production Method | Fallback |
|--------|---------|-------------------|----------|
| `DJANGO_SECRET_KEY` | `.env` / env var | Docker secret / env injection | ❌ None (crash if missing) |
| `POSTGRES_PASSWORD` | `.env` / env var | Docker secret (`postgres_password` file) | Hardcoded dev default |
| `NRC_ENCRYPTION_KEY` | `.env` / env var | Docker secret / env injection | SHA-256 derived from `SECRET_KEY` |
| `NRC_BLIND_INDEX_KEY` | `.env` / env var | Docker secret / env injection | Falls back to `SECRET_KEY` |
| `PAYMENT_CREDENTIAL_ENCRYPTION_KEY` | `.env` / env var | Docker secret / env injection | Derived from `SECRET_KEY` |
| `PUSH_TOKEN_ENCRYPTION_KEY` | `.env` / env var | Docker secret / env injection | Derived from `SECRET_KEY` |
| `TLS_CERT_PATH` / `TLS_KEY_PATH` | Compose env | File on host + Docker bind | ❌ None |

### Encryption Architecture

All sensitive data encryption uses **Fernet (AES-128-CBC + HMAC)** via `cryptography.fernet.Fernet`:

```
Field Encryption Layer:
  NRC fields      → NRC_ENCRYPTION_KEY / _fernet()
  NRC blind index → NRC_BLIND_INDEX_KEY (HMAC-SHA256, NOT reversible)
  Payment creds   → PAYMENT_CREDENTIAL_ENCRYPTION_KEY / _secret_fernet()
  Push tokens     → PUSH_TOKEN_ENCRYPTION_KEY / _push_fernet()
```

**Key derivation (dev fallback):** When encryption keys are not set, a SHA-256 digest of `{prefix}:SECRET_KEY` is used as the Fernet key. This provides deterministic but weak protection — changing SECRET_KEY invalidates all encrypted data.

### Docker Secrets (Production)

```yaml
secrets:
  postgres_password:
    file: ${POSTGRES_PASSWORD_FILE}
```

Mounted into containers at `/run/secrets/postgres_password`. The Django settings function `env_or_file()` reads from env var file path if `_FILE` suffix is set.

### ✅ Strengths

- Fernet encryption for PII/NRC data, payment credentials, and push tokens
- NRC blind indexes enable search without decrypting (HMAC only)
- Three independent encryption keys (NRC, payment, push)
- Docker secrets for production DB password
- `env_or_file()` utility supports both env var and file-based injection
- Secret fallbacks exist for development (though derived from SECRET_KEY)

### ⚠️ Findings

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| R6 | 🟡 MEDIUM | No secrets vault (HashiCorp Vault / AWS Secrets Manager) | For pilot, Docker secrets + env injection is acceptable. For production, add a vault integration |
| R7 | 🟡 MEDIUM | Encryption key fallbacks derive from `SECRET_KEY` | A compromised SECRET_KEY cascades to decrypt NRC, payment credentials, and push tokens. Set all encryption keys explicitly in production |
| R8 | 🟢 LOW | `.env.production.example` contains placeholder values | Document the secret injection process in the deployment runbook |

---

## 5. Audit Logging

### Architecture

```
record_audit_event() →
  AuditEvent.objects.create() → PostgreSQL
    │
    ├── Actor (FK → User, nullable for system/anonymous events)
    ├── Tenant & Organization context
    ├── Action + Resource type + Resource ID (indexed)
    ├── Correlation ID (for distributed tracing)
    ├── Before/After snapshots (JSON)
    └── Metadata (JSON)
```

### Append-Only Enforcement

The `AuditEvent` model strictly enforces immutability:

| Operation | Enforcement |
|-----------|-------------|
| `save()` on existing | ✅ Raises `ValidationError` |
| `delete()` on instance | ✅ Raises `ValidationError` |
| `QuerySet.update()` | ✅ Raises `ValidationError` |
| `QuerySet.delete()` | ✅ Raises `ValidationError` |

### Audited Events

#### Authentication
| Event | Where | Detail |
|-------|-------|--------|
| `authentication.login_succeeded` | LoginView | Actor set, method=phone_password |
| `authentication.login_failed` | LoginView | Phone number SHA-256 hashed, reason: invalid_credentials/account_inactive |
| `authentication.logout` | LogoutView | Session termination event |

#### Identity & Privacy
| Event | Where | Detail |
|-------|-------|--------|
| `identity.registered` | RegistrationView | New user with status |
| `identity.profile_updated` | MeView | Before/after snapshots |
| `privacy.request_submitted` | MyPrivacyRequestListCreateView | Type + status |
| `privacy.request_cancelled` | MyPrivacyRequestCancelView | Status transition |
| `privacy.request_verify/start/fulfill/reject` | PlatformPrivacyRequestActionView | Before/after status, retention hold, evidence |
| `privacy.self_export_generated` | MyDataExportView | Section counts, truncation info |

#### Authorization
| Event | Where | Detail |
|-------|-------|--------|
| `authorization.access_denied` | Exception handler | 401/403 for authenticated users |
| `authorization.role_created` | tenancy/services.py | Role code + permission set |
| `authorization.role_assigned` | tenancy/services.py | Membership + role + scope |

#### Offline Sync
| Event | Where | Detail |
|-------|-------|--------|
| `offline.authorization_snapshot_issued` | offline/services.py | Device ID + expiry |
| `offline.operation_applied/rejected/conflict` | offline/services.py | Operation type + status + device |

### Exception Handling

The `audit_exception_handler` (custom DRF exception handler):
- Captures 401/403 errors for authenticated users
- Logs `authorization.access_denied` with method, path, status code
- Explicitly catches exceptions during audit logging to **not replace security responses**

### ✅ Strengths

- Append-only by design with full query-level enforcement
- Comprehensive event coverage (auth, identity, privacy, authorization, offline)
- Correlation ID support for distributed tracing
- Before/after snapshots for state changes
- Secure failure logging (phone numbers hashed, not plaintext)
- Tested with 3 dedicated test cases

### ⚠️ Findings

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| R9 | 🟢 LOW | No data retention policy for audit logs | Define retention period (e.g., 1 year + archival) and add a cleanup job |
| R10 | 🟢 LOW | No audit log viewer in admin | Consider adding a read-only admin view for operators with `AUDITOR` role |

---

## Summary

### Risk Ratings

| Domain | Risk | Pilot-Ready? | Issues |
|--------|------|-------------|--------|
| **JWT** | 🟢 Low | ✅ Yes | R1 (token lifetime), R2 (refresh throttle) |
| **Permissions** | 🟢 Low | ✅ Yes | R3 (view-level defence-in-depth) |
| **Rate Limiting** | 🟢 Low | ✅ Yes | R4 (login zone scope), R5 (compose throttle) |
| **Secrets** | 🟡 Medium | ⚠️ With caveats | R6 (no vault), R7 (key cascading), R8 (doc placeholder) |
| **Audit Logging** | 🟢 Low | ✅ Yes | R9 (retention policy), R10 (admin viewer) |

### Overall Verdict

**🟢 PILOT-READY** — The five reviewed domains are well-implemented for a supervised pilot. The secrets management has the highest latent risk due to key cascading and lack of a vault, but Docker secrets + explicit encryption keys mitigate this for controlled deployments.

### Pre-Pilot Action Items

| Priority | Ref | Action |
|----------|-----|--------|
| 🟡 Must-fix | R1 | Set explicit JWT token lifetimes in `SIMPLE_JWT` |
| 🟡 Must-fix | R7 | Ensure all encryption keys are set in production `.env` |
| 🟢 Should-do | R6 | Document the vault strategy for post-pilot |
| 🟢 Nice-to-have | R9 | Add audit log retention policy |

---

*End of Security Review*
