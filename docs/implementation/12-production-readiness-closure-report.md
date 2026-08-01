# Production Readiness Closure Report

**Status:** In progress — not approved for production release  
**Started:** 2026-07-26  
**Authority:** `docs/product/01-mvp-scope.md`,
`docs/product/07-approved-mvp-policy-decisions.md`,
`docs/implementation/06-mvp-api-completion-matrix.md`, and
`docs/testing/08-qa-uat-security-sre-plan.md`

## Verified baseline

- Existing PostgreSQL suite: 79/79 passed before schema changes.
- Django system check: no issues.
- Migration drift check: no changes before the closure work.
- Dependency consistency: no broken requirements.
- The workspace `.git` directory is present but does not contain usable Git
  repository metadata. Change-history, review, rollback and commit evidence are
  therefore a production blocker until source control is restored.

## Closure increment 1 — refund and ticket reissue

Implemented:

- operator-owned refund policy;
- refund Requested → Approved/Rejected → Paid → Completed lifecycle;
- positive-amount database constraints;
- confirmed-payment refund ceiling;
- duplicate payout-reference prevention;
- requester/approver separation;
- ticket-specific refund linkage;
- completed-refund ticket revocation;
- unboarded ticket reissue with a new QR/validation code;
- immutable replacement linkage to the original ticket;
- organization-scoped permissions and audit events.

Focused PostgreSQL result: 2/2 new refund/reissue tests passed. NRC/encryption
regression plus refund/reissue: 6/6 passed.

## Security evidence

- Bandit application scan: zero findings after remediation.
- pip-audit initially found vulnerable pins in `python-dotenv==1.2.1` and
  `cryptography==46.0.5`.
- Pins upgraded to `python-dotenv==1.2.2` and `cryptography==48.0.1`.
- Re-audit result: no known vulnerabilities.
- Production deployment settings now support explicit HSTS preload and trusted
  proxy SSL-header configuration. These must only be enabled for the verified
  production ingress topology.

Generated local evidence files:

- `backend/bandit-report.json`
- `backend/pip-audit-report.json`

## Not yet production complete

The project must not be represented as production-ready until the remaining
items in the completion matrix are implemented and validated. In particular:
invoice payment allocation, payment connectors/webhooks/reconciliation,
domain-specific offline mutations, push-provider delivery, subscription
lifecycle enforcement, secure media pipeline, print/report exports, OpenAPI,
load/fuzz/DAST evidence, backup/restore evidence, observability and an
independent authorized penetration test remain open.

## Closure increment 2 — payment, offline, push and subscription

Implemented and focused-tested:

- partial corporate invoice payment allocation and paid-state reconciliation;
- encrypted provider connector configuration;
- sandbox/production separation and connector self-test;
- idempotent provider payment intent;
- HMAC-signed webhook with five-minute replay window;
- amount/currency/merchant/reference mismatch quarantine;
- credential rotation and connector disable audit;
- offline trip, ticket-validation, cargo-accept/custody, cash-record and
  walk-up-booking handlers;
- offline seat conflict and changed-payload idempotency conflict outcomes;
- encrypted device push tokens and plaintext backfill migration;
- bounded push dispatcher, per-device attempt records, retry backoff and
  permanent-token invalidation;
- subscription invoice, tax, manual payment decision, activation, renewal
  period, plan change, grace and suspension lifecycle;
- entitlement checks at new booking, cargo and schedule boundaries.

Official payment and push providers still require provider-issued staging
credentials and their specific adapters. The core contracts do not treat a
provider acceptance as a confirmed business payment.

## OpenAPI strict-generation finding

`drf-spectacular==0.30.0` and self-hosted Swagger/ReDoc assets are pinned.
The first strict generation correctly exposed 73 unique untyped `APIView`
operations. Explicit request/response contracts, method-field types and stable
domain enum names have now been added. The current
`spectacular --validate --fail-on-warn` release gate passes with **0 errors and
0 warnings**, and `backend/openapi.yaml` is the generated client contract.

## Closure increment 3 — production engineering and upload security

Implemented:

- non-root Python 3.13/Gunicorn production container;
- PostgreSQL readiness dependency and API liveness probe;
- separate push and subscription scheduler processes;
- TLS reverse proxy with request throttling and security headers;
- read-only containers, temporary filesystems and no-new-privileges controls;
- CI/local release gates for migration drift, strict OpenAPI, full tests,
  dependency consistency, dependency CVEs, Bandit and Semgrep;
- configurable fail-closed malware scanning before branding, advertising and
  private payment files are stored;
- idempotent booking-expiry scheduler with warning notifications, unpaid seat
  release, corporate-approval cancellation, audit and confirmed-payment guard;
- tenant-scoped printer profiles, versioned 58/80mm template definitions and
  exact-payload idempotent offline print-attempt audit;
- owner/trip/payment/cargo UTF-8 CSV exports with permission enforcement,
  bounded date ranges, audit events and spreadsheet-formula neutralization;
- PostgreSQL backup integrity check and confirmation-guarded restore scripts;
- bilingual SRE incident/recovery runbook and authorized security test scope.
- bilingual privacy and platform-terms drafts with explicit legal/commercial
  approval placeholders.
- bounded, confirmation-guarded Schemathesis staging-fuzz runner that requires
  a written authorization reference and emits JUnit/HAR evidence.
- confirmation-guarded OWASP ZAP runner with passive baseline and separately
  authorized API/full active modes; it refuses declared production hosts and
  records authorization metadata plus HTML/Markdown/XML/JSON evidence.
- confirmation-guarded testssl.sh 3.2.3 and OWASP-aligned security-header gate
  with JSON/HTML evidence. These two runners are prepared but have not passed a
  real staging environment yet.
- safe EICAR upload runner that requires scanner-specific rejection and retains
  authorization/response evidence. It is prepared but has no staging pass
  evidence yet.
- organization-scoped monitoring snapshot and alert endpoints for queue/backlog,
  reconciliation, backup-age and certificate-age visibility aligned to the QA/SRE
  monitoring baseline. These endpoints expose current state but do not by
  themselves satisfy deployed dashboard, alert-routing or restore-drill
  evidence.
- server-enforced Starter/Growth/Pro/Enterprise usage limits now gate sales
  counter creation and workforce staff-account creation in addition to the
  previously enforced media campaign/video limits. Commercial usage-limit
  enforcement is therefore narrower than before, though full staging
  verification and policy sign-off still remain.
- audited privacy-rights request lifecycle with 30-day due dates, platform
  Security/Super Admin authority, requester/reviewer separation, deletion
  evidence, retention holds and bounded self-data export.
- adapter-neutral payment reconciliation scheduler with encrypted credential
  loading, amount/currency/merchant/reference checks, bounded exponential
  backoff and staff-verification handoff rather than unsafe auto-confirmation.

The actual production secret store, certificate paths, object storage, malware
scanner daemon/signatures, monitoring backend and infrastructure restore drill
remain deployment evidence, not local-code evidence.

## Regression checkpoint

- Full PostgreSQL regression after the privacy, printing, reconciliation and
  version-contract increments: **104/104 passed in 902.631 seconds**.
- Django system check: no issues.
- Migration drift: none.
- Dependency consistency: no broken requirements.
- Dependency vulnerability audit: no known vulnerabilities.
- Bandit initially reported one low hardcoded-password false positive for an
  empty encrypted-token filter. The line is explicitly documented as a
  non-secret empty-value query; re-scan result: zero findings.
- Current source-only Bandit re-scan: **0 findings**.
- The previous dependency report covers 23 resolved packages with **0 known
  vulnerabilities**, but predates the Gunicorn runtime pin. The current
  requirements re-audit has not completed in the local Windows environment and
  must not be treated as current release evidence until it does.
- Every custom handler below the versioned API resolver is now contract-tested
  to accept the resolver `version` keyword; the repository-wide regression
  test prevents the previously latent action-endpoint 500 class from returning.

## Remaining release blockers

## Client delivery evidence

- Flutter Business has a sign-in flow, server-calculated organization context
  and a permission-gated online ticket/booking worklist as of 2026-07-27.
- The counter-sale mutation, cargo operations and offline client are not
  implemented. Flutter analyzer and widget-test evidence is also pending due
  to unresolved local Dart/Flutter command timeouts; no client release claim
  is supported by the current evidence.

HBT is not yet approved for public production. These items require real
infrastructure, third-party authority or unfinished domain contracts:

1. Provider-issued staging credentials and official KBZPay/AYA Pay/MMQR/bank
   adapters plus reconciliation evidence.
2. Live FCM/APNs adapters, audible-channel device verification and receipt
   handling.
3. Scanner-enabled upload tests (including EICAR, MIME spoof and DOCX samples),
   object storage and media/video processing.
4. Policy-driven cancellation/refund/reschedule integration, export/print
   contracts and complete commercial usage-limit enforcement.
   The payment-decision route now enforces `ticket.issue` for optional ticket
   allocations; the corresponding Flutter client workflow and end-to-end
   evidence remain open.
5. Load/concurrency/fuzz evidence, authorized staging DAST, TLS/header scan and
   independent penetration test/retest.
6. Deployed dashboards/alerts, backup retention and a measured restore drill.
7. Restored usable Git metadata, protected review workflow and signed,
   reproducible release images.
8. Legal entity/contact, retention schedule, governing law, liability and
   counsel approval for the bilingual privacy/terms drafts.
