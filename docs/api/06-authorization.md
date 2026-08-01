You are a Distinguished Enterprise Security Architect, Identity and Access Management (IAM) Expert, Enterprise API Architect, REST API Governance Expert, Domain-Driven Design (DDD) Expert, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/api/06-authorization.md

Purpose:

Define the Authorization Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, principles, access control models, permission management, and authorization lifecycle for every API within the platform.

This document defines authorization governance only.

Authentication is documented separately.

This document is NOT an implementation guide.

This document MUST remain technology-neutral.

No framework-specific guidance.

No programming language examples.

No source code.

No implementation details.

This document applies to:

- Public APIs
- Internal APIs
- Mobile APIs
- Administrative APIs
- Partner APIs
- Integration APIs

The document MUST be AI Vendor Neutral and compatible with:

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

1. Purpose

2. Executive Summary

Explain the importance of authorization in enterprise API ecosystems.

3. Scope

Include:

- In Scope
- Out of Scope

4. Authorization Philosophy

Describe principles including:

- Least Privilege
- Default Deny
- Explicit Permission
- Separation of Duties
- Defense in Depth
- Business-Driven Access Control

5. Authorization Concepts

Define:

- Subject
- Resource
- Permission
- Role
- Policy
- Access Decision
- Authorization Context

6. Authorization Models

Describe conceptually:

- Role-Based Access Control (RBAC)
- Attribute-Based Access Control (ABAC)
- Policy-Based Access Control (PBAC)
- Resource-Based Authorization

Explain intended use cases without implementation guidance.

7. Multi-Tenant Authorization

Describe:

- Tenant Isolation
- Company Isolation
- Branch Isolation
- Cross-Tenant Restrictions
- Context-Aware Authorization

8. Permission Principles

Describe:

- Permission Assignment
- Permission Inheritance
- Permission Granularity
- Permission Revocation
- Temporary Permissions

9. Role Management Principles

Describe:

- Role Definition
- Role Assignment
- Role Hierarchy
- Role Separation
- Administrative Roles

10. Resource Access Control

Describe:

- Read Access
- Create Access
- Update Access
- Delete Access
- Administrative Operations
- Sensitive Resources

11. Authorization Decision Process

Describe conceptually:

- Identity Verification
- Context Evaluation
- Policy Evaluation
- Permission Verification
- Access Decision
- Audit Recording

12. Security Principles

Describe:

- Least Privilege
- Default Deny
- Segregation of Duties
- Privileged Access Protection
- Authorization Auditing

13. Consumer Responsibilities

Describe expectations for API consumers regarding proper use of granted permissions.

14. Provider Responsibilities

Describe expectations for API providers regarding enforcement of authorization policies and access control.

15. Governance

Describe:

- Authorization Policy Management
- Permission Review
- Role Review
- Compliance
- Audit Requirements

16. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every authenticated request MUST be authorized before accessing protected resources.
- Authorization MUST follow the principle of least privilege.
- Access MUST be denied by default unless explicitly granted.
- Cross-tenant access MUST NOT be permitted unless formally approved.
- Authorization decisions MUST be auditable.
- Permissions MUST be revocable.
- Administrative operations MUST require elevated privileges.

17. References

Reference:

- API Principles
- Authentication
- API Security
- Architecture Documentation
- Security Documentation
- Module Specifications

18. Glossary

Include terms such as:

- Authorization
- Permission
- Role
- Policy
- RBAC
- ABAC
- PBAC
- Resource
- Subject
- Least Privilege

19. Summary

Summarize how authorization protects business resources, enforces organizational boundaries, supports multi-tenant security, and enables secure, scalable access control across the HoBo Transport Platform.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Security-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

No implementation details

No framework-specific guidance

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)