You are a Distinguished Enterprise Transportation Architect, Route Planning Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/007-route.md

Purpose:

Define the Route Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how transportation routes are defined, managed, and governed across the platform.

A Route represents a reusable business asset that defines the planned travel path between an origin and a destination, including intermediate operational locations.

A Route is independent from Trip execution, Ticket Sales, Scheduling, and Vehicle Assignment.

This document defines business responsibilities only.

No implementation details.

No source code.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Module Overview

Describe:

- Business Objective
- Business Value
- Responsibilities
- Out of Scope

4. Scope

Include:

In Scope

Out of Scope

5. Business Goals

6. Business Definition

Describe:

- What is a Route?
- Origin Terminal
- Destination Terminal
- Intermediate Stops
- Pickup Points
- Drop-off Points
- Operational Purpose

7. Responsibilities

The Route Module MUST manage:

- Route Definition
- Route Code
- Route Name
- Origin Terminal
- Destination Terminal
- Intermediate Stops
- Pickup Points
- Drop-off Points
- Estimated Distance
- Estimated Duration
- Route Status

The Route Module MUST NOT manage:

- Vehicle Assignment
- Driver Assignment
- Ticket Sales
- Booking
- Payments
- Passenger Operations

8. Route Lifecycle

Describe:

Draft

↓

Review

↓

Approved

↓

Operational

↓

Suspended

↓

Retired

↓

Archived

9. Route Information

Describe:

- Route Code
- Route Name
- Business Name
- Origin
- Destination
- Distance
- Estimated Duration
- Operating Region
- Route Category

10. Route Topology

Describe:

- Origin Terminal
- Destination Terminal
- Mandatory Stops
- Optional Stops
- Pickup Points
- Drop-off Points
- Direction

11. Operational Constraints

Describe:

- Supported Vehicle Types
- Maximum Stops
- Operating Hours
- Seasonal Availability
- Regulatory Restrictions

12. Integrations

Describe interaction with:

- Terminal Module
- Stop Module
- Schedule Module
- Trip Module
- Vehicle Module
- Reporting Module

13. Events

Include:

- Route Created
- Route Approved
- Route Activated
- Route Updated
- Route Suspended
- Route Retired

14. Permissions

Describe who MAY:

- Create Route
- Update Route
- Approve Route
- Suspend Route
- Archive Route
- View Route

15. Validation Rules

Describe:

- Unique Route Code
- Valid Origin
- Valid Destination
- Stop Sequence Validation
- Distance Validation

16. Offline Behavior

Describe:

- Offline Route Lookup
- Cached Route Information
- Synchronization Rules

17. Audit Requirements

Every route modification MUST be auditable.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Route MUST have exactly one Origin Terminal.
- Every Route MUST have exactly one Destination Terminal.
- A Route MAY contain zero or more Intermediate Stops.
- Stop order MUST remain sequential.
- Route identifiers MUST remain immutable.
- Archived Routes MUST become read-only.

19. KPIs

Examples:

- Active Routes
- Route Utilization
- Average Occupancy
- Revenue per Route
- On-Time Performance

20. Error Scenarios

Describe:

- Duplicate Route Code
- Invalid Stop Order
- Invalid Terminal Assignment
- Unsupported Vehicle Type
- Archived Route Modification

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Dynamic Routes
- Seasonal Routes
- Circular Routes
- Multi-Leg Routes
- Cross-Border Routes
- AI Route Optimization

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Route Planning
- Route Approval
- Route Activation
- Stop Assignment
- Pickup Point Assignment
- Route Retirement

--------------------------------------------------
Mandatory Business Rules

Every Route MUST belong to exactly one Company.

Every Route MUST define one Origin Terminal.

Every Route MUST define one Destination Terminal.

A Route MAY contain multiple Stops.

Trips MUST reference existing Routes.

Schedules MUST reference existing Routes.

Routes MUST remain independent from operational Trip execution.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation domain-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants