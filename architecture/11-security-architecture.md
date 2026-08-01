You are a Distinguished Enterprise Security Architect, Chief Information Security Officer (CISO), Principal Security Engineer, DevSecOps Architect, Cloud Security Architect, Zero Trust Specialist, and Enterprise Software Architect.

Create the file:

architecture/11-security-architecture.md

Purpose:

Define the official Security Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative architecture specification describing how security is designed across the entire platform.

This document MUST be treated as the single source of truth for architecture-level security decisions.

The document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST focus on architecture only.

No implementation details.

No source code.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Security Vision

4. Security Principles

Describe principles including:

- Zero Trust
- Defense in Depth
- Least Privilege
- Security by Design
- Privacy by Design
- Secure by Default
- Fail Secure
- Audit Everything

5. Security Objectives

6. Threat Model

Describe threats including:

- Unauthorized Access
- Account Takeover
- Data Breach
- Insider Threat
- API Abuse
- Supply Chain Attack
- Credential Theft
- Malware
- Ransomware
- DDoS
- Business Logic Abuse

7. Security Domains

Define architecture for:

- Identity
- Authentication
- Authorization
- Data Protection
- API Security
- Infrastructure Security
- Mobile Security
- AI Security
- Operational Security

8. Identity Architecture

9. Authentication Architecture

Describe:

- Username/Password
- MFA Ready
- Passwordless Ready
- Device Trust
- Session Management

10. Authorization Architecture

Describe:

- RBAC
- ABAC
- Tenant Isolation
- Permission Hierarchy

11. Multi-Tenant Security

12. API Security

Describe:

- Authentication
- Authorization
- Rate Limiting
- API Keys
- JWT
- OAuth Readiness
- Request Validation

13. Data Protection

Describe:

- Encryption at Rest
- Encryption in Transit
- Key Rotation
- Secret Management
- Sensitive Data Classification

14. Mobile Security

15. Offline Security

Describe:

- Offline Authentication
- Local Encryption
- Secure Storage
- Sync Validation

16. Infrastructure Security

Describe:

- Network Segmentation
- Firewall
- Reverse Proxy
- Container Isolation
- Server Hardening

17. Database Security

18. AI Security

Describe:

- Prompt Security
- AI Provider Isolation
- Prompt Injection Awareness
- AI Metadata Protection
- AI Access Control

19. Logging & Audit Architecture

20. Monitoring & Detection

21. Incident Response

22. Disaster Recovery Security

23. Security Governance

24. Compliance Strategy

Describe readiness for:

- OWASP Top 10
- OWASP ASVS
- ISO 27001
- SOC 2
- GDPR (where applicable)
- Local Privacy Regulations

25. Security Risks

26. Security Assumptions

27. Future Security Evolution

Describe evolution from:

Basic Security

→ Enterprise Security

→ Zero Trust Platform

without changing business modules.

28. Security Checklist

29. Glossary

30. Summary

--------------------------------------------------
Mandatory Security Rules
--------------------------------------------------

Security MUST be designed into the architecture.

Every request MUST be authenticated.

Every action MUST be authorized.

Every business operation SHOULD be auditable.

Sensitive data MUST be protected.

Secrets MUST never be stored in source code.

Tenant data MUST remain isolated.

The platform MUST support future MFA.

The platform MUST support future SSO.

The platform MUST support future Identity Providers.

AI providers MUST remain isolated behind an AI Gateway.

Security decisions MUST prioritize confidentiality, integrity, and availability.

--------------------------------------------------
Architecture Goals
--------------------------------------------------

The architecture MUST support:

- Zero Trust
- Security by Design
- Privacy by Design
- Multi-Tenant Security
- Offline Security
- Mobile Security
- Cloud Security
- API Security
- AI Security
- Vendor Neutrality
- High Availability
- Enterprise Compliance

--------------------------------------------------
Requirements
--------------------------------------------------

Enterprise-grade Markdown

Architecture-focused

No source code

No implementation examples

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants