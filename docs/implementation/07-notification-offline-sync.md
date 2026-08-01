# Notification and Offline Sync Implementation Decisions

## Authority and interpretation

The architecture, module and workflow Markdown files currently contain
document-generation prompts rather than fully resolved specifications.
Confirmed decisions in `docs/product/01-mvp-scope.md` therefore take precedence.
This file records the concrete implementation boundary used by the backend.

## Notification decisions

- A business event and a notification are separate records.
- Notification delivery never changes the underlying business decision.
- Notification creation is scheduled after the owning database transaction
  commits. Failure is logged and does not roll back payment, booking or cargo.
- Each recipient/event/channel combination is unique to prevent duplicates.
- In-app and push are separate channel records.
- Push status records mean queued, sent, delivered or failed; the backend does
  not claim that a user heard or read an alert.
- Lock-screen title and body contain minimal information. Detailed IDs are held
  in authenticated deep-link data.
- Action-required events create a persistent Pending Work item. A push sound is
  never the sole workflow trigger.
- Delivery attempts are append-only through the public API.
- Tenant notification logs require explicit permissions.

## Initial event integration

Manual payment currently emits:

1. payment submitted to the passenger;
2. payment verification required to authorized staff;
3. a persistent payment-verification work item;
4. payment confirmed or rejected to the passenger;
5. completion of staff work items when a decision is recorded.

Remaining booking, ticket, trip and cargo event producers are tracked in the API
completion matrix and are not represented as complete.

## Offline synchronization decisions

- A device installation belongs to one human user and may be revoked.
- A device does not confer authority by itself.
- Offline authority is a cached snapshot tied to device, membership and
  organization and expires after 12 hours.
- Issuing a new snapshot revokes prior active snapshots for the same device and
  organization.
- Upload operations use a client-generated UUID.
- Reusing the UUID with identical content returns the existing result.
- Reusing the UUID with different content returns a conflict and never executes
  the second request.
- A batch is limited to 100 upload operations.
- Every upload result is retained and audited.
- Unsupported offline actions are explicitly rejected; the server does not
  store them as if their business operation succeeded.
- Delta downloads use a monotonically increasing organization cursor.
- Download payloads MUST contain only the data authorized for that sync
  contract. Adding a resource to the change feed requires a data-exposure
  review.
- Manual synchronization is always exposed to the client.

## Conflict policy

Conflict handling is selected per operation:

| Operation class | Policy |
|---|---|
| Mark notification read | Idempotent set operation |
| Complete pending work | Idempotent state transition |
| Ticket/seat sale | Server business-rule resolution; never generic last-write-wins |
| Payment/refund | Exact idempotency plus server authorization; never last-write-wins |
| Cargo custody | Valid state transition plus current-version check |
| Trip events | Append-only event identity plus assignment/scope validation |

## Security boundary

- Every sync endpoint requires online JWT authentication.
- Organization membership and `offline.sync` permission are checked again by
  the server.
- Upload requires a non-expired authorization snapshot.
- Revoked devices and snapshots are denied.
- Tenant data is filtered by the organization resolved from the authenticated
  user.
- Device push tokens are write-only in API responses. Production deployment
  still requires encrypted-at-rest storage or an external secrets/token vault
  before push delivery is enabled.

## Client responsibilities

Flutter clients must keep an encrypted local database, an append-only outbox,
the last acknowledged cursor and the last valid authorization snapshot. They
must display online, offline, synchronizing and failed states and must not erase
an outbox item until the server returns a terminal result.

