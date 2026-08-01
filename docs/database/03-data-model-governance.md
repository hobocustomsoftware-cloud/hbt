You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/database/03-data-model-governance.md

Purpose:

Define the Data Model Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for designing, reviewing, maintaining, and evolving logical data models across the platform.

This document defines data model governance only.

This document is NOT an implementation guide.

This document is NOT a database schema.

This document is NOT an ER diagram.

This document is NOT a database technology guide.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

No SQL examples.

No ORM examples.

No framework-specific guidance.

No programming language examples.

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

# Data Model Governance

## 1. Purpose

Explain the purpose of data model governance and its role in ensuring that business information is represented consistently, accurately, and sustainably across the platform.

---

## 2. Executive Summary

Describe how data model governance establishes a consistent logical representation of business information while remaining independent of implementation technologies.

Clearly distinguish:

- Business Domain = Business Capability

- Data Model = Logical Representation of Business Information

- Entity = Business Object

- Database Schema = Physical Implementation

---

## 3. Scope

### In Scope

Include:

- Logical data models

- Business entities

- Value objects

- Domain relationships

- Shared reference models

- Tenant-owned models

- Data model lifecycle

### Out of Scope

Exclude:

- Physical schema

- SQL implementation

- ORM implementation

- Database optimization

- Infrastructure design

---

## 4. Objectives

Describe objectives including:

- Maintain logical consistency

- Support Domain-Driven Design

- Reduce model duplication

- Preserve business meaning

- Improve maintainability

- Support platform scalability

- Enable future evolution

---

## 5. Data Model Components

Describe conceptual components including:

- Business Domains

- Aggregates

- Entities

- Value Objects

- Reference Data

- Shared Models

- Tenant-owned Models

- Derived Models

Explain the business significance of each component.

---

## 6. Data Model Lifecycle

Describe the conceptual lifecycle including:

- Business Requirement Identification

- Model Definition

- Domain Review

- Governance Approval

- Adoption

- Evolution

- Deprecation

- Retirement

Explain governance expectations for each stage.

---

## 7. Data Modeling Principles

Describe conceptual principles including:

- Business-first modeling

- Single source of truth

- Domain ownership

- Consistency

- High cohesion

- Low coupling

- Extensibility

- Maintainability

- Security by design

- Auditability

Explain the business purpose of each principle.

---

## 8. Governance

Describe governance for:

- Model ownership

- Domain ownership

- Review process

- Approval process

- Change governance

- Documentation governance

- Continuous improvement

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Every data model MUST represent a clearly defined business concept.

- Business entities MUST belong to a single business domain.

- Shared models MUST have a single authoritative owner.

- Duplicate logical models MUST be avoided.

- Data model changes MUST follow governance approval.

- Deprecated models MUST remain traceable.

- Data models SHOULD be periodically reviewed.

---

## 10. Security Considerations

Describe:

- Information confidentiality

- Tenant isolation

- Data ownership

- Information integrity

- Auditability

- Least necessary information

- Long-term information protection

---

## 11. Audit Considerations

Describe why model approvals, ownership assignments, governance reviews, lifecycle changes, documentation updates, and model retirement SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Principles

- Database Architecture

- Entity Governance

- Relationship Governance

- Security Documentation

- Architecture Documentation

- Module Documentation

---

## 13. References

Reference:

- Database Documentation README

- Database Principles

- Database Architecture

- Security Documentation

- Module Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Data Model

- Business Domain

- Aggregate

- Entity

- Value Object

- Reference Data

- Shared Model

- Tenant-owned Model

- Derived Model

- Domain Ownership

- Model Lifecycle

- Logical Consistency

---

## 15. Summary

Summarize how Data Model Governance establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for creating, governing, and evolving logical representations of business information across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Data Model Governance-focused

Information Architecture-focused

Architecture-first

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

No implementation details

No SQL examples

No ORM examples

No framework-specific guidance

No programming language examples

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)