You are a Distinguished Enterprise Privacy Architect, Data Protection Officer (DPO), Enterprise Security Architect, Privacy Governance Expert, Cybersecurity Governance Expert, Domain-Driven Design (DDD) Expert, Enterprise Solution Architect, and Technical Documentation Architect.

Create the file:

docs/security/07-privacy-and-pii.md

Purpose:

Define the Privacy and Personally Identifiable Information (PII) Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business requirements for collecting, processing, using, sharing, retaining, and disposing of personal information while protecting individual privacy and maintaining organizational accountability.

This document defines privacy governance only.

This document is NOT an implementation guide.

This document is NOT a legal compliance manual.

This document is NOT a database design.

This document is NOT an API specification.

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

# Privacy and Personally Identifiable Information (PII)

## 1. Purpose

Explain the purpose of protecting personal information and respecting individual privacy throughout the lifecycle of personal data.

---

## 2. Executive Summary

Describe how privacy governance ensures that personal information is collected, processed, stored, shared, retained, and disposed of responsibly.

Clearly distinguish:

- Personal Information = Information about an identifiable individual

- Privacy = Protection of individual rights

- Data Protection = Protection of all business information

- Confidentiality = Controlled access to information

---

## 3. Scope

### In Scope

Include:

- Passenger personal information

- Employee personal information

- Customer contact information

- Identity information

- Emergency contact information

- Consent management

- Data subject requests

- Personal information lifecycle

### Out of Scope

Exclude:

- Business information unrelated to individuals

- Authentication implementation

- Authorization implementation

- Encryption implementation

- Regulatory implementation details

---

## 4. Privacy Objectives

Describe objectives including:

- Protect individual privacy

- Respect personal information

- Support transparency

- Enable lawful business operations

- Reduce privacy risk

- Strengthen customer trust

- Support regulatory obligations

---

## 5. Personal Information Categories

Describe conceptual categories such as:

- Identity Information

- Contact Information

- Travel Information

- Payment-related Personal Information

- Employment Information

- Emergency Contact Information

- Operational Personal Information

Explain the business purpose of each category.

---

## 6. Personal Information Lifecycle

Describe conceptual stages including:

- Collection

- Validation

- Use

- Sharing

- Update

- Retention

- Archival

- Disposal

Explain governance for each stage.

---

## 7. Privacy Principles

Describe principles including:

- Purpose Limitation

- Data Minimization

- Accuracy

- Transparency

- Accountability

- Confidentiality

- Storage Limitation

- Individual Rights

Explain the business purpose of each principle.

---

## 8. Consent and Individual Rights

Describe governance for:

- Consent

- Withdrawal of Consent

- Information Access Requests

- Correction Requests

- Deletion Requests

- Restriction Requests

- Objection Requests

Explain conceptually without referencing specific regulations.

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Personal information MUST have a defined business purpose.

- Only the minimum necessary personal information SHOULD be collected.

- Personal information MUST remain accurate where practical.

- Personal information sharing MUST be authorized.

- Personal information retention MUST follow organizational policy.

- Disposal MUST be controlled and auditable.

- Privacy incidents MUST be documented.

---

## 10. Security Considerations

Describe:

- Confidentiality

- Privacy protection

- Unauthorized disclosure

- Identity protection

- Cross-tenant privacy

- Third-party information sharing

---

## 11. Audit Considerations

Describe why consent changes, information access, sharing activities, correction requests, deletion activities, and privacy-related decisions SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Security Principles

- Data Protection

- Multi-Tenant Security

- Audit & Logging

- AI Security

- Architecture Documentation

---

## 13. References

Reference:

- Security Documentation README

- Data Protection

- Architecture Documentation

- Standards Documentation

---

## 14. Glossary

Include definitions for:

- Privacy

- Personally Identifiable Information (PII)

- Consent

- Data Subject

- Data Minimization

- Purpose Limitation

- Confidentiality

- Privacy Incident

- Personal Information Lifecycle

---

## 15. Summary

Summarize how Privacy and PII Governance establishes a comprehensive, business-oriented, technology-neutral, and auditable framework for protecting personal information while supporting trusted business operations across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Privacy Governance-focused

Security Governance-focused

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