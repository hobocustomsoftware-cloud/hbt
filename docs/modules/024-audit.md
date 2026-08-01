You are a Distinguished Enterprise Governance Architect, Audit Systems Expert, Compliance Architect, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/024-audit.md

Purpose:

Define the Audit Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how business activities, user actions, approvals, operational changes, and critical system events are recorded for governance, compliance, traceability, and accountability.

The Audit Module is a cross-cutting governance capability.

Audit records provide historical evidence.

The Audit Module MUST remain independent from application logging, debugging, and monitoring.

Application logs are NOT audit records.

The Audit Module records business accountability.

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

- What is an Audit Record?
- Difference between Audit and Logging
- Difference between Audit and Reporting
- Difference between Audit and Monitoring
- Relationship with Business Transactions
- Relationship with Compliance

7. Responsibilities

The Audit Module MUST manage:

- Audit ID
- Audit Timestamp
- Company
- Branch
- User
- User Role
- Action
- Entity Type
- Entity Identifier
- Before State
- After State
- Change Summary
- Reason
- Approval Reference
- Source Device
- IP Address
- Session Identifier

The Audit Module MUST NOT manage:

- Business Transactions
- User Authentication
- Application Logs
- Performance Metrics
- Monitoring Alerts

8. Audit Lifecycle

Describe:

Recorded

↓

Verified

↓

Retained

↓

Archived

↓

Disposed (Business Policy)

Include lifecycle rules.

9. Auditable Activities

Describe:

- Authentication Events
- Booking Activities
- Ticket Activities
- Boarding Activities
- Payment Activities
- Settlement Activities
- Cargo Activities
- User Administration
- Permission Changes
- Configuration Changes
- AI Requests (Metadata Only)

10. Audit Categories

Describe:

- Security Audit
- Financial Audit
- Operational Audit
- Compliance Audit
- Administrative Audit
- AI Governance Audit

11. Data Retention

Describe:

- Retention Policy
- Legal Hold
- Archive Policy
- Disposal Policy

12. Integrations

Describe interaction with:

- Authentication Module
- Booking Module
- Ticket Module
- Payment Module
- Settlement Module
- Cargo Module
- Reporting Module
- AI Assistant Module

13. Events

Include:

- Audit Recorded
- Audit Verified
- Audit Archived
- Audit Retrieved

14. Permissions

Describe who MAY:

- View Audit
- Search Audit
- Export Audit
- Archive Audit
- Apply Legal Hold

Clearly state that audit records MUST NOT be editable.

15. Validation Rules

Describe:

- Entity Validation
- User Validation
- Timestamp Validation
- Integrity Validation
- Tamper Detection

16. Offline Behavior

Describe:

- Offline Audit Capture
- Deferred Synchronization
- Integrity Verification
- Conflict Resolution

17. Audit Integrity

Describe:

- Immutability
- Chain of Custody
- Evidence Preservation
- Tamper Resistance
- Verification

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every business-critical action MUST generate an audit record.
- Audit records MUST be immutable.
- Audit records MUST NOT be deleted before retention policy expires.
- Approval actions MUST record approver identity.
- AI interactions SHOULD record metadata without exposing sensitive prompts where prohibited.

19. KPIs

Examples:

- Audited Transaction Rate
- Unauthorized Access Attempts
- Approval Compliance Rate
- Audit Retrieval Time
- Audit Completeness
- Audit Coverage

20. Error Scenarios

Describe:

- Missing Audit Record
- Tampered Record
- Incomplete Audit
- Unauthorized Access
- Corrupted Archive
- Synchronization Failure

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Digital Signatures
- Immutable Storage
- Blockchain-backed Verification
- Compliance Automation
- AI-assisted Audit Review
- Regulatory Reporting

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Business Event
- Audit Capture
- Integrity Verification
- Storage
- Search
- Export
- Archive
- Legal Hold

--------------------------------------------------
Mandatory Business Rules

Audit records MUST remain immutable.

Business-critical events MUST generate audit records.

Audit retention MUST follow company policy.

Audit records MUST support legal investigation.

Audit history MUST remain traceable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Governance-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants