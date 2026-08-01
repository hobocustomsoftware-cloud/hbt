# MVP API Quality, Security and Reliability Report

## Report status

- Review date: 2026-07-26
- Environment: local Windows development environment
- Database: PostgreSQL
- Test runner: Django test runner
- Total automated tests: 79
- Result: 79 passed, 0 failed
- Migration drift: none
- Python compilation: passed
- Dependency consistency: passed

This report does not claim that every planned MVP API is complete or that the
system is impossible to hack. It records reproducible evidence and remaining
release blockers.

## Commercial web and media increment

Implemented and verified on 2026-07-26:

- public four-plan catalogue with server-calculated 5% tax totals
- tenant subscription entitlements and safe-suspension boundaries
- public operator branding and tenant-audited configuration
- promotion/coupon/group-discount calculation inside Fare Quote
- coupon limits and redemption at transactional quote lock
- operator and external-advertiser campaign ownership
- Starter Media Channel denial and Growth/Pro/Enterprise video limits
- separate advertiser verification, advertising-payment confirmation and
  editorial approval using Platform Super Admin authority
- public feed restricted to approved, in-window content

Focused commercial/media tests: 7 passed. The complete backend regression suite
passed with no failures. Migration consistency, Django system checks and Python
compilation passed.

Known closure items include malware scanning, binary file signature inspection,
verified video transcoding, impression/click anti-fraud and the complete
subscription lifecycle write APIs.

## NRC reference and privacy increment

- Added 14 state/region, 446 deduplicated township-code and six citizenship-type
  reference records from a bundled, attributed, versioned source.
- Added Myanmar and English parsing, canonicalization and rendering.
- Added state/township pairing validation and six-digit serial validation.
- Added public cascading-selector and validation endpoints.
- Replaced legacy plaintext use with authenticated encryption and keyed blind
  indexes for Passenger and Cargo identities.
- Added stronger masked output and encrypted migration/manual-review behavior.
- Verified `12/KaMaYa(N)123456` and `9/PaMaNa(N)123456` round trips.
- NRC-focused tests: 4 passed. Full regression suite: 79 passed.

## Changes included in this review

- Notification inbox, pending work, retry and delivery audit foundation.
- Payment, ticket, trip and Cargo Lite notification event producers.
- Device enrollment and revocation.
- Time-bounded offline authorization snapshots.
- Idempotent offline operation receipts.
- Delta synchronization cursor and change feed.
- Deterministic payment destination selection:
  counter, terminal operation, branch, then organization.
- Cargo pricing-rule retrieve/update/deactivate API.
- Public liveness and database-backed readiness probes.
- API throttling baseline.
- Secure cookie, MIME sniffing and clickjacking settings.
- Production startup rejection when the development secret-key fallback is
  still in use.

## Verification commands and results

| Check | Command | Result |
|---|---|---|
| Django configuration | `manage.py check` | Passed, no issues |
| Migration drift | `manage.py makemigrations --check --dry-run` | No changes detected |
| Full automated suite | `manage.py test --keepdb --verbosity 1` | 71 passed |
| Python syntax/import compilation | `python -m compileall -q apps config` | Passed |
| Installed dependency consistency | `python -m pip check` | No broken requirements |
| Django production security check | `manage.py check --deploy` | Five local-environment warnings |

## Unit and domain test coverage

### Identity and access

- Phone identity normalization.
- Myanmar language default.
- Password hashing and password omission from API output.
- Inactive-account login denial.
- Login phone cannot be changed through profile update.
- Platform access cannot be self-granted.
- Cross-tenant role assignment is rejected.
- Scoped roles require the correct scope identifier.
- Custom roles cannot exceed delegator permissions.
- Tenant organization IDOR access is denied.
- Support access cannot be self-approved.

### Locations, route, fleet and workforce

- Cross-organization branch and terminal relationships are rejected.
- Another tenant cannot retrieve a branch.
- Multiple counter hierarchy can be created.
- Route segments must move forward.
- Non-bookable aisle positions cannot be sold as seats.
- Expired driver licence is not operationally eligible.
- Verified and available driver is eligible.

### Trip operations

- Schedule and route snapshots are preserved.
- Vehicle, driver and conductor assignments are auditable.
- Vehicle overlap is rejected.
- Ineligible driver assignment is rejected.
- Ready-to-arrival lifecycle is auditable.
- Ready requires vehicle and driver.
- Invalid trip transition is rejected.
- Replayed offline trip event ID is idempotent.

### Booking, payment, ticket and boarding

- Multi-passenger booking receives distinct seats.
- Booking client-request retry returns the same booking.
- Segment seat double-sale is rejected.
- Ticket issuance requires confirmed payment and booking.
- Each traveler receives an individual e-ticket.
- Payment decision atomically confirms booking and issues tickets.
- Payment recorder cannot confirm the same payment.
- Duplicate boarding/validation is rejected.

### Cargo Lite

