You are a Distinguished Enterprise SaaS Architect, Multi-Tenant Architecture Expert, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/003-tenant.md

Purpose:

Define the Tenant Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how organizations are isolated within the platform using a Multi-Tenant SaaS architecture.

The Tenant Module represents the highest business boundary for customer organizations.

A Tenant represents an independent organization (e.g., an Express Bus Company) that owns its own business data, users, branches, vehicles, routes, trips, and operational resources.

This document defines business responsibilities only.

No implementation details.

No source code.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Module Overview

Describe:

- Business Objective
- Business Value
- Responsibilities
- Out of Scope

4. Scope

Include:

In Scope

Out of Scope

5. Business Goals

6. Business Definition

Describe:

- What is a Tenant?
- Why a Tenant exists
- Tenant ownership model
- Tenant lifecycle

7. Responsibilities

The Tenant Module MUST manage:

- Tenant Registration
- Tenant Activation
- Tenant Suspension
- Tenant Reactivation
- Tenant Deactivation
- Tenant Configuration
- Tenant Branding
- Subscription Association
- Tenant Status

The Tenant Module MUST NOT manage:

- Authentication
- Authorization
- User Profiles
- Financial Transactions
- Trip Operations
- Ticket Sales

8. Tenant Lifecycle

Describe:

Registration

↓

Verification

↓

Provisioning

↓

Activation

↓

Operational

↓

Suspended

↓

Reactivated

↓

Archived

9. Tenant States

Describe:

Pending

Active

Suspended

Disabled

Archived

10. Tenant Configuration

Describe:

- Company Information
- Business Settings
- Time Zone
- Currency
- Language
- Regional Settings
- Branding
- Contact Information

11. Tenant Isolation

Describe principles for:

- Business Data Isolation
- User Isolation
- Resource Isolation
- Configuration Isolation
- Audit Isolation

12. Tenant Ownership

Describe ownership of:

- Branches
- Employees
- Vehicles
- Routes
- Trips
- Tickets
- Passengers
- Reports
- Settings

13. Subscription Association

Describe relationship with:

- Subscription Plans
- Trial
- Expiration
- Renewal
- Upgrade
- Downgrade

14. Integrations

Describe interaction with:

- Authentication Module
- Company Module
- Branch Module
- Subscription Module
- Audit Module
- Notification Module

15. Events

Include:

- Tenant Registered
- Tenant Verified
- Tenant Activated
- Tenant Suspended
- Tenant Reactivated
- Tenant Archived
- Tenant Configuration Updated

16. Permissions

Describe roles allowed to:

- Create Tenant
- Update Tenant
- Suspend Tenant
- Reactivate Tenant
- View Tenant
- Archive Tenant

17. Validation Rules

Describe:

- Registration Validation
- Business Name Validation
- Unique Tenant Identifier
- Required Configuration

18. Offline Behavior

Describe:

- Offline Access Policy
- Local Configuration Cache
- Synchronization
- Conflict Resolution

19. Audit Requirements

Every tenant lifecycle event MUST be auditable.

20. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every business organization MUST belong to exactly one Tenant.
- Every user MUST belong to exactly one Tenant.
- Business data MUST NOT cross Tenant boundaries.
- Archived Tenants MUST become read-only.
- Suspended Tenants MUST NOT perform operational activities.
- Tenant identifiers MUST remain immutable.

21. KPIs

Examples:

- Active Tenants
- Trial Conversion Rate
- Tenant Retention Rate
- Tenant Growth
- Average Tenant Lifetime

22. Error Scenarios

Describe business failures including:

- Duplicate Registration
- Invalid Configuration
- Subscription Expired
- Suspended Tenant Access
- Missing Required Information

23. Dependencies

Describe upstream and downstream dependencies.

24. Future Expansion

Describe future support for:

- Multi-Company Groups
- Franchise Organizations
- White-Label Tenants
- Marketplace Tenants
- Enterprise Organizations

25. References

Reference related Architecture documents, ADRs, Security Standards, and SaaS Policies.

26. Glossary

27. Summary

--------------------------------------------------
Mandatory Business Rules

A Tenant MUST be the highest business boundary.

Every business resource MUST belong to exactly one Tenant.

Tenant data MUST remain isolated.

Tenant identifiers MUST be globally unique.

Tenant lifecycle events MUST be auditable.

Suspended Tenants MUST NOT perform operational business activities.

Tenant configuration MUST be independent.

The Tenant Module MUST remain independent from authentication and authorization.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Multi-Tenant SaaS-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants