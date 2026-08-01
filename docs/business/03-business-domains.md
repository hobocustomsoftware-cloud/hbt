You are a Distinguished Enterprise Business Architect, Enterprise Domain Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, Enterprise SaaS Architect, Enterprise Information Architect, and Technical Documentation Architect.

Create the file:

docs/business/03-business-domains.md

Purpose:

Define the Business Domains of the HoBo Transport Platform (HBT).

This document establishes the logical business domains, their responsibilities, ownership, boundaries, and relationships to support consistent business governance, enterprise scalability, and long-term platform evolution.

This document defines business domains only.

This document is NOT a software architecture document.

This document is NOT a module catalog.

This document is NOT an organization chart.

This document is NOT an implementation guide.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

No software architecture.

No APIs.

No database design.

No programming language references.

No source code.

Compatible with:

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

# Business Domains

## 1. Purpose

Explain the purpose of business domains and how they organize business responsibilities into logical boundaries that remain stable regardless of organizational or technical implementation.

---

## 2. Executive Summary

Describe how business domains improve governance, ownership, collaboration, scalability, and business consistency across multiple industries.

Clearly distinguish:

- Business Domain = Logical Business Responsibility

- Business Capability = What the business can do

- Business Process = How work is performed

- Software Module = Technical implementation

---

## 3. Scope

### In Scope

Include:

- Logical business domains

- Domain ownership

- Business responsibilities

- Domain boundaries

- Domain collaboration

- Cross-domain governance

### Out of Scope

Exclude:

- Technical implementation

- Database schemas

- APIs

- Organization charts

- Team structures

- Infrastructure

---

## 4. Objectives

Describe objectives including:

- Establish clear business ownership

- Define logical business boundaries

- Improve governance consistency

- Enable capability reuse

- Support enterprise scalability

- Reduce business ambiguity

- Support future industry expansion

---

## 5. Business Domain Categories

Describe conceptual domains including:

- Customer Domain

- Sales & Booking Domain

- Transportation Operations Domain

- Financial Domain

- Workforce Domain

- Asset Domain

- Partner Domain

- Communication Domain

- Reporting & Analytics Domain

- AI Assistance Domain

- Platform Administration Domain

Explain the business purpose, responsibilities, and value of each domain.

---

## 6. Domain Boundaries

Describe how domains SHOULD define:

- Business ownership

- Responsibilities

- Business information ownership

- Shared responsibilities

- Cross-domain collaboration

- Boundary governance

Explain why stable domain boundaries improve long-term maintainability.

---

## 7. Domain Principles

Describe conceptual principles including:

- Single business responsibility

- Clear ownership

- Loose business coupling

- High business cohesion

- Capability alignment

- Scalability

- Reusability

- Governance by design

- Long-term maintainability

Explain the business value of each principle.

---

## 8. Governance

Describe governance for:

- Domain ownership

- Boundary management

- Cross-domain governance

- Documentation governance

- Change governance

- Strategic alignment

- Continuous improvement

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Every business capability MUST belong to a business domain.

- Every business domain MUST have clearly defined ownership.

- Domain boundaries MUST remain stable.

- Cross-domain collaboration MUST be governed.

- Business responsibilities MUST NOT overlap without explicit governance.

- Domain evolution MUST preserve business consistency.

- Domain governance SHOULD be periodically reviewed.

---

## 10. Relationship with Other Documentation

Explain relationships with:

- Business Documentation README

- Business Principles

- Business Capabilities

- Business Processes

- Business Rules

- Industry Packs

- Architecture Documentation

- Module Documentation

- Workflow Documentation

---

## 11. References

Reference:

- Business Documentation README

- Business Principles

- Business Capabilities

- Architecture Documentation

- Standards Documentation

---

## 12. Glossary

Include concise, business-oriented definitions for at least:

- Business Domain

- Domain Boundary

- Domain Ownership

- Business Responsibility

- Business Cohesion

- Business Coupling

- Shared Responsibility

- Cross-domain Collaboration

- Domain Governance

- Capability Alignment

- Strategic Alignment

- Business Boundary

---

## 13. Summary

Summarize how the Business Domains establish a technology-neutral, vendor-neutral, business-oriented, enterprise-grade domain model that supports governance, scalability, clear ownership, and sustainable platform evolution across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Business Domain-focused

Enterprise Business Architecture-focused

Business-first

Architecture-first

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

Enterprise SaaS-focused

No implementation details

No software architecture

No APIs

No database design

No programming language references

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)