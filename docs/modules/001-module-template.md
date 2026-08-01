You are a Distinguished Enterprise Software Architect, Domain-Driven Design (DDD) Expert, Principal Business Analyst, Technical Writer, and Enterprise Documentation Architect.

Create the file:

docs/modules/001-module-template.md

Purpose:

Define the official Module Documentation Standard for the HoBo Transport Platform (HBT).

This document is the authoritative template that MUST be used for documenting every business module across the platform.

It establishes a consistent structure so that all modules are documented in the same way regardless of the author or AI coding assistant.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document defines documentation standards only.

No implementation details.

No source code.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Document Purpose

2. Module Overview

Describe:

- Module Name
- Module Description
- Business Objective
- Business Value
- Module Owner

3. Responsibilities

Describe what the module MUST own.

Describe what the module MUST NOT own.

4. Scope

Describe:

In Scope

Out of Scope

5. Business Goals

6. Actors

Describe:

Primary Actors

Secondary Actors

External Systems

7. Business Rules

Describe how business rules should be documented.

Each rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

8. Use Cases

For every use case include:

- Use Case ID
- Name
- Goal
- Primary Actor
- Preconditions
- Main Flow
- Alternate Flow
- Exception Flow
- Post Conditions

9. Domain Model

Describe:

- Entities
- Value Objects
- Aggregates
- Domain Services
- Repositories

10. State Machine

Describe:

- States
- State Transitions
- Entry Conditions
- Exit Conditions

11. Commands

Describe:

- Command Name
- Purpose
- Validation
- Result

12. Queries

Describe:

- Query Name
- Purpose
- Returned Information

13. Events

Describe:

- Domain Events
- Integration Events
- Event Triggers
- Event Consumers

14. Integrations

Describe:

Internal Modules

External Systems

AI Services

Notifications

15. Permissions

Describe:

Roles

Permissions

Restrictions

16. Validation Rules

Describe:

Input Validation

Business Validation

Cross Module Validation

17. Offline Behavior

Describe:

Offline Availability

Offline Restrictions

Offline Queue

Synchronization

Conflict Resolution

18. Audit Requirements

Describe:

Audit Events

User Activity

Business Activity

System Activity

19. Reports

Describe module reports and dashboards.

20. KPIs

Describe measurable indicators for the module.

21. Error Scenarios

Describe expected business failures and recovery behavior.

22. Dependencies

Describe upstream and downstream dependencies.

23. Security Considerations

24. Performance Considerations

25. Observability Considerations

26. Future Expansion

27. References

Describe related:

Architecture Documents

ADR Documents

Standards

Policies

28. Glossary

29. Summary

--------------------------------------------------
Documentation Rules

Every module MUST follow this template.

Every module MUST define its responsibilities clearly.

Business rules MUST be uniquely identified.

Use cases MUST be complete.

Events MUST identify publishers and consumers.

Permissions MUST follow least privilege.

Offline behavior MUST be documented where applicable.

Dependencies MUST be explicit.

References MUST link to relevant architecture documents.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Documentation-focused

Business-focused

No implementation examples

No source code

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants