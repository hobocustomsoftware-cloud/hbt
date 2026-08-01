You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/database/01-database-principles.md

Purpose:

Define the Database Principles for the HoBo Transport Platform (HBT).

This document establishes the foundational principles that govern how business information is organized, managed, protected, and evolved across the platform.

This document defines database principles only.

This document is NOT an implementation guide.

This document is NOT a schema definition.

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

# Database Principles

## 1. Purpose

Explain the purpose of database principles and their role in supporting consistent information management, enterprise scalability, maintainability, data quality, and long-term business evolution.

---

## 2. Executive Summary

Describe how database principles provide the foundation for governing business information throughout its lifecycle.

Clearly distinguish:

- Data = Business Information

- Database = Organized Information Repository

- Data Model = Logical Representation of Business Information

- Database Schema = Physical Representation

---

## 3. Scope

### In Scope

Include:

- Business information governance

- Data modeling principles

- Entity consistency

- Relationship consistency

- Data quality

- Data integrity

- Information lifecycle

- Multi-tenant information governance

### Out of Scope

Exclude:

- Database implementation

- Database engine selection

- SQL optimization

- Physical storage

- Infrastructure configuration

---

## 4. Objectives

Describe objectives including:

- Maintain business information consistency

- Support scalable architecture

- Preserve information integrity

- Enable maintainability

- Improve data quality

- Support tenant isolation

- Support long-term evolution

---

## 5. Core Principles

Describe conceptual principles including:

- Business-first data design

- Single source of truth

- Data integrity by design

- Consistency

- Simplicity

- Reusability

- Scalability

- Extensibility

- Security by design

- Auditability

Explain the business purpose of each principle.

---

## 6. Information Lifecycle Principles

Describe governance throughout the lifecycle:

- Creation

- Validation

- Storage

- Usage

- Update

- Archiving

- Retention

- Retirement

Explain governance expectations for each stage.

---

## 7. Data Governance Principles

Describe governance for:

- Data ownership

- Data stewardship

- Information quality

- Information classification

- Data accountability

- Information traceability

- Change governance

---

## 8. Database Governance

Describe governance for:

- Database ownership

- Design approval

- Data model governance

- Documentation requirements

- Change management

- Review process

- Continuous improvement

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Business information MUST have a clearly defined owner.

- Information MUST have a defined lifecycle.

- Database design MUST align with business domains.

- Information integrity MUST be preserved.

- Tenant information MUST remain isolated.

- Database documentation MUST remain current.

- Database principles SHOULD be periodically reviewed.

---

## 10. Security Considerations

Describe:

- Information confidentiality

- Information integrity

- Information availability

- Tenant isolation

- Least necessary information

- Auditability

- Long-term protection

---

## 11. Audit Considerations

Describe why database governance decisions, data ownership, lifecycle changes, design approvals, documentation updates, and governance reviews SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Architecture Documentation

- Module Documentation

- Security Documentation

- API Documentation

- Workflow Documentation

- Standards Documentation

---

## 13. References

Reference:

- Database Documentation README

- Architecture Documentation

- Security Documentation

- Module Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Data

- Database

- Data Model

- Entity

- Relationship

- Data Integrity

- Data Governance

- Data Steward

- Data Lifecycle

- Single Source of Truth

- Multi-Tenancy

- Auditability

---

## 15. Summary

Summarize how the Database Principles establish a technology-neutral, vendor-neutral, business-oriented, and maintainable foundation for managing business information consistently, securely, and sustainably across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Database Governance-focused

Information Architecture-focused

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