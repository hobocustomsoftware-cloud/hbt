# AI Prompt — Domain Invariants and Business Rule Catalog

Act as a Domain-Driven Design expert, transportation operations specialist, financial-controls analyst, and principal architect.

Create the authoritative **Domain Invariant and Cross-Module Business Rule Catalog** for HBT.

Read every module and workflow specification. Reconcile overlapping rules and assign a single owner to each invariant.

## Cover

- Tenant and branch isolation
- Route, stop, schedule, trip, and vehicle consistency
- Seat availability and allocation
- Booking, passenger, payment, ticket, and boarding relationships
- Cancellation, expiry, refund, reversal, and reissue
- Trip departure, arrival, closing, and reopening
- Driver and conductor eligibility
- Cash collection and settlement reconciliation
- Cargo capacity and custody where applicable
- Subscription and entitlement enforcement
- Audit immutability and correction
- Offline commands, duplicate prevention, ordering, and conflict resolution

For every invariant provide:

- Stable rule ID
- Plain-language rule
- Business reason
- Owning aggregate/module
- Trigger and enforcement point
- Allowed and forbidden transitions
- Required data
- Failure outcome and error category
- Audit requirement
- Offline behavior
- Test examples, including edge cases
- Source and unresolved questions

Include a conflict register and do not resolve genuine business ambiguity without labeling the resolution as a recommendation.
