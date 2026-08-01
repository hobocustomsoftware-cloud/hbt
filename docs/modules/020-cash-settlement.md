You are a Distinguished Enterprise Financial Systems Architect, Transportation Cash Operations Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/020-cash-settlement.md

Purpose:

Define the Cash Settlement Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how collected cash is reconciled, verified, settled, and closed after transportation operations.

A Cash Settlement represents the reconciliation of collected funds between operational staff and the company.

A Cash Settlement is NOT a Payment.

A Cash Settlement is NOT an Accounting Ledger.

Cash Settlement begins after operational cash collection has occurred.

The Cash Settlement Module manages operational cash reconciliation only.

The Cash Settlement Module MUST remain independent from Payroll, General Ledger, Financial Accounting, Vehicle Management, and Route Planning.

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

- What is Cash Settlement?
- Difference between Payment and Cash Settlement
- Relationship with Trip
- Relationship with Conductor
- Relationship with Branch
- Relationship with Payment

7. Responsibilities

The Cash Settlement Module MUST manage:

- Settlement Number
- Settlement Date
- Settlement Status
- Trip Reference
- Conductor Reference
- Branch Reference
- Expected Amount
- Actual Amount
- Difference Amount
- Difference Reason
- Verified By
- Verification Time
- Settlement Notes

The Cash Settlement Module MUST NOT manage:

- Passenger Payments
- Payroll
- Accounting Ledger
- Vehicle Assignment
- Route Planning

8. Settlement Lifecycle

Describe:

Draft

↓

Pending Verification

↓

Verified

↓

Approved

↓

Closed

OR

Rejected

↓

Reopened (Business Policy)

↓

Archived

Include state transition rules.

9. Settlement Sources

Describe:

- Ticket Sales
- Roadside Cash Collection
- Manual Ticket Revenue
- Additional Service Charges
- Other Operational Collections

10. Cash Reconciliation

Describe:

- Expected Amount Calculation
- Actual Cash Count
- Difference Calculation
- Shortage Handling
- Overage Handling
- Exception Approval

11. Verification Process

Describe:

- Cash Counting
- Supporting Document Review
- Manual Ticket Verification
- Supervisor Approval
- Branch Confirmation

12. Integrations

Describe interaction with:

- Payment Module
- Ticket Module
- Trip Module
- Conductor Module
- Branch Module
- Reporting Module
- Audit Module

13. Events

Include:

- Settlement Created
- Cash Counted
- Difference Detected
- Settlement Verified
- Settlement Approved
- Settlement Closed
- Settlement Reopened

14. Permissions

Describe who MAY:

- Create Settlement
- Verify Settlement
- Approve Settlement
- Reopen Settlement
- Close Settlement
- View Settlement

15. Validation Rules

Describe:

- Trip Validation
- Conductor Validation
- Amount Validation
- Difference Validation
- Approval Validation

16. Offline Behavior

Describe:

- Offline Cash Recording
- Offline Difference Recording
- Deferred Synchronization
- Conflict Resolution

17. Audit Requirements

Every Settlement MUST be auditable.

Every amount modification MUST be auditable.

Every approval MUST be traceable.

Every reopening MUST be recorded.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Settlement MUST belong to exactly one Company.
- Every Settlement MUST reference exactly one Trip.
- Every Settlement MUST reference exactly one Conductor.
- Expected Amount MUST be system-calculated.
- Manual modifications MUST require authorization.
- Closed Settlements MUST become immutable.
- Settlement differences MUST record a reason.

19. KPIs

Examples:

- Settlement Accuracy Rate
- Cash Difference Rate
- Average Settlement Time
- Pending Settlement Count
- Reopened Settlement Count
- Verified Settlement Rate

20. Error Scenarios

Describe:

- Amount Mismatch
- Missing Trip
- Duplicate Settlement
- Unauthorized Approval
- Reconciliation Failure
- Offline Synchronization Conflict

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Smart Cash Counting Devices
- QR Cash Reconciliation
- Bank Deposit Verification
- Digital Settlement
- AI Anomaly Detection
- Automatic Difference Investigation

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Settlement Creation
- Cash Counting
- Difference Calculation
- Supervisor Verification
- Approval
- Settlement Closing
- Settlement Reopening

--------------------------------------------------
Mandatory Business Rules

Every Settlement MUST belong to exactly one Company.

Every Settlement MUST reference exactly one Trip.

Every Settlement MUST reference exactly one Conductor.

Expected Amount MUST be calculated from operational transactions.

Closed Settlements MUST remain immutable.

Settlement differences MUST always include a documented reason.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation financial operations-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants