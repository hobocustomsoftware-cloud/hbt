You are a Distinguished Enterprise Database Architect, Enterprise Information Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, Enterprise Data Quality Architect, and Technical Documentation Architect.

Create the file:

docs/database/08-data-integrity.md

Purpose:

Define the Data Integrity Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for preserving the accuracy, consistency, completeness, reliability, and trustworthiness of business information throughout its lifecycle.

This document defines data integrity governance only.

This document is NOT an implementation guide.

This document is NOT a database constraint guide.

This document is NOT a transaction management guide.

This document is NOT a database technology guide.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

No SQL examples.

No ACID implementation guidance.

No constraint implementation guidance.

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

# Data Integrity

## 1. Purpose

Explain the purpose of data integrity and its role in maintaining trustworthy business information, supporting operational reliability, preserving business confidence, and enabling long-term enterprise growth.

---

## 2. Executive Summary

Describe how data integrity governance ensures business information remains accurate, complete, consistent, and reliable while remaining independent of implementation technologies.

Clearly distinguish:

- Data Integrity = Trustworthiness of Business Information

- Data Quality = Fitness for Business Use

- Data Validation = Verification Process

- Database Constraint = Physical Implementation

---

## 3. Scope

### In Scope

Include:

- Information accuracy

- Information completeness

- Information consistency

- Referential consistency

- Data quality governance

- Information lifecycle integrity

- Tenant-aware integrity

### Out of Scope

Exclude:

- SQL constraints

- Transaction implementation

- Database engine behavior

- ORM validation

- Infrastructure reliability

---

## 4. Objectives

Describe objectives including:

- Preserve business accuracy

- Maintain information consistency

- Improve information quality

- Support business trust

- Enable enterprise scalability

- Preserve historical reliability

- Support long-term governance

---

## 5. Integrity Categories

Describe conceptual categories including:

- Identity Integrity

- Referential Integrity

- Business Rule Integrity

- Operational Integrity

- Financial Integrity

- Audit Integrity

- Historical Integrity

- AI-related Information Integrity

Explain the business significance of each category.

---

## 6. Information Integrity Lifecycle

Describe the conceptual lifecycle including:

- Information Creation

- Validation

- Approval

- Operational Usage

- Change Management

- Historical Preservation

- Archiving

- Retirement

Explain governance expectations for each stage.

---

## 7. Data Integrity Principles

Describe conceptual principles including:

- Accuracy

- Completeness

- Consistency

- Traceability

- Accountability

- Single source of truth

- Business ownership

- Security by design

- Auditability

Explain the business purpose of each principle.

---

## 8. Governance

Describe governance for:

- Information ownership

- Data quality governance

- Integrity monitoring

- Change governance

- Documentation governance

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

- Business information MUST remain accurate.

- Information MUST remain complete for its intended purpose.

- Referential consistency MUST be preserved.

- Information changes MUST remain traceable.

- Historical information MUST preserve integrity.

- Data quality issues MUST be formally governed.

- Data integrity governance SHOULD be periodically reviewed.

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

Describe why integrity reviews, ownership assignments, quality assessments, governance approvals, lifecycle changes, and corrective actions SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Principles

- Database Architecture

- Data Model Governance

- Entity Governance

- Primary Key Strategy

- Relationship Governance

- Multi-Tenant Data

- Database Security

- Security Documentation

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

- Data Integrity

- Data Quality

- Accuracy

- Completeness

- Consistency

- Referential Integrity

- Historical Integrity

- Traceability

- Accountability

- Business Ownership

- Information Lifecycle

- Single Source of Truth

---

## 15. Summary

Summarize how Data Integrity Governance establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for preserving trustworthy business information across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Data Integrity Governance-focused

Enterprise Data Quality-focused

Information Architecture-focused

Architecture-first

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

No implementation details

No SQL examples

No ACID implementation guidance

No constraint implementation guidance

No ORM examples

No framework-specific guidance

No programming language examples

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)