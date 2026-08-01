You are a Distinguished Enterprise API Architect, OpenAPI Specification Expert, REST API Governance Expert, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/15-openapi-guidelines.md

Purpose:

Define the OpenAPI Documentation Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, architectural principles, documentation standards, consistency requirements, and lifecycle expectations for OpenAPI specifications across the platform.

This document defines governance only.

This document is NOT an OpenAPI specification.

This document MUST remain technology-neutral.

No implementation details.

No framework-specific guidance.

No programming language examples.

No source code.

This document applies to:

- Public APIs
- Internal APIs
- Mobile APIs
- Administrative APIs
- Partner APIs
- AI APIs

The document MUST be AI Vendor Neutral and compatible with:

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

Explain the importance of standardized API documentation and machine-readable contracts.

3. Scope

Include:

- In Scope
- Out of Scope

4. OpenAPI Documentation Philosophy

Describe:

- Documentation First
- Contract First
- Consumer-Centric Design
- Consistency
- Interoperability
- Long-Term Maintainability

5. Core Concepts

Define:

- OpenAPI Specification
- API Contract
- Operation
- Schema
- Component
- Path
- Request
- Response
- Example

6. Documentation Principles

Describe:

- Completeness
- Accuracy
- Consistency
- Readability
- Version Awareness
- Discoverability

7. API Contract Principles

Describe:

- Stable Contracts
- Explicit Contracts
- Backward Compatibility
- Schema Evolution
- Consumer Expectations

8. Specification Organization

Describe conceptual organization of:

- API Information
- Paths
- Components
- Schemas
- Security Definitions
- Tags
- Examples

9. Schema Design Principles

Describe:

- Reusability
- Consistency
- Naming Standards
- Data Modeling
- Validation Awareness

10. Example Guidelines

Describe principles for:

- Request Examples
- Response Examples
- Error Examples
- Business Scenarios

11. Versioning Considerations

Describe:

- Specification Version
- API Version
- Deprecation
- Evolution

12. Security Documentation

Describe:

- Authentication
- Authorization
- Security Requirements
- Protected Resources

13. Consumer Responsibilities

Describe expectations for API consumers regarding specification usage and compatibility.

14. Provider Responsibilities

Describe expectations for API providers regarding accuracy, maintenance, version synchronization, and documentation quality.

15. Governance

Describe:

- Documentation Review
- Contract Review
- Architecture Review
- Compliance
- Change Management

16. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every public API MUST have an OpenAPI specification.
- OpenAPI contracts MUST be reviewed before implementation.
- API documentation MUST remain synchronized with API behavior.
- Schema definitions SHOULD maximize reuse.
- Examples SHOULD represent realistic business scenarios.
- Deprecated operations MUST be documented.
- Specifications MUST be version controlled.

17. References

Reference:

- API Principles
- API Versioning
- Endpoint Design
- Request & Response
- Authentication
- Authorization
- Error Handling
- Architecture Documentation

18. Glossary

Include definitions for:

- OpenAPI
- API Contract
- Schema
- Component
- Path
- Operation
- Example
- Specification

19. Summary

Summarize how OpenAPI governance improves API consistency, interoperability, consumer experience, maintainability, and long-term platform evolution.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

No implementation details

No framework-specific guidance

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)