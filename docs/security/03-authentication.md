You are a Distinguished Enterprise Security Architect, Enterprise Identity Architect, Authentication Specialist, Cybersecurity Governance Expert, Domain-Driven Design (DDD) Expert, Enterprise Solution Architect, and Technical Documentation Architect.

Create the file:

docs/security/03-authentication.md

Purpose:

Define the Authentication Governance for the HoBo Transport Platform (HBT).

This document establishes the principles, governance, lifecycle, and business requirements for verifying the identity of users, services, and trusted entities before granting access to platform resources.

This document defines authentication governance only.

This document is NOT an implementation guide.

This document is NOT an authorization specification.

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

# Authentication

## 1. Purpose

Explain the purpose of authentication and its role in establishing trust before access to business resources is granted.

---

## 2. Executive Summary

Describe authentication as the process of identity verification.

Clearly distinguish:

- Identity = Claimed Identity

- Authentication = Identity Verification

- Authorization = Permission Evaluation

- Session = Trusted Interaction Context

Emphasize that successful authentication MUST NOT automatically grant unrestricted access.

---

## 3. Scope

### In Scope

Include:

- Human authentication

- Service authentication

- Trusted integrations

- Authentication lifecycle

- Session establishment

- Authentication governance

### Out of Scope

Exclude:

- Authorization decisions

- Role assignment

- Permission management

- Identity lifecycle management

- API implementation

---

## 4. Authentication Objectives

Describe objectives including:

- Verify identity

- Prevent unauthorized access

- Establish trusted sessions

- Support accountability

- Protect business resources

- Enable secure user experience

---

## 5. Authentication Subjects

Describe conceptual authentication subjects, including:

- Platform Administrator

- Tenant Administrator

- Branch Employee

- Driver

- Conductor

- Passenger

- Service Account

- External System

Explain why each subject requires authentication.

---

## 6. Authentication Lifecycle

Describe conceptual stages, including:

- Authentication Requested

- Identity Presented

- Verification Performed

- Authentication Successful

- Authentication Failed

- Session Established

- Session Expired

- Re-authentication Required

Explain governance without implementation.

---

## 7. Authentication Factors

Describe authentication factor categories conceptually, including:

- Knowledge Factors

- Possession Factors

- Inherence Factors

- Contextual Factors

Explain when stronger authentication SHOULD be required based on business risk.

---

## 8. Session Governance

Describe governance for:

- Session establishment

- Session continuity

- Session expiration

- Session termination

- Re-authentication

- Concurrent sessions

Use business language only.

---

## 9. Authentication Governance

Describe governance for:

- Authentication policies

- Failed authentication handling

- Account protection

- Exceptional access

- Trusted devices

- Authentication review

---

## 10. Security Considerations

Describe:

- Credential confidentiality

- Authentication integrity

- Session protection

- Privileged authentication

- High-risk authentication

- Identity assurance

---

## 11. Audit Considerations

Describe why successful authentication, failed authentication, session creation, session termination, privileged authentication, and exceptional authentication events SHOULD remain auditable.

---

## 12. Relationship with Other Documentation

Explain relationships with:

- Identity & Access Management

- Authorization

- Multi-Tenant Security

- Audit & Logging

- API Security

- Architecture Documentation

---

## 13. References

Reference:

- Security Principles

- IAM Documentation

- Architecture Documentation

- Standards Documentation

---

## 14. Glossary

Include definitions for:

- Authentication

- Identity Verification

- Credential

- Session

- Multi-factor Authentication

- Trusted Device

- Authentication Assurance

- Re-authentication

---

## 15. Summary

Summarize how authentication establishes trusted identities and secure access foundations while remaining separate from authorization and identity management.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Security Governance-focused

Authentication Governance-focused

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