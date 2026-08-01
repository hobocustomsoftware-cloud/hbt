# MVP API Completion Matrix

## Status

- Last reviewed: 2026-07-26
- Backend: Django REST Framework and PostgreSQL
- API base path: `/api/v1/`
- Scope source: `docs/product/01-mvp-scope.md`

This matrix records implemented behavior, not only planned Markdown prompts.

## Status definitions

| Status | Meaning |
|---|---|
| Complete | Implemented and covered by automated tests appropriate to the current phase |
| Partial | A usable foundation exists, but one or more approved MVP journeys remain |
| Missing | No usable API contract exists |
| Deferred | Explicitly outside the current MVP |

## Module matrix

| Module | Current status | Implemented coverage | Required closure |
|---|---|---|---|
| Identity | Complete | Registration, JWT login/refresh/logout, profile, password hashing | Rate limiting and stronger production authentication policy |
| Tenant and organization | Complete | Business provisioning, organization membership, invitations, active context | Complete unresolved onboarding policy decisions |
| Roles and permissions | Complete | System roles, custom roles, assignment, delegation guard, scopes, audit | Approval limits remain a separate backlog item |
| Locations and counters | Complete | Branch, physical terminal, company terminal operation, multiple counters | Device/shift policy remains open |
| Network | Complete | Routes and ordered route stops | Advanced route-change governance |
| Fleet and workforce | Complete | Vehicles, seat layouts, staff, driver and conductor profiles | Temporary replacement workflow |
| Schedule and trip | Complete | Schedules, trips, assignments, ready through arrival, stop events | Delay escalation and passenger notification policy |
| Passenger | Complete | Self profile and organization-managed passenger records; versioned NRC state/township/type references; Myanmar/English validation/rendering; encrypted NRC and blind-index duplicate protection | NRC source field validation, key rotation runbook and final retention policy |
| Booking | Partial | Self-service search, segment seats, multi-passenger booking, counter booking, company approval/invoice, guarded cancellation, idempotent unpaid-expiry worker, seat release and expiry warning/notification | Policy-driven fee/refund integration and reschedule API |
| Fare and corporate sales | Partial | Effective fare rules, server quote snapshots, audited override, quote lock, company-authorized approval, invoice issue/void | Discount approval limits, invoice payment allocation and scheduled overdue handling |
| Promotion and coupon | Partial | Percentage, fixed and buy-X-get-Y rules; passenger threshold; route/schedule/channel eligibility; quote snapshot; per-account/total limits; redemption on quote lock | Approval thresholds, public discovery, expiry/usage reporting and concurrency load test |
| Ticketing | Partial | Passenger-specific ticket issuance, QR/reference, lookup, printing foundation, audited unboarded-ticket revocation/reissue with replacement linkage | Share-image contract and checkpoint inspection separation |
| Boarding | Complete | Ticket validation and boarding recording | Broader inspector journey tests |
| Payment | Partial | Receiving accounts/versions, deterministic counter-to-company scope resolver, evidence, manual decision, ticket issuance integration, operator refund policy and guarded refund lifecycle, partial/full corporate-invoice allocation, encrypted provider connector, sandbox test, idempotent intent, signed/replay-bounded webhook quarantine, credential rotation/disable and bounded adapter-neutral reconciliation with invariant checks/backoff/audit | Official provider adapters/credentials and cancellation/reschedule settlement integration |
| Cargo Lite | Partial | Contacts, items, manual/per-kg/tiered pricing, fees, pricing-rule update/deactivate, custody, manifest, handover, notifications, reporting | Closing/export/print contracts |
| Printing and operations | Partial | Generic print payload, organization printer profiles, versioned 58/80mm template definitions, exact-idempotent online/offline print attempts, failed-print evidence, reprint audit, trip close and settlement | Bluetooth transport remains client-side; ESC/POS rendering/device certification and production printer matrix remain |
| Notification | Partial | In-app inbox, unread count, read state, push queue records, pending work, logs, retry, encrypted device tokens, bounded dispatch worker, per-device attempts, backoff and invalid-token revocation | Live FCM/APNs adapters, signed delivery receipts and staging evidence |
| Offline synchronization | Partial | Device enrollment/revocation, time-bounded authorization snapshot, capabilities, idempotent upload receipt, delta cursor/pull, guarded trip transition, ticket validation, cargo accept/custody, cash record and walk-up booking handlers | Cargo acceptance fixture coverage, conflict UI localization and sustained concurrency/load evidence |
| SaaS subscription | Partial | Public catalogue, 5% tax, invoice issue, manual payment submit/verification, activation/period extension, scheduled/immediate plan change, grace/suspension scheduler, new booking/cargo/schedule entitlement boundaries, server-enforced counter/staff account plan limits and media active/video limits | Cancellation/reactivation API polish, scheduler deployment evidence and full staging verification against commercial policy |
| Operator branding | Partial | Tenant-owned logo/cover and bilingual public operator profile, public list/detail, audited configuration and fail-closed configurable malware scanner hook | Image dimension verification, scanner-enabled staging evidence, platform verification workflow and object-storage delivery |
| Media and advertising | Partial | Operator and external-advertiser campaign ownership, image/video creative validation, Starter denial, plan limits, submission, advertiser/platform review, manual ad-payment confirmation, public approved feed and fail-closed configurable malware scanner hook | Video provider/transcoding, scanner-enabled staging evidence, delivery worker, impression/click anti-abuse, reporting and campaign billing packages |
| Reporting | Partial | Owner JSON dashboard plus tenant-authorized, audited UTF-8 CSV exports for owner summary, trip, confirmed payment and cargo data; date-range limits and spreadsheet-formula neutralization; organization monitoring dashboard and threshold-based alert snapshot endpoints for queue/backlog/backup/certificate visibility | Scheduled delivery, agreed accounting layouts, optional PDF rendering and deployed monitoring backend evidence |
| Feedback | Complete | Passenger/staff submission, private security category, owner filtering, triage and response | Optional attachments and platform-wide product analytics |
| Privacy rights | Partial | Self access/correction/export/deletion/restriction requests, one-active-request concurrency guard, 30-day due date, requester cancellation, platform Security/Super Admin review lifecycle, requester/reviewer separation, deletion evidence and retention-hold recording, immutable audit and bounded self-data JSON export | Approved retention schedule, automated eligible-field anonymization, legal identity/contact and counsel-reviewed response templates |
| OpenAPI | Complete | Pinned generator, self-hosted Swagger/ReDoc, explicit APIView contracts, stable domain enum names and generated `backend/openapi.yaml` | Strict `--validate --fail-on-warn` generation passes with 0 errors and 0 warnings; regenerate at every release |

## Production engineering evidence

- Non-root production API image and Gunicorn runtime are defined in
  `backend/Dockerfile`.
- PostgreSQL, API, push worker, scheduler and TLS reverse proxy topology is
  defined in `devops/compose.production.yml`.
- CI and local release gates enforce migrations, strict OpenAPI, PostgreSQL
  tests, dependency consistency, dependency CVEs, Bandit and Semgrep.
- Backup/restore scripts and the SRE/incident runbook are present. A restore
  drill in the target infrastructure is still required before release.
- Authorized SQLi/XSS/IDOR/JWT/webhook/upload/DOCX/race-condition test scope is
  documented in `security/authorized-testing-runbook.md`. Active DAST and an
  independent penetration test still require an authorized staging target.

## Notification endpoint coverage

| Operation | Endpoint | Status |
|---|---|---|
| List personal inbox | `GET /me/notifications/` | Complete |
| Unread count | `GET /me/notifications/unread-count/` | Complete |
| Mark notification read | `POST /me/notifications/{id}/read/` | Complete |
| List personal pending work | `GET /me/pending-work/` | Complete |
| Complete personal pending work | `POST /me/pending-work/{id}/complete/` | Complete |
| Organization delivery log | `GET /organizations/{org}/notification-logs/` | Complete |
| Retry failed notification | `POST /organizations/{org}/notification-logs/{id}/retry/` | Complete |
| Payment submitted/verification/decision events | Internal business-event integration | Complete |
| Push delivery provider | Background delivery integration | Missing |

## Monitoring endpoint coverage

| Operation | Endpoint | Status |
|---|---|---|
| Public health | `GET /health/` | Complete |
| Public liveness | `GET /health/live/` | Complete |
| Public readiness | `GET /health/ready/` | Complete |
| Organization monitoring snapshot | `GET /organizations/{org}/monitoring/dashboard/` | Complete |
| Organization threshold-based alerts | `GET /organizations/{org}/monitoring/alerts/` | Complete |

Current monitoring API coverage includes active-device activity, push queue age,
offline sync backlog age, webhook backlog age, reconciliation backlog,
pending work, selected booking/cargo/refund/subscription counters, disk free
space, and optional backup/certificate evidence when infrastructure paths are
configured via environment variables. It does not replace external dashboards,
alerts, load evidence or restore drills.

## Business-client organization context

`GET /me/organizations/{organization_id}/context/` returns an authenticated
member's selected organization and the server-calculated effective permission
codes for that membership. It is intended for client routing and visibility;
every protected API operation remains independently authorized by the server.
The generic organization permission catalog endpoint is not an effective
permission snapshot and must not be used by staff clients for access decisions.

## Business-client ticket worklist

The Flutter Business ticket tab is an online, permission-gated read worklist.
It reads `GET /organizations/{org}/bookings/` only with `booking.view` and
`GET /organizations/{org}/tickets/` only with `ticket.view`. It has no create,
confirm, payment, print, boarding or ticket-issue action. Counter-sale
mutation remains incomplete until passenger, trip/seat, fare-quote, payment
decision and ticket-issue journeys are delivered and validated together.

## Counter booking and payment-to-ticket client boundaries

The counter-booking and fare-quote client increment is planned, not
implemented. It requires `passenger.view`, `passenger.manage`, `trip.view`,
`booking.manage` and `fare.quote`, and ends after a locked server quote.
The Business API now provides `GET /organizations/{org}/trips/{trip}/seats/`
with pickup/dropoff parameters for counter-authorized, segment-aware seat
availability. The Flutter counter-booking and seat-picker UI remains required
before this client increment can be released.

Task 5 manual payment and ticket issue is also planned, not implemented. It
requires `payment.record`, `payment.confirm` and `ticket.issue` according to
the operation performed. The payment-decision API now additionally enforces
`ticket.issue` when optional ticket allocations are present. The remaining
work is the client workflow and its end-to-end validation.

## Offline endpoint coverage

| Operation | Endpoint | Status |
|---|---|---|
| Enroll/list a user's devices | `GET/POST /me/devices/` | Complete |
| Revoke a user's device | `POST /me/devices/{id}/revoke/` | Complete |
| Read sync capabilities | `GET /sync/capabilities/` | Complete |
| Issue authorization snapshot | `POST /organizations/{org}/devices/{device}/authorization-snapshot/` | Complete |
| Upload idempotent operation batch | `POST /organizations/{org}/devices/{device}/sync/push/` | Partial |
| Download organization delta | `GET /organizations/{org}/devices/{device}/sync/pull/` | Partial |

Approved upload operations currently are:

- `notification.read`
- `pending_work.complete`
- `trip.transition`
- `ticket.validate`
- `cargo.accept`
- `cargo.transition`
- `payment.record_cash`
- `booking.walk_up`

These business operations use current online authorization again at upload
time, exact operation idempotency and domain-specific state/seat/version rules.

## Next closure order

1. Complete subscription lifecycle commands and enforce entitlements at all
   commercial creation boundaries.
2. Complete media upload security, provider adapter and delivery accounting.
3. Add push-provider dispatch and delivery-receipt processing.
4. Add event producers for booking expiry, ticket issue, trip changes and cargo
   exceptions/arrival/handover.
5. Add offline handlers one domain at a time: trip event, ticket validation,
   cargo custody, payment record, then walk-up booking.
6. Add version checks and documented conflict outcomes for every mutable
   offline resource.
7. Complete payment resolver, company booking/invoice and refund/reissue APIs.
8. Generate OpenAPI only after the contracts above stabilize.
