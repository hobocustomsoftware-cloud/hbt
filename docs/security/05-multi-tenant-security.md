You are a Distinguished Enterprise Security Architect, Multi-Tenant SaaS Architect, Enterprise Solution Architect, Cybersecurity Governance Expert, Domain-Driven Design (DDD) Expert, and Technical Documentation Architect.

Create the file:

docs/security/05-multi-tenant-security.md

Purpose:

Define the Multi-Tenant Security Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business rules for protecting tenant isolation, ensuring that each tenant's business data, resources, users, and operations remain securely separated from all other tenants.

This document defines security governance only.

This document is NOT an implementation guide.

This document is NOT a database isolation guide.

This document is NOT an infrastructure design.

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

# Multi-Tenant Security

## 1. Purpose

Explain the purpose of multi-tenant security and its role in protecting customer organizations operating on a shared platform.

---

## 2. Executive Summary

Describe how tenant isolation enables multiple independent organizations to securely share the same platform while maintaining strict separation of business information.

Clearly distinguish:

- Platform = Shared Service

- Tenant = Independent Customer Organization

- Shared Infrastructure = Common Platform Resources

- Tenant Isolation = Business Separation

---

## 3. Scope

### In Scope

Include:

- Tenant isolation

- Data isolation

- Organizational boundaries

- Access boundaries

- Administrative boundaries

- Cross-tenant protection

- Shared platform governance

### Out of Scope

Exclude:

- Infrastructure implementation

- Database implementation

- Authentication mechanisms

- Authorization algorithms

- Network security implementation

---

## 4. Objectives

Describe objectives including:

- Protect tenant confidentiality

- Prevent cross-tenant access

- Maintain business independence

- Support regulatory compliance

- Enable secure SaaS scalability

- Protect customer trust

---

## 5. Tenant Boundaries

Describe conceptual boundaries including:

- Organizational boundary

- Business data boundary

- Operational boundary

- Administrative boundary

- Reporting boundary

- AI analysis boundary

- Audit boundary

Explain why each boundary MUST remain isolated.

---

## 6. Shared Platform Resources

Describe conceptually which resources MAY be shared, including:

- Platform infrastructure

- Shared platform services

- Platform administration

- Common reference information

Explain that sharing MUST NOT compromise tenant isolation.

---

## 7. Isolation Principles

Describe conceptual principles including:

- Data isolation

- Access isolation

- Administrative isolation

- Operational isolation

- Reporting isolation

- AI context isolation

- Audit isolation

---

## 8. Cross-Tenant Governance

Describe governance for:

- Cross-tenant access requests

- Platform support activities

- Emergency administrative access

- Data migration

- Tenant onboarding

- Tenant offboarding

---

## 9. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- Tenant data MUST remain isolated.

- Cross-tenant access MUST require explicit organizational authorization.

- Shared platform components MUST NOT expose tenant information.

- Administrative activities MUST remain auditable.

- Tenant ownership MUST remain traceable.

- Tenant lifecycle events MUST be documented.

---

## 10. Security Considerations

Describe:

- Tenant confidentiality

- Data segregation

- Shared resource protection

- Administrative access

- Information leakage prevention

- Regulatory considerations

---

## 11. Audit Considerations

Describe why tenant creation, tenant changes, cross-tenant administrative activities, tenant migration, tenant archival, and tenant deletion SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Security Principles

- Identity & Access Management

- Authentication

- Authorization

- Data Protection

- API Security

- Audit & Logging

- Architecture Documentation

---

## 13. References

Reference:

- Security Documentation README

- Architecture Documentation

- Tenant Module

- Company Module

- Branch Module

- Standards Documentation

---

## 14. Glossary

Include definitions for:

- Tenant

- Multi-Tenancy

- Tenant Isolation

- Shared Infrastructure

- Organizational Boundary

- Cross-Tenant Access

- Administrative Boundary

- Data Segregation

---

## 15. Summary

Summarize how multi-tenant security establishes a trusted, auditable, business-oriented, and technology-neutral governance framework that protects the independence, confidentiality, and integrity of every tenant operating on the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Security Governance-focused

Multi-Tenant Governance-focused

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