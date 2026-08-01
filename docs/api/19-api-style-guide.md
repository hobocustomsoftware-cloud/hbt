You are a Distinguished Enterprise API Architect, REST API Style Guide Expert, Enterprise Integration Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/19-api-style-guide.md

Purpose:

Define the API Style Guide for the HoBo Transport Platform (HBT).

This document establishes the governance, naming conventions, documentation standards, consistency requirements, and design expectations for all APIs across the platform.

This document defines governance only.

This document MUST complement, but MUST NOT duplicate:

- API Principles
- Endpoint Design
- Request & Response
- Error Handling
- OpenAPI Guidelines

This document is NOT an implementation guide.

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
- Future AI Coding Assistants.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

Explain why a consistent API style improves usability, maintainability, interoperability, and developer experience.

3. Scope

Include:

- In Scope
- Out of Scope

4. API Style Philosophy

Describe principles including:

- Consistency
- Simplicity
- Predictability
- Readability
- Business-Oriented Design
- Documentation First
- Long-Term Maintainability

5. Core Concepts

Define:

- API Style
- Naming Convention
- Resource
- Operation
- Consistency
- Contract
- Developer Experience

6. Naming Standards

Describe conceptual guidance for:

- Resource Names
- URI Naming
- Operation Names
- Query Parameters
- Headers
- Enumerations
- Identifiers

Focus on consistency principles rather than syntax.

7. Resource Design Consistency

Describe:

- Collection Resources
- Individual Resources
- Nested Resources
- Relationships
- Canonical Resources

8. Request and Response Consistency

Describe:

- Uniform Request Structures
- Uniform Response Structures
- Metadata Consistency
- Error Consistency
- Pagination Consistency

9. Documentation Consistency

Describe:

- Terminology
- Business Vocabulary
- Examples
- Version Synchronization
- Cross References

10. Business Vocabulary

Describe why terminology MUST remain consistent across:

- Modules
- APIs
- Documentation
- UI
- Reports

11. Multi-Tenant Consistency

Describe:

- Tenant Terminology
- Company Terminology
- Branch Terminology
- Ownership Terminology

12. Consumer Responsibilities

Describe expectations for API consumers regarding consistent interpretation of contracts, terminology, and version usage.

13. Provider Responsibilities

Describe expectations for API providers regarding naming consistency, documentation quality, contract stability, and style compliance.

14. Governance

Describe:

- Style Guide Governance
- Documentation Review
- API Review
- Architecture Review
- Compliance
- Continuous Improvement

15. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- API terminology MUST remain consistent across the platform.
- Resource naming MUST follow platform conventions.
- Documentation MUST use approved business vocabulary.
- Style guide compliance MUST be verified before release.
- API contracts SHOULD remain predictable.
- Cross-document terminology MUST remain synchronized.
- Style changes MUST undergo architecture review.

16. References

Reference:

- API Principles
- Endpoint Design
- Request & Response
- Error Handling
- OpenAPI Guidelines
- Architecture Documentation
- Module Specifications

17. Glossary

Include definitions for:

- API Style
- Resource
- Naming Convention
- Consistency
- Business Vocabulary
- Contract
- Canonical Resource
- Developer Experience

18. Summary

Summarize how a unified API style guide improves consistency, readability, interoperability, maintainability, developer productivity, and long-term sustainability across the HoBo Transport Platform.

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