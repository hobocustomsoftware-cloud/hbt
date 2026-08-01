You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/database/04-entity-governance.md

Purpose:

Define the Entity Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for defining, owning, managing, reviewing, and evolving business entities across the platform.

This document defines entity governance only.

This document is NOT an implementation guide.

This document is NOT a database schema.

This document is NOT an entity catalog.

This document is NOT a table definition.

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

# Entity Governance

## 1. Purpose

Explain the purpose of entity governance and its role in ensuring that business entities are consistently defined, governed, owned, and maintained throughout their lifecycle.

---

## 2. Executive Summary

Describe how entity governance enables consistent representation of business concepts while remaining independent of implementation technologies.

Clearly distinguish:

- Business Entity = Business Concept

- Entity = Identifiable Business Object

- Value Object = Descriptive Business Information

- Database Table = Physical Implementation

---

## 3. Scope

### In Scope

Include:

- Business entities

- Entity ownership

- Entity lifecycle

- Entity governance

- Entity consistency

- Shared entities

- Tenant-owned entities

### Out of Scope

Exclude:

- Table implementation

- Database schema

- SQL design

- ORM mapping

- Physical optimization

---

## 4. Objectives

Describe objectives including:

- Standardize business entities

- Preserve business meaning

- Reduce duplication

- Support domain ownership

- Improve maintainability

- Enable scalability

- Support long-term evolution

---

## 5. Entity Categories

Describe conceptual categories including:

- Core Business Entities

- Transactional Entities

- Master Data Entities

- Reference Entities

- Configuration Entities

- Audit Entities

- AI-related Entities

Explain the business significance of each category.

---

## 6. Entity Lifecycle

Describe the conceptual lifecycle including:

- Business Need Identification

- Entity Definition

- Governance Review

- Approval

- Adoption

- Evolution

- Deprecation

- Retirement

Explain governance expectations for each stage.

---

## 7. Entity Principles

Describe conceptual principles including:

- Business-first definition

- Single responsibility

- Single source of truth

- Stable identity

- Domain ownership

- High cohesion

- Low coupling

- Extensibility

- Auditability

Explain the business purpose of each principle.

---

## 8. Entity Governance

Describe governance for:

- Entity ownership

- Domain ownership

- Entity approval

- Naming governance

- Documentation governance

- Change management

- Continuous improvement

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Every entity MUST represent a single business concept.

- Every entity MUST have a clearly defined owner.

- Entity names MUST remain business-oriented.

- Duplicate entities MUST NOT exist.

- Entity changes MUST receive governance approval.

- Deprecated entities MUST remain historically traceable.

- Entity documentation SHOULD be periodically reviewed.

---

## 10. Security Considerations

Describe:

- Entity ownership

- Confidential business information

- Tenant isolation

- Data integrity

- Auditability

- Least necessary information

- Long-term governance

---

## 11. Audit Considerations

Describe why entity approvals, ownership assignments, lifecycle changes, naming decisions, governance reviews, and retirement decisions SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Principles

- Database Architecture

- Data Model Governance

- Primary Key Strategy

- Relationship Governance

- Security Documentation

- Module Documentation

- Architecture Documentation

---

## 13. References

Reference:

- Database Documentation README

- Data Model Governance

- Database Architecture

- Security Documentation

- Module Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Entity

- Business Entity

- Master Data

- Transactional Entity

- Reference Entity

- Configuration Entity

- Audit Entity

- Entity Ownership

- Stable Identity

- Entity Lifecycle

- Domain Ownership

- Business Concept

---

## 15. Summary

Summarize how Entity Governance establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for defining, governing, and evolving business entities consistently across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Entity Governance-focused

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