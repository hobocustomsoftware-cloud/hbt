You are a Distinguished Enterprise Solution Architect, Transportation Logistics Expert, Business Process Architect, Domain-Driven Design (DDD) Expert, Enterprise Workflow Architect, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/workflows/010-cargo-workflow.md

Purpose:

Define the Cargo Workflow for the HoBo Transport Platform (HBT).

This document describes the complete business workflow for transporting cargo from shipment request through delivery completion.

This document defines business workflow governance only.

This document is NOT an implementation guide.

This document is NOT a warehouse management guide.

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

# Cargo Workflow

## 1. Purpose

Explain the purpose of cargo transportation and its role within the HoBo Transport Platform.

---

## 2. Executive Summary

Describe how cargo transportation operates independently from passenger transportation while sharing operational resources such as vehicles, routes, trips, and terminals.

Clearly distinguish:

- Passenger Booking = Passenger Reservation

- Cargo Shipment = Freight Transportation Request

- Passenger Ticket = Travel Authorization

- Cargo Receipt = Shipment Acceptance Record

- Boarding = Passenger Admission

- Cargo Loading = Freight Handling

---

## 3. Scope

### In Scope

Include:

- Shipment request

- Shipment acceptance

- Cargo inspection

- Cargo pricing

- Cargo loading

- In-transit handling

- Cargo unloading

- Cargo delivery

- Delivery confirmation

### Out of Scope

Exclude:

- Passenger booking

- Passenger ticketing

- Boarding

- Financial accounting

- Warehouse implementation

- Fleet maintenance

---

## 4. Workflow Objectives

Describe objectives including:

- Safe transportation

- Shipment traceability

- Accurate cargo handling

- Operational accountability

- Customer confidence

- Auditability

---

## 5. Business Actors

Describe responsibilities of:

- Sender

- Receiver

- Cargo Officer

- Conductor

- Driver

- Terminal Staff

- System

---

## 6. Trigger

Describe business events that initiate cargo transportation, such as:

- Shipment request submitted

- Walk-in cargo acceptance

- Partner shipment request

---

## 7. Preconditions

Describe conditions that SHOULD exist before shipment processing begins, including:

- Shipment accepted

- Sender identified

- Destination available

- Trip available

- Cargo accepted under business policy

---

## 8. Main Workflow

Describe the normal business flow from shipment request through successful delivery.

Use business language only.

Avoid implementation details.

---

## 9. Alternative Flows

Examples include:

- Shipment consolidated

- Partial shipment

- Alternate delivery location

- Multiple receiving parties

---

## 10. Exception Flows

Examples include:

- Shipment rejected

- Damaged shipment

- Lost shipment

- Delivery failure

- Customer unavailable

- Operational interruption

---

## 11. Postconditions

Describe possible business outcomes including:

- Delivered

- Returned

- Cancelled

- Damaged

- Lost

- Investigation Required

---

## 12. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Every shipment MUST have one sender.

- Every shipment MUST have one destination.

- Every shipment MUST belong to one transportation service.

- Cargo acceptance MUST follow organizational policy.

- Shipment status transitions MUST remain traceable.

- Cargo delivery MUST be verifiable.

- Shipment handling MUST remain auditable.

---

## 13. Cargo Shipment State Transition

Describe conceptual states such as:

- Draft

- Accepted

- Awaiting Loading

- Loaded

- In Transit

- Arrived

- Delivered

- Returned

- Cancelled

- Lost

- Damaged

Explain valid business transitions without implementation.

---

## 14. Related Domain Events

Describe conceptual business events including:

- Shipment Accepted

- Cargo Loaded

- Trip Departed

- Cargo Arrived

- Cargo Delivered

- Shipment Returned

- Shipment Lost

- Shipment Damaged

---

## 15. Related Modules

Reference:

- Cargo

- Trip

- Vehicle

- Route

- Terminal

- Notification

- Payment

- Audit

Explain how each module participates in the workflow.

---

## 16. Related APIs

Reference conceptually:

- Cargo API

- Trip API

- Notification API

Do not describe endpoints.

---

## 17. Security Considerations

Describe:

- Shipment ownership

- Cargo authorization

- Operational integrity

- Chain of custody

- Auditability

---

## 18. Audit Considerations

Describe why shipment acceptance, loading, transfer, delivery, returns, and incidents SHOULD be fully auditable.

---

## 19. Failure Recovery Considerations

Describe conceptual recovery expectations for:

- Delivery interruption

- Shipment investigation

- Lost cargo

- Damaged cargo

- Manual reconciliation

---

## 20. References

Reference:

- Workflow README

- Cargo Module

- Trip Module

- Vehicle Module

- Terminal Module

- Notification Module

- Audit Module

- Architecture Documentation

---

## 21. Glossary

Include definitions for:

- Shipment

- Cargo

- Sender

- Receiver

- Cargo Receipt

- Chain of Custody

- Delivery Confirmation

- Shipment Lifecycle

---

## 22. Summary

Summarize how the Cargo Workflow provides a controlled, traceable, auditable, and business-oriented process for freight transportation across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Business-oriented

Logistics-focused

Architecture-focused

Workflow-focused

Documentation-first

Technology-neutral

Vendor-neutral

No implementation details

No framework-specific guidance

No programming language examples

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)