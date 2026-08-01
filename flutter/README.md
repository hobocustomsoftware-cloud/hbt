# HBT Flutter Applications

This directory contains the Flutter clients for HoBo Transport Platform (HBT).

## Applications

| Directory | Client | MVP priority |
|---|---|---|
| `hbt_business_app/` | Bus operator owners, managers, counter staff, dispatchers, finance staff, drivers and conductors | First |
| `hbt_passenger_app/` | Passenger ticket discovery, booking, payment submission and e-ticket use | Second |

## Architecture decisions

- HBT Business is Myanmar-first, role- and scope-aware, and opens to the
  authenticated user's permitted work context.
- It uses the Django REST API under `/api/v1`; the base URL is supplied at
  build/run time through `HBT_API_BASE_URL`.
- Access and refresh tokens are kept in secure platform storage. Passwords,
  wallet PINs, OTPs and payment-provider secrets must never be stored locally.
- Offline transaction support is not complete merely because a screen is
  visible. Before the affected workflows are released, the app must have an
  encrypted local database, durable outbox, idempotency UUIDs, authorization
  snapshot handling, manual retry and conflict UI in accordance with
  `../docs/implementation/07-notification-offline-sync.md`.

## Source documents used

- `../docs/product/01-mvp-scope.md`
- `../architecture/07-api-architecture.md`
- `../architecture/08-offline-architecture.md`
- `../architecture/10-technology-stack.md`
- `../docs/implementation/07-notification-offline-sync.md`
- `../docs/security/21-access-control-matrix.md`

Several older architecture/security files currently define the documentation
standard as generation prompts rather than resolved rules. For concrete mobile
decisions, the confirmed decisions in the MVP scope and notification/offline
sync document take precedence.
