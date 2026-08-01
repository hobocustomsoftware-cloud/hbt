You are a Distinguished Enterprise Solution Architect, Business Process Architect, Domain-Driven Design (DDD) Expert, Enterprise Workflow Architect, Transportation Domain Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/workflows/002-booking-workflow.md

Purpose:

Define the Booking Workflow for the HoBo Transport Platform (HBT).

This document describes the complete business workflow for passenger booking from the initial booking request until the booking reaches its final business outcome.

This document defines business workflow governance only.

This document is NOT an implementation guide.

This document is NOT an API specification.

This document is NOT a database design.

This document MUST remain technology-neutral.

No implementation details.

No framework-specific guidance.

No programming language examples.

No source code.

The document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI Coding Assistants

--------------------------------------------------
Include the following sections
--------------------------------------------------

# Booking Workflow

## 1. Purpose

Explain the purpose of the booking workflow and its role within passenger transportation operations.

---

## 2. Executive Summary

Describe how a booking represents the customer's intention to reserve transportation services and how it coordinates multiple business modules.

---

## 3. Scope

### In Scope

Include:

- Passenger booking
- Trip selection
- Seat reservation
- Booking lifecycle
- Booking validation
- Booking confirmation
- Booking cancellation
- Booking expiration

### Out of Scope

Exclude:

- Payment processing
- Ticket issuance
- Boarding
- Cash settlement
- Cargo operations
- System implementation

---

## 4. Workflow Objectives

Describe objectives including:

- Reliable reservation
- Accurate seat allocation
- Business rule enforcement
- Operational consistency
- Customer confidence

---

## 5. Business Actors

Describe responsibilities of:

- Passenger
- Booking Officer
- Customer Service
- System
- External Partner (if applicable)

---

## 6. Trigger

Describe business events that may initiate the workflow, such as:

- Passenger requests a booking
- Booking created by an operator
- Booking received from an external partner

---

## 7. Preconditions

Describe conditions that SHOULD exist before booking can proceed, including:

- Passenger information available
- Trip available
- Schedule available
- Seats available
- Booking window open

---

## 8. Main Workflow

Describe the normal business flow from booking request through successful booking completion.

Use business language only.

Avoid implementation details.

---

## 9. Alternative Flows

Examples include:

- Seat unavailable
- Passenger changes seat
- Schedule changed before confirmation
- Booking modified before confirmation

---

## 10. Exception Flows

Examples include:

- Trip cancelled
- Booking rejected
- Booking expired
- Invalid passenger information
- Business rule violation

---

## 11. Postconditions

Describe the expected business state after workflow completion, including:

- Booking confirmed
- Booking cancelled
- Booking expired
- Booking rejected

---

## 12. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- A booking MUST belong to exactly one passenger.
- A booking MUST reference one trip.
- Reserved seats MUST NOT exceed available capacity.
- Expired bookings MUST NOT remain active.
- Booking modifications SHOULD follow business policy.
- Booking cancellation MUST preserve auditability.
- Booking status transitions MUST be traceable.

---

## 13. Booking State Transition

Describe conceptual booking states such as:

- Draft
- Pending
- Confirmed
- Cancelled
- Expired
- Rejected

Explain valid business transitions without implementation.

---

## 14. Related Domain Events

Describe conceptual business events including:

- Booking Created
- Booking Updated
- Booking Confirmed
- Booking Cancelled
- Booking Expired
- Booking Rejected

---

## 15. Related Modules

Reference:

- Passenger
- Route
- Schedule
- Trip
- Seat Layout
- Payment
- Ticket
- Notification
- Audit

Explain how they participate in the workflow.

---

## 16. Related APIs

Reference conceptually:

- Booking API
- Passenger API
- Trip API
- Notification API

Do not describe endpoints.

---

## 17. Security Considerations

Describe:

- Passenger privacy
- Booking ownership
- Authorization
- Auditability
- Data integrity

---

## 18. Audit Considerations

Describe why booking creation, modification, cancellation, expiration, and confirmation SHOULD be auditable.

---

## 19. Failure Recovery Considerations

Describe conceptual recovery expectations for:

- Interrupted booking process
- Duplicate booking attempts
- Temporary operational failures
- Retry scenarios

---

## 20. References

Reference:

- Workflow README
- Booking Module
- Passenger Module
- Trip Module
- Payment Module
- Ticket Module
- API Documentation
- Architecture Documentation

---

## 21. Glossary

Include definitions for:

- Booking
- Reservation
- Passenger
- Trip
- Confirmation
- Cancellation
- Expiration
- Booking Lifecycle

---

## 22. Summary

Summarize how the booking workflow provides a consistent, auditable, reliable, and business-oriented process for reserving passenger transportation services across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Business-oriented

Architecture-focused

Workflow-focused

Governance-focused

Documentation-first

Technology-neutral

Vendor-neutral

No implementation details

No framework-specific guidance

No programming language examples

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)