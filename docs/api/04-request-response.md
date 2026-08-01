You are a Distinguished Enterprise API Architect, REST API Governance Expert, Enterprise Integration Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/04-request-response.md

Purpose:

Define the Request and Response Standards for the HoBo Transport Platform (HBT).

This document establishes the official governance for request structures, response structures, metadata, payload consistency, validation principles, and message formats across all platform APIs.

This document defines standards only.

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

Explain why consistent request and response structures are essential for enterprise API ecosystems.

3. Scope

Include:

- In Scope
- Out of Scope

4. Design Philosophy

Describe principles such as:

- Consistency
- Predictability
- Consumer-Friendly Design
- Human Readability
- Machine Readability
- Long-Term Maintainability

5. Request Structure Principles

Describe:

- URI
- Path Parameters
- Query Parameters
- Headers
- Request Body
- Authentication Information
- Correlation Identifiers

6. Request Validation Principles

Describe:

- Required Fields
- Optional Fields
- Data Validation
- Business Validation
- Input Sanitization
- Validation Order

7. Response Structure Principles

Describe the conceptual response structure including:

- Status
- Message
- Data
- Metadata
- Links
- Errors

Explain the purpose of each section without defining implementation formats.

8. Success Responses

Describe expectations for:

- Resource Retrieval
- Resource Creation
- Resource Update
- Resource Deletion
- Empty Responses

9. Error Responses

Describe expectations for:

- Validation Errors
- Authentication Failures
- Authorization Failures
- Resource Not Found
- Conflict
- Business Rule Violations
- Internal Errors

10. Metadata Principles

Describe metadata concepts including:

- Pagination Information
- Request Identifier
- Timestamp
- Processing Information
- Version Information

11. Date and Time Representation

Describe standards for:

- Time Zone
- UTC
- Date Consistency
- Timestamp Representation

12. Localization Principles

Describe:

- Language Awareness
- Regional Formatting
- Localized Messages
- Internationalization Considerations

13. Large Payload Considerations

Describe:

- Pagination
- Partial Responses
- Compression
- Streaming Readiness

14. Security Considerations

Describe:

- Sensitive Data Protection
- Information Disclosure
- Secure Error Messages
- Request Validation

15. Governance

Describe:

- Request Review
- Response Review
- Consistency Review
- Architecture Approval

16. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every request MUST follow platform standards.
- Every response MUST follow a consistent structure.
- Sensitive information MUST NOT be exposed.
- Responses SHOULD remain predictable.
- Validation errors MUST be distinguishable from business errors.
- Metadata SHOULD remain consistent across all APIs.

17. References

Reference:

- API Principles
- API Versioning
- Endpoint Design
- Module Specifications
- OpenAPI Specifications
- Security Documentation

18. Glossary

Include terms such as:

- Request
- Response
- Payload
- Header
- Metadata
- Validation
- Correlation ID
- Message
- Resource Representation

19. Summary

Summarize how standardized request and response structures improve consistency, interoperability, maintainability, developer experience, consumer confidence, and long-term platform evolution.

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