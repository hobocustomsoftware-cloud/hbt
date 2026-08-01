You are a Distinguished Enterprise Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Platform Engineering Lead.

Create the file:

architecture/04-module-boundary.md

Purpose:

Define the official module boundaries of the HoBo Transport Platform (HBT).

This document establishes clear ownership, responsibilities, dependencies, communication rules, and architectural boundaries between all modules.

This document MUST be AI Vendor Neutral and understandable by:

- Software Architects
- Backend Engineers
- Mobile Engineers
- DevOps Engineers
- QA Engineers
- Product Managers
- AI Coding Assistants
- Future Engineering Teams

This document MUST describe architectural boundaries only and MUST NOT include implementation details or source code.

Include the following sections:

1. Purpose
2. Executive Summary
3. Boundary Philosophy
4. Domain-Driven Design Boundaries
5. Bounded Context Overview
6. Shared Platform Modules
7. Business Modules
8. Module Responsibilities
9. Module Ownership
10. Public Responsibilities
11. Internal Responsibilities
12. Module Dependencies
13. Allowed Dependencies
14. Forbidden Dependencies
15. Communication Rules
16. Shared Contracts
17. Shared Events
18. Data Ownership
19. Database Ownership
20. API Ownership
21. Event Ownership
22. Configuration Ownership
23. Security Boundaries
24. Tenant Boundaries
25. Offline Synchronization Boundaries
26. Background Job Boundaries
27. Integration Boundaries
28. Extension Points
29. Future Module Expansion
30. Boundary Validation Checklist
31. Summary

Define the Shared Platform Modules:

- Identity
- Authentication
- Authorization
- Tenant Management
- User Management
- Customer Management
- Organization Management
- Payment
- Wallet
- Notification
- Reporting
- Search
- File Storage
- Configuration
- AI Services
- Audit Log

Define the Business Modules:

- Express Bus Ticket
- Cargo Management
- Taxi Platform
- Motorcycle Ride Platform
- Motel & Guest House
- Hotel Management

For every module describe:

- Purpose
- Responsibilities
- Owned Business Data
- Public Interfaces
- Dependencies
- Consumers
- Producers
- Business Events
- Shared Services Used
- Extension Opportunities

Define architectural rules such as:

- Every module MUST own its business logic.
- Every module MUST own its data.
- Modules MUST communicate through published APIs or domain events.
- Modules MUST NOT directly access another module's database.
- Modules MUST NOT bypass public interfaces.
- Shared platform services MUST remain technology agnostic.
- Business modules SHOULD remain independent whenever possible.
- Cross-module dependencies MUST be minimized.
- Circular dependencies MUST NOT exist.
- Shared services MUST NOT contain business-specific logic.
- Business logic MUST remain inside the owning module.

Describe allowed communication patterns including:

- Direct API Calls
- Domain Events
- Background Jobs
- Notifications
- Shared Infrastructure Services

Describe forbidden patterns including:

- Shared business tables
- Cross-module SQL queries
- Direct repository access
- Tight coupling
- Hidden dependencies
- Shared mutable state

Include a Future Expansion section describing how new modules can be added without affecting existing modules.

Potential future modules include:

- Ferry
- Railway
- Airline
- Tourism
- Logistics Marketplace
- Vehicle Rental
- Warehouse Management
- Loyalty
- Insurance
- Marketplace

Conclude with a Module Boundary Statement explaining:

Every module is an independently evolving business capability that shares the platform infrastructure while maintaining strict ownership, loose coupling, and clear architectural boundaries.

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