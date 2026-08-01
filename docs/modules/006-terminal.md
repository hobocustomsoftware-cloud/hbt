You are a Distinguished Enterprise Transportation Architect, Operations Architect, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/006-terminal.md

Purpose:

Define the Terminal Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how transportation terminals operate within the platform.

A Terminal represents an operational hub where passengers, vehicles, trips, staff, and transportation services are coordinated.

A Terminal is NOT merely a physical location. It is an operational business unit responsible for passenger handling, vehicle dispatching, boarding, arrival processing, and local operational management.

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

- What is a Terminal?
- Operational Responsibilities
- Passenger Service Responsibilities
- Vehicle Coordination
- Relationship with Branch
- Relationship with Trips

7. Responsibilities

The Terminal Module MUST manage:

- Terminal Profile
- Terminal Status
- Ticket Counters
- Boarding Gates
- Departure Areas
- Arrival Areas
- Waiting Areas
- Passenger Flow
- Operational Configuration
- Terminal Operating Hours

The Terminal Module MUST NOT manage:

- Ticket Pricing
- Vehicle Maintenance
- Authentication
- Payment Processing
- Route Planning

8. Terminal Lifecycle

Describe:

Creation

↓

Verification

↓

Activation

↓

Operational

↓

Temporary Closure

↓

Permanent Closure

↓

Archive

9. Terminal Information

Describe:

- Terminal Name
- Terminal Code
- Address
- Geographic Coordinates
- Contact Information
- Business Hours
- Supported Services

10. Operational Areas

Describe:

- Ticket Counters
- Check-In Area
- Boarding Gates
- Waiting Area
- Arrival Area
- Cargo Area
- Customer Service Desk

11. Passenger Operations

Describe:

- Ticket Sales
- Reservation Validation
- Passenger Check-In
- Boarding Control
- Arrival Processing
- Passenger Assistance

12. Vehicle Operations

Describe:

- Vehicle Arrival
- Platform Assignment
- Departure Authorization
- Vehicle Departure
- Vehicle Return

13. Terminal Resources

Describe management of:

- Gates
- Counters
- Staff
- Equipment
- Local Assets

14. Integrations

Describe interaction with:

- Branch Module
- Route Module
- Trip Module
- Ticket Module
- Boarding Module
- Notification Module
- Audit Module

15. Events

Include:

- Terminal Created
- Terminal Activated
- Terminal Closed
- Check-In Started
- Boarding Started
- Boarding Completed
- Departure Authorized
- Arrival Confirmed

16. Permissions

Describe who MAY:

- Create Terminal
- Update Terminal
- Open Terminal
- Close Terminal
- Assign Gates
- Manage Operations

17. Validation Rules

Describe:

- Unique Terminal Code
- Operating Hours
- Gate Availability
- Counter Availability

18. Offline Behavior

Describe:

- Offline Check-In
- Offline Boarding
- Offline Ticket Validation
- Offline Queue Management
- Synchronization
- Conflict Resolution

19. Audit Requirements

Every operational event at a Terminal MUST be auditable.

20. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Terminal MUST belong to exactly one Branch.
- Every Trip MUST depart from one Terminal.
- Every Trip MUST arrive at one Terminal.
- Boarding MUST occur only at authorized locations.
- Closed Terminals MUST NOT process departures.
- Terminal operational history MUST remain immutable.

21. KPIs

Examples:

- Daily Passenger Count
- On-Time Departure Rate
- Boarding Duration
- Gate Utilization
- Counter Utilization
- Customer Waiting Time

22. Error Scenarios

Describe:

- Gate Unavailable
- Terminal Closed
- Boarding Failure
- Passenger Overflow
- Network Failure
- Offline Synchronization Failure

23. Dependencies

Describe upstream and downstream dependencies.

24. Future Expansion

Describe support for:

- Smart Terminals
- Self Check-In
- QR Gate Validation
- Facial Recognition
- Automated Boarding
- AI Assisted Terminal Operations

25. References

Reference related Architecture documents, ADRs, and Module Specifications.

26. Glossary

27. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Counter Ticket Sales
- Passenger Check-In
- Boarding
- Departure Control
- Arrival Processing
- Roadside Passenger Coordination
- Daily Terminal Opening
- Daily Terminal Closing

--------------------------------------------------
Mandatory Business Rules

Every Terminal MUST belong to exactly one Branch.

Every Trip MUST have one Departure Terminal.

Every Trip MUST have one Arrival Terminal.

Every Boarding Event MUST belong to one Terminal unless explicitly marked as Roadside Boarding.

Offline terminal operations MUST synchronize safely.

Terminal operational history MUST remain auditable.

The Terminal Module MUST remain independent from Pricing, Authentication, and Payment modules.

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