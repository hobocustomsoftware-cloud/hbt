You are a Distinguished Enterprise Software Architect, Solution Architect, Domain-Driven Design (DDD) Expert, Cloud Architect, and Principal Platform Engineer.

Create the file:

architecture/03-system-overview.md

Purpose:

Provide a high-level architectural overview of the HoBo Transport Platform (HBT).

This document is intended to help stakeholders, architects, developers, DevOps engineers, SREs, QA engineers, product managers, and AI coding assistants understand the overall system before implementation.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST describe the platform from a system perspective and MUST NOT contain implementation-specific code.

Include the following sections:

1. Purpose
2. Executive Summary
3. System Overview
4. Product Ecosystem
5. Platform Vision
6. High-Level Architecture
7. Core Platform Components
8. Business Modules
9. Shared Platform Services
10. External Integrations
11. User Types
12. System Interfaces
13. Client Applications
14. Backend Services
15. Data Layer
16. AI Services
17. Security Layer
18. Offline-First Strategy
19. Multi-Tenant Strategy
20. Deployment Overview
21. Scalability Strategy
22. Reliability Strategy
23. Observability Strategy
24. Future Expansion
25. Architecture Principles
26. Assumptions
27. Constraints
28. Risks
29. Success Criteria
30. Summary

Describe the platform ecosystem including:

Client Layer

- Flutter Mobile App
- Web Admin Portal
- Operations Dashboard
- Super Admin Portal
- Partner Portal
- Public APIs

Business Modules

- Express Bus Ticket
- Cargo Management
- Taxi Platform
- Motorcycle Ride Platform
- Motel & Guest House
- Hotel Management

Shared Platform Services

- Authentication
- Authorization
- Tenant Management
- User Management
- Customer Management
- Booking
- Scheduling
- Pricing
- Payments
- Wallet
- Notification
- Reporting
- Audit Logs
- Search
- File Storage
- Configuration
- AI Services

Infrastructure Components

- API Layer
- Background Workers
- Cache
- Object Storage
- Database
- Message Queue
- Monitoring
- Logging
- Backup
- Disaster Recovery

Describe external integrations such as:

- Payment Gateways
- SMS Providers
- Email Providers
- Push Notification Services
- Maps & Geolocation
- Government APIs (where applicable)
- Third-party Booking Partners

Describe the architecture philosophy:

- Modular Monolith as the initial architecture
- Evolution toward distributed services when justified
- API First
- Offline First
- Mobile First
- Security First
- Event-Driven where appropriate
- AI Assisted Development
- AI Vendor Neutral

Include a section explaining how every business module shares one common platform while remaining logically independent.

Include a section describing the system boundaries and interactions between:

- Users
- Business Modules
- Shared Services
- External Systems
- Infrastructure

Describe the high-level data flow from:

User Request
→ Authentication
→ Business Module
→ Shared Services
→ Database
→ Notification
→ Audit Log
→ Analytics

Include measurable architecture goals:

- Availability
- Reliability
- Scalability
- Performance
- Maintainability
- Security
- Extensibility
- Engineering Productivity

Conclude with an Architecture Overview Statement explaining:

The HoBo Transport Platform is a unified, modular, offline-first transportation ecosystem built on a shared engineering platform that enables multiple transportation services to evolve independently while maintaining consistent architecture, security, operational excellence, and development standards.

Requirements:

- Enterprise-grade Markdown
- No source code
- No implementation examples
- Business and architecture focused
- AI Vendor Neutral
- Long-term maintainable
- Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate
- Clear enough that any AI assistant can follow it consistently
- Suitable for both human engineers and AI coding assistants