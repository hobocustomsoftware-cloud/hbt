You are a Distinguished Enterprise Transportation Architect, Passenger Operations Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/017-boarding.md

Purpose:

Define the Boarding Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how passengers are validated, checked-in, boarded, and recorded before and during transportation operations.

A Boarding represents the operational event where a Passenger is authorized and recorded as entering a Trip.

A Boarding is NOT a Ticket.

A Boarding is NOT a Booking.

One Ticket SHOULD normally produce one Boarding event.

The Boarding Module manages operational boarding activities only.

The Boarding Module MUST remain independent from Ticket Pricing, Payment Processing, Route Planning, Vehicle Registration, and Driver Management.

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

- What is Boarding?
- Difference between Booking, Ticket, and Boarding
- Relationship with Passenger
- Relationship with Trip
- Relationship with Ticket
- Relationship with Conductor

7. Responsibilities

The Boarding Module MUST manage:

- Boarding Record
- Boarding Time
- Boarding Location
- Boarding Method
- Passenger Validation
- Ticket Validation
- Seat Confirmation
- Boarding Status
- Boarding Operator
- Boarding Notes

The Boarding Module MUST NOT manage:

- Ticket Pricing
- Payment Processing
- Driver Assignment
- Route Planning
- Vehicle Registration

8. Boarding Lifecycle

Describe:

Pending

↓

Validated

↓

Boarded

↓

Completed

OR

Rejected

↓

Cancelled

↓

Archived

Include state transition rules.

9. Boarding Types

Describe:

- Terminal Boarding
- Roadside Boarding
- Manual Boarding
- QR Boarding
- Staff Boarding
- Emergency Boarding

10. Passenger Validation

Describe:

- Ticket Validation
- Identity Verification
- Seat Validation
- Duplicate Boarding Prevention
- Trip Validation

11. Boarding Methods

Describe:

- QR Code Scan
- Barcode Scan
- Manual Ticket Number
- Passenger Search
- Offline Boarding

12. Roadside Boarding

Describe:

- Passenger added after departure
- Manual seat assignment
- Cash collection reference
- Ticket creation reference
- Offline operation
- GPS/location capture (optional)

13. Integrations

Describe interaction with:

- Passenger Module
- Booking Module
- Ticket Module
- Trip Module
- Payment Module
- Conductor Module
- Reporting Module
- Audit Module

14. Events

Include:

- Boarding Started
- Passenger Validated
- Passenger Boarded
- Boarding Rejected
- Roadside Boarding Recorded
- Boarding Completed

15. Permissions

Describe who MAY:

- Start Boarding
- Validate Passenger
- Record Boarding
- Reject Boarding
- Cancel Boarding
- View Boarding History

16. Validation Rules

Describe:

- Ticket Validation
- Trip Validation
- Duplicate Boarding Prevention
- Seat Validation
- Boarding Window Validation

17. Offline Behavior

Describe:

- Offline Passenger Lookup
- Offline Ticket Validation
- Offline Boarding Recording
- Deferred Synchronization
- Conflict Resolution

18. Audit Requirements

Every Boarding event MUST be auditable.

Every validation result MUST be auditable.

Every rejected Boarding MUST be traceable.

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Boarding MUST reference exactly one Trip.
- Every Boarding MUST reference exactly one Passenger.
- One Ticket SHOULD normally produce one Boarding.
- Duplicate Boarding MUST be prevented.
- Roadside Boarding MUST reference an active Trip.
- Completed Boarding records MUST remain immutable.

20. KPIs

Examples:

- Boarding Time
- Average Boarding Duration
- Boarding Success Rate
- Duplicate Boarding Attempts
- No Show Rate
- Roadside Boarding Count

21. Error Scenarios

Describe:

- Duplicate Boarding
- Invalid Ticket
- Wrong Trip
- Seat Conflict
- Offline Synchronization Conflict
- Expired Ticket

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe support for:

- Facial Recognition
- NFC Boarding
- Biometric Boarding
- AI Fraud Detection
- Smart Boarding Gates
- GPS Boarding Verification

24. References

Reference related Architecture documents, ADRs, and Module Specifications.

25. Glossary

26. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Boarding Preparation
- Passenger Validation
- Terminal Boarding
- Roadside Boarding
- Offline Boarding
- Boarding Completion

--------------------------------------------------
Mandatory Business Rules

Every Boarding MUST belong to exactly one Company.

Every Boarding MUST reference exactly one Trip.

Every Boarding MUST reference exactly one Passenger.

Duplicate Boarding MUST NOT be allowed.

Roadside Boarding MUST always reference an active Trip.

Completed Boarding records MUST remain immutable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation operations-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants