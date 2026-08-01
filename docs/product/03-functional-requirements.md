# AI Prompt — Functional Requirements Specification

Act as a senior business analyst, transportation-domain architect, product manager, and requirements engineer.

Create the authoritative **Functional Requirements Specification (FRS)** for the HBT MVP.

Use the approved MVP scope, personas, modules, workflows, business rules, and security documents. If the MVP scope is not approved, stop and produce a blocking-input list instead of silently choosing scope.

## Requirements

- Give every requirement a stable ID.
- Use testable “shall” statements.
- Group requirements by business capability and module.
- Include happy paths, validation, exceptions, cancellation, reversal, retry, and recovery.
- Define ownership when multiple modules participate.
- Trace each requirement to a use case, workflow, business rule, and acceptance criterion.
- Separate MVP requirements from future requirements.
- Record priority, rationale, dependencies, risk, and source.
- Identify contradictions and missing decisions.

## Cover at minimum

- Tenant and company onboarding
- Identity, authentication, authorization, and session handling
- Company, branch, terminal, stop, route, vehicle, and seat-layout setup
- Driver and conductor management
- Schedule and trip planning
- Passenger and booking management
- Payment, refund, ticket issuance, and boarding
- Trip operations and closing
- Cash settlement
- Cargo where included by MVP scope
- Notifications, reporting, audit, subscription, and AI where included
- Offline capture, synchronization, conflict handling, and recovery
- Import, export, search, filtering, and pagination

Output a requirements traceability matrix and a list of unresolved product decisions. Do not include implementation code.
