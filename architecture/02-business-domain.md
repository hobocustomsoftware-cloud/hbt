You are a Principal Domain-Driven Design (DDD) Architect, Enterprise Solution Architect, Business Analyst, and Transportation Industry Consultant.

Create the file:

architecture/02-business-domain.md

Purpose:

Define the official business domain model for the HoBo Transport Platform (HBT).

This document MUST describe the business domains, bounded contexts, core business capabilities, and relationships between domains.

The document MUST be AI Vendor Neutral and understandable by:

- Product Managers
- Business Analysts
- Solution Architects
- Software Engineers
- AI Coding Assistants
- Future Engineering Teams

This document MUST focus on business concepts only and MUST NOT contain implementation details.

Include the following sections:

1. Purpose
2. Executive Summary
3. Domain-Driven Design Philosophy
4. Business Domain Overview
5. Core Domain
6. Supporting Domains
7. Generic Domains
8. Bounded Context Overview
9. Domain Relationships
10. Shared Platform Services
11. Cross-Domain Communication
12. Domain Ownership
13. Future Domain Expansion
14. Business Rules
15. Glossary

Define the Core Domain as:

- Transportation Services Platform

Define the initial business domains:

1. Express Bus Ticket
2. Cargo Management
3. Taxi Platform
4. Motorcycle Ride Platform
5. Motel & Guest House
6. Hotel Management

For each domain describe:

- Purpose
- Responsibilities
- Primary Users
- Business Capabilities
- Business Events
- Business Rules
- Shared Dependencies
- Future Expansion

Define shared platform domains including:

- Identity & Access Management
- User Management
- Customer Management
- Organization / Tenant Management
- Payment
- Wallet
- Booking
- Pricing
- Scheduling
- Route Management
- Vehicle Management
- Driver Management
- Notification
- Reporting
- Audit Log
- Configuration
- AI Services
- File Storage
- Search

Define common actors such as:

- Passenger
- Customer
- Driver
- Operator
- Ticket Agent
- Cargo Staff
- Hotel Receptionist
- Motel Owner
- Fleet Manager
- Dispatcher
- Finance Staff
- Administrator
- Super Administrator
- External Partner

Describe business relationships between domains.

Explain which capabilities are shared across every business module.

Define bounded contexts and explain that each business domain MUST remain independent while sharing common platform services.

Include a Future Expansion section with possible domains such as:

- Ferry
- Train
- Airline
- Tourism
- Car Rental
- Logistics Marketplace
- Delivery Services
- Warehouse Management
- Travel Insurance
- Loyalty & Rewards

Conclude with a Domain Vision Statement explaining:

The HoBo Transport Platform is a unified transportation ecosystem composed of independent business domains that share one common engineering platform while maintaining clear business boundaries.

Requirements:

- Enterprise-grade Markdown
- No source code
- No implementation examples
- Business-focused
- AI Vendor Neutral
- Long-term maintainable
- DDD terminology
- Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate
- Clear enough that any AI assistant can follow it consistently
- Suitable for both human engineers and AI coding assistants