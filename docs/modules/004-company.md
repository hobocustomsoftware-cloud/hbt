You are a Distinguished Enterprise Domain Architect, Transportation Business Architect, Domain-Driven Design (DDD) Expert, Enterprise SaaS Architect, Principal Business Analyst, and Technical Documentation Architect.

Create the file:

docs/modules/004-company.md

Purpose:

Define the Company Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how transportation companies are represented within the platform.

The Company Module defines the business identity of an organization operating transportation services.

A Company represents the legal and operational business entity responsible for providing transport services.

This module is independent from tenant management and authentication.

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

- What is a Company?
- Legal Organization
- Operational Organization
- Relationship with Tenant
- Business Identity
- Ownership

7. Responsibilities

The Company Module MUST manage:

- Company Profile
- Legal Name
- Commercial Name
- Registration Number
- Tax Information
- Contact Information
- Business Address
- Company Branding
- Business Status

The Company Module MUST NOT manage:

- Authentication
- Authorization
- Ticket Sales
- Trips
- Payments
- Vehicles
- Employees

8. Company Lifecycle

Describe:

Registration

↓

Verification

↓

Activation

↓

Operational

↓

Suspended

↓

Closed

↓

Archived

9. Company Information

Describe:

- Legal Name
- Display Name
- Logo
- Brand Colors
- Contact Numbers
- Email
- Website
- Address
- Business License
- Tax Identifier

10. Organizational Ownership

Describe ownership of:

- Branches
- Terminals
- Routes
- Vehicles
- Employees
- Drivers
- Conductors
- Trips
- Reports

11. Company Branding

Describe:

- Logo
- Brand Identity
- Theme
- Receipt Branding
- Ticket Branding

12. Integrations

Describe interaction with:

- Tenant Module
- Branch Module
- Terminal Module
- Reporting Module
- Notification Module
- Audit Module

13. Events

Include:

- Company Registered
- Company Verified
- Company Activated
- Company Updated
- Company Suspended
- Company Closed
- Branding Updated

14. Permissions

Describe who MAY:

- Create Company
- Update Company
- Suspend Company
- View Company
- Archive Company

15. Validation Rules

Describe:

- Unique Registration Number
- Required Company Information
- Branding Validation
- Contact Validation

16. Offline Behavior

Describe:

- Offline Profile Access
- Cached Company Information
- Synchronization Rules

17. Audit Requirements

Every company profile change MUST be auditable.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Every Company MUST belong to exactly one Tenant.
- Every Branch MUST belong to exactly one Company.
- Company identity MUST remain unique.
- Company branding MUST be versioned.
- Archived Companies MUST become read-only.

19. KPIs

Examples:

- Active Companies
- Branch Growth
- Fleet Growth
- Route Coverage
- Operational Availability

20. Error Scenarios

Describe:

- Duplicate Registration
- Missing Required Information
- Invalid Business License
- Invalid Contact Information
- Archived Company Modification

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- Multi-brand Organizations
- Holding Companies
- Franchise Networks
- International Companies
- Corporate Groups

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Mandatory Business Rules

Every Company MUST belong to one Tenant.

Every Branch MUST belong to one Company.

Company identity MUST remain immutable after creation except through approved business procedures.

Company profile changes MUST be auditable.

The Company Module MUST remain independent from Authentication, Authorization, and Operational Modules.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Transportation domain-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants