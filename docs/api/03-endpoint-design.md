You are a Distinguished Enterprise API Architect, REST API Design Expert, Domain-Driven Design (DDD) Expert, Enterprise Integration Architect, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/03-endpoint-design.md

Purpose:

Define the Endpoint Design Standards for the HoBo Transport Platform (HBT).

This document establishes the official standards for designing API endpoints across the platform.

It defines how resources are represented, named, organized, and exposed through RESTful APIs.

This document is NOT an API reference.

This document MUST remain technology-neutral.

No implementation details.

No framework-specific guidance.

No source code.

No language-specific examples.

This document applies to:

- Public APIs
- Internal APIs
- Mobile APIs
- Partner APIs
- Administrative APIs

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

Explain the importance of consistent endpoint design in enterprise systems.

3. Scope

Include:

- In Scope
- Out of Scope

4. Endpoint Design Philosophy

Describe:

- Resource-Oriented Design
- Predictability
- Consistency
- Simplicity
- Long-Term Maintainability

5. Resource Modeling

Explain:

- Resource
- Collection
- Singleton Resource
- Nested Resource
- Relationships

6. URI Design Principles

Describe:

- Stable URIs
- Human Readability
- Machine Readability
- Predictable Structure
- Hierarchical Organization

7. Resource Naming Standards

Describe standards for:

- Plural Resource Names
- Lowercase Naming
- Hyphenated Names
- Consistent Terminology
- Business-Oriented Naming

Provide conceptual examples of preferred and discouraged naming patterns without implementation-specific details.

8. Resource Hierarchy

Describe:

- Parent Resources
- Child Resources
- Nested Resources
- Maximum Recommended Nesting Depth

Explain when nested resources SHOULD and SHOULD NOT be used.

9. Collection Endpoints

Describe expectations for collection resources, including:

- Listing
- Filtering
- Searching
- Pagination
- Sorting

10. Individual Resource Endpoints

Describe expectations for:

- Retrieval
- Update
- Replacement
- Deletion

11. Action-Oriented Operations

Explain why APIs SHOULD expose resources instead of actions.

Describe acceptable approaches for operations that cannot naturally be modeled as resources.

12. URI Stability

Describe:

- Permanent Resource Identity
- URI Evolution
- Redirect Strategy
- Deprecation Considerations

13. Endpoint Consistency

Describe consistency requirements for:

- URI Structure
- Naming
- Parameter Placement
- Resource Relationships
- Response Expectations

14. Error Considerations

Describe endpoint expectations regarding:

- Invalid Resources
- Unsupported Operations
- Validation Errors
- Authorization Failures

15. Security Considerations

Describe:

- Resource Access Control
- Authorization
- Sensitive Resources
- Multi-Tenant Isolation

16. Governance

Describe:

- Endpoint Review
- Naming Review
- Architecture Approval
- Consistency Validation

17. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Endpoints MUST represent business resources.
- Resource names MUST use plural nouns.
- URIs MUST remain stable whenever possible.
- Endpoints MUST NOT expose implementation details.
- APIs MUST maintain consistent URI structures.
- Deep nesting SHOULD be avoided.
- Endpoint naming MUST follow platform terminology.

18. References

Reference:

- API Principles
- API Versioning
- Module Specifications
- Architecture Documentation
- OpenAPI Specifications

19. Glossary

Include definitions for:

- Endpoint
- Resource
- Collection
- URI
- Nested Resource
- Singleton Resource
- Resource Identifier

20. Summary

Summarize how consistent endpoint design improves discoverability, usability, maintainability, interoperability, and long-term platform evolution.

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