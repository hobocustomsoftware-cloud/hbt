You are a Distinguished Enterprise API Architect, Enterprise Security Architect, Enterprise Integration Architect, REST API Governance Expert, Principal Software Architect, Performance Architect, and Technical Documentation Architect.

Create the file:

docs/api/11-rate-limiting.md

Purpose:

Define the API Rate Limiting Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, architectural principles, fair usage policies, abuse prevention strategies, and operational standards for API rate limiting across the platform.

This document defines governance only.

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

Explain why rate limiting is essential for protecting enterprise APIs, ensuring fair usage, preventing abuse, and maintaining platform availability.

3. Scope

Include:

- In Scope
- Out of Scope

4. Rate Limiting Philosophy

Describe principles including:

- Fair Usage
- Platform Stability
- Consumer Equality
- Abuse Prevention
- Predictable Service
- Sustainable Scalability

5. Core Concepts

Define:

- Rate Limit
- Quota
- Burst
- Throttling
- Request Window
- Retry Interval
- Service Capacity

6. Rate Limiting Models

Describe conceptually:

- Fixed Window
- Sliding Window
- Token Bucket
- Leaky Bucket
- Adaptive Rate Limiting

Explain strengths, limitations, and appropriate use cases without implementation guidance.

7. Rate Limiting Scope

Describe conceptual limiting scopes such as:

- Per User
- Per API Consumer
- Per Tenant
- Per Company
- Per Branch
- Per API Key
- Per IP Address
- Per Device
- Per Endpoint

Explain when each scope is appropriate.

8. Fair Usage Policy

Describe:

- Shared Platform Resources
- Consumer Fairness
- Resource Protection
- Excessive Usage
- Temporary Restrictions

9. Throttling Principles

Describe:

- Soft Limits
- Hard Limits
- Grace Periods
- Retry Expectations
- Progressive Restriction

10. Service Protection

Describe:

- Denial of Service Protection
- Abuse Detection
- Automated Clients
- Suspicious Activity
- Traffic Spikes

11. Consumer Responsibilities

Describe expectations for API consumers regarding request frequency, retries, caching, and responsible usage.

12. Provider Responsibilities

Describe expectations for API providers regarding transparency, consistency, monitoring, capacity planning, and fair enforcement.

13. Multi-Tenant Considerations

Describe:

- Tenant Isolation
- Shared Resource Protection
- Subscription Tier Awareness
- Fair Allocation

14. Governance

Describe:

- Rate Limit Policy
- Capacity Planning
- Monitoring
- Compliance
- Documentation Review

15. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Public APIs MUST enforce rate limiting.
- Rate limiting MUST remain consistent and predictable.
- Consumers SHOULD receive sufficient information to recover from throttling.
- Rate limits SHOULD align with subscription or service tiers where applicable.
- Abuse detection MUST protect platform availability.
- Rate limiting policies MUST be documented before implementation.
- Rate limiting events SHOULD be auditable.

16. References

Reference:

- API Principles
- Authentication
- Authorization
- Request and Response Standards
- API Security
- Subscription Documentation
- Architecture Documentation

17. Glossary

Include definitions for:

- Rate Limit
- Quota
- Burst
- Throttling
- Retry Interval
- Fair Usage
- Denial of Service
- Abuse Prevention

18. Summary

Summarize how standardized rate limiting protects platform stability, ensures fair resource allocation, improves security, supports multi-tenant scalability, and enhances long-term operational reliability across the HoBo Transport Platform.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Performance-focused

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