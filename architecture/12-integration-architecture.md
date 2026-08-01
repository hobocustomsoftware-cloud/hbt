You are a Distinguished Enterprise Integration Architect, Solution Architect, API Architect, Domain-Driven Design (DDD) Expert, Cloud Integration Specialist, Event-Driven Architecture Expert, and Principal Platform Engineer.

Create the file:

architecture/12-integration-architecture.md

Purpose:

Define the official Integration Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative specification describing how the platform communicates with external systems, third-party services, internal platform services, partner ecosystems, and future integrations.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST describe architecture only.

No implementation details.

No source code.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Integration Vision

4. Integration Principles

Include principles such as:

- API First
- Contract First
- Event-Driven
- Loose Coupling
- Resilient Communication
- Vendor Neutral
- Replaceable Integrations
- Secure by Default
- Observable Integrations

5. Integration Goals

6. Integration Landscape

Describe integrations between:

- Mobile Apps
- Web Applications
- Shared Platform Services
- Business Modules
- External Partners
- AI Providers
- Government Services

7. Internal Integration Architecture

Describe communication between modules using:

- Public APIs
- Domain Events
- Integration Events
- Background Jobs
- Shared Infrastructure

8. External Integration Architecture

Describe integrations with:

- Payment Providers
- Banking APIs
- SMS Providers
- Email Providers
- Push Notification Providers
- Maps & Geolocation
- Identity Providers
- AI Providers
- File Storage
- Analytics Platforms

9. Partner Integration Architecture

Describe support for:

- Bus Operators
- Cargo Partners
- Taxi Partners
- Hotel Partners
- Fleet Operators
- Future Marketplace Partners

10. API Gateway Architecture

Describe responsibilities:

- Authentication
- Authorization
- Routing
- Rate Limiting
- Request Validation
- Monitoring
- Audit Logging

11. Event-Driven Integration

Describe:

- Domain Events
- Integration Events
- Event Publishing
- Event Subscription
- Event Versioning
- Event Reliability

12. Asynchronous Processing

Describe:

- Queues
- Background Workers
- Scheduled Tasks
- Retry Processing
- Dead Letter Queue Readiness

13. AI Integration Architecture

Describe:

- AI Gateway
- Multi-Provider Routing
- Prompt Management
- Provider Failover
- Vendor Neutral Design

14. Offline Integration

Describe:

- Synchronization APIs
- Retry Strategy
- Conflict Handling
- Queue Processing

15. Security Architecture

Describe:

- Secure Communication
- TLS
- API Authentication
- OAuth Readiness
- JWT
- API Keys
- Secret Management

16. Data Exchange Standards

Describe:

- Request Contracts
- Response Contracts
- Error Standards
- Metadata
- Correlation IDs
- Idempotency

17. Observability

Describe:

- Metrics
- Logs
- Traces
- Health Checks
- Alerting

18. Error Handling

Describe:

- Retry
- Timeout
- Circuit Breaker Readiness
- Graceful Degradation
- Failure Recovery

19. Integration Governance

20. Versioning Strategy

21. Change Management

22. Testing Strategy

Describe:

- Contract Testing
- Integration Testing
- End-to-End Testing
- Partner Sandbox Testing

23. Integration Risks

24. Assumptions

25. Future Evolution

Describe evolution from:

REST Integrations

→ Event-Driven Integrations

→ Distributed Platform

→ Enterprise Integration Ecosystem

without changing business modules.

26. Integration Checklist

27. Glossary

28. Summary

--------------------------------------------------
Mandatory Integration Rules
--------------------------------------------------

Business modules MUST communicate only through published contracts.

Internal implementation MUST remain private.

External providers MUST be replaceable.

Every integration MUST be monitored.

Every integration MUST be authenticated.

Integration failures MUST NOT corrupt business data.

Communication SHOULD be asynchronous whenever appropriate.

Business logic MUST remain inside the owning module.

Integration contracts MUST be versioned.

All integrations MUST support audit logging.

AI providers MUST remain behind an abstraction layer.

--------------------------------------------------
Platform Integrations
--------------------------------------------------

Include architecture for:

- Authentication
- Authorization
- Payment
- Wallet
- Booking
- Routes
- Vehicles
- Drivers
- Cargo
- Hotel
- Notifications
- Search
- AI Services
- Reporting
- Audit Logs
- File Storage

--------------------------------------------------
Requirements
--------------------------------------------------

Enterprise-grade Markdown

Architecture-focused

No source code

No implementation examples

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants