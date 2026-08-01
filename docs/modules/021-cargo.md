You are a Distinguished Enterprise Logistics Architect, Transportation Cargo Systems Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/021-cargo.md

Purpose:

Define the Cargo Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how cargo shipments are registered, transported, tracked, delivered, and audited.

The Cargo Module supports parcel, package, document, and freight transportation using company-operated vehicles.

Cargo operations MUST remain independent from Passenger operations.

A Cargo Shipment is NOT a Passenger Booking.

A Cargo Shipment is NOT a Passenger Ticket.

The Cargo Module manages cargo transportation operations only.

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

- What is Cargo?
- Difference between Cargo and Passenger
- Difference between Cargo Shipment and Booking
- Relationship with Trip
- Relationship with Vehicle
- Relationship with Branch
- Relationship with Payment

7. Responsibilities

The Cargo Module MUST manage:

- Cargo Number
- Shipment Number
- Cargo Status
- Sender
- Receiver
- Pickup Branch
- Destination Branch
- Pickup Date
- Expected Delivery Date
- Actual Delivery Date
- Cargo Type
- Package Count
- Weight
- Dimensions
- Declared Value
- Freight Charge
- Cargo Notes

The Cargo Module MUST NOT manage:

- Passenger Tickets
- Passenger Boarding
- Payroll
- Driver Scheduling
- Route Planning

8. Cargo Lifecycle

Describe:

Registered

↓

Accepted

↓

Loaded

↓

In Transit

↓

Arrived

↓

Ready for Pickup

↓

Delivered

OR

Returned

↓

Cancelled

↓

Archived

Include state transition rules.

9. Cargo Types

Describe:

- Parcel
- Document
- Box
- Fragile Goods
- Oversized Cargo
- Temperature Sensitive Goods
- High Value Goods

10. Cargo Acceptance

Describe:

- Sender Verification
- Receiver Information
- Package Inspection
- Weight Verification
- Dimension Verification
- Restricted Goods Validation

11. Cargo Loading

Describe:

- Vehicle Assignment
- Trip Assignment
- Loading Sequence
- Capacity Validation
- Loading Confirmation

12. Cargo Delivery

Describe:

- Branch Pickup
- Home Delivery (Future)
- Receiver Verification
- Delivery Confirmation
- Failed Delivery
- Return Process

13. Tracking

Describe:

- Shipment Status
- Current Branch
- Current Trip
- Delivery Progress
- Estimated Arrival

14. Integrations

Describe interaction with:

- Trip Module
- Vehicle Module
- Branch Module
- Payment Module
- Reporting Module
- Notification Module
- Audit Module

15. Events

Include:

- Cargo Registered
- Cargo Accepted
- Cargo Loaded
- Cargo Departed
- Cargo Arrived
- Cargo Delivered
- Cargo Returned

16. Permissions

Describe who MAY:

- Register Cargo
- Accept Cargo
- Assign Trip
- Load Cargo
- Deliver Cargo
- Return Cargo
- View Cargo

17. Validation Rules

Describe:

- Weight Validation
- Dimension Validation
- Restricted Goods Validation
- Vehicle Capacity Validation
- Receiver Validation

18. Offline Behavior

Describe:

- Offline Registration
- Offline Delivery
- Deferred Synchronization
- Conflict Resolution

19. Audit Requirements

Every Cargo movement MUST be auditable.

Every status change MUST be recorded.

Every delivery confirmation MUST be traceable.

20. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Cargo MUST belong to exactly one Company.
- Every Cargo MUST have exactly one Sender.
- Every Cargo MUST have exactly one Receiver.
- Cargo MUST reference at least one Trip.
- Delivered Cargo MUST become immutable.
- Restricted goods MUST NOT be accepted.

21. KPIs

Examples:

- Cargo Volume
- Delivery Success Rate
- Average Delivery Time
- Return Rate
- Capacity Utilization
- Revenue by Cargo

22. Error Scenarios

Describe:

- Missing Receiver
- Overweight Cargo
- Vehicle Capacity Exceeded
- Duplicate Shipment
- Delivery Failure
- Offline Synchronization Conflict

23. Dependencies

Describe upstream and downstream dependencies.

24. Future Expansion

Describe support for:

- Multi-leg Logistics
- Warehouse Management
- Barcode Tracking
- QR Tracking
- RFID
- GPS Cargo Tracking
- Cold Chain Logistics
- AI Route Optimization

25. References

Reference related Architecture documents, ADRs, and Module Specifications.

26. Glossary

27. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Cargo Registration
- Cargo Acceptance
- Trip Assignment
- Cargo Loading
- Cargo Transportation
- Cargo Delivery
- Cargo Return

--------------------------------------------------
Mandatory Business Rules

Every Cargo MUST belong to exactly one Company.

Every Cargo MUST reference at least one Trip.

Every Cargo MUST have one Sender and one Receiver.

Delivered Cargo MUST remain immutable.

Every Cargo movement MUST be fully auditable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation logistics-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants