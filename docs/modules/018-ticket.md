You are a Distinguished Enterprise Transportation Architect, Ticketing Systems Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/018-ticket.md

Purpose:

Define the Ticket Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how transportation tickets are issued, validated, managed, reissued, cancelled, and linked to passenger journeys.

A Ticket represents the authorization for a Passenger to travel on a specific Trip.

A Ticket is NOT a Booking.

A Ticket is NOT a Payment.

A Ticket MAY be issued from a Booking or directly at the ticket counter, depending on business policy.

The Ticket Module manages transportation ticket information only.

The Ticket Module MUST remain independent from Payment Settlement, Cash Settlement, Vehicle Management, Route Planning, and Driver Management.

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

- What is a Ticket?
- Difference between Booking and Ticket
- Difference between Ticket and Payment
- Relationship with Passenger
- Relationship with Trip
- Relationship with Boarding

7. Responsibilities

The Ticket Module MUST manage:

- Ticket Number
- Ticket Type
- Ticket Status
- Issue Date
- Passenger Reference
- Trip Reference
- Seat Assignment
- Boarding Point
- Drop-off Point
- Fare Snapshot
- Issuing Channel
- Issuing Operator

The Ticket Module MUST NOT manage:

- Payment Processing
- Cash Settlement
- Driver Assignment
- Vehicle Registration
- Route Definition

8. Ticket Lifecycle

Describe:

Draft

↓

Issued

↓

Validated

↓

Boarded

↓

Completed

OR

Cancelled

↓

Refunded (Business Policy Dependent)

↓

Archived

Include state transition rules.

9. Ticket Types

Describe:

- Standard Ticket
- VIP Ticket
- Staff Ticket
- Complimentary Ticket
- Child Ticket
- Corporate Ticket
- Manual Ticket
- Electronic Ticket

10. Ticket Issuance

Describe:

- Counter Issuance
- Booking Conversion
- Walk-in Passenger
- Roadside Ticket
- Manual Ticket
- Electronic Ticket

11. Ticket Validation

Describe:

- QR Validation
- Barcode Validation
- Manual Validation
- Passenger Verification
- Boarding Verification

12. Fare Snapshot

Describe:

Every Ticket MUST preserve:

- Fare
- Discounts
- Taxes
- Service Charges

Historical fare information MUST remain immutable.

13. Integrations

Describe interaction with:

- Booking Module
- Passenger Module
- Trip Module
- Boarding Module
- Payment Module
- Reporting Module
- Audit Module

14. Events

Include:

- Ticket Issued
- Ticket Updated
- Ticket Cancelled
- Ticket Validated
- Passenger Boarded
- Ticket Completed

15. Permissions

Describe who MAY:

- Issue Ticket
- Update Ticket
- Validate Ticket
- Cancel Ticket
- Reissue Ticket
- View Ticket

16. Validation Rules

Describe:

- Ticket Number Uniqueness
- Trip Validation
- Passenger Validation
- Seat Validation
- Duplicate Ticket Prevention

17. Offline Behavior

Describe:

- Offline Ticket Issuance
- Offline Validation
- Offline QR Verification
- Deferred Synchronization
- Conflict Resolution

18. Audit Requirements

Every Ticket event MUST be auditable.

Every fare modification MUST be auditable.

Every cancellation MUST be traceable.

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Ticket MUST reference exactly one Passenger.
- Every Ticket MUST reference exactly one Trip.
- One Passenger MAY possess multiple Tickets over time.
- One active Ticket MUST reserve only one Seat.
- Cancelled Tickets MUST release reserved resources according to company policy.
- Completed Tickets MUST remain immutable.

20. KPIs

Examples:

- Tickets Issued
- Tickets Cancelled
- Ticket Validation Rate
- Boarding Success Rate
- Electronic Ticket Usage
- Manual Ticket Usage

21. Error Scenarios

Describe:

- Duplicate Ticket
- Invalid Trip
- Invalid Passenger
- Seat Conflict
- Duplicate Validation
- Offline Synchronization Conflict

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe support for:

- Dynamic QR Tickets
- NFC Tickets
- Digital Wallet Tickets
- Multi-Leg Tickets
- Transfer Tickets
- AI Fraud Detection
- Blockchain Ticket Verification

24. References

Reference related Architecture documents, ADRs, and Module Specifications.

25. Glossary

26. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Ticket Issuance
- Booking Conversion
- Walk-in Ticket Sale
- Roadside Ticket Issuance
- Ticket Validation
- Ticket Cancellation
- Ticket Reissue

--------------------------------------------------
Mandatory Business Rules

Every Ticket MUST belong to exactly one Company.

Every Ticket MUST reference exactly one Passenger.

Every Ticket MUST reference exactly one Trip.

Every active Ticket MUST reserve one Seat.

Completed Tickets MUST remain immutable.

Historical fare information MUST remain immutable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation ticketing-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants