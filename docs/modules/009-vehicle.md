You are a Distinguished Enterprise Transportation Architect, Fleet Management Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/009-vehicle.md

Purpose:

Define the Vehicle Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how transportation vehicles are defined, managed, and governed across the platform.

A Vehicle represents a transportation asset that MAY be assigned to operational trips.

The Vehicle Module is responsible for maintaining vehicle master data and operational availability.

The Vehicle Module MUST remain independent from Trip execution, Driver assignment, Ticket Sales, Passenger Management, and Payment processing.

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

- What is a Vehicle?
- Transportation Asset
- Relationship with Company
- Relationship with Branch
- Relationship with Trips
- Relationship with Seat Layout

7. Vehicle Categories

Describe support for:

- Express Bus
- Mini Bus
- Cargo Truck
- Taxi
- Motorcycle
- Shuttle
- Future Vehicle Types

8. Responsibilities

The Vehicle Module MUST manage:

- Vehicle Profile
- Vehicle Registration Number
- Fleet Number
- Vehicle Type
- Vehicle Category
- Brand
- Model
- Manufacturing Year
- Color
- Capacity
- Seat Layout Reference
- Operational Status
- Branch Assignment

The Vehicle Module MUST NOT manage:

- Driver Assignment
- Trip Execution
- Passenger Boarding
- Ticket Sales
- Payments
- Maintenance Work Orders

9. Vehicle Lifecycle

Describe:

Draft

↓

Registration

↓

Verification

↓

Operational

↓

Maintenance

↓

Suspended

↓

Retired

↓

Archived

10. Vehicle Information

Describe:

- Vehicle Code
- Registration Number
- Fleet Number
- Chassis Number (if applicable)
- Engine Number (if applicable)
- Brand
- Model
- Year
- Capacity
- Fuel Type

11. Operational Capabilities

Describe:

- Passenger Transport
- Cargo Transport
- VIP Service
- Air Conditioning
- Wi-Fi
- GPS Availability
- Accessibility Support

12. Vehicle Assignment

Describe relationships with:

- Branch
- Route Compatibility
- Seat Layout
- Future Driver Assignment
- Future Trip Assignment

13. Operational Status

Describe possible states:

- Available
- Reserved
- In Service
- Under Maintenance
- Out of Service
- Retired

14. Integrations

Describe interaction with:

- Branch Module
- Route Module
- Seat Layout Module
- Driver Module
- Trip Module
- Reporting Module
- Audit Module

15. Events

Include:

- Vehicle Registered
- Vehicle Verified
- Vehicle Activated
- Vehicle Updated
- Vehicle Suspended
- Vehicle Retired

16. Permissions

Describe who MAY:

- Register Vehicle
- Update Vehicle
- Activate Vehicle
- Suspend Vehicle
- Archive Vehicle
- View Vehicle

17. Validation Rules

Describe:

- Unique Registration Number
- Unique Fleet Number
- Capacity Validation
- Vehicle Type Validation
- Seat Layout Compatibility

18. Offline Behavior

Describe:

- Offline Vehicle Lookup
- Cached Vehicle Information
- Synchronization Rules

19. Audit Requirements

Every Vehicle modification MUST be auditable.

20. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Vehicle MUST belong to exactly one Company.
- Every Vehicle MUST be assigned to exactly one Branch.
- Every Vehicle MUST have one Vehicle Category.
- Every Vehicle MAY reference one Seat Layout.
- Registration numbers MUST remain unique.
- Archived Vehicles MUST become read-only.

21. KPIs

Examples:

- Active Vehicles
- Fleet Availability
- Fleet Utilization
- Average Capacity Utilization
- Vehicle Downtime
- Vehicles Under Maintenance

22. Error Scenarios

Describe:

- Duplicate Registration Number
- Invalid Vehicle Category
- Capacity Mismatch
- Invalid Branch Assignment
- Archived Vehicle Modification

23. Dependencies

Describe upstream and downstream dependencies.

24. Future Expansion

Describe support for:

- Electric Vehicles
- Autonomous Vehicles
- IoT Integration
- Live GPS Tracking
- Predictive Maintenance
- Fleet Optimization
- Carbon Emission Reporting

25. References

Reference related Architecture documents, ADRs, and Module Specifications.

26. Glossary

27. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Vehicle Registration
- Vehicle Verification
- Vehicle Activation
- Branch Assignment
- Operational Availability
- Vehicle Retirement

--------------------------------------------------
Mandatory Business Rules

Every Vehicle MUST belong to exactly one Company.

Every Vehicle MUST belong to exactly one Branch.

Every Vehicle MUST have one Vehicle Category.

Seat Layout compatibility MUST be validated before assignment.

Only Operational Vehicles MAY be assigned to Trips.

Vehicle operational history MUST remain immutable and auditable.

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