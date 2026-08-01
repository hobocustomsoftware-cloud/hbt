You are a Distinguished Enterprise Solution Architect, Enterprise Financial Systems Architect, Business Process Architect, Domain-Driven Design (DDD) Expert, Enterprise Workflow Architect, Transportation Domain Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/workflows/003-payment-workflow.md

Purpose:

Define the Payment Workflow for the HoBo Transport Platform (HBT).

This document describes the complete business workflow for payment processing related to passenger transportation services.

This document defines business workflow governance only.

This document is NOT a payment implementation guide.

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

# Payment Workflow

## 1. Purpose

Explain the purpose of the payment workflow and its role in confirming financial obligations for transportation services.

---

## 2. Executive Summary

Describe how payment transforms an eligible booking into a financially confirmed transaction while remaining independent from ticket issuance.

Explain why Payment and Ticket are separate business domains.

---

## 3. Scope

### In Scope

Include:

- Payment initiation
- Payment validation
- Payment authorization
- Payment confirmation
- Payment failure
- Payment cancellation
- Payment expiration
- Payment reconciliation trigger

### Out of Scope

Exclude:

- Booking creation
- Ticket issuance
- Boarding
- Cash settlement
- Refund processing
- Accounting implementation
- Payment gateway implementation

---

## 4. Workflow Objectives

Describe objectives including:

- Financial integrity
- Transaction consistency
- Customer confidence
- Duplicate payment prevention
- Business rule enforcement
- Auditability

---

## 5. Business Actors

Describe responsibilities of:

- Passenger
- Booking Officer
- Cashier
- Payment Service
- System
- External Payment Provider (if applicable)

---

## 6. Trigger

Describe business events that may initiate payment, such as:

- Booking awaiting payment
- Walk-in purchase
- Payment requested by operator
- External payment request

---

## 7. Preconditions

Describe conditions that SHOULD exist before payment can proceed, including:

- Valid booking (where applicable)
- Payable amount determined
- Payment window open
- Payment method available
- Customer identity established (where required)

---

## 8. Main Workflow

Describe the normal business flow from payment request through successful payment completion.

Use business language only.

Avoid implementation details.

---

## 9. Alternative Flows

Examples include:

- Different payment method selected
- Partial payment not permitted
- Payment method unavailable
- Payment retried before completion

---

## 10. Exception Flows

Examples include:

- Payment declined
- Payment expired
- Duplicate payment attempt
- Business validation failure
- Payment cancelled
- External service unavailable

---

## 11. Postconditions

Describe possible business outcomes such as:

- Payment Completed
- Payment Pending
- Payment Failed
- Payment Cancelled
- Payment Expired

Explain how these outcomes influence downstream workflows without describing implementation.

---

## 12. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every payment MUST belong to one business transaction.
- Duplicate financial payments MUST NOT occur.
- Completed payments MUST remain auditable.
- Failed payments MUST NOT authorize ticket issuance.
- Payment status transitions MUST be traceable.
- Payment amount MUST follow business policy.
- Payment completion SHOULD trigger subsequent business workflows.

---

## 13. Payment State Transition

Describe conceptual payment states such as:

- Draft
- Pending
- Authorized
- Completed
- Failed
- Cancelled
- Expired

Explain valid business transitions without implementation.

---

## 14. Related Domain Events

Describe conceptual events including:

- Payment Initiated
- Payment Authorized
- Payment Completed
- Payment Failed
- Payment Cancelled
- Payment Expired

---

## 15. Related Modules

Reference:

- Booking
- Passenger
- Ticket
- Cash Settlement
- Refund
- Notification
- Audit

Explain how each module participates in the workflow.

---

## 16. Related APIs

Reference conceptually:

- Payment API
- Booking API
- Notification API

Do not describe endpoints.

---

## 17. Security Considerations

Describe:

- Financial data protection
- Authorization
- Transaction integrity
- Auditability
- Duplicate payment protection

---

## 18. Audit Considerations

Describe why payment initiation, authorization, completion, failure, cancellation, and expiration SHOULD be auditable.

---

## 19. Failure Recovery Considerations

Describe conceptual recovery expectations for:

- Interrupted payment
- Network interruption
- Duplicate requests
- Retry scenarios
- Temporary external service failures

---

## 20. References

Reference:

- Workflow README
- Booking Module
- Payment Module
- Cash Settlement Module
- Refund Module
- Notification Module
- API Documentation
- Architecture Documentation

---

## 21. Glossary

Include definitions for:

- Payment
- Authorization
- Financial Transaction
- Payment Completion
- Payment Failure
- Payment Cancellation
- Payment Expiration
- Payment Lifecycle

---

## 22. Summary

Summarize how the payment workflow provides a secure, auditable, reliable, and business-oriented financial process for transportation services across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Business-oriented

Architecture-focused

Financial workflow-focused

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