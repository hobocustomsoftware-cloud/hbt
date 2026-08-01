You are a Distinguished Enterprise API Architect, Enterprise Integration Architect, REST API Governance Expert, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/02-api-versioning.md

Purpose:

Define the API Versioning Policy for the HoBo Transport Platform (HBT).

This document establishes the governance, principles, lifecycle, compatibility strategy, and change management policies for all APIs across the platform.

This document is NOT an API implementation guide.

This document MUST remain technology-neutral.

No framework-specific guidance.

No source code.

No implementation examples.

The versioning policy applies to:

- REST APIs
- Internal APIs
- External APIs
- Mobile APIs
- Partner APIs
- Administrative APIs
- Future Event APIs

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

Explain why API versioning is essential for long-term enterprise systems.

3. Scope

Include:

- In Scope
- Out of Scope

4. Versioning Philosophy

Describe:

- Stability
- Predictability
- Backward Compatibility
- Controlled Evolution
- Consumer Protection

5. Versioning Strategy

Describe supported strategies conceptually:

- URI Versioning
- Header Versioning
- Media Type Versioning

Explain why HBT adopts one official strategy.

6. Version Lifecycle

Describe stages such as:

- Draft
- Development
- Preview
- Stable
- Deprecated
- Sunset
- Retired

7. Compatibility Principles

Explain:

- Backward Compatibility
- Forward Compatibility
- Non-breaking Changes
- Breaking Changes

8. Breaking Change Policy

Describe examples of conceptual breaking changes, such as:

- Removing resources
- Renaming fields
- Changing required fields
- Changing business behavior
- Removing response attributes

9. Non-Breaking Change Policy

Examples:

- Adding optional fields
- Adding endpoints
- Documentation improvements
- Performance improvements

10. Deprecation Policy

Describe:

- Deprecation Notice
- Communication
- Migration Guidance
- Support Period

11. Sunset Policy

Describe:

- Retirement Process
- Consumer Notification
- Migration Timeline
- Archive Policy

12. Consumer Responsibilities

Explain expectations for API consumers regarding upgrades, testing, and migration.

13. Provider Responsibilities

Explain expectations for API providers regarding stability, documentation, and communication.

14. Governance

Describe:

- Version Approval
- Release Management
- Architectural Review
- Compliance

15. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every public API MUST have an explicit version.
- Breaking changes MUST create a new major version.
- Deprecated APIs SHOULD remain available during the support period.
- Version changes MUST be documented before release.
- Consumers MUST receive advance notice before retirement.

16. References

Reference:

- API Principles
- Architecture Documentation
- Module Specifications
- OpenAPI Specifications
- Security Documentation

17. Glossary

Include terms such as:

- Version
- Major Version
- Minor Version
- Patch
- Compatibility
- Deprecation
- Sunset
- Consumer
- Provider

18. Summary

Summarize how versioning protects platform stability, enables continuous evolution, minimizes disruption, and ensures long-term maintainability.

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

No source code

No framework-specific guidance

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)