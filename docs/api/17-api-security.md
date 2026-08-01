You are a Distinguished Enterprise Security Architect, Enterprise API Security Architect, Zero Trust Architect, REST API Governance Expert, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/17-api-security.md

Purpose:

Define the API Security Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, architectural principles, security expectations, operational policies, and risk management standards for securing APIs across the platform.

This document defines governance only.

This document MUST complement, but MUST NOT duplicate:

- Authentication Standards
- Authorization Standards
- Rate Limiting Standards

This document is NOT an implementation guide.

This document MUST remain technology-neutral.

No implementation details.

No framework-specific guidance.

No programming language examples.

No source code.

This document applies to:

- Public APIs
- Internal APIs
- Administrative APIs
- Mobile APIs
- Partner APIs
- AI APIs
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

Explain why API security governance is essential for protecting business operations, customer data, financial integrity, and platform trust.

3. Scope

Include:

- In Scope
- Out of Scope

4. API Security Philosophy

Describe principles including:

- Security by Default
- Zero Trust
- Least Privilege
- Defense in Depth
- Secure by Design
- Privacy by Design
- Continuous Protection

5. Security Objectives

Describe:

- Confidentiality
- Integrity
- Availability
- Authenticity
- Accountability
- Non-Repudiation

6. Threat Landscape

Describe common API threats conceptually, including:

- Unauthorized Access
- Broken Authentication
- Broken Authorization
- Data Exposure
- Injection Attacks
- Replay Attacks
- Denial of Service
- API Abuse
- Business Logic Abuse
- Credential Compromise

Do not discuss implementation.

7. Security Principles

Describe:

- Identity Verification
- Secure Communication
- Input Validation
- Output Protection
- Data Classification
- Error Information Protection
- Auditability
- Traceability

8. Sensitive Data Protection

Describe:

- Personally Identifiable Information (PII)
- Financial Data
- Operational Data
- Confidential Business Data
- Data Minimization
- Data Retention

9. Multi-Tenant Security

Describe:

- Tenant Isolation
- Company Isolation
- Branch Isolation
- Data Ownership
- Context Enforcement

10. AI Security Considerations

Describe:

- Prompt Protection
- Sensitive Business Context
- AI Request Isolation
- AI Response Validation
- Responsible AI Usage

11. Consumer Responsibilities

Describe expectations for API consumers regarding credential protection, secure integration, data handling, responsible usage, and incident reporting.

12. Provider Responsibilities

Describe expectations for API providers regarding secure architecture, monitoring, auditing, documentation, vulnerability management, and continuous improvement.

13. Security Monitoring

Describe:

- Audit Logging
- Security Events
- Incident Detection
- Traceability
- Operational Visibility

14. Governance

Describe:

- Security Governance
- Architecture Review
- Risk Assessment
- Compliance Review
- Documentation Review
- Continuous Improvement

15. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- APIs MUST follow Security by Default principles.
- Sensitive business data MUST be protected.
- Tenant isolation MUST be enforced.
- Security events SHOULD be auditable.
- Security controls MUST be documented before implementation.
- Security reviews MUST occur before production release.
- Business logic security MUST be evaluated during architecture review.

16. References

Reference:

- API Principles
- Authentication
- Authorization
- Error Handling
- Rate Limiting
- File Upload
- API Lifecycle
- Architecture Documentation
- Security Documentation

17. Glossary

Include definitions for:

- API Security
- Zero Trust
- Least Privilege
- Confidentiality
- Integrity
- Availability
- Defense in Depth
- PII
- Security Incident
- Threat

18. Summary

Summarize how API security governance protects business operations, customer trust, regulatory compliance, financial integrity, and long-term sustainability across the HoBo Transport Platform.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Security-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

No implementation details

No framework-specific guidance

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)