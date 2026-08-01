# AI Prompt — MVP API Endpoint and Contract Catalog

Act as a REST API architect, Django REST Framework expert, domain architect, security architect, and integration test lead.

Create an implementation-ready **MVP API Endpoint and Contract Catalog** for HBT.

Use only modules and journeys approved for the MVP. Follow the existing API governance documents.

## For every endpoint define

- Stable operation ID
- HTTP method and path
- Owning module
- Purpose and actors
- Required permission and data scope
- Path, query, header, and body parameters
- Request and response schemas
- Validation and domain invariants
- Success status
- Error statuses and canonical error codes
- Idempotency and retry behavior
- Pagination, filtering, and sorting
- Concurrency and optimistic-locking behavior
- Audit and observability events
- Offline/synchronization relevance
- Rate-limit class
- Example requests and responses using fictional data
- Acceptance and contract tests

Also define shared primitives, versioning, correlation IDs, timestamps, money, identifiers, localization, bulk operations, file handling, and deprecation.

Produce a coverage matrix mapping MVP use cases to operations. Flag missing domain decisions rather than inventing them. The catalog must be suitable for later conversion to OpenAPI.
