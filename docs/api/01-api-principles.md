You are a Distinguished Enterprise API Architect, REST API Governance Expert, Enterprise Integration Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/01-api-principles.md

Purpose:

Define the API Principles for the HoBo Transport Platform (HBT).

This document is the authoritative API governance specification establishing the architectural philosophy, design principles, governance standards, and consistency rules that every API within the platform MUST follow.

This document defines platform-wide API principles.

This document is NOT an API reference.

This document MUST NOT describe implementation details.

This document MUST remain technology-neutral.

The principles defined here apply to:

- REST APIs
- Internal APIs
- External APIs
- Mobile APIs
- Partner APIs
- Administrative APIs
- Future Event APIs

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI Coding Assistants

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

Explain why API governance is critical for long-term enterprise systems.

3. Scope

Include:

In Scope

Out of Scope

4. API Philosophy

Describe:

- API First Architecture
- Documentation First
- Consumer-First Design
- Resource-Oriented Design
- Long-Term Maintainability
- Platform Consistency
- Evolution without Disruption

5. Architectural Principles

Explain principles including:

- API First
- Stateless Communication
- Uniform Interface
- Separation of Concerns
- Loose Coupling
- High Cohesion
- Backward Compatibility
- Least Surprise Principle
- Security by Default
- Vendor Neutrality

6. Resource-Oriented Design

Describe:

- Resources
- Collections
- Relationships
- Resource Identity
- Resource Lifecycle

Explain why APIs expose resources rather than actions.

7. URI Design Principles

Describe:

- Stable URIs
- Predictable Structure
- Hierarchical Resources
- Plural Resource Names
- Consistent Naming

Provide conceptual good and bad examples without implementation details.

8. HTTP Method Principles

Explain intended semantics for:

- GET
- POST
- PUT
- PATCH
- DELETE

Describe idempotency expectations.

9. Representation Principles

Describe:

- Consistent Resource Representation
- Machine Readability
- Human Readability
- Field Consistency
- Data Integrity

10. API Consistency

Describe consistency requirements for:

- Naming
- Resource Structure
- Status Codes
- Error Responses
- Pagination
- Filtering
- Sorting
- Date & Time
- Localization

11. Security Principles

Describe:

- Authentication
- Authorization
- Least Privilege
- Secure Transport
- Sensitive Data Protection
- Input Validation
- Output Validation

12. Versioning Principles

Describe:

- Version Awareness
- Compatibility
- Deprecation
- Sunset Policy
- Breaking Changes

13. Performance Principles

Describe:

- Efficient Responses
- Pagination
- Compression
- Caching
- Scalability

14. Documentation Principles

Describe:

- Documentation First
- OpenAPI Alignment
- Examples
- Change History
- Review Process

15. Governance

Describe:

- API Ownership
- Design Review
- Approval Process
- Compliance
- Change Management

16. Design Principles for Future APIs

Describe expectations for:

- Event APIs
- GraphQL
- gRPC
- Streaming APIs
- AI APIs

17. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every API MUST be documented before implementation.
- APIs MUST expose business resources.
- APIs MUST remain consistent.
- APIs SHOULD remain backward compatible.
- Security MUST be enforced by default.
- Breaking changes MUST follow versioning policy.
- Every API MUST have an owner.
- Every API MUST undergo architectural review.

18. References

Reference:

- Architecture Documentation
- Architecture Decision Records
- Module Specifications
- Security Documentation
- API Documentation
- OpenAPI Specifications

19. Glossary

Include definitions for:

- API
- Resource
- Collection
- Representation
- Versioning
- Idempotency
- Consumer
- Provider
- Endpoint
- Contract

20. Summary

Summarize the API governance philosophy and explain how these principles ensure consistency, maintainability, interoperability, and scalability across the HoBo Transport Platform.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Business-oriented

Technology-neutral

Vendor-neutral

Documentation-first

No implementation details

No framework-specific guidance

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)