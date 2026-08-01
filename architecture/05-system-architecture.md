You are a Distinguished Enterprise Architect, Chief Software Architect, Principal Platform Engineer, Cloud Architect, Domain-Driven Design (DDD) Expert, DevOps Architect, Site Reliability Engineer, and AI Systems Architect.

Create the file:

architecture/05-system-architecture.md

Purpose:

Define the official master system architecture for the HoBo Transport Platform (HBT).

This is the MOST IMPORTANT architecture document in the repository.

Every architecture document, engineering standard, implementation guideline, and AI coding assistant MUST treat this document as the authoritative architectural specification.

The document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

The document MUST describe the complete architecture of the platform while remaining technology-neutral where possible.

No implementation code should appear.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Architecture Vision

4. Architecture Principles

5. Architecture Goals

6. Architecture Constraints

7. Quality Attributes

8. System Context

9. High-Level Architecture

10. Layered Architecture

Describe layers including:

- Client Layer
- API Layer
- Application Layer
- Domain Layer
- Infrastructure Layer
- Data Layer
- External Services

11. Platform Components

12. Shared Platform Services

13. Business Modules

Describe:

- Express Bus
- Cargo
- Taxi
- Motorcycle
- Motel
- Hotel

14. Cross-Cutting Concerns

Including:

- Authentication
- Authorization
- Audit
- Logging
- Configuration
- Monitoring
- Notifications
- Search
- AI Services
- Caching
- Validation
- Localization

15. Multi-Tenant Architecture

Describe:

- Tenant Isolation
- Tenant Configuration
- Tenant Branding
- Tenant Data Ownership

16. Offline-First Architecture

Describe:

- Local Storage
- Synchronization
- Conflict Resolution
- Retry Strategy
- Queue-based Synchronization
- Connectivity Detection

17. Event-Driven Architecture

Describe:

- Domain Events
- Integration Events
- Event Publishing
- Event Consumption

18. API Architecture

Describe:

- API First
- Versioning
- Resource Design
- Error Standards
- Idempotency
- Pagination
- Filtering
- Rate Limiting

19. Data Architecture

Describe:

- Transactional Data
- Master Data
- Reference Data
- Reporting Data

20. Integration Architecture

Describe:

- Payment Providers
- SMS
- Email
- Push Notification
- Maps
- Government APIs
- Third-party Partners

21. Security Architecture

Describe:

- Identity
- Authentication
- Authorization
- Encryption
- Secret Management
- Audit Trail
- Zero Trust

22. Scalability Strategy

Describe:

- Horizontal Scaling
- Vertical Scaling
- Stateless Services
- Load Distribution

23. High Availability

24. Reliability

25. Performance Strategy

26. Disaster Recovery

27. Backup Strategy

28. Observability

Include:

- Metrics
- Logs
- Traces
- Dashboards
- Alerting

29. Deployment Strategy

Describe environments:

- Local
- Development
- Testing
- Staging
- Production

30. AI Integration Architecture

Describe:

- AI Gateway
- Vendor Neutral Design
- Prompt Management
- AI Provider Abstraction
- Future AI Expansion

31. Architecture Decision Records (ADR)

Explain how architecture decisions MUST be documented.

32. Architecture Governance

Describe:

- Review Process
- Approval Process
- Change Management
- Compliance

33. Risks

34. Assumptions

35. Future Evolution

Explain how the platform can evolve from:

Modular Monolith

to

Distributed Services

without changing business modules.

36. Architecture Checklist

37. Glossary

38. Summary

--------------------------------------------------
Architecture Principles
--------------------------------------------------

The architecture MUST support:

- Modular Monolith First
- API First
- Offline First
- Mobile First
- Security First
- Cloud Ready
- AI Ready
- AI Vendor Neutral
- Multi-Tenant
- Event-Driven
- Domain-Driven Design
- Clean Architecture
- SOLID
- High Cohesion
- Loose Coupling
- Observability
- Maintainability
- Scalability
- Reliability
- Testability

--------------------------------------------------
Mandatory Architecture Rules
--------------------------------------------------

Business modules MUST own their business logic.

Business modules MUST own their data.

Business modules MUST NOT directly access another module.

Every module MUST expose only public interfaces.

Shared platform services MUST NOT contain business-specific logic.

Cross-cutting concerns MUST remain centralized.

Every architectural decision MUST prioritize long-term maintainability over short-term convenience.

Every architecture decision MUST support future platform expansion.

The architecture MUST allow adding new transportation domains without modifying existing modules.

--------------------------------------------------
Future Expansion

Potential future modules:

- Ferry
- Railway
- Airline
- Tourism
- Logistics Marketplace
- Warehouse
- Delivery
- Vehicle Rental
- Travel Insurance
- Loyalty Platform

--------------------------------------------------
Conclusion

End with an Architecture Vision Statement explaining that:

"The HoBo Transport Platform is a long-term, modular, offline-first transportation ecosystem built on a shared engineering platform. Every business capability evolves independently while following one unified architecture, one security model, one engineering standard, and one operational model."

--------------------------------------------------
Requirements
--------------------------------------------------

Enterprise-grade Markdown

No source code

No implementation examples

Business-focused

Architecture-focused

Long-term maintainable

AI Vendor Neutral

Written for both enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants

