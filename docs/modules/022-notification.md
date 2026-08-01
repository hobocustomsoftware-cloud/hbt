You are a Distinguished Enterprise Integration Architect, Notification Systems Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/022-notification.md

Purpose:

Define the Notification Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how notifications are generated, delivered, tracked, retried, and audited across the platform.

The Notification Module is a cross-cutting infrastructure service.

Notifications are generated from Business Events.

The Notification Module MUST NOT contain business decision logic.

Business Modules publish events.

The Notification Module consumes events and delivers notifications.

This module supports Passenger, Cargo, Staff, and Administrative notifications.

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

- What is a Notification?
- Difference between Event and Notification
- Difference between Notification and Messaging
- Relationship with Business Events
- Relationship with Users

7. Responsibilities

The Notification Module MUST manage:

- Notification Number
- Notification Type
- Notification Status
- Notification Channel
- Recipient
- Recipient Type
- Notification Template
- Language
- Delivery Time
- Retry Count
- Delivery Result
- Failure Reason

The Notification Module MUST NOT manage:

- Booking Decisions
- Payment Decisions
- Passenger Validation
- Cargo Operations
- Business Workflow

8. Notification Lifecycle

Describe:

Created

↓

Queued

↓

Processing

↓

Sent

↓

Delivered

OR

Failed

↓

Retrying

↓

Expired

↓

Archived

Include state transition rules.

9. Notification Types

Describe:

- Booking Notification
- Ticket Notification
- Payment Notification
- Cargo Notification
- Trip Notification
- System Notification
- Security Notification

10. Notification Channels

Describe:

- SMS
- Email
- Push Notification
- In-App Notification
- Telegram (Future)
- WhatsApp (Future)
- Voice Call (Future)

11. Templates

Describe:

- Multi-language Templates
- Company Branding
- Variables
- Localization
- Versioning

12. Event Sources

Describe events from:

- Booking
- Ticket
- Payment
- Boarding
- Cargo
- Trip
- Settlement
- Audit

13. Integrations

Describe interaction with:

- Booking Module
- Ticket Module
- Passenger Module
- Cargo Module
- Reporting Module
- Audit Module

14. Events

Include:

- Notification Created
- Notification Queued
- Notification Sent
- Notification Delivered
- Notification Failed
- Notification Retried

15. Permissions

Describe who MAY:

- Create Templates
- Send Notifications
- Retry Notifications
- Cancel Notifications
- View Notification Logs

16. Validation Rules

Describe:

- Recipient Validation
- Template Validation
- Channel Validation
- Duplicate Notification Prevention

17. Offline Behavior

Describe:

- Queue Persistence
- Retry after Connectivity
- Delivery Synchronization
- Duplicate Prevention

18. Audit Requirements

Every Notification MUST be auditable.

Every delivery attempt MUST be recorded.

Every retry MUST be traceable.

Every template change MUST be auditable.

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Notifications MUST originate from Business Events.
- Notification failures MUST NOT rollback business transactions.
- Templates MUST support localization.
- Failed notifications SHOULD be retried according to company policy.
- Delivery history MUST remain immutable.

20. KPIs

Examples:

- Delivery Success Rate
- SMS Success Rate
- Email Success Rate
- Push Delivery Rate
- Average Delivery Time
- Retry Rate

21. Error Scenarios

Describe:

- Invalid Recipient
- Missing Template
- SMS Gateway Failure
- Email Failure
- Duplicate Notification
- Queue Failure

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe support for:

- AI Personalized Notifications
- Smart Delivery Time Optimization
- Omnichannel Delivery
- Customer Preference Center
- Rich Media Messages
- Chatbot Integration

24. References

Reference related Architecture documents, ADRs, and Module Specifications.

25. Glossary

26. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Event Published
- Notification Creation
- Queue Processing
- Channel Selection
- Delivery
- Retry
- Delivery Confirmation

--------------------------------------------------
Mandatory Business Rules

Notifications MUST originate from Business Events.

Notification delivery MUST be asynchronous.

Business transactions MUST NOT depend on successful notification delivery.

Delivery history MUST remain immutable.

Template changes MUST be version controlled.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Event-driven architecture-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants