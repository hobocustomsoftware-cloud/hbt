You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/database/02-database-architecture.md

Purpose:

Define the Database Architecture for the HoBo Transport Platform (HBT).

This document establishes the architectural principles, logical organization, governance, and structural boundaries for managing business information across the platform.

This document defines database architecture only.

This document is NOT an implementation guide.

This document is NOT a schema definition.

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

# Database Architecture

## 1. Purpose

Explain the purpose of database architecture and its role in organizing business information, supporting enterprise scalability, maintaining consistency, and enabling long-term platform evolution.

---

## 2. Executive Summary

Describe how the database architecture provides a logical structure for managing business information while remaining independent of any specific database technology.

Clearly distinguish:

- Database Architecture = Organizational Structure of Information

- Data Model = Logical Representation of Business Domains

- Database Schema = Physical Implementation

- Database Engine = Technology Platform

---

## 3. Scope

### In Scope

Include:

- Logical database architecture

- Business domain organization

- Information boundaries

- Data ownership

- Multi-tenant information organization

- Shared platform information

- Cross-domain relationships

### Out of Scope

Exclude:

- Database engine selection

- Physical storage design

- Performance tuning

- SQL implementation

- Infrastructure architecture

---

## 4. Architecture Objectives

Describe objectives including:

- Organize business information logically

- Support Domain-Driven Design

- Promote modular architecture

- Enable enterprise scalability

- Preserve information consistency

- Support tenant isolation

- Facilitate future platform growth

---

## 5. Architectural Building Blocks

Describe conceptual building blocks including:

- Business Domains

- Entities

- Value Objects

- Relationships

- Shared Reference Data

- Tenant-owned Data

- Platform-owned Data

- Audit Information

Explain the business significance of each building block.

---

## 6. Architectural Organization

Describe the logical organization of information including:

- Core Platform Information

- Tenant Information

- Operational Information

- Financial Information

- Configuration Information

- Reporting Information

- Audit Information

- AI-related Information

Explain governance expectations for each area.

---

## 7. Architecture Principles

Describe conceptual principles including:

- Domain-driven organization

- Separation of concerns

- Information ownership

- Single source of truth

- High cohesion

- Low coupling

- Scalability

- Extensibility

- Security by design

- Auditability

Explain the business purpose of each principle.

---

## 8. Architecture Governance

Describe governance for:

- Architecture ownership

- Domain ownership

- Data ownership

- Architecture review

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

- Every business domain MUST have clearly defined ownership.

- Shared information MUST have a single authoritative source.

- Database architecture MUST align with business domains.

- Cross-domain dependencies MUST remain controlled.

- Tenant-owned information MUST remain isolated.

- Architecture documentation MUST remain current.

- Architecture reviews SHOULD be conducted periodically.

---

## 10. Security Considerations

Describe:

- Tenant isolation

- Information confidentiality

- Information integrity

- Information availability

- Least necessary information

- Auditability

- Long-term information protection

---

## 11. Audit Considerations

Describe why architectural decisions, domain ownership, structural changes, governance approvals, documentation updates, and architecture reviews SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Principles

- Architecture Documentation

- ADR Documentation

- Module Documentation

- Security Documentation

- API Documentation

- Workflow Documentation

- Standards Documentation

---

## 13. References

Reference:

- Database Documentation README

- Database Principles

- Architecture Documentation

- Security Documentation

- Module Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Database Architecture

- Business Domain

- Entity

- Value Object

- Shared Data

- Tenant Data

- Platform Data

- Information Ownership

- Domain Boundary

- Information Boundary

- Reference Data

- Audit Information

---

## 15. Summary

Summarize how the Database Architecture establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for organizing business information consistently across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Database Architecture-focused

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