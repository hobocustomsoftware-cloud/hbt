You are a Distinguished API Architect, Enterprise Solution Architect, Principal Backend Engineer, Domain-Driven Design (DDD) Expert, Integration Architect, and Platform Engineering Lead.

Create the file:

architecture/07-api-architecture.md

Purpose:

Define the official API Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative specification for all APIs within the platform.

Every backend engineer, frontend engineer, mobile engineer, AI coding assistant, and external integration MUST follow this document.

The document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST define API architecture principles and governance.

No implementation code should appear.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. API Vision

4. API Principles

5. API First Strategy

6. API Architecture Overview

7. API Lifecycle

8. API Governance

9. API Versioning Strategy

10. API Naming Standards

11. Resource Design Standards

12. URI Design Guidelines

13. HTTP Method Standards

14. Request Standards

15. Response Standards

16. Standard Response Format

17. Error Response Standards

18. Validation Standards

19. Pagination Standards

20. Filtering Standards

21. Sorting Standards

22. Search Standards

23. Batch Operations

24. Idempotency

25. Optimistic Concurrency

26. API Security

Describe:

- Authentication
- Authorization
- RBAC
- Tenant Isolation
- Rate Limiting
- API Keys
- JWT
- OAuth Ready
- Audit Logging

27. Multi-Tenant API Strategy

28. Offline Synchronization APIs

Describe:

- Upload Queue
- Download Queue
- Delta Synchronization
- Conflict Detection
- Conflict Resolution
- Retry Policies

29. Event APIs

30. Internal APIs

31. External APIs

32. Public APIs

33. Partner APIs

34. AI APIs

35. Notification APIs

36. File APIs

37. Payment APIs

38. Reporting APIs

39. Monitoring APIs

40. API Documentation Standards

41. OpenAPI Standards

42. API Deprecation Policy

43. API Compatibility Policy

44. API Testing Standards

45. API Observability

46. API Performance Goals

47. API Security Checklist

48. API Governance Checklist

49. Future Evolution

Describe evolution from:

REST APIs

to

Hybrid REST + Event + gRPC Architecture

without breaking clients.

50. Glossary

51. Summary

--------------------------------------------------
Architecture Principles
--------------------------------------------------

The API architecture MUST support:

- API First
- REST First
- Resource-Oriented Design
- Consistent Contracts
- Versioned APIs
- Stateless Communication
- Secure by Default
- Multi-Tenant
- Offline First
- Mobile First
- AI Ready
- Vendor Neutral
- Backward Compatibility
- Observability
- Scalability

--------------------------------------------------
Mandatory Rules
--------------------------------------------------

Every public API MUST be versioned.

Every endpoint MUST have a documented contract.

Every response MUST follow a standard structure.

Every error MUST use a standard error format.

Every API MUST enforce authorization.

Every API MUST validate input.

Sensitive data MUST NOT be exposed.

Business modules MUST expose APIs only through public interfaces.

Internal implementation MUST remain hidden.

Breaking API changes MUST follow the governance process.

Every API MUST support monitoring and audit logging.

--------------------------------------------------
Platform APIs

Define API groups for:

- Identity
- Authentication
- Authorization
- Tenant
- Organization
- Users
- Customers
- Bus Ticket
- Cargo
- Taxi
- Motorcycle
- Motel
- Hotel
- Booking
- Routes
- Vehicles
- Drivers
- Payments
- Wallet
- Reports
- Notifications
- Files
- Search
- AI Services
- Administration

--------------------------------------------------
Requirements

Enterprise-grade Markdown

No source code

No implementation examples

Architecture-focused

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants