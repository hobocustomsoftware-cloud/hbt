You are a Distinguished Enterprise Transportation Architect, Passenger Operations Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/015-passenger.md

Purpose:

Define the Passenger Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how passenger information is managed throughout transportation operations.

A Passenger represents the individual who travels on a Trip.

A Passenger is NOT necessarily the Customer who purchases the ticket.

The Passenger Module manages passenger identity, travel information, operational status, and travel history.

The Passenger Module MUST remain independent from Booking, Payment, Ticket Pricing, Route Planning, and Trip Scheduling.

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

- What is a Passenger?
- Difference between Passenger and Customer
- Relationship with Booking
- Relationship with Ticket
- Relationship with Boarding
- Relationship with Trip

7. Responsibilities

The Passenger Module MUST manage:

- Passenger Profile
- Passenger Code
- Full Name
- Gender
- Date of Birth
- Phone Number
- National Identification (Optional)
- Passport (Optional)
- Emergency Contact
- Travel Notes
- Special Assistance Requirements

The Passenger Module MUST NOT manage:

- Ticket Pricing
- Payments
- Vehicle Assignment
- Driver Assignment
- Route Planning

8. Passenger Lifecycle

Describe:

Registered

↓

Booked

↓

Checked-In

↓

Boarded

↓

Traveling

↓

Completed

↓

Archived

9. Passenger Categories

Describe:

- Adult
- Child
- Infant
- Senior Citizen
- VIP
- Staff Passenger

10. Passenger Services

Describe support for:

- Seat Preference
- Special Assistance
- Wheelchair Support
- Elderly Assistance
- Child Passenger
- Medical Notes

11. Operational Status

Describe:

- Booked
- Checked-In
- Boarded
- No Show
- Cancelled
- Completed

12. Integrations

Describe interaction with:

- Booking Module
- Ticket Module
- Boarding Module
- Trip Module
- Reporting Module
- Audit Module

13. Events

Include:

- Passenger Registered
- Passenger Updated
- Passenger Checked-In
- Passenger Boarded
- Passenger No Show
- Passenger Completed Journey

14. Permissions

Describe who MAY:

- Register Passenger
- Update Passenger
- View Passenger
- Archive Passenger

15. Validation Rules

Describe:

- Identity Validation
- Duplicate Passenger Prevention
- Contact Validation
- Boarding Validation

16. Offline Behavior

Describe:

- Offline Passenger Lookup
- Offline Boarding Validation
- Synchronization Rules

17. Audit Requirements

Every Passenger modification MUST be auditable.

Every travel event MUST be auditable.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Passenger MUST have a unique Passenger Code.
- One Passenger MAY have many Bookings over time.
- One Passenger MAY travel on many Trips.
- Passenger history MUST remain immutable.
- Passenger identity SHOULD be reusable across future journeys.

19. KPIs

Examples:

- Total Passengers
- Repeat Passenger Rate
- Passenger Completion Rate
- No Show Rate
- Passenger Satisfaction

20. Error Scenarios

Describe:

- Duplicate Passenger
- Invalid Identity
- Duplicate Boarding
- Missing Contact Information

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Passenger Loyalty Program
- Digital Identity
- Biometric Verification
- AI Passenger Preferences
- Cross-Company Passenger Profiles

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Passenger Registration
- Passenger Identification
- Boarding Validation
- Journey Completion
- Passenger History Management

--------------------------------------------------
Mandatory Business Rules

Every Passenger MUST belong to exactly one Company.

Every Passenger MAY have multiple Bookings.

Every Passenger MAY travel on multiple Trips.

Passenger history MUST remain immutable.

Passenger identity SHOULD be reusable across future journeys.

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