You are a Distinguished Enterprise Solution Architect, Business Process Architect, Domain-Driven Design (DDD) Expert, Enterprise Workflow Architect, Business Process Management (BPM) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/workflows/README.md

Purpose:

Provide an overview of the Workflow Documentation for the HoBo Transport Platform (HBT).

This document establishes the purpose, governance, organization, and architectural relationship of workflow documentation across the platform.

This document defines documentation governance only.

This document is NOT a business workflow specification.

This document is NOT an implementation guide.

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

# Workflow Documentation

## 1. Purpose

Explain the purpose of workflow documentation and its role within the HBT documentation ecosystem.

---

## 2. Executive Summary

Describe why workflow documentation is essential for understanding business processes, cross-module interactions, operational consistency, and long-term maintainability.

---

## 3. Scope

Include:

### In Scope

Examples:

- Business workflows
- Operational processes
- Cross-module interactions
- Business actors
- Business events
- State transitions
- Business rules
- Exception flows

### Out of Scope

Examples:

- Source code
- API implementation
- Database schema
- UI design
- Infrastructure
- Deployment
- Technology-specific implementation

---

## 4. Workflow Documentation Philosophy

Describe principles including:

- Business First
- Documentation First
- Process-Oriented Design
- Domain-Driven Design
- Separation of Concerns
- Long-Term Maintainability
- Technology Neutrality

---

## 5. Relationship with Other Documentation

Explain how workflow documentation relates to:

- Architecture Documentation
- Module Documentation
- API Documentation
- Database Documentation
- Security Documentation
- Testing Documentation

Clarify that workflow documentation connects business modules together but does not replace any of these documents.

---

## 6. Workflow Categories

Describe conceptual workflow categories such as:

- Customer Workflows
- Operational Workflows
- Financial Workflows
- Cargo Workflows
- Administrative Workflows
- AI Workflows
- Reporting Workflows
- Platform Workflows

Explain their purpose without implementation details.

---

## 7. Workflow Components

Describe the common components of every workflow document, including:

- Purpose
- Actors
- Trigger
- Preconditions
- Main Workflow
- Alternative Flows
- Exception Flows
- Business Rules
- State Transitions
- Related Domain Events
- Related Modules
- Related APIs
- Security Considerations
- Audit Considerations
- Failure Recovery

---

## 8. Workflow Design Principles

Describe principles including:

- Clear Business Ownership
- Explicit Triggers
- Predictable State Changes
- Consistent Business Vocabulary
- Event Awareness
- Auditability
- Error Recovery
- Consumer Independence

---

## 9. Workflow Governance

Describe:

- Workflow Ownership
- Documentation Review
- Architecture Review
- Business Review
- Version Management
- Change Management
- Continuous Improvement

---

## 10. Workflow Organization

Describe the recommended document organization.

Example:

001-workflow-template.md

002-booking-workflow.md

003-payment-workflow.md

004-ticket-issuance-workflow.md

005-boarding-workflow.md

006-trip-operation-workflow.md

007-trip-closing-workflow.md

008-cash-settlement-workflow.md

009-refund-workflow.md

010-cargo-workflow.md

011-notification-workflow.md

012-reporting-workflow.md

013-ai-assistant-workflow.md

014-subscription-workflow.md

Explain that numbering reflects documentation order rather than execution order.

---

## 11. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every workflow MUST represent a complete business process.
- Workflow documentation MUST remain technology-neutral.
- Every workflow SHOULD identify all participating business actors.
- Workflow state transitions MUST be documented.
- Cross-module interactions MUST be explicitly identified.
- Workflow documentation MUST undergo architecture review before approval.
- Business terminology MUST remain consistent with platform standards.

---

## 12. References

Reference:

- Architecture Documentation
- Module Documentation
- API Documentation
- Security Documentation
- Database Documentation
- Testing Documentation

---

## 13. Glossary

Include definitions for:

- Workflow
- Business Process
- Actor
- Trigger
- State Transition
- Business Rule
- Domain Event
- Exception Flow

---

## 14. Summary

Summarize how workflow documentation bridges business requirements, architecture, modules, APIs, and implementation while improving consistency, communication, maintainability, and long-term platform evolution.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Architecture-focused

Business-focused

Workflow-focused

Governance-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

No implementation details

No framework-specific guidance

No programming language examples

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)