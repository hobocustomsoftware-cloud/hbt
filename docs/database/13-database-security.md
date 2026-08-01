You are a Distinguished Enterprise Security Architect, Enterprise Database Architect, Enterprise Information Security Architect, Data Governance Architect, Enterprise Solution Architect, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/database/13-database-security.md

Purpose:

Define the Database Security Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for protecting business information throughout its lifecycle while supporting confidentiality, integrity, availability, compliance, and long-term enterprise sustainability.

This document defines database security governance only.

This document is NOT an implementation guide.

This document is NOT a database hardening guide.

This document is NOT a network security guide.

This document is NOT an encryption implementation guide.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

No SQL examples.

No encryption algorithms.

No infrastructure security guidance.

No IAM implementation guidance.

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

# Database Security Governance

## 1. Purpose

Explain the purpose of database security governance and its role in protecting business information, supporting trust, reducing organizational risk, and enabling secure enterprise growth.

---

## 2. Executive Summary

Describe how database security governance protects business information throughout its lifecycle while remaining independent of implementation technologies.

Clearly distinguish:

- Database Security = Business Information Protection

- Information Security = Organizational Security Discipline

- Security Controls = Governance Requirements

- Technical Security = Implementation Activity

---

## 3. Scope

### In Scope

Include:

- Information confidentiality

- Information integrity

- Information availability

- Information ownership

- Tenant-aware security

- Security governance

- Compliance support

### Out of Scope

Exclude:

- Encryption implementation

- Network security

- Infrastructure security

- SQL security configuration

- Database engine configuration

---

## 4. Objectives

Describe objectives including:

- Protect confidential information

- Preserve information integrity

- Maintain information availability

- Support compliance

- Reduce organizational risk

- Enable enterprise scalability

- Support long-term sustainability

---

## 5. Security Categories

Describe conceptual categories including:

- Confidential Information

- Internal Business Information

- Public Information

- Financial Information

- Audit Information

- Tenant Information

- AI-related Information

Explain the business significance of each category.

---

## 6. Security Lifecycle

Describe the conceptual lifecycle including:

- Information Classification

- Risk Assessment

- Protection

- Controlled Access

- Monitoring

- Periodic Review

- Retirement

Explain governance expectations for each stage.

---

## 7. Security Principles

Describe conceptual principles including:

- Confidentiality

- Integrity

- Availability

- Least privilege

- Need-to-know

- Defense in depth

- Security by design

- Zero trust mindset

- Accountability

- Auditability

Explain the business purpose of each principle.

---

## 8. Governance

Describe governance for:

- Security ownership

- Information classification

- Risk governance

- Security review

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

- Confidential business information MUST be protected.

- Information access MUST follow least privilege principles.

- Tenant information MUST remain isolated.

- Security decisions MUST be formally governed.

- Security reviews MUST be periodically performed.

- Security incidents MUST be documented and reviewed.

- Security governance SHOULD evolve alongside platform growth.

---

## 10. Security Considerations

Describe:

- Confidentiality

- Integrity

- Availability

- Tenant isolation

- Risk management

- Business continuity

- Long-term protection

---

## 11. Audit Considerations

Describe why security classifications, risk assessments, access approvals, governance decisions, security reviews, incident responses, and policy changes SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Database README

- Database Principles

- Multi-Tenant Data

- Data Integrity

- Audit Data

- Data Lifecycle

- Performance Principles

- Security Documentation

- Module Documentation

- Architecture Documentation

---

## 13. References

Reference:

- Database Documentation README

- Database Principles

- Security Documentation

- Architecture Documentation

- Standards Documentation

---

## 14. Glossary

Include concise, business-oriented definitions for at least:

- Database Security

- Confidentiality

- Integrity

- Availability

- Least Privilege

- Need-to-Know

- Defense in Depth

- Zero Trust

- Information Classification

- Security Governance

- Risk Management

- Business Continuity

---

## 15. Summary

Summarize how Database Security Governance establishes a technology-neutral, vendor-neutral, business-oriented, and maintainable framework for protecting business information across the HoBo Transport Platform while supporting enterprise trust, compliance, resilience, and long-term sustainability.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Database Security Governance-focused

Enterprise Information Security-focused

Information Governance-focused

Architecture-first

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

No implementation details

No SQL examples

No encryption algorithms

No infrastructure security guidance

No IAM implementation guidance

No ORM examples

No framework-specific guidance

No programming language examples

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)