# Production Endpoint Scope Matrix

This document records the authorization boundary expected for production APIs. It is intentionally based on existing permission and resource-scope models; it does not introduce a new scope type.

## Scope rules

- **Company**: actor may access resources belonging to the actor organization when the active role grants the requested permission.
- **Branch**: actor may access resources attached to an explicitly assigned branch.
- **Counter / terminal**: actor may access resources attached to an explicitly assigned counter/terminal where the existing resource model provides that relation.
- **Assigned trip**: actor may access only trips for which the actor is the assigned driver/conductor when the active role grants the permission.
- **Self**: passenger-facing endpoints must constrain records to the authenticated user/member relationship.
- **Cross-role reuse is denied**: a scope assignment for one permission cannot be reused to satisfy another permission unless the same active role assignment explicitly grants that permission.
- **Organization is always the outer boundary**: supported scoped querysets must never return another organization's rows, including for company scope.

## Endpoint families

| Area | Read boundary | Mutate boundary | Production regression focus |
|---|---|---|---|
| Scheduling / trips | `trip.view` + trip scope | `trip.manage` + trip scope | branch, assigned-trip, cross-org |
| Bookings / seat locks | `booking.view` + trip scope | `booking.manage` + trip scope | cross-org, cross-role, seat-lock object access |
| Ticketing | ticket permission + trip scope | ticket permission + trip scope | passenger/counter/assigned-trip isolation |
| Boarding | boarding permission + trip scope | boarding permission + trip scope | assigned trip and cross-org |
| Cargo | cargo permission + trip/branch scope | cargo permission + trip/branch scope | shipment object access and reports |
| Payments | payment permission + source trip scope | payment permission + source trip scope | payment leakage and privileged mutation |
| Cash settlement | settlement permission + trip scope | settlement permission + trip scope | settlement object access and locking |
| Reports / exports | same source-data scope | export permission + same source-data scope | tenant/scope leakage and bounded output |
| Corporate customer/invoice | existing company-level permission + actor organization | corresponding manage/issue/void permission + actor organization | cross-org object access and self-approval rules |
| Passenger self-service | authenticated user/member relation | authenticated user/member relation | IDOR/BOLA and cross-account access |
| Offline sync | valid authorization snapshot + actor organization | same | expired/revoked snapshot, replay, idempotency |

## Fail-closed expectations

A resource not supported by the centralized `scoped_queryset()` mapping must not silently become organization-wide. New resource types require an explicit authorization decision and regression coverage before they are treated as operationally scoped.

## Release gate

The matrix is complete only when endpoint tests demonstrate both an allowed path and a denied path for every applicable scope class, plus cross-organization isolation. CI must pass before the production branch is considered releasable.
