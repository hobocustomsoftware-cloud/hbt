You are a Distinguished Performance Architect, Site Reliability Engineer (SRE), Enterprise Software Architect, Cloud Architect, Platform Architect, Database Performance Engineer, and Principal Systems Engineer.

Create the file:

architecture/17-performance-architecture.md

Purpose:

Define the official Performance Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative architecture specification describing how performance, scalability, responsiveness, efficiency, resource utilization, and capacity optimization are designed across the platform.

This document MUST serve as the single source of truth for all performance-related architectural decisions.

This document MUST be AI Vendor Neutral and compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI coding assistants

This document MUST describe architecture only.

No implementation details.

No source code.

--------------------------------------------------
Include the following sections
--------------------------------------------------

1. Purpose

2. Executive Summary

3. Performance Vision

4. Performance Principles

Describe principles including:

- Performance by Design
- Scalability by Design
- Efficiency First
- Resource Optimization
- Latency Awareness
- Throughput Optimization
- Cost Efficiency
- Reliability
- Offline First
- Vendor Neutral

5. Performance Goals

6. Performance Architecture Overview

Describe performance considerations for:

- Client Layer
- API Layer
- Domain Layer
- Data Layer
- AI Layer
- Infrastructure Layer

7. Performance Objectives

Define objectives for:

- Response Time
- Throughput
- Availability
- Reliability
- Scalability
- Resource Utilization

8. Client Performance

Describe:

- Flutter Performance
- Startup Time
- UI Responsiveness
- Local Caching
- Offline Performance
- Network Optimization
- Battery Efficiency

9. API Performance

Describe:

- Request Processing
- Pagination
- Filtering
- Compression
- Rate Limiting
- Response Optimization
- Idempotency

10. Database Performance

Describe:

- Query Optimization
- Index Strategy
- Read Optimization
- Write Optimization
- Connection Pooling
- Partition Readiness
- Future Sharding Readiness

11. Cache Strategy

Describe:

- Application Cache
- Session Cache
- Query Cache
- AI Cache
- Cache Invalidation
- Cache Consistency

12. Background Processing

Describe:

- Queue Optimization
- Worker Scaling
- Batch Processing
- Scheduled Tasks

13. AI Performance

Describe:

- Prompt Optimization
- Token Optimization
- Context Optimization
- Provider Selection
- Response Streaming
- Cost vs Performance Trade-offs

14. Offline Performance

Describe:

- Local Database Performance
- Synchronization Efficiency
- Queue Performance
- Conflict Resolution Efficiency

15. Network Performance

Describe:

- Payload Optimization
- Compression
- Connection Reuse
- Retry Strategy
- Bandwidth Optimization

16. Storage Performance

Describe:

- Database Storage
- Object Storage
- File Access
- Backup Performance

17. Scalability Strategy

Describe:

- Vertical Scaling
- Horizontal Scaling
- Stateless Services
- Worker Scaling
- Database Scaling
- Cache Scaling

18. Capacity Planning

19. Load Management

Describe:

- Traffic Spikes
- Peak Hours
- Rate Limiting
- Backpressure
- Graceful Degradation

20. Performance Monitoring

Describe:

- Latency
- Throughput
- CPU
- Memory
- Disk
- Network
- Database
- AI Metrics

21. Performance Testing

Describe:

- Load Testing
- Stress Testing
- Spike Testing
- Endurance Testing
- Benchmark Testing

22. Performance Governance

23. Performance Risks

Include risks such as:

- Database Bottlenecks
- AI Latency
- Network Congestion
- Cache Misses
- Resource Exhaustion
- Memory Leaks
- Slow Queries
- Queue Backlogs

24. Performance Assumptions

25. Future Performance Evolution

Describe evolution from:

Single Server Optimization

→ Horizontal Scaling

→ High Availability

→ Distributed Platform

→ Global Multi-Region Performance

without changing business modules.

26. Performance Checklist

27. Glossary

28. Summary

--------------------------------------------------
Performance Areas

Describe architecture for:

- Mobile Applications
- Web Applications
- REST APIs
- AI Gateway
- PostgreSQL
- Redis
- Background Workers
- Object Storage
- Synchronization
- Offline Mode
- Search
- Reporting
- Analytics

--------------------------------------------------
Architecture Goals

The performance architecture MUST support:

- Enterprise Performance
- Low Latency
- High Throughput
- Multi-Tenant SaaS
- Offline First
- AI Ready
- Cost Efficiency
- Reliability
- Scalability
- Vendor Neutrality
- Long-Term Maintainability

--------------------------------------------------
Mandatory Rules

Performance MUST be measurable.

Critical user workflows MUST be optimized.

Business modules MUST remain performance independent.

Performance optimization MUST NOT compromise correctness.

Caching MUST NOT violate data consistency requirements.

Database queries SHOULD remain efficient.

The architecture MUST support future horizontal scaling.

AI services MUST remain replaceable.

Performance bottlenecks MUST be observable.

Every optimization SHOULD be justified by measurable outcomes.

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