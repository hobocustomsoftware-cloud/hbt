You are a Distinguished Enterprise Security Architect, Enterprise Authorization Architect, Access Control Specialist, Cybersecurity Governance Expert, Domain-Driven Design (DDD) Expert, Enterprise Solution Architect, and Technical Documentation Architect.

Create the file:

docs/security/04-authorization.md

Purpose:

Define the Authorization Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, and business rules for determining what authenticated identities are permitted to access and perform within the platform.

This document defines authorization governance only.

This document is NOT an implementation guide.

This document is NOT an authentication specification.

This document is NOT an identity management specification.

This document is NOT an API specification.

This document is NOT a database design.

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

# Authorization

## 1. Purpose

Explain the purpose of authorization and its role in ensuring authenticated identities are granted only the permissions necessary to perform approved business activities.

---

## 2. Executive Summary

Describe authorization as the process of evaluating whether an authenticated identity is permitted to perform a requested action on a protected business resource.

Clearly distinguish:

- Identity = Who

- Authentication = Identity Verification

- Authorization = Access Decision

- Audit = Accountability

Emphasize that successful authentication MUST NOT imply authorization.

---

## 3. Scope

### In Scope

Include:

- Access governance

- Permission governance

- Role governance

- Resource protection

- Business ownership

- Privileged access

- Delegated access

### Out of Scope

Exclude:

- Authentication mechanisms

- Identity lifecycle management

- Session management

- API implementation

- Database permissions

---

## 4. Authorization Objectives

Describe objectives including:

- Least privilege

- Controlled business access

- Protection of business resources

- Tenant isolation

- Accountability

- Regulatory compliance

- Operational flexibility

---

## 5. Protected Resources

Describe conceptual business resources including:

- Tenant

- Company

- Branch

- Booking

- Ticket

- Payment

- Cash Settlement

- Cargo

- Reports

- AI Assistant

- Administrative Functions

Explain why each resource requires authorization.

---

## 6. Authorization Subjects

Describe conceptual subjects including:

- Platform Administrator

- Tenant Administrator

- Branch Manager

- Operations Staff

- Finance Staff

- Driver

- Conductor

- Passenger

- Service Account

- External Integration

---

## 7. Authorization Model

Describe conceptually:

- Role-based authorization

- Attribute-based authorization

- Resource ownership

- Business context

- Delegated authority

- Temporary authorization

Explain that organizations MAY combine multiple authorization approaches based on business needs.

---

## 8. Access Governance

Describe governance for:

- Permission assignment

- Role assignment

- Access review

- Privileged access

- Temporary access

- Emergency access

- Access revocation

---

## 9. Business Authorization Rules

Describe conceptual business rules including:

- Ownership validation

- Tenant boundary validation

- Organizational responsibility

- Business approval requirements

- Segregation of duties

- Read versus write access

---

## 10. Security Considerations

Describe:

- Privileged access

- Cross-tenant access prevention

- Excessive permissions

- Separation of duties

- Access accountability

- Resource protection

---

## 11. Audit Considerations

Describe why authorization decisions, permission changes, privileged access, delegated access, temporary access, and access revocations SHOULD remain fully auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Security Principles

- IAM

- Authentication

- Multi-Tenant Security

- Audit & Logging

- API Security

- Architecture Documentation

---

## 13. References

Reference:

- Security Principles

- IAM Documentation

- Authentication Documentation

- Architecture Documentation

- Standards Documentation

---

## 14. Glossary

Include definitions for:

- Authorization

- Permission

- Role

- Resource

- Least Privilege

- Privileged Access

- Resource Ownership

- Delegated Access

- Separation of Duties

---

## 15. Summary

Summarize how authorization provides a consistent, auditable, business-oriented, and technology-neutral framework for controlling access to protected business resources across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Security Governance-focused

Authorization Governance-focused

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