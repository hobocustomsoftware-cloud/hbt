You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, Enterprise SaaS Architect, and Technical Documentation Architect.

Create the file:

docs/database/07-multi-tenant-data.md

Purpose:

Define the Multi-Tenant Data Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for organizing, owning, isolating, sharing, and evolving tenant-related business information across the platform.

This document defines multi-tenant data governance only.

This document is NOT an implementation guide.

This document is NOT a database architecture comparison.

This document is NOT a database schema.

This document does NOT prescribe shared-database, separate-database, or hybrid implementation strategies.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

No SQL examples.

No database topology guidance.

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

# Multi-Tenant Data Governance

## 1. Purpose

Explain the purpose of multi-tenant data governance and its role in protecting tenant information, ensuring isolation, supporting scalability, and enabling secure platform growth.

---

## 2. Executive Summary

Describe how multi-tenant governance enables multiple organizations to operate securely within a shared platform while preserving ownership and business boundaries.

Clearly distinguish:

- Platform-owned Information

- Tenant-owned Information

- Shared Reference Information

- Cross-tenant Information

---

## 3. Scope

### In Scope

Include:

- Tenant ownership

- Tenant information

- Shared reference information

- Cross-tenant governance

- Tenant lifecycle

- Tenant boundaries

- Tenant isolation

### Out of Scope

Exclude:

- Database topology

- Physical deployment

- Infrastructure architecture

- SQL implementation

- Storage optimization

---

## 4. Objectives

Describe objectives including:

- Protect tenant ownership

- Preserve tenant isolation

- Support enterprise scalability

- Enable controlled information sharing

- Maintain governance consistency

- Improve maintainability

- Support long-term platform evolution

---

## 5. Information Categories

Describe conceptual categories including:

- Platform-owned Information

- Tenant-owned Information

- Shared Reference Information

- Cross-tenant Shared Information

- Tenant Configuration Information

- Tenant Operational Information

- Tenant Financial Information

- Tenant Audit Information

Explain the business significance of each category.

---

## 6. Tenant Information Lifecycle

Describe the conceptual lifecycle including:

- Tenant Registration

- Information Initialization

- Operational Usage

- Business Growth

- Tenant Evolution

- Suspension

- Archiving

- Retirement

Explain governance expectations for each stage.

---

## 7. Multi-Tenant Principles

Describe conceptual principles including:

- Tenant ownership

- Tenant isolation

- Least necessary sharing

- Controlled cross-tenant interaction

- Business boundary preservation

- Scalability

- Security by design

- Auditability

- Long-term maintainability

Explain the business purpose of each principle.

---

## 8. Governance

Describe governance for:

- Tenant ownership

- Information ownership

- Cross-tenant governance

- Shared reference governance

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

- Every tenant MUST own its business information.

- Tenant information MUST remain isolated from other tenants.

- Shared reference information MUST have a single authoritative owner.

- Cross-tenant information sharing MUST be explicitly governed.

- Tenant lifecycle changes MUST be formally governed.

- Tenant retirement MUST preserve governance requirements.

- Multi-tenant governance SHOULD be periodically reviewed.

---

## 10. Security Considerations

Describe:

- Tenant isolation

- Information confidentiality

- Information integrity

- Least privilege

- Shared information protection

- Auditability

- Long-term governance

---

## 11. Audit Considerations

Describe why tenant ownership assignments, lifecycle changes, cross-tenant governance decisions, information sharing approvals, governance reviews, and tenant retirement SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Architecture

- Entity Governance

- Data Integrity

- Database Security

- Security Documentation

- Module Documentation

- Architecture Documentation

---

## 13. References

Reference:

- Database Documentation README

- Database Architecture

- Security Documentation

- Module Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Tenant

- Multi-Tenancy

- Tenant-owned Information

- Platform-owned Information

- Shared Reference Information

- Cross-tenant Information

- Tenant Isolation

- Tenant Lifecycle

- Information Ownership

- Business Boundary

- Shared Governance

- Tenant Governance

---

## 15. Summary

Summarize how Multi-Tenant Data Governance establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for protecting tenant ownership, preserving information boundaries, and enabling scalable enterprise SaaS operations across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Multi-Tenant Governance-focused

Enterprise SaaS-focused

Information Architecture-focused

Architecture-first

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

No implementation details

No SQL examples

No database topology guidance

No ORM examples

No framework-specific guidance

No programming language examples

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)