- Manual and per-kilogram pricing.
- Itemized and mixed pricing.
- Decimal excess kilogram calculation.
- Multiple item and charge lines.
- Internal allocation/border fee does not reduce customer charge.
- Cargo QR excludes sender phone data.
- Confirmed cargo payment cannot exceed server total.
- Receiver handover requires masked verification.
- End-to-end custody, payment, printing, trip closing and settlement.

### Notification and offline synchronization

- Duplicate business event creates one notification per channel.
- Action event creates one pending-work item.
- User can read only their own notification.
- Authorization snapshot contains current effective access and expires.
- Duplicate sync operation returns the original result.
- Device and organization-scoped delta pull.

## Security abuse tests

The automated abuse suite currently checks:

- Password disclosure and plain-text password storage.
- SQL-injection login bypass attempts.
- SQL-injection search attempts escaping a tenant filter.
- Registration mass-assignment of staff/superuser fields.
- Notification insecure direct object reference (IDOR).
- Device installation takeover.
- Unauthorized sync submission.
- Cross-tenant organization and branch retrieval.
- Cross-tenant relational assignment.
- Role privilege escalation.
- Payment self-approval.
- Duplicate financial and operational requests.
- Malformed or unsupported state transitions.
- Sensitive data omission from QR payload.
- Audit record mutation and bulk deletion prevention.

## Static security review

The backend source was searched for common high-risk constructs:

- dynamic `eval` or `exec`;
- shell execution;
- unsafe subprocess use;
- unsafe deserialization;
- raw SQL and `RawSQL`;
- `mark_safe`;
- embedded API keys and passwords.

No high-risk application use was found. The only direct SQL is the constant
`SELECT 1` readiness probe. Public `AllowAny` endpoints are limited to
registration/authentication and health probes.

## Django deploy-check findings

The local `.env` currently runs with debug/development settings, producing:

1. HSTS disabled;
2. SSL redirect disabled;
3. secure session cookie disabled in debug;
4. secure CSRF cookie disabled in debug;
5. debug enabled.

These are production release blockers but not code-test failures. The production
environment must set:

- `DJANGO_DEBUG=false`
- `DJANGO_SECURE_SSL_REDIRECT=true`
- a reviewed non-zero `DJANGO_SECURE_HSTS_SECONDS`
- a production `DJANGO_SECRET_KEY`
- production hosts and reverse-proxy TLS configuration

The application now refuses non-debug startup with the known development
secret fallback.

## SRE and reliability coverage

Implemented and tested:

- liveness independent of database access;
- readiness verifies PostgreSQL;
- readiness fails with HTTP 503 when PostgreSQL is unavailable;
- safe client retry through idempotency identities;
- duplicate notification suppression;
- immutable audit history;
- sync batch size limit;
- recoverable device revocation;
- cursor-based incremental synchronization.

Not yet evidenced:

- sustained load and capacity targets;
- p95/p99 latency;
- process crash recovery;
- PostgreSQL failover;
- worker queue backlog recovery;
- backup restore and measured RPO/RTO;
- network partition and reconnect tests on Flutter;
- push-provider outage behavior;
- multi-hour soak testing;
- production metrics and alert routing.

These require a deployed test environment and agreed measurable NFR targets.

## Security testing not yet performed

The following must be completed before a production security sign-off:

- dependency CVE scan using a maintained vulnerability database;
- SAST tool scan;
- authenticated DAST against a deployed staging URL;
- API fuzzing;
- file-upload malware scanning;
- TLS and security-header scan at the edge;
- PostgreSQL privilege review;
- secrets-store and CI/CD review;
- mobile binary and local-storage assessment;
- independent penetration test.

No automated or manual test can prove that a system is “unhackable.” Release
approval must be based on threat coverage, residual risk and repeatable evidence.

## API completion blockers requiring stakeholder decisions

The following cannot be finalized without inventing business policy that
`docs/product/01-mvp-scope.md` explicitly leaves open:

1. Corporate booking approval levels, approvers and rejection behavior.
2. Company invoice numbering, tax fields and payment terms.
3. Refund amount rules, approval thresholds and cancellation fees.
4. Ticket revocation, reissue, screenshot and checkpoint-inspection rules.
5. Booking expiry duration and warning thresholds.
6. Trip delay notification and escalation thresholds.
7. Exact crew offline data visibility and mutation limits.
8. Subscription plans, grace period, entitlement suspension and renewal rules.
9. Report export formats, retention and recipients.
10. Device enrollment, shift handover and emergency access policy.

Until those decisions are approved, the API Completion Matrix correctly marks
the affected modules Partial or Missing.

## Release conclusion

The current backend is internally consistent and all 71 automated tests pass.
It is suitable for continued MVP development and Flutter contract integration
for completed operations. It is not yet approved for production and must not be
reported as “all MVP APIs complete” until the open business decisions, push
provider, domain-specific offline handlers, OpenAPI contract, production
security checks, load tests and staging penetration tests are closed.
