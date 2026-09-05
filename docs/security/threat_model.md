# HoBo Transport Production Threat Model

## Assets

- Tenant and membership records
- Passenger identity and booking data
- Trip, seat, boarding, cargo, payment and settlement data
- Authentication credentials, JWT refresh tokens and sessions
- Offline synchronization operations and authorization snapshots
- Audit/security telemetry and incident evidence
- Operational reports and CSV exports

## Primary attack paths

### 1. Account takeover

Threats: credential stuffing, brute force, stolen refresh tokens, session abuse.

Controls: JWT access expiry and refresh rotation/blacklisting, authentication audit events, request correlation, throttling, credential failure telemetry, defensive session/token revocation.

### 2. IDOR / BOLA

Threats: changing UUIDs/IDs in detail, action, export or self-service requests to reach another user's or tenant's object.

Controls: object lookup must include organization and/or authenticated-user relationship; operational resources must additionally enforce the active permission's scope; regression tests must exercise both allowed and denied IDs.

### 3. Privilege escalation / scope confusion

Threats: reusing a branch/counter/assigned-trip scope granted to a different permission; using an expired/future role assignment.

Controls: active role windows, permission-specific scope validation, centralized scoped querysets, cross-role regression tests.

### 4. Cross-tenant data leakage

Threats: unscoped querysets, report joins, exports, sync bootstrap and object actions returning another organization.

Controls: organization is the outer boundary; supported scoped querysets anchor company scope to membership organization; report sources inherit their source-data scope; tenant regression tests.

### 5. Concurrency abuse

Threats: double booking, seat-lock races, duplicate payment/settlement operations, offline replay.

Controls: transactional services, row locking where contention exists, idempotency keys/operation IDs and deterministic conflict handling.

### 6. Bulk extraction / export abuse

Threats: large report requests, repeated CSV exports, sensitive operational data extraction.

Controls: bounded date ranges, bounded/paginated source queries, export audit events, permission and source-data scope enforcement, rate limiting.

### 7. Offline synchronization abuse

Threats: replayed operations, reused operation IDs with different payloads, revoked/expired authorization snapshots.

Controls: authorization snapshot validation, idempotency, payload consistency checks, audit telemetry and explicit denial on invalid snapshots.

### 8. Ransomware / destructive access

Threats: compromised privileged account or infrastructure used to delete/encrypt data.

Controls: isolated backups, tested restore procedures, least privilege, audit trails, credential/session containment and integrity verification.

## Security telemetry requirements

Every security-sensitive event should be attributable to actor (when authenticated), organization (when known), request/correlation ID, resource identifier/type (when safe), timestamp, action and outcome. Never store passwords, raw tokens, payment secrets or unnecessary sensitive PII.

## Detection → containment

1. Detect anomalous authentication, authorization, export, sync or privileged activity.
2. Correlate events by request/session/user/resource/time.
3. Preserve relevant evidence without modifying the original audit record.
4. Revoke affected sessions/tokens/credentials and apply rate restrictions.
5. Isolate the affected account or tenant when justified by incident scope.
6. Verify data integrity and restore from known-good backups if required.
7. Record customer-impact assessment and notification/escalation decisions.

## Safety boundary

Incident response is defensive. HoBo Transport does not retaliate, deploy malware, compromise attacker systems, DDoS, or perform unauthorized access. Traceability is provided through lawful application and infrastructure telemetry and preserved evidence.
