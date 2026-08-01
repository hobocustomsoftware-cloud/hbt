You are a Distinguished Enterprise Financial Systems Architect, Transportation Payment Systems Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/019-payment.md

Purpose:

Define the Payment Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how passenger payments are recorded, authorized, reconciled, refunded, and linked to transportation services.

A Payment represents a financial transaction made for transportation services.

A Payment is NOT a Ticket.

A Payment is NOT a Cash Settlement.

One Booking MAY have one or more Payments depending on business policy.

One Payment MAY cover one or more Tickets.

The Payment Module manages customer financial transactions only.

The Payment Module MUST remain independent from Cash Settlement, Payroll, Accounting Ledger, Vehicle Operations, and Route Planning.

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

- What is a Payment?
- Difference between Payment and Ticket
- Difference between Payment and Cash Settlement
- Relationship with Booking
- Relationship with Ticket
- Relationship with Passenger

7. Responsibilities

The Payment Module MUST manage:

- Payment Number
- Payment Date
- Payment Method
- Payment Status
- Amount
- Currency
- Discount
- Tax
- Service Charge
- Total Amount
- Received Amount
- Change Amount
- Payment Reference
- Payment Operator

The Payment Module MUST NOT manage:

- Cash Settlement
- Payroll
- Accounting Ledger
- Driver Assignment
- Vehicle Assignment

8. Payment Lifecycle

Describe:

Pending

↓

Authorized

↓

Completed

OR

Failed

↓

Cancelled

↓

Refunded

↓

Archived

Include state transition rules.

9. Payment Methods

Describe:

- Cash
- Credit Card
- Debit Card
- QR Payment
- Mobile Wallet
- Bank Transfer
- Corporate Credit
- Voucher

10. Payment Allocation

Describe:

- One Payment → One Ticket
- One Payment → Multiple Tickets
- Partial Payment
- Split Payment
- Outstanding Balance

11. Refund Management

Describe:

- Full Refund
- Partial Refund
- Refund Approval
- Refund Reason
- Refund Audit

12. Integrations

Describe interaction with:

- Booking Module
- Ticket Module
- Passenger Module
- Cash Settlement Module
- Reporting Module
- Audit Module

13. Events

Include:

- Payment Initiated
- Payment Authorized
- Payment Completed
- Payment Failed
- Payment Cancelled
- Payment Refunded

14. Permissions

Describe who MAY:

- Create Payment
- Authorize Payment
- Cancel Payment
- Refund Payment
- View Payment

15. Validation Rules

Describe:

- Amount Validation
- Currency Validation
- Duplicate Payment Prevention
- Outstanding Balance Validation

16. Offline Behavior

Describe:

- Offline Cash Payment
- Deferred Electronic Payment
- Synchronization Rules
- Conflict Resolution

17. Audit Requirements

Every Payment transaction MUST be auditable.

Every refund MUST be traceable.

Every payment modification MUST be recorded.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Payment MUST belong to exactly one Company.
- Every Payment MUST reference at least one Booking or Ticket.
- Completed Payments MUST become immutable.
- Refunds MUST reference the original Payment.
- Negative payment amounts MUST NOT be allowed.
- Payment totals MUST equal allocated amounts.

19. KPIs

Examples:

- Total Revenue
- Payment Success Rate
- Refund Rate
- Cash Payment Percentage
- QR Payment Percentage
- Outstanding Balance

20. Error Scenarios

Describe:

- Duplicate Payment
- Payment Amount Mismatch
- Invalid Currency
- Failed Authorization
- Refund Exceeds Original Amount
- Offline Synchronization Conflict

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Stripe
- Dinger
- KBZPay
- WavePay
- Apple Pay
- Google Pay
- Subscription Payments
- Installment Payments

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Payment Creation
- Payment Authorization
- Cash Collection
- QR Payment
- Refund Processing
- Outstanding Balance Collection

--------------------------------------------------
Mandatory Business Rules

Every Payment MUST belong to exactly one Company.

Every Payment MUST reference at least one Booking or Ticket.

Completed Payments MUST remain immutable.

Refunds MUST always reference an original Payment.

Payment allocation MUST be fully traceable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Financial systems-focused

Transportation payment-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants