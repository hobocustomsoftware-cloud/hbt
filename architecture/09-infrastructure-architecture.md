You are a Distinguished Infrastructure Architect, Cloud Architect, Platform Engineer, DevOps Architect, Site Reliability Engineer (SRE), and Enterprise Systems Architect.

Create the file:

architecture/09-infrastructure-architecture.md

Purpose:

Define the official Infrastructure Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative specification describing how infrastructure, networking, compute resources, storage, deployment environments, observability, security, disaster recovery, and operational services are organized.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

The document MUST describe architecture only.

No implementation code should appear.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Infrastructure Vision

4. Infrastructure Principles

5. Infrastructure Goals

6. Infrastructure Layers

Describe:

- Client Layer
- Edge Layer
- Network Layer
- Application Layer
- Data Layer
- Storage Layer
- Monitoring Layer
- Operations Layer

7. Environment Strategy

Define environments:

- Local
- Development
- Testing
- Staging
- Production
- Disaster Recovery

8. Compute Architecture

Describe:

- Application Servers
- Background Workers
- Scheduled Jobs
- API Services
- AI Services

9. Network Architecture

Describe:

- DNS
- Reverse Proxy
- Load Balancer
- Firewall
- Private Network
- Public Network
- VPN
- Internal Communication

10. Container Architecture

Describe:

- Docker
- Container Isolation
- Image Standards
- Runtime Standards

11. Storage Architecture

Describe:

- Database Storage
- Object Storage
- File Storage
- Backup Storage
- Log Storage

12. Database Infrastructure

Describe:

- PostgreSQL
- Read Replicas
- Backup
- Recovery
- Future Clustering

13. Cache Architecture

Describe:

- Redis
- Session Cache
- Application Cache
- Query Cache

14. Message Processing

Describe:

- Background Jobs
- Queue Workers
- Event Processing
- Scheduled Tasks

15. AI Infrastructure

Describe:

- AI Gateway
- AI Provider Abstraction
- AI Request Routing
- AI Metadata Storage

16. Monitoring Architecture

Describe:

- Metrics
- Logs
- Traces
- Dashboards
- Alerting

17. Logging Architecture

18. Security Infrastructure

Describe:

- TLS
- Certificates
- Secrets Management
- Network Segmentation
- Firewall Rules
- Zero Trust

19. Identity Infrastructure

20. Backup Strategy

21. Disaster Recovery

22. High Availability

23. Scalability Strategy

Describe:

- Vertical Scaling
- Horizontal Scaling
- Stateless Services
- Auto Scaling Ready

24. Performance Strategy

25. Capacity Planning

26. Infrastructure Observability

27. Infrastructure Governance

28. Infrastructure Standards

29. Infrastructure Risks

30. Infrastructure Assumptions

31. Future Evolution

Describe evolution from:

Single Server

→ Multi-Server

→ High Availability Cluster

→ Cloud Infrastructure

→ Multi-Region Architecture

without changing business modules.

32. Infrastructure Checklist

33. Glossary

34. Summary

--------------------------------------------------
Infrastructure Components
--------------------------------------------------

Describe infrastructure for:

- Flutter Applications
- Web Portal
- API Services
- Authentication
- AI Services
- PostgreSQL
- Redis
- Object Storage
- File Storage
- Docker
- Reverse Proxy
- Monitoring
- Logging
- Backup
- Notification Services

--------------------------------------------------
Architecture Principles
--------------------------------------------------

The infrastructure MUST support:

- Cloud Ready
- Container Ready
- High Availability
- Fault Tolerant
- Security First
- Infrastructure as Code Ready
- Observability by Default
- AI Ready
- Offline First
- Multi-Tenant
- Vendor Neutral
- Cost Efficiency
- Scalability
- Reliability
- Maintainability

--------------------------------------------------
Mandatory Rules
--------------------------------------------------

Infrastructure MUST be reproducible.

Every environment MUST be isolated.

Production MUST NOT share infrastructure with development.

Secrets MUST NOT be stored in source code.

Infrastructure MUST support automated deployment.

Infrastructure MUST support automated backup.

Infrastructure MUST support monitoring.

Infrastructure MUST support disaster recovery.

Infrastructure MUST support future cloud migration.

Business modules MUST remain infrastructure independent.

--------------------------------------------------
Requirements
--------------------------------------------------

Enterprise-grade Markdown

No source code

No implementation examples

Architecture-focused

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants