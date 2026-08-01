You are a Distinguished Enterprise Security Architect, Enterprise Information Protection Architect, Data Governance Expert, Cybersecurity Governance Expert, Domain-Driven Design (DDD) Expert, Enterprise Solution Architect, and Technical Documentation Architect.

Create the file:

docs/security/06-data-protection.md

Purpose:

Define the Data Protection Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for protecting business information throughout its lifecycle, ensuring confidentiality, integrity, availability, and appropriate handling of organizational data.

This document defines data protection governance only.

This document is NOT an implementation guide.

This document is NOT an encryption implementation guide.

This document is NOT a database design.

This document is NOT a backup implementation guide.

This document MUST remain technology-neutral.

This document MUST remain vendor-neutral.

No implementation details.

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

# Data Protection

## 1. Purpose

Explain the purpose of protecting business information throughout its lifecycle and its role in preserving confidentiality, integrity, availability, and organizational trust.

---

## 2. Executive Summary

Describe how data protection governs the collection, classification, storage, use, sharing, retention, archival, and disposal of business information.

Clearly distinguish:

- Data = Business Information

- Data Protection = Information Safeguarding

- Privacy = Protection of Personal Information

- Backup = Business Continuity Capability

---

## 3. Scope

### In Scope

Include:

- Business information

- Operational information

- Financial information

- Customer information

- Reporting information

- Audit information

- AI business information

- Data lifecycle governance

### Out of Scope

Exclude:

- Privacy regulation implementation

- Authentication mechanisms

- Authorization algorithms

- Database implementation

- Infrastructure implementation

---

## 4. Data Protection Objectives

Describe objectives including:

- Confidentiality

- Integrity

- Availability

- Information reliability

- Business continuity

- Regulatory support

- Customer trust

---

## 5. Data Classification

Describe conceptual data classifications such as:

- Public

- Internal

- Confidential

- Restricted

Explain the business purpose and expected handling requirements for each classification.

---

## 6. Data Lifecycle

Describe the conceptual lifecycle including:

- Data Creation

- Data Collection

- Data Validation

- Data Storage

- Data Usage

- Data Sharing

- Data Retention

- Data Archival

- Data Disposal

Explain governance for each stage.

---

## 7. Data Ownership

Describe governance for:

- Business ownership

- Data stewardship

- Custodianship

- Accountability

- Data quality responsibilities

---

## 8. Data Handling Principles

Describe conceptual principles including:

- Minimum necessary use

- Information accuracy

- Data integrity

- Secure sharing

- Controlled retention

- Secure disposal

- Business accountability

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Business information MUST be classified.

- Confidential information MUST receive additional protection.

- Information owners MUST remain accountable.

- Information retention MUST follow organizational policy.

- Data disposal MUST be authorized.

- Data quality SHOULD be maintained.

- Business information MUST remain traceable.

---

## 10. Security Considerations

Describe:

- Information confidentiality

- Information integrity

- Availability

- Information ownership

- Unauthorized disclosure

- Data loss prevention

---

## 11. Audit Considerations

Describe why classification changes, ownership changes, retention decisions, archival activities, disposal activities, and information access SHOULD remain auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Security Principles

- Multi-Tenant Security

- Privacy & PII

- Audit & Logging

- Backup & Disaster Recovery

- AI Security

- Architecture Documentation

---

## 13. References

Reference:

- Security Documentation README

- Security Principles

- Multi-Tenant Security

- Architecture Documentation

- Standards Documentation

---

## 14. Glossary

Include definitions for:

- Data Protection

- Data Classification

- Confidential Information

- Restricted Information

- Data Lifecycle

- Data Steward

- Data Custodian

- Data Retention

- Data Disposal

- Information Integrity

---

## 15. Summary

Summarize how data protection establishes a comprehensive, business-oriented, technology-neutral, and auditable governance framework that safeguards business information throughout its entire lifecycle.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Security Governance-focused

Data Governance-focused

Architecture-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

Long-term maintainable

No implementation details

No framework-specific guidance

No programming language examples

No source code

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)