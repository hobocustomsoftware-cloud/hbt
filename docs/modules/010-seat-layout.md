You are a Distinguished Enterprise Transportation Architect, Passenger Operations Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/010-seat-layout.md

Purpose:

Define the Seat Layout Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how seat layouts are defined, managed, and reused across transportation vehicles.

A Seat Layout represents the physical seating configuration of a vehicle.

A Seat Layout is reusable and MAY be assigned to multiple vehicles of the same configuration.

The Seat Layout Module MUST remain independent from Booking, Ticketing, Passenger Assignment, and Trip execution.

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

- What is a Seat Layout?
- Relationship with Vehicle
- Relationship with Booking
- Relationship with Trip
- Relationship with Passenger

7. Layout Types

Describe support for:

- 2+2 Standard Bus
- 2+1 VIP Bus
- Sleeper Bus
- Mini Bus
- Future Layout Types

8. Responsibilities

The Seat Layout Module MUST manage:

- Layout Profile
- Layout Code
- Layout Name
- Row Configuration
- Column Configuration
- Seat Definitions
- Seat Numbering Rules
- Seat Categories
- Seat Availability Rules
- Layout Status

The Seat Layout Module MUST NOT manage:

- Passenger Assignment
- Ticket Sales
- Trip Execution
- Booking Transactions
- Payment Processing

9. Seat Layout Lifecycle

Describe:

Draft

↓

Review

↓

Approved

↓

Operational

↓

Retired

↓

Archived

10. Seat Definition

Describe:

- Seat Number
- Seat Position
- Row
- Column
- Window Seat
- Aisle Seat
- Driver Area
- Empty Space
- Stair Area
- Restroom Area (if applicable)

11. Seat Categories

Describe support for:

- Standard Seat
- VIP Seat
- Sleeper Bed
- Reserved Seat
- Crew Seat
- Disabled Passenger Seat

12. Numbering Rules

Describe:

- Left-to-Right
- Front-to-Back
- Custom Numbering
- Immutable Seat Identifiers

13. Layout Validation

Describe:

- Duplicate Seat Numbers
- Invalid Positions
- Row Consistency
- Vehicle Compatibility

14. Integrations

Describe interaction with:

- Vehicle Module
- Booking Module
- Passenger Module
- Ticket Module
- Boarding Module
- Reporting Module

15. Events

Include:

- Layout Created
- Layout Approved
- Layout Updated
- Layout Activated
- Layout Retired

16. Permissions

Describe who MAY:

- Create Layout
- Update Layout
- Approve Layout
- Archive Layout
- View Layout

17. Offline Behavior

Describe:

- Offline Layout Loading
- Cached Seat Maps
- Synchronization Rules

18. Audit Requirements

Every Seat Layout modification MUST be auditable.

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Seat MUST have a unique identifier within a Layout.
- A Layout MAY be assigned to multiple Vehicles.
- Archived Layouts MUST become read-only.
- Seat identifiers MUST remain immutable.
- Layout changes MUST NOT affect completed Trips.

20. KPIs

Examples:

- Active Layouts
- Vehicle Coverage
- Seat Utilization
- Average Occupancy
- Booking Success Rate

21. Error Scenarios

Describe:

- Duplicate Seat Number
- Invalid Seat Position
- Incompatible Vehicle
- Archived Layout Assignment

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe support for:

- Dynamic Seat Maps
- Cabin Classes
- Premium Zones
- AI Seat Recommendation
- Family Seating Optimization
- Accessibility Optimization

24. References

Reference related Architecture documents, ADRs, and Module Specifications.

25. Glossary

26. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Layout Creation
- Layout Approval
- Vehicle Assignment
- Layout Versioning
- Layout Retirement

--------------------------------------------------
Mandatory Business Rules

Every Seat Layout MUST belong to exactly one Company.

Every Seat MUST have a unique identifier within the Layout.

A Seat Layout MAY be assigned to multiple Vehicles.

Only Operational Seat Layouts MAY be assigned to Vehicles.

Seat identifiers MUST remain immutable.

Completed Trips MUST always preserve the historical Seat Layout used.

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