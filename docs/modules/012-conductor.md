You are a Distinguished Enterprise Transportation Architect, Passenger Operations Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/012-conductor.md

Purpose:

Define the Conductor Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how conductors are registered, qualified, managed, and assigned to transportation operations.

Within the HBT domain model, the canonical business term is "Conductor".

For Myanmar localization, user interfaces MAY display the role as:

- ယာဉ်အကူ
- Spare
- ယာဉ်အကူ (Spare)

However, APIs, documentation, database schemas, events, and internal architecture MUST consistently use the canonical term "Conductor".

A Conductor represents the operational crew member responsible for passenger service, ticket validation, roadside passenger handling, cash collection, boarding assistance, luggage coordination, and trip support.

The Conductor Module manages conductor master data, operational qualifications, assignments, and availability.

The Conductor Module MUST remain independent from Trip execution, Ticket Sales transactions, Passenger records, Booking records, and Payment processing.

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

3. Myanmar Business Terminology

Explain:

The Myanmar transportation industry commonly uses the term:

"Spare"

Within HBT:

Canonical Domain Name:

Conductor

Localized UI Labels MAY include:

- ယာဉ်အကူ
- Spare
- ယာဉ်အကူ (Spare)

4. Module Overview

Describe:

- Business Objective
- Business Value
- Responsibilities
- Out of Scope

5. Scope

Include:

In Scope

Out of Scope

6. Business Definition

Describe:

- What is a Conductor?
- Operational Responsibilities
- Passenger Service Responsibilities
- Relationship with Driver
- Relationship with Vehicle
- Relationship with Trip

7. Operational Responsibilities

Describe support for:

- Passenger Boarding
- Passenger Assistance
- Roadside Passenger Boarding
- Ticket Validation
- Manual Ticket Issuance
- Cash Collection
- Cash Settlement
- Luggage Handling
- Seat Guidance
- Passenger Counting
- Incident Reporting

8. Responsibilities

The Conductor Module MUST manage:

- Conductor Profile
- Employee Number
- Conductor Code
- Contact Information
- Branch Assignment
- Operational Status
- Employment Status
- Operational Qualifications

The Conductor Module MUST NOT manage:

- Driver Responsibilities
- Vehicle Maintenance
- Passenger Records
- Ticket Pricing
- Payment Processing
- Route Planning

9. Conductor Lifecycle

Describe:

Recruitment

↓

Verification

↓

Training

↓

Operational

↓

Suspended

↓

Inactive

↓

Retired

↓

Archived

10. Operational Availability

Describe:

- Available
- Assigned
- On Duty
- Off Duty
- Leave
- Suspended

11. Daily Operational Duties

Describe:

Before Departure

During Boarding

During Trip

Roadside Boarding

Passenger Assistance

Cash Handling

Arrival Processing

Trip Closing

12. Roadside Passenger Operations

Describe architecture for:

- Boarding passengers outside terminals
- Manual seat assignment
- Cash collection
- Ticket issuance
- Offline operations
- Duplicate passenger prevention
- Synchronization after connectivity returns

13. Cash Responsibilities

Describe:

- Cash Collection
- Ticket Revenue
- Manual Receipts
- Cash Reconciliation
- Daily Settlement

14. Integrations

Describe interaction with:

- Driver Module
- Vehicle Module
- Trip Module
- Boarding Module
- Ticket Module
- Payment Module
- Reporting Module
- Audit Module

15. Events

Include:

- Conductor Registered
- Conductor Activated
- Assigned to Trip
- Passenger Boarded
- Roadside Boarding Recorded
- Cash Collected
- Cash Settled
- Conductor Suspended

16. Permissions

Describe who MAY:

- Register Conductor
- Update Conductor
- Assign Conductor
- Suspend Conductor
- Archive Conductor
- View Conductor

17. Validation Rules

Describe:

- Unique Conductor Code
- Branch Validation
- Assignment Validation
- Cash Settlement Validation

18. Offline Behavior

Describe:

- Offline Passenger Boarding
- Offline Ticket Validation
- Offline Cash Collection
- Offline Manual Tickets
- Offline Synchronization
- Conflict Resolution

19. Audit Requirements

Every operational activity MUST be auditable.

Every cash movement MUST be auditable.

Every roadside boarding MUST be auditable.

20. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Conductor MUST belong to exactly one Company.
- Every Conductor MUST belong to exactly one Branch.
- Only active Conductors MAY be assigned to Trips.
- Every roadside passenger MUST be linked to a Trip.
- Every manual ticket MUST be traceable.
- Every collected payment MUST be reconciled.
- Completed cash settlements MUST become immutable.

21. KPIs

Examples:

- Active Conductors
- Boarding Time
- Passengers Assisted
- Roadside Boarding Count
- Cash Collection Accuracy
- Settlement Completion Rate

22. Error Scenarios

Describe:

- Duplicate Passenger
- Duplicate Seat Assignment
- Cash Difference
- Offline Sync Conflict
- Invalid Trip Assignment
- Suspended Conductor Assignment

23. Dependencies

Describe upstream and downstream dependencies.

24. Future Expansion

Describe support for:

- Mobile Conductor Application
- QR Ticket Validation
- Digital Cash Collection
- AI Passenger Counting
- Smart Boarding
- Digital Settlement

25. References

Reference related Architecture documents, ADRs, and Module Specifications.

26. Glossary

27. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Conductor Registration
- Trip Assignment
- Boarding Operations
- Roadside Boarding
- Ticket Validation
- Manual Ticket Issuance
- Cash Collection
- Daily Settlement

--------------------------------------------------
Mandatory Business Rules

Every Conductor MUST belong to exactly one Company.

Every Conductor MUST belong to exactly one Branch.

Every Conductor MAY be assigned to operational Trips.

Roadside Boarding MUST be linked to a Trip.

Every cash transaction MUST be auditable.

Offline operations MUST synchronize safely.

Completed settlements MUST remain immutable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation operations-focused

Myanmar transportation terminology aware

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants