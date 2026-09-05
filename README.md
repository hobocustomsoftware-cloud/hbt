# HoBo Transport (HBT)

Myanmar intercity bus ticketing and bus-gate operations platform.

## Production Readiness

The `backend/mvp-production-hardening` branch is the **production-ready backend MVP baseline** for HoBo Transport.

This branch is intentionally kept separate from `main`. The production-ready baseline is **not merged into `main`** by this change.

### CI/CD gate

The latest GitHub Actions `backend-ci` run completed successfully on commit `8f006b885aec246c588871146d1e8d05db1d5849`.

The release gate passed:

- Django test suite
- Django migration consistency check
- OpenAPI schema validation
- `pip check`
- `pip-audit`
- Bandit security scan
- Semgrep security scan

## What is included

### Booking and passenger operations

- Passenger registration/login and account management
- Trip discovery and booking
- Seat locking and booking lifecycle
- Manual payment verification
- Ticketing and boarding workflows
- QR-based boarding validation

### Bus-gate operations

- Organization/tenant isolation
- RBAC and operational scope enforcement
- Trip, fleet and assignment workflows
- Seat allocation and segment reuse
- Cargo acceptance, loading, transit, unloading and handover
- Cash settlement and reconciliation
- Agent commission and settlement
- Printing/document workflows
- Operational and financial reporting
- Monitoring dashboards
- Offline-first synchronization with authorization snapshots, idempotency and conflict handling

## Security baseline

The backend includes production-oriented defensive controls for:

- Tenant isolation and cross-organization access prevention
- Role and operational-scope authorization
- API-level authorization-denial audit telemetry
- Sensitive audit-field redaction
- Offline synchronization authorization checks
- Idempotency and duplicate-operation protection
- JWT access/refresh-token hardening and refresh-token blacklisting
- Request throttling
- Secure production configuration defaults
- Dependency and static security scanning
- Security threat-model and incident-response documentation

Security design follows a defensive model: **Prevent → Detect → Trace → Contain → Preserve Evidence → Recover**.

The system is not designed for offensive retaliation against attackers. Incident response focuses on protecting customers, tenants and system/data integrity while preserving evidence for investigation.

## Data and operational safeguards

- PostgreSQL is the production database target.
- Critical business operations use transactional validation and locking where required.
- Offline operations support server-side validation and idempotent processing.
- Reporting/export workloads have bounded date ranges and source-data scope filtering.
- API responses are validated against the project's OpenAPI schema in CI.

## Payments

The MVP uses **manual payment verification** (cash, bank transfer or wallet QR evidence with staff verification).

Automatic payment gateways, webhook-based automatic verification, automatic reconciliation and automatic refunds are intentionally deferred to a later licensed/provider-backed phase.

## Architecture

The repository contains two primary product areas:

1. **Passenger Booking** — customer-facing trip search, booking, payment evidence, tickets and boarding.
2. **Business Operations** — bus-company operational control including trips, fleet, staff roles, cargo, cash, reporting and offline workflows.

The backend is implemented with Django and Django REST Framework and uses PostgreSQL for production data storage.

## Development and validation

Install backend dependencies from `backend/requirements.txt` and the security tooling from `backend/requirements-security.txt`.

Before release, the same automated CI gate should remain green on the exact commit intended for deployment.

Recommended deployment practice:

1. Pin the exact production commit.
2. Apply migrations during the deployment process.
3. Run health checks and smoke tests.
4. Verify database connectivity and required environment configuration.
5. Confirm backups and restore procedures are operational.
6. Monitor authentication, authorization, errors and business-critical operations after release.
7. Keep a rollback path to the previous known-good production commit.

## Production security responsibilities

Application-level hardening does not replace deployment infrastructure controls. A real production deployment must also provide:

- Strong secret management; never commit production secrets.
- Restricted database/network access.
- HTTPS/TLS termination and appropriate edge protection/WAF where applicable.
- Isolated and tested database backups, with a documented recovery procedure.
- Centralized monitoring, alerting and log retention.
- Access control for production infrastructure and administrative accounts.
- A tested incident-response and rollback procedure.

These are deployment responsibilities and must be verified in the actual production environment before exposing the service to real customer traffic.

## Documentation

- `backend/PRODUCTION_READINESS.md` — production readiness gates and release criteria
- `docs/production_scope_matrix.md` — operational scope model
- `docs/role_permission_matrix.md` — role/permission model
- `docs/security/threat_model.md` — security threat model
- `docs/security/incident_response_runbook.md` — incident-response procedure

## Branch policy for this baseline

- `main` is **not changed or merged** as part of this production-readiness handoff.
- `backend/mvp-production-hardening` is the reviewed production-ready backend baseline.
- Do not deploy an unreviewed commit in place of the CI-validated production commit.

## Status

**Backend MVP: Production-ready baseline**  
**CI/CD: GREEN**  
**Production deployment: requires environment/infrastructure verification**
