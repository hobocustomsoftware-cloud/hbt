You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/database/05-primary-key-strategy.md

Purpose:

Define the Primary Key Strategy for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for assigning, managing, protecting, and governing unique identities for business entities across the platform.

This document defines identity governance only.

This document is NOT an implementation guide.

This document is NOT a database schema.

This document is NOT a database technology comparison.

This document does NOT mandate any specific identifier technology.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

No SQL examples.

No UUID implementation guidance.

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

# Primary Key Strategy

## 1. Purpose

Explain the purpose of identity governance and its role in uniquely identifying business entities, preserving referential consistency, supporting traceability, and enabling long-term platform evolution.

---

## 2. Executive Summary

Describe how a primary key strategy provides stable business identity while remaining independent of implementation technologies.

Clearly distinguish:

- Business Identity = Long-lived Identity of a Business Entity

- Primary Key = Unique Identifier

- Business Identifier = Human-recognizable Identifier

- Database Technology = Implementation Mechanism

---

## 3. Scope

### In Scope

Include:

- Entity identity

- Identity governance

- Stable identifiers

- Identity lifecycle

- Cross-domain identity

- Tenant identity considerations

- Identity consistency

### Out of Scope

Exclude:

- Identifier generation algorithms

- UUID implementation

- Integer implementation

- Database engine behavior

- Storage optimization

---

## 4. Objectives

Describe objectives including:

- Ensure unique entity identity

- Preserve long-term stability

- Support referential integrity

- Improve traceability

- Enable scalability

- Support tenant isolation

- Simplify governance

---

## 5. Identity Categories

Describe conceptual categories including:

- Platform Identity

- Tenant Identity

- Business Entity Identity

- Transaction Identity

- Reference Identity

- Audit Identity

- AI-related Identity

Explain the business significance of each category.

---

## 6. Identity Lifecycle

Describe the conceptual lifecycle including:

- Identity Assignment

- Identity Validation

- Operational Usage

- Cross-domain Reference

- Historical Preservation

- Deprecation

- Retirement

Explain governance expectations for each stage.

---

## 7. Identity Principles

Describe conceptual principles including:

- Uniqueness

- Stability

- Immutability

- Traceability

- Domain ownership

- Consistency

- Independence from business meaning

- Security by design

- Auditability

Explain the business purpose of each principle.

---

## 8. Identity Governance

Describe governance for:

- Identity ownership

- Assignment governance

- Naming governance

- Cross-domain governance

- Documentation governance

- Change governance

- Continuous improvement

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Every business entity MUST have a unique identity.

- Entity identities MUST remain stable throughout the entity lifecycle.

- Primary keys MUST NOT contain changing business meaning.

- Identity reuse MUST NOT occur.

- Cross-domain references MUST preserve identity consistency.

- Identity governance changes MUST receive formal approval.

- Identity strategy SHOULD be periodically reviewed.

---

## 10. Security Considerations

Describe:

- Identity confidentiality where applicable

- Identity integrity

- Tenant-aware identity

- Identity traceability

- Least necessary exposure

- Auditability

- Long-term governance

---

## 11. Audit Considerations

Describe why identity assignments, governance approvals, lifecycle changes, cross-domain references, identity retirements, and governance reviews SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Principles

- Database Architecture

- Data Model Governance

- Entity Governance

- Relationship Governance

- Data Integrity

- Security Documentation

---

## 13. References

Reference:

- Database Documentation README

- Entity Governance

- Data Model Governance

- Security Documentation

- Architecture Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Primary Key

- Business Identity

- Business Identifier

- Stable Identity

- Identity Lifecycle

- Referential Integrity

- Identity Ownership

- Cross-domain Reference

- Identity Governance

- Immutable Identity

- Traceability

- Identity Consistency

---

## 15. Summary

Summarize how the Primary Key Strategy establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for governing stable identities across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Identity Governance-focused

Database Architecture-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

No implementation details

No SQL examples

No UUID comparisons

No ORM examples

No framework-specific guidance

No programming language examples

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)