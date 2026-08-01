You are a Distinguished Enterprise API Architect, REST API Governance Expert, Enterprise Integration Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, Performance Architect, and Technical Documentation Architect.

Create the file:

docs/api/08-pagination.md

Purpose:

Define the Pagination Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, principles, consistency requirements, and lifecycle for paginated API responses across the platform.

This document defines pagination governance only.

This document is NOT an API reference.

This document MUST remain technology-neutral.

No framework-specific guidance.

No programming language examples.

No source code.

No implementation details.

This standard applies to:

- Public APIs
- Internal APIs
- Mobile APIs
- Administrative APIs
- Partner APIs
- Reporting APIs

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

Explain why pagination is essential for enterprise APIs with large datasets.

3. Scope

Include:

- In Scope
- Out of Scope

4. Pagination Philosophy

Describe principles including:

- Performance
- Predictability
- Scalability
- Consistency
- Consumer Experience
- Long-Term Maintainability

5. Pagination Concepts

Define:

- Collection
- Page
- Page Size
- Offset
- Cursor
- Window
- Result Set

6. Pagination Strategies

Describe conceptually:

- Offset-Based Pagination
- Page-Based Pagination
- Cursor-Based Pagination
- Keyset Pagination

Explain the strengths, limitations, and appropriate use cases for each strategy.

Do not recommend implementation details.

7. Pagination Metadata

Describe conceptual metadata such as:

- Current Position
- Page Size
- Total Records
- Total Pages
- Next Page
- Previous Page
- Navigation Information

Do not define implementation formats.

8. Large Dataset Considerations

Describe:

- Performance
- Memory Usage
- Response Size
- Database Impact
- Consumer Experience

9. Sorting and Pagination

Explain why stable sorting is essential for predictable pagination.

Describe conceptual relationships between sorting and pagination.

10. Filtering and Pagination

Describe:

- Filtering Before Pagination
- Consistent Result Sets
- Search Integration

11. Consistency Principles

Describe:

- Stable Ordering
- Duplicate Prevention
- Missing Record Prevention
- Predictable Navigation

12. Performance Principles

Describe:

- Efficient Data Retrieval
- Payload Optimization
- Caching Considerations
- Scalability

13. Consumer Responsibilities

Describe expectations for API consumers regarding pagination usage and navigation.

14. Provider Responsibilities

Describe expectations for API providers regarding consistency, metadata, stability, and performance.

15. Governance

Describe:

- Pagination Standards
- Architectural Review
- Consistency Validation
- Documentation Review

16. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Large collections MUST support pagination.
- Pagination metadata MUST remain consistent.
- Pagination SHOULD provide predictable navigation.
- Sorting MUST remain stable across pages.
- Filtering MUST be applied before pagination.
- Pagination standards MUST be documented before implementation.

17. References

Reference:

- API Principles
- Request and Response Standards
- Endpoint Design
- Filtering and Sorting
- Architecture Documentation
- Module Specifications

18. Glossary

Include terms such as:

- Pagination
- Page
- Offset
- Cursor
- Result Set
- Collection
- Stable Ordering
- Page Size

19. Summary

Summarize how standardized pagination improves scalability, performance, interoperability, developer experience, and long-term maintainability across the HoBo Transport Platform.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Performance-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

No implementation details

No framework-specific guidance

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)