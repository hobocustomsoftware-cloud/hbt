You are a Distinguished Enterprise Solution Architect, Transportation Domain Architect, Operations Architect, Domain-Driven Design (DDD) Expert, Enterprise Software Architect, and Chief Technology Officer (CTO).

Create the file:

architecture/21-operational-architecture.md

Purpose:

Define the official Operational Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative architecture specification describing how real-world transportation operations are modeled, coordinated, executed, monitored, and evolved across the platform.

This document MUST bridge business operations with software architecture.

This document MUST become the master reference for all transportation workflows.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST describe operational architecture only.

No implementation details.

No source code.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Operational Vision

4. Operational Principles

Describe principles including:

- Business First
- Operational Consistency
- Offline First
- Real-Time Visibility
- Multi-Tenant
- Safety
- Accountability
- Auditability
- Automation
- Vendor Neutral

5. Operational Goals

6. Transportation Business Model

Describe support for:

- Express Bus
- Cargo
- Taxi
- Hotel
- Future Transportation Services

7. Operational Organization

Describe organizational hierarchy:

- Platform
- Company
- Branch
- Terminal
- Route
- Trip

8. Operational Roles

Define responsibilities for:

- Super Admin
- Company Owner
- Company Admin
- Branch Manager
- Terminal Manager
- Dispatcher
- Ticket Seller
- Gate Staff
- Conductor
- Driver
- Inspector
- Finance
- Customer Support
- Passenger

9. Operational Lifecycle

Describe lifecycle:

Trip Planning

↓

Vehicle Assignment

↓

Driver Assignment

↓

Crew Assignment

↓

Schedule Approval

↓

Ticket Sales

↓

Passenger Check-In

↓

Departure

↓

Roadside Boarding

↓

Passenger Drop-Off

↓

Trip Completion

↓

Cash Settlement

↓

Daily Closing

10. Trip Architecture

Describe:

- Planned Trip
- Active Trip
- Delayed Trip
- Suspended Trip
- Completed Trip
- Cancelled Trip

11. Route Operations

Describe:

- Route
- Stops
- Pickup Points
- Drop-Off Points
- Intermediate Stops

12. Passenger Operations

Describe:

- Reservation
- Walk-In Passenger
- Roadside Passenger
- Transfer Passenger
- Reassigned Passenger
- VIP Passenger

13. Roadside Boarding Architecture

Describe:

- Boarding without prior booking
- Seat Allocation
- Cash Collection
- Ticket Issuance
- Receipt Printing
- Offline Ticket Issuance
- Sync After Connectivity
- Duplicate Ticket Prevention
- Passenger Validation

14. Seat Management

Describe:

- Seat Availability
- Reserved
- Confirmed
- Checked-In
- Boarded
- Roadside Boarding
- Released
- No Show
- Completed

15. Ticket Lifecycle

Describe:

Created

↓

Reserved

↓

Confirmed

↓

Checked-In

↓

Boarded

↓

Completed

↓

Archived

Include:

- Cancellation
- Reissue
- Transfer
- Refund

16. Cash Collection Architecture

Describe:

- Terminal Collection
- Conductor Collection
- Partial Payments
- Outstanding Balance
- Settlement
- Reconciliation

17. Conductor Operations

Describe responsibilities:

- Passenger Boarding
- Seat Assignment
- Cash Collection
- Ticket Issuance
- Ticket Verification
- Passenger Counting
- Trip Notes
- Incident Reporting
- Offline Operation
- Synchronization

18. Driver Operations

Describe:

- Vehicle Inspection
- Departure Confirmation
- Arrival Confirmation
- Incident Reporting

19. Dispatch Operations

Describe:

- Vehicle Assignment
- Driver Assignment
- Crew Assignment
- Route Assignment
- Delay Management
- Emergency Replacement

20. Terminal Operations

Describe:

- Counter Sales
- Passenger Check-In
- Gate Validation
- Departure Control
- Arrival Processing

21. Cargo Operations

Describe:

- Cargo Booking
- Cargo Loading
- Tracking
- Delivery Confirmation

22. Payment Operations

Describe:

- Cash
- QR Payment
- Mobile Wallet
- Bank Transfer
- Future Payment Providers

23. Offline Operations

Describe:

- Offline Booking
- Offline Boarding
- Offline Ticket Printing
- Offline Payments
- Offline Queue
- Synchronization
- Conflict Resolution

24. Operational Monitoring

Describe:

- Active Trips
- Passenger Count
- Available Seats
- Boarding Status
- Cash Status
- Delays
- Incidents

25. Operational KPIs

Include:

- Departure On-Time Rate
- Seat Utilization
- Occupancy Rate
- Boarding Time
- Revenue per Trip
- Revenue per Route
- Conductor Accuracy
- Cash Difference
- Trip Completion Rate

26. Operational Audit

Describe:

- Ticket Audit
- Cash Audit
- Trip Audit
- User Activity
- Offline Activity
- AI Activity

27. Operational Risks

Include:

- Duplicate Boarding
- Ticket Fraud
- Cash Leakage
- Overbooking
- Connectivity Failure
- Human Error

28. Operational Assumptions

29. Future Operational Evolution

Describe evolution from:

Manual Operations

↓

Digital Operations

↓

AI-Assisted Operations

↓

Predictive Operations

↓

Autonomous Transportation Operations

without changing business domains.

30. Operational Checklist

31. Glossary

32. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Ticket Sales
- Reservation
- Check-In
- Roadside Boarding
- Trip Dispatch
- Vehicle Assignment
- Driver Assignment
- Conductor Operations
- Cash Settlement
- Daily Closing
- Incident Management
- Passenger Verification
- Offline Synchronization

--------------------------------------------------
Mandatory Rules

Every passenger MUST belong to a trip.

Every seat MUST have only one active passenger.

Every ticket MUST be traceable.

Every cash transaction MUST be auditable.

Every trip MUST have assigned crew.

Roadside boarding MUST support offline operation.

Offline transactions MUST synchronize safely.

Operational history MUST remain immutable.

Business operations MUST remain independent from infrastructure.

Every operational workflow MUST support future AI assistance.

--------------------------------------------------
Architecture Goals

The operational architecture MUST support:

- Multi-Tenant SaaS
- Offline First
- AI Ready
- Enterprise Operations
- High Availability
- Security
- Auditability
- Scalability
- Vendor Neutrality
- Long-Term Maintainability

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Transportation domain-focused

No implementation examples

No source code

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants