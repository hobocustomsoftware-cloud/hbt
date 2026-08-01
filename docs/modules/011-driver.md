You are a Distinguished Enterprise Transportation Architect, Fleet Operations Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/011-driver.md

Purpose:

Define the Driver Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how drivers are registered, qualified, managed, and made available for transportation operations.

A Driver represents a certified transportation operator who MAY be assigned to operational trips.

The Driver Module manages driver master data, qualifications, certifications, and operational availability.

The Driver Module MUST remain independent from Trip execution, Booking, Ticketing, Passenger Management, and Payment processing.

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

- What is a Driver?
- Relationship with Company
- Relationship with Branch
- Relationship with Vehicle
- Relationship with Trip

7. Driver Responsibilities

Describe operational responsibilities including:

- Safe Vehicle Operation
- Passenger Safety
- Trip Execution
- Vehicle Inspection
- Compliance with Regulations
- Incident Reporting

8. Responsibilities

The Driver Module MUST manage:

- Driver Profile
- Employee Number
- Driver Code
- License Information
- License Class
- License Expiry
- Certifications
- Medical Fitness
- Contact Information
- Emergency Contact
- Branch Assignment
- Employment Status
- Operational Status

The Driver Module MUST NOT manage:

- Vehicle Assignment
- Trip Scheduling
- Passenger Boarding
- Ticket Sales
- Payroll
- Payment Processing

9. Driver Lifecycle

Describe:

Recruitment

↓

Verification

↓

Certification

↓

Active

↓

Suspended

↓

Inactive

↓

Retired

↓

Archived

10. Driver Qualifications

Describe:

- License Categories
- Driving Experience
- Authorized Vehicle Categories
- Medical Clearance
- Safety Training
- Regulatory Compliance

11. Operational Availability

Describe possible states:

- Available
- Assigned
- On Duty
- Off Duty
- Leave
- Suspended
- Retired

12. Compliance Requirements

Describe:

- License Renewal
- Medical Checkups
- Regulatory Audits
- Safety Certifications

13. Integrations

Describe interaction with:

- Branch Module
- Vehicle Module
- Conductor Module
- Schedule Module
- Trip Module
- Reporting Module
- Audit Module

14. Events

Include:

- Driver Registered
- Driver Verified
- Driver Certified
- Driver Activated
- Driver Suspended
- License Renewed
- Driver Retired

15. Permissions

Describe who MAY:

- Register Driver
- Update Driver
- Verify Qualifications
- Activate Driver
- Suspend Driver
- Archive Driver
- View Driver

16. Validation Rules

Describe:

- Unique Driver Code
- Unique License Number
- License Expiry Validation
- Medical Fitness Validation
- Vehicle Category Authorization

17. Offline Behavior

Describe:

- Offline Driver Lookup
- Cached Qualification Data
- Synchronization Rules

18. Audit Requirements

Every Driver modification MUST be auditable.

Every qualification change MUST be auditable.

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Driver MUST belong to exactly one Company.
- Every Driver MUST belong to exactly one Branch.
- Every Driver MUST possess at least one valid license.
- Expired licenses MUST prevent operational assignment.
- Suspended Drivers MUST NOT be assigned to Trips.
- Driver history MUST remain immutable.

20. KPIs

Examples:

- Active Drivers
- License Compliance Rate
- Driver Availability
- Safety Incidents
- Training Completion Rate
- Trip Completion Rate

21. Error Scenarios

Describe:

- Duplicate License Number
- Expired License
- Missing Medical Clearance
- Invalid Branch Assignment
- Suspended Driver Assignment

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe support for:

- Digital Driver License
- Biometric Verification
- Driver Mobile App
- GPS Driver Check-In
- AI Driver Performance Analysis
- Fatigue Detection
- Compliance Monitoring

24. References

Reference related Architecture documents, ADRs, and Module Specifications.

25. Glossary

26. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Driver Registration
- Qualification Verification
- License Renewal
- Availability Management
- Operational Assignment
- Retirement

--------------------------------------------------
Mandatory Business Rules

Every Driver MUST belong to exactly one Company.

Every Driver MUST belong to exactly one Branch.

Every Driver MUST possess a valid operational license.

Only Available Drivers MAY be assigned to Trips.

Expired licenses MUST automatically invalidate operational eligibility.

Driver operational history MUST remain immutable and auditable.

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