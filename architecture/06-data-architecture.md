You are a Distinguished Data Architect, Enterprise Architect, Database Architect, Domain-Driven Design (DDD) Expert, Data Governance Specialist, and Principal Platform Engineer.

Create the file:

architecture/06-data-architecture.md

Purpose:

Define the official Data Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative specification for how business data is organized, owned, shared, secured, synchronized, stored, governed, and evolved across the platform.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

The document MUST focus on architecture and governance.

No implementation details or source code should appear.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Data Architecture Vision

4. Data Principles

5. Data Ownership

6. Domain Data Ownership

Describe ownership for:

- Express Bus
- Cargo
- Taxi
- Motorcycle
- Motel
- Hotel

7. Shared Platform Data

Including:

- Users
- Organizations
- Tenants
- Customers
- Roles
- Permissions
- Audit Logs
- Notifications
- Files
- Configuration
- AI Metadata

8. Data Classification

Include:

- Master Data
- Transaction Data
- Reference Data
- Configuration Data
- Operational Data
- Reporting Data
- Analytical Data

9. Data Lifecycle

Describe:

- Creation
- Validation
- Storage
- Update
- Archive
- Deletion
- Retention

10. Data Relationships

11. Database Architecture

Describe:

- Shared Database Strategy
- Schema Organization
- Future Evolution
- Data Isolation

12. Multi-Tenant Data Strategy

Include:

- Tenant Isolation
- Tenant Ownership
- Shared Resources
- Cross-Tenant Restrictions

13. Offline Data Strategy

Describe:

- Local Storage
- Synchronization
- Sync Queue
- Conflict Resolution
- Retry Mechanism
- Data Recovery

14. Data Consistency

Describe:

- Strong Consistency
- Eventual Consistency
- Transaction Boundaries

15. Data Integrity

16. Data Validation

17. Data Security

Describe:

- Encryption
- Access Control
- Data Masking
- Sensitive Data
- Privacy Protection

18. Audit Data

19. Reporting Data

20. Analytics Data

21. Search Index Data

22. AI Data

Describe:

- Prompt Metadata
- AI Request Metadata
- AI Response Metadata
- AI Usage Metrics

23. Backup Strategy

24. Disaster Recovery

25. Data Migration Strategy

26. Data Versioning

27. Data Governance

28. Data Quality

29. Naming Standards

Define standards for:

- Tables
- Columns
- Constraints
- Indexes
- Views
- Materialized Views
- Functions
- Procedures
- Triggers

30. Data Architecture Rules

Mandatory Rules:

- Every module MUST own its own business data.
- Shared services MUST own shared data only.
- Business modules MUST NOT modify another module's data directly.
- Database access MUST respect module boundaries.
- Sensitive data MUST be encrypted.
- Every business change MUST be auditable.
- Every record MUST support traceability where appropriate.
- Data retention policies MUST be defined.
- Offline synchronization MUST preserve integrity.
- AI metadata MUST remain isolated from business data.

31. Future Evolution

Describe evolution from:

Shared PostgreSQL Database

to

Distributed Data Services

without changing business domains.

32. Data Architecture Checklist

33. Glossary

34. Summary

--------------------------------------------------
Architecture Goals
--------------------------------------------------

The architecture MUST support:

- Offline First
- Multi-Tenant
- High Integrity
- Scalability
- Security
- High Performance
- Auditability
- AI Readiness
- Vendor Neutrality
- Future Distributed Architecture

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

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants