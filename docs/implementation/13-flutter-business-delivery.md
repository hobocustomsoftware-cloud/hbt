# Flutter Business Delivery Record

**Status:** In progress - not approved for pilot or production
**Last updated:** 2026-07-28
**Authority:** `docs/product/01-mvp-scope.md`,
`docs/implementation/06-mvp-api-completion-matrix.md`, and
`docs/implementation/07-notification-offline-sync.md`

## Delivered increments

### 1. Application structure

- `main.dart` is limited to application startup.
- App shell, API configuration/client, authentication/session, organization
  context, business shell and ticket worklist are separated by responsibility.
- The Business app keeps access/refresh tokens and the selected organization ID
  in platform secure storage.

### 2. Organization context and permissions

- `GET /me/organizations/{organization_id}/context/` returns the selected
  organization and server-calculated effective permission codes for the
  authenticated membership.
- The Business app reloads this context after sign-in and when the user selects
  another organization.
- UI visibility uses this context only as a convenience. The API independently
  authorizes every request.

### 3. Ticket worklist foundation

- The ticket tab lists organization bookings only with `booking.view` and
  issued tickets only with `ticket.view`.
- It calls only `GET /organizations/{org}/bookings/` and
  `GET /organizations/{org}/tickets/`; it has no write action.
- Counter sale, fare quote, payment decision and ticket issue mutations are
  deliberately not represented as implemented.
- The worklist is online only. It does not cache records or queue actions.

### 4. Counter booking and fare quote (implemented; end-to-end evidence pending)

This increment ends after a server fare quote is locked; manual payment
confirmation and ticket issuance are separate follow-up increments.

- Required permissions are `passenger.view`, `passenger.manage`, `trip.view`,
  `booking.manage` and `fare.quote`.
- The client must create or select an organization-managed passenger, select a
  current trip and valid route stops/seats, create the booking, then request
  and lock the server-generated fare quote.
- The client must use the generated API contracts for `POST
  /organizations/{org}/passengers/`, `GET /organizations/{org}/trips/`, `POST
  /organizations/{org}/bookings/`, `POST
  /organizations/{org}/bookings/{booking}/fare-quotes/create/` and `POST
  /organizations/{org}/fare-quotes/{quote}/lock/`.
- **Seat availability contract:** `GET
  /organizations/{org}/trips/{trip}/seats/?pickup_stop={id}&dropoff_stop={id}`
  now returns counter-authorized, segment-aware availability. The Flutter seat
  picker remains to be implemented; it must use this response rather than a
  booking list or client-side conflict calculation.
- Client-calculated fares, direct status changes, payment confirmation, ticket
  issue and offline queueing are out of scope for this increment.
- Acceptance evidence requires permission-denied UI coverage, a successful
  booking-to-locked-quote journey against PostgreSQL, API-contract tests and
  Flutter analyzer/widget-test results.
- The Flutter Business screen now creates/selects passengers, reads planned or
  ready trips, resolves route stops and segment-aware seats, creates a counter
  booking, then creates and locks a server fare quote. Direct Dart analysis
  and Django system checks passed on 2026-07-27. Widget/device and PostgreSQL
  end-to-end evidence remains pending because the Flutter wrapper is not yet
  responsive in this environment.

### 5. Manual payment decision and ticket issue (implemented; evidence pending)

This increment uploads wallet-QR or bank-transfer payment evidence, permits a
separate authorized decision, and renders issued-ticket results returned by
the server.

- Required permissions are `payment.record` to submit a record,
  `payment.confirm` to approve or reject it, and `ticket.issue` for every
  ticket issuance path.
- The planned contract uses `POST /organizations/{org}/payments/`, `POST
  /organizations/{org}/payments/{payment}/decision/` and, where issuance is
  not performed as part of the confirmed-payment result, `POST
  /organizations/{org}/tickets/issue/`.
- The client must show recorded/submitted/confirmed/rejected state from the
  API. It must never label a manual record as paid locally or create a ticket
  before server confirmation.
- **Server-side authorization:** the payment-decision endpoint now requires
  `ticket.issue` when its payload includes ticket allocations, in addition to
  its existing `payment.confirm` permission. The focused backend authorization
  test passed on 2026-07-27.
- Acceptance evidence requires requester/approver separation, rejection and
  duplicate-idempotency coverage, a payment-to-ticket audit trail, and tests
  proving a user with only `payment.confirm` cannot issue tickets.
- The Flutter flow starts from a locked quote, selects an active receiving
  account version, uploads JPEG/PNG/WebP/PDF payment evidence, then records
  wallet-QR or bank-transfer payment. It exposes
  confirm/reject only when the current server permissions allow it, and lists
  issued tickets when `ticket.view` is granted. Direct Dart analysis passed on
  2026-07-28; widget/device and PostgreSQL end-to-end evidence remains pending.

### 6. Cargo worklist, acceptance and custody operations (implemented; evidence pending)

- The cargo tab lists organization shipments only with `cargo.view`.
- Users with `cargo.accept` can create/select sender and receiver contacts,
  choose origin/destination terminal operations, and submit a server-priced
  manual shipment acceptance. Server-side counter/terminal scope and cargo
  policy validation remain authoritative.
- Users with `cargo.manage` assign accepted cargo to a trip using the
  dedicated `assign-trip` contract, then submit only valid custody states:
  `loaded`, `in_transit`, `arrived`, `ready_pickup` and `handed_over`.
  Handover supplies recipient name plus masked phone/ID confirmation.
- Payment allocation payout, cargo receipt/label printing, offline custody
  events, device-scope acceptance and a camera QR flow are not yet implemented
  in Flutter.
- Direct Dart analysis passed on 2026-07-28; widget/device and PostgreSQL
  end-to-end evidence remains pending.

## Current evidence

- Focused backend tenancy suite: 3/3 tests passed on 2026-07-27.
- Strict OpenAPI generation with `--validate --fail-on-warn` passed on
  2026-07-27 and refreshed `backend/openapi.yaml`.
- Flutter analyzer and widget tests remain pending. Local Dart/Flutter commands
  did not return output before their time limit while pre-existing Dart
  processes were active; this is not evidence of a passing client build.

## Next increments

1. Implement Cargo payment allocation, receipt/label printing and QR lookup.
2. Add camera QR flow and real-device cargo acceptance/assignment evidence.
3. Encrypted local database, durable outbox, authorization snapshot and sync
   conflict UI before any offline business mutation is released.
