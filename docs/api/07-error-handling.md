You are a Distinguished Enterprise API Architect, Enterprise Integration Architect, REST API Governance Expert, Enterprise Security Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/07-error-handling.md

Purpose:

Define the Error Handling Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, principles, classification, consistency requirements, and lifecycle for API error handling across the platform.

This document defines error handling governance only.

This document is NOT an API reference.

This document MUST remain technology-neutral.

No framework-specific guidance.

No programming language examples.

No source code.

No implementation details.

This document applies to:

- Public APIs
- Internal APIs
- Mobile APIs
- Administrative APIs
- Partner APIs
- Integration APIs

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

Explain why consistent error handling is essential for enterprise APIs.

3. Scope

Include:

- In Scope
- Out of Scope

4. Error Handling Philosophy

Describe principles such as:

- Consistency
- Predictability
- Consumer-Friendly Design
- Human Readability
- Machine Readability
- Security by Default
- Long-Term Maintainability

5. Error Classification

Describe conceptual categories such as:

- Validation Errors
- Authentication Errors
- Authorization Errors
- Resource Errors
- Business Rule Violations
- Conflict Errors
- Rate Limiting
- Service Availability
- Internal System Errors
- External Dependency Errors

6. Error Response Principles

Describe conceptual response elements including:

- Status
- Error Code
- Message
- Details
- Correlation Identifier
- Timestamp

Do not define implementation formats.

7. Business Error vs System Error

Explain the differences and why they MUST be distinguished.

8. Validation Error Principles

Describe:

- Input Validation
- Business Validation
- Multiple Validation Errors
- Field-Level Errors

9. Security Considerations

Describe:

- Information Disclosure Prevention
- Sensitive Data Protection
- Internal Exception Protection
- Safe Error Messages

10. Error Traceability

Describe:

- Correlation ID
- Request ID
- Audit References
- Operational Monitoring

11. Localization Principles

Describe:

- User-Friendly Messages
- Localization
- Machine-Readable Error Codes

12. Consumer Responsibilities

Describe expectations for API consumers regarding error handling, retries, and resilience.

13. Provider Responsibilities

Describe expectations for API providers regarding consistent classification, documentation, and traceability.

14. Governance

Describe:

- Error Catalog
- Error Code Management
- Documentation Review
- Consistency Review
- Compliance

15. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every error MUST follow a consistent structure.
- Business errors MUST be distinguishable from system errors.
- Sensitive implementation details MUST NOT be exposed.
- Error responses SHOULD support localization.
- Every error SHOULD be traceable.
- Error codes MUST remain stable once published.
- Validation errors SHOULD clearly identify invalid input.

16. References

Reference:

- API Principles
- Request and Response Standards
- API Security
- Authentication
- Authorization
- Architecture Documentation

17. Glossary

Include definitions for:

- Error
- Exception
- Validation Error
- Business Error
- System Error
- Correlation ID
- Traceability
- Error Code

18. Summary

Summarize how standardized error handling improves reliability, developer experience, operational visibility, security, interoperability, and long-term maintainability across the HoBo Transport Platform.

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