You are a Distinguished Enterprise Security Architect, Identity and Access Management (IAM) Architect, Domain-Driven Design (DDD) Expert, Principal Software Architect, Enterprise Business Analyst, and Technical Documentation Architect.

Create the file:

docs/modules/002-authentication.md

Purpose:

Define the Authentication Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how identities are authenticated before accessing platform resources.

The Authentication Module MUST provide secure identity verification while remaining independent from authorization, user management, and tenant management.

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

6. Actors

Include:

- Super Admin
- Company Admin
- Employee
- Driver
- Conductor
- Customer
- External Identity Provider

7. Responsibilities

Authentication MUST include:

- Identity Verification
- Login
- Logout
- Session Creation
- Session Termination
- Token Issuance
- Token Refresh
- Device Registration
- Password Verification
- MFA Support
- Account Lockout
- Authentication Audit

Authentication MUST NOT manage:

- User Profiles
- Permissions
- Roles
- Tenants
- Business Data

8. Authentication Lifecycle

Describe:

Identity Request

↓

Credential Validation

↓

Identity Verification

↓

Session Creation

↓

Access Granted

↓

Session Refresh

↓

Logout

↓

Session Termination

9. Authentication Methods

Describe support for:

- Username & Password
- Email & Password
- Phone Number
- OTP
- MFA
- Passkeys (Future)
- Enterprise SSO (Future)

10. Session Management

Describe:

- Session Creation
- Session Expiration
- Concurrent Sessions
- Device Sessions
- Forced Logout
- Idle Timeout

11. Credential Policies

Describe:

- Password Rules
- Password Expiration
- Password History
- Password Reset
- Credential Rotation

12. Device Management

Describe:

- Trusted Devices
- New Device Detection
- Device Registration
- Device Revocation

13. Account Security

Describe:

- Failed Login Attempts
- Lockout Policy
- Suspicious Login
- Risk Detection
- Recovery Process

14. Authentication Events

Include:

- Login Requested
- Login Successful
- Login Failed
- Logout
- Session Expired
- Password Changed
- Password Reset
- Device Registered
- Account Locked

15. Integrations

Describe interaction with:

- User Module
- Authorization Module
- Tenant Module
- Audit Module
- Notification Module
- AI Services

16. Offline Behavior

Describe:

- Offline Login Policy
- Cached Credentials
- Offline Restrictions
- Synchronization

17. Audit Requirements

Every authentication event MUST be auditable.

18. Security Considerations

Describe:

- Least Privilege
- Zero Trust
- Credential Protection
- Token Protection
- Session Protection
- Replay Prevention

19. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Authentication MUST occur before authorization.
- Every authenticated session MUST belong to exactly one identity.
- Locked accounts MUST NOT authenticate.
- Expired sessions MUST NOT access protected resources.
- Authentication events MUST be immutable.

20. KPIs

Examples:

- Login Success Rate
- Failed Login Rate
- Average Login Time
- MFA Adoption
- Session Duration

21. Error Scenarios

Describe business failures including:

- Invalid Credentials
- Locked Account
- Expired Password
- Expired Session
- Suspicious Login
- Network Failure

22. Dependencies

Describe upstream and downstream dependencies.

23. Future Expansion

Describe future support for:

- Passwordless Authentication
- Biometric Authentication
- Enterprise Identity Federation
- AI Risk-Based Authentication
- Adaptive Authentication

24. References

Reference related Architecture documents, ADRs, and Security Standards.

25. Glossary

26. Summary

--------------------------------------------------
Mandatory Business Rules

Authentication MUST be independent from authorization.

Authentication MUST verify identity only.

Every successful authentication MUST create an auditable session.

Every failed authentication MUST be recorded.

Authentication MUST support multi-tenant architecture.

Authentication MUST support future MFA.

Authentication MUST support offline-capable mobile clients where permitted by business policy.

Authentication MUST remain vendor neutral.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

Security-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants