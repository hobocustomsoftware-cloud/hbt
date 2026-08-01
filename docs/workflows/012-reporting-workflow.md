You are a Distinguished Enterprise Solution Architect, Enterprise Business Intelligence Architect, Reporting & Analytics Expert, Business Process Architect, Domain-Driven Design (DDD) Expert, Enterprise Workflow Architect, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/workflows/012-reporting-workflow.md

Purpose:

Define the Reporting Workflow for the HoBo Transport Platform (HBT).

This document describes the complete business workflow for collecting, validating, consolidating, and presenting business information for operational, financial, and management reporting.

This document defines business workflow governance only.

This document is NOT an implementation guide.

This document is NOT a BI tool guide.

This document is NOT an analytics implementation.

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

# Reporting Workflow

## 1. Purpose

Explain the purpose of reporting and its role in providing trusted business information for operational management, financial oversight, regulatory compliance, and strategic decision-making.

---

## 2. Executive Summary

Describe how reporting consolidates information from multiple business domains into reliable business reports.

Clearly distinguish:

- Business Transaction = Business Activity

- Business Event = Operational Occurrence

- Report = Business Information

- Business Insight = Analytical Interpretation

---

## 3. Scope

### In Scope

Include:

- Operational reporting

- Financial reporting

- Passenger reporting

- Cargo reporting

- Performance reporting

- Management reporting

- Compliance reporting

- Historical reporting

### Out of Scope

Exclude:

- Business transaction execution

- Business approvals

- AI recommendations

- Predictive analytics implementation

- Dashboard implementation

- Data warehouse implementation

---

## 4. Workflow Objectives

Describe objectives including:

- Trusted business information

- Data consistency

- Operational visibility

- Financial transparency

- Regulatory compliance

- Management decision support

---

## 5. Business Actors

Describe responsibilities of:

- Operations Manager

- Finance Officer

- Branch Manager

- Executive Management

- Auditor

- Regulatory Authority

- System

---

## 6. Trigger

Describe business events that initiate report generation, such as:

- Scheduled reporting cycle

- Operational completion

- Financial settlement completed

- Regulatory reporting period

- Management request

- Audit request

---

## 7. Preconditions

Describe conditions that SHOULD exist before reporting begins, including:

- Source records finalized

- Business data validated

- Reporting period defined

- Reporting policy applicable

---

## 8. Main Workflow

Describe the normal business process from identifying reporting requirements through report preparation, validation, publication, and availability.

Use business language only.

Avoid implementation details.

---

## 9. Alternative Flows

Examples include:

- On-demand reports

- Exception reports

- Consolidated enterprise reports

- Branch-specific reports

---

## 10. Exception Flows

Examples include:

- Missing business records

- Data inconsistency

- Reporting period adjustment

- Regulatory correction request

- Report withdrawal

---

## 11. Postconditions

Describe possible outcomes including:

- Report Published

- Report Approved

- Report Pending Review

- Report Rejected

- Report Archived

---

## 12. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Reports MUST be based on finalized business records.

- Published reports MUST remain traceable.

- Reporting periods MUST follow organizational policy.

- Report revisions MUST be documented.

- Confidential reports MUST follow access policy.

- Historical reports MUST remain available according to retention policy.

- Reporting activities MUST remain auditable.

---

## 13. Reporting State Transition

Describe conceptual states such as:

- Requested

- Preparing

- Validating

- Approved

- Published

- Archived

- Withdrawn

Explain valid business transitions without implementation.

---

## 14. Related Domain Events

Describe conceptual business events including:

- Reporting Requested

- Data Validated

- Report Approved

- Report Published

- Report Archived

- Report Corrected

---

## 15. Related Modules

Reference:

- Booking

- Payment

- Ticket

- Trip

- Cargo

- Cash Settlement

- Refund

- Audit

- Notification

Explain how each module contributes business information to reporting.

---

## 16. Related APIs

Reference conceptually:

- Reporting API

- Audit API

- Notification API

Do not describe endpoints.

---

## 17. Security Considerations

Describe:

- Report confidentiality

- Access authorization

- Data integrity

- Information classification

- Auditability

---

## 18. Audit Considerations

Describe why report preparation, approvals, revisions, publication, archival, and access SHOULD be fully auditable.

---

## 19. Failure Recovery Considerations

Describe conceptual recovery expectations for:

- Missing source information

- Reporting interruption

- Data correction

- Report regeneration

- Manual validation

---

## 20. References

Reference:

- Workflow README

- Reporting Module

- Audit Module

- Notification Module

- Booking Module

- Payment Module

- Cargo Module

- Cash Settlement Module

- Architecture Documentation

---

## 21. Glossary

Include definitions for:

- Report

- Reporting Period

- Operational Report

- Financial Report

- Management Report

- Compliance Report

- Business Information

- Report Lifecycle

---

## 22. Summary

Summarize how the Reporting Workflow provides a controlled, trusted, auditable, and business-oriented mechanism for transforming finalized business information into reports that support operational management, financial oversight, regulatory compliance, and executive decision-making.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Business-oriented

Business Intelligence-focused

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