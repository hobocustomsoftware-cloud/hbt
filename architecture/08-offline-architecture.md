You are a Distinguished Enterprise Architect, Mobile Systems Architect, Distributed Systems Engineer, Offline-First Specialist, Principal Platform Engineer, and Site Reliability Engineer.

Create the file:

architecture/08-offline-architecture.md

Purpose:

Define the official Offline-First Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative specification for how the platform MUST continue operating during network interruptions while ensuring reliable synchronization, consistency, security, and data integrity.

The document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

The document MUST focus on architecture only.

No implementation code should appear.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Offline Vision

4. Offline-First Principles

5. Business Requirements

6. Offline Use Cases

Describe offline scenarios for:

- Ticket Selling
- Ticket Validation
- Cargo Booking
- Cargo Receiving
- Taxi Dispatch
- Motorcycle Dispatch
- Hotel Check-in
- Hotel Check-out
- Payment Recording
- Customer Registration

7. Offline User Experience

8. Connectivity States

Define:

- Online
- Offline
- Limited Connectivity
- Synchronizing
- Synchronization Failed

9. Local Data Storage

Describe:

- Local Database
- Cached Data
- Temporary Data
- Persistent Data
- Configuration Data

10. Synchronization Architecture

Describe:

- Upload Queue
- Download Queue
- Delta Synchronization
- Incremental Sync
- Full Sync
- Initial Sync

11. Synchronization Workflow

12. Queue Management

13. Retry Strategy

14. Conflict Detection

15. Conflict Resolution

Describe strategies such as:

- Last Write Wins
- Version Comparison
- Timestamp Comparison
- Manual Resolution
- Business Rule Resolution

16. Data Ownership

17. Data Consistency

18. Transaction Recovery

19. Duplicate Prevention

20. Idempotency

21. Offline Authentication

22. Offline Authorization

23. Local Security

24. Encryption

25. Sensitive Data Protection

26. Audit Logging

27. Background Synchronization

28. Push Synchronization

29. Scheduled Synchronization

30. Manual Synchronization

31. Synchronization Monitoring

32. Synchronization Metrics

33. Error Recovery

34. Failure Scenarios

35. Device Replacement Strategy

36. Backup & Restore

37. Multi-Tenant Offline Strategy

38. Performance Targets

39. Scalability

40. Future Evolution

Describe evolution from:

Device-Based Offline Sync

to

Distributed Edge Synchronization

without changing business modules.

41. Architecture Rules

Mandatory Rules:

- The application MUST remain usable without internet whenever business rules allow.
- Every offline operation MUST be recoverable.
- Every synchronized transaction MUST be traceable.
- Duplicate synchronization MUST NOT create duplicate business records.
- Synchronization MUST be idempotent.
- Business integrity MUST be preserved.
- Sensitive data MUST remain encrypted.
- Synchronization failures MUST NOT lose business data.
- Manual synchronization MUST always be available.
- Business modules MUST remain independent.

42. Offline Readiness Checklist

43. Glossary

44. Summary

--------------------------------------------------
Offline Design Goals
--------------------------------------------------

The architecture MUST support:

- Offline First
- Low Bandwidth Networks
- High Latency Networks
- Temporary Connectivity Loss
- Reliable Synchronization
- Conflict Resolution
- Data Integrity
- Security
- Scalability
- Auditability
- AI Readiness
- Vendor Neutrality

--------------------------------------------------
Platform Scope

Define offline support for:

- Flutter Mobile Applications
- Web Progressive Enhancement
- Local Database
- API Synchronization
- Background Workers
- Notification Queue
- Reporting Queue
- Audit Queue

--------------------------------------------------
Requirements

Enterprise-grade Markdown

No source code

No implementation examples

Architecture-focused

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants