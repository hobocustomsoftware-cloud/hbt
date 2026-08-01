You are a Distinguished Site Reliability Engineer (SRE), Enterprise Observability Architect, Cloud Architect, DevOps Architect, Platform Engineer, and Principal Software Architect.

Create the file:

architecture/14-observability-architecture.md

Purpose:

Define the official Observability Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative architecture specification describing how the platform is observed, monitored, measured, traced, alerted, diagnosed, and operated throughout its lifecycle.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

The document MUST focus on architecture only.

No implementation details.

No source code.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Observability Vision

4. Observability Principles

Describe principles including:

- Observability by Default
- Everything is Measurable
- Everything is Traceable
- Automation First
- Security by Design
- Vendor Neutral
- Actionable Telemetry
- Continuous Improvement

5. Observability Goals

6. Architecture Overview

Describe architecture layers:

- Client Layer
- API Layer
- Business Layer
- Infrastructure Layer
- Platform Layer
- AI Layer

7. Telemetry Strategy

Describe telemetry collection for:

- Metrics
- Logs
- Traces
- Events

8. Metrics Architecture

Describe metrics for:

- Business Metrics
- System Metrics
- Infrastructure Metrics
- API Metrics
- Database Metrics
- Queue Metrics
- AI Metrics
- Mobile Metrics

9. Logging Architecture

Describe:

- Structured Logging
- Log Levels
- Correlation IDs
- Tenant Context
- User Context
- Request Context
- Security Events
- Audit Events

10. Distributed Tracing

Describe:

- Trace Context
- Span Hierarchy
- Cross-Service Tracing
- AI Request Tracing
- Background Job Tracing

11. Health Monitoring

Describe:

- Liveness
- Readiness
- Startup Health
- Dependency Health
- Database Health
- Cache Health
- AI Provider Health

12. Alerting Strategy

Describe:

- Critical Alerts
- Warning Alerts
- Business Alerts
- Security Alerts
- Infrastructure Alerts

13. Dashboard Strategy

Describe dashboards for:

- Executive Dashboard
- Operations Dashboard
- Engineering Dashboard
- Business Dashboard
- Security Dashboard
- AI Dashboard

14. Incident Detection

15. Root Cause Analysis

16. Performance Monitoring

Describe monitoring for:

- API Response Time
- Database Performance
- Queue Latency
- Background Jobs
- Cache Performance
- Mobile Synchronization
- Offline Synchronization
- AI Response Time

17. Capacity Monitoring

18. Availability Monitoring

19. Reliability Monitoring

20. SLA / SLO / Error Budget

Describe:

- Service Level Indicators (SLI)
- Service Level Objectives (SLO)
- Service Level Agreements (SLA)
- Error Budget Strategy

21. AI Observability

Describe:

- AI Provider Monitoring
- Prompt Tracking
- Token Usage
- Latency
- Cost Monitoring
- Failure Analysis
- Provider Comparison

22. Security Monitoring

Describe:

- Authentication Events
- Authorization Failures
- Intrusion Detection Readiness
- Audit Monitoring

23. Compliance Monitoring

24. Observability Governance

25. Data Retention Strategy

26. Observability Risks

27. Assumptions

28. Future Evolution

Describe evolution from:

Basic Monitoring

→ Full Observability

→ Predictive Operations

→ Autonomous Operations

without changing business modules.

29. Observability Checklist

30. Glossary

31. Summary

--------------------------------------------------
Mandatory Rules

Every service MUST emit telemetry.

Every request MUST be traceable.

Every production issue SHOULD be diagnosable.

Critical business operations MUST be measurable.

Every alert MUST be actionable.

Observability MUST support Multi-Tenant SaaS.

Observability MUST support Offline First.

Observability MUST support AI Services.

Telemetry MUST NOT expose sensitive information.

Audit logs MUST remain immutable.

Production observability MUST remain isolated from development.

--------------------------------------------------
Architecture Goals

The architecture MUST support:

- High Availability
- Reliability
- Scalability
- Performance Optimization
- AI Monitoring
- Enterprise Operations
- Incident Response
- Capacity Planning
- Vendor Neutrality
- Long-Term Maintainability

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

No implementation examples

No source code

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants