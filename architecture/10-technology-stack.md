You are a Distinguished Enterprise Architect, Chief Technology Officer (CTO), Principal Software Architect, Cloud Architect, DevOps Architect, Platform Engineer, and AI Engineering Lead.

Create the file:

architecture/10-technology-stack.md

Purpose:

Define the official Technology Stack and Technology Decision Records (TDR) for the HoBo Transport Platform (HBT).

This document serves as the authoritative reference explaining why each technology has been selected, what problems it solves, acceptable alternatives, future migration strategies, and technology governance.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST describe technology decisions only.

No implementation code should appear.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Technology Vision

4. Technology Selection Principles

Describe principles such as:

- Stability First
- Simplicity
- Long-Term Maintainability
- Enterprise Ready
- Open Standards
- Vendor Neutral
- Offline First
- Security First
- Community Support
- Documentation Quality
- AI Compatibility

5. Technology Governance

6. Approved Technology Stack

Frontend

- Flutter

Backend

- Python
- Django
- Django REST Framework

Database

- PostgreSQL

Cache

- Redis

Object Storage

- MinIO

Web Server

- Nginx

Containerization

- Docker
- Docker Compose

Messaging

- Background Job Framework
- Queue Architecture

Monitoring

- Metrics
- Logs
- Traces

CI/CD

- GitHub Actions

AI Layer

- AI Gateway
- Multi-Provider Support
- Vendor Abstraction

7. Technology Decision Records (TDR)

For each technology describe:

- Why it was selected
- Business justification
- Technical justification
- Advantages
- Limitations
- Risks
- Alternatives considered
- Future evolution

Include TDRs for:

- Flutter
- Python
- Django
- Django REST Framework
- PostgreSQL
- Redis
- Docker
- Docker Compose
- Nginx
- MinIO
- GitHub Actions
- REST APIs
- Modular Monolith
- Domain-Driven Design
- Clean Architecture
- Offline-First
- Multi-Tenant
- AI Gateway

8. Rejected Technologies

Describe why the following are not selected initially:

- Microservices
- Kubernetes
- GraphQL
- MongoDB
- Firebase-only Architecture
- Vendor-specific AI SDKs

Explain that they MAY be adopted in the future when justified.

9. Future Technology Evolution

Describe evolution from:

Current Stack

→ Enterprise Scale

→ Distributed Services

→ Cloud Native

without changing business domains.

10. Technology Lifecycle

Describe:

- Evaluation
- Approval
- Adoption
- Maintenance
- Upgrade
- Deprecation
- Retirement

11. Version Management Policy

12. Dependency Policy

13. Open Source Policy

14. Security Patch Policy

15. AI Compatibility Policy

Describe:

- AI Vendor Neutral
- Prompt Portability
- Tool Independence
- Technology Documentation Standards

16. Technology Review Process

17. Architecture Decision Process

18. Risk Assessment

19. Technology Roadmap

20. Technology Checklist

21. Glossary

22. Summary

--------------------------------------------------
Mandatory Technology Rules
--------------------------------------------------

Technology decisions MUST prioritize long-term maintainability.

Business requirements MUST drive technology choices.

Technology MUST remain replaceable.

Technology MUST support Offline First.

Technology MUST support Multi-Tenant SaaS.

Technology MUST support enterprise security.

Technology MUST be well documented.

Technology MUST be widely supported.

Technology SHOULD avoid unnecessary complexity.

Technology SHOULD minimize vendor lock-in.

AI integrations MUST remain provider independent.

--------------------------------------------------
Requirements
--------------------------------------------------

Enterprise-grade Markdown

No source code

No implementation examples

Architecture-focused

Business-focused

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants