You are a Distinguished Enterprise Transportation Architect, Reservation Systems Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/016-booking.md

Purpose:

Define the Booking Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how transportation bookings are created, managed, confirmed, modified, cancelled, and linked to operational trips.

A Booking represents a reservation for one or more passengers on a planned Trip.

A Booking is NOT a Ticket.

One Booking MAY contain multiple Passengers.

Each Passenger MAY later receive an individual Ticket.

The Booking Module manages reservation information only.

The Booking Module MUST remain independent from Ticket issuance, Payment processing, Boarding execution, and Cash Settlement.

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

- What is a Booking?
- Difference between Booking and Ticket
- Difference between Booking and Reservation
- Relationship with Passenger
- Relationship with Trip
- Relationship with Ticket
- Relationship with Payment

7. Responsibilities

The Booking Module MUST manage:

- Booking Number
- Booking Date
- Booking Channel
- Booking Status
- Trip Reference
- Passenger List
- Reserved Seats
- Contact Person
- Contact Phone
- Pickup Point
- Drop-off Point
- Booking Notes

The Booking Module MUST NOT manage:

- Ticket Printing
- Payment Settlement
- Driver Assignment
- Vehicle Assignment
- Route Planning
- Boarding Operations

8. Booking Lifecycle

Describe:

Draft

↓

Reserved

↓

Confirmed

↓

Modified

↓

Cancelled

↓

Expired

↓

Completed

↓

Archived

Include state transition rules.

9. Booking Types

Describe:

- Individual Booking
- Group Booking
- Family Booking
- Corporate Booking
- Agent Booking
- Walk-in Booking
- Online Booking

10. Seat Reservation

Describe:

- Seat Reservation
- Seat Hold
- Seat Release
- Seat Change
- Seat Availability Validation

11. Booking Channels

Describe:

- Counter
- Agent
- Mobile App
- Website
- Call Center
- API Integration

12. Integrations

Describe interaction with:

- Passenger Module
- Trip Module
- Ticket Module
- Payment Module
- Boarding Module
- Reporting Module
- Audit Module

13. Events

Include:

- Booking Created
- Booking Confirmed
- Booking Modified
- Booking Cancelled
- Booking Expired
- Booking Completed

14. Permissions

Describe who MAY:

- Create Booking
- Update Booking
- Confirm Booking
- Cancel Booking
- View Booking
- Archive Booking

15. Validation Rules

Describe:

- Trip Validation
- Seat Availability Validation
- Duplicate Booking Prevention
- Passenger Validation
- Booking Expiry Validation

16. Offline Behavior

Describe:

- Offline Booking Creation
- Offline Seat Reservation
- Synchronization Rules
- Conflict Resolution

17. Audit Requirements

Every Booking modification MUST be auditable.

Every status change MUST be auditable.

Every seat reservation MUST be traceable.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Booking MUST reference exactly one Trip.
- One Booking MAY include multiple Passengers.
- One Passenger MAY appear in multiple Bookings over time.
- Reserved Seats MUST NOT be double-booked.
- Cancelled Bookings MUST release reserved seats.
- Completed Bookings MUST become immutable.

19. KPIs

Examples:

- Booking Count
- Booking Conversion Rate
- Cancellation Rate
- Seat Utilization
- Group Booking Percentage
- Online Booking Percentage

20. Error Scenarios

Describe:

- Duplicate Booking
- Seat Already Reserved
- Invalid Trip
- Booking Expired
- Passenger Duplication
- Offline Synchronization Conflict

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Waitlist Management
- Dynamic Seat Allocation
- Promotional Reservations
- Loyalty Reservations
- AI Booking Prediction
- Multi-Leg Journey Booking

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Booking Creation
- Seat Reservation
- Booking Confirmation
- Passenger Assignment
- Booking Modification
- Booking Cancellation
- Seat Release

--------------------------------------------------
Mandatory Business Rules

Every Booking MUST belong to exactly one Company.

Every Booking MUST reference exactly one Trip.

One Booking MAY contain multiple Passengers.

Reserved Seats MUST remain unique within a Trip.

Cancelled Bookings MUST automatically release reserved seats.

Completed Bookings MUST remain immutable and fully auditable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation reservation-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants