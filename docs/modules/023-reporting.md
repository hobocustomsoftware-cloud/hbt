You are a Distinguished Enterprise Business Intelligence Architect, Enterprise Reporting Systems Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/023-reporting.md

Purpose:

Define the Reporting Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how operational, financial, transportation, passenger, cargo, and management reports are generated, organized, secured, and distributed.

The Reporting Module provides historical and operational reporting.

The Reporting Module is NOT responsible for predictive analytics or artificial intelligence.

Reporting presents verified business data.

Business analysis and AI recommendations belong to separate modules.

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

- What is Reporting?
- Difference between Reporting and Analytics
- Difference between Reports and Dashboards
- Relationship with Operational Data
- Relationship with Audit
- Relationship with AI

7. Responsibilities

The Reporting Module MUST manage:

- Report Catalog
- Report Definition
- Report Parameters
- Report Filters
- Report Execution
- Report Scheduling
- Report Export
- Report Distribution
- Report History
- Report Access

The Reporting Module MUST NOT manage:

- Business Transactions
- Data Modification
- AI Recommendations
- Predictive Models
- Operational Decisions

8. Report Lifecycle

Describe:

Draft

↓

Published

↓

Executed

↓

Exported

↓

Archived

Include lifecycle rules.

9. Report Categories

Describe:

Operational Reports

Financial Reports

Passenger Reports

Cargo Reports

Trip Reports

Vehicle Reports

Driver Reports

Conductor Reports

Settlement Reports

Exception Reports

Executive Reports

Compliance Reports

10. Dashboards

Describe:

- Executive Dashboard
- Branch Dashboard
- Terminal Dashboard
- Operations Dashboard
- Financial Dashboard
- Cargo Dashboard

11. Report Filters

Describe:

- Date Range
- Company
- Branch
- Terminal
- Route
- Trip
- Driver
- Conductor
- Vehicle
- Passenger
- Cargo
- Payment Method

12. Export Formats

Describe:

- PDF
- Excel
- CSV
- JSON
- Print
- Scheduled Email

13. Integrations

Describe interaction with:

- Booking Module
- Ticket Module
- Boarding Module
- Payment Module
- Settlement Module
- Cargo Module
- Audit Module

14. Events

Include:

- Report Generated
- Report Exported
- Report Scheduled
- Report Delivered
- Report Failed

15. Permissions

Describe who MAY:

- Create Reports
- Publish Reports
- Execute Reports
- Export Reports
- Schedule Reports
- View Reports

16. Validation Rules

Describe:

- Parameter Validation
- Date Validation
- Permission Validation
- Export Validation

17. Offline Behavior

Describe:

- Cached Reports
- Offline Export
- Synchronization
- Data Freshness

18. Audit Requirements

Every report execution MUST be auditable.

Every export MUST be recorded.

Every scheduled report MUST be traceable.

Permission changes MUST be auditable.

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Reports MUST use approved business data.
- Reports MUST NOT modify source data.
- Scheduled reports MUST preserve execution history.
- Report exports MUST be auditable.
- Report permissions MUST follow company policy.

20. KPIs

Describe KPI reporting for:

- Revenue
- Passenger Count
- Occupancy Rate
- On-Time Departure
- On-Time Arrival
- Cargo Revenue
- Cash Difference
- Booking Conversion
- Cancellation Rate
- No Show Rate

21. Error Scenarios

Describe:

- Invalid Parameters
- Missing Data
- Permission Denied
- Export Failure
- Timeout
- Scheduled Job Failure

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe support for:

- Self-Service Reporting
- BI Integration
- Power BI
- Tableau
- Looker
- Embedded Dashboards
- Real-Time Dashboards

24. References

Reference related Architecture documents, ADRs, and Module Specifications.

25. Glossary

26. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- Report Request
- Data Validation
- Report Generation
- Report Export
- Scheduled Report
- Report Delivery

--------------------------------------------------
Mandatory Business Rules

Reports MUST be read-only.

Reports MUST use approved business data.

Exports MUST be auditable.

Report permissions MUST follow role-based access.

Historical reports MUST remain reproducible.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Business Intelligence-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants