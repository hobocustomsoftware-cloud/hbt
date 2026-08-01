You are a Distinguished Software Test Architect, Quality Assurance (QA) Architect, Site Reliability Engineer (SRE), Enterprise Software Architect, DevSecOps Architect, and Principal Engineering Leader.

Create the file:

architecture/15-testing-architecture.md

Purpose:

Define the official Testing Architecture for the HoBo Transport Platform (HBT).

This document is the authoritative architecture specification describing how quality assurance, automated testing, validation, verification, reliability testing, and release confidence are designed across the platform.

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

3. Testing Vision

4. Testing Principles

Describe principles including:

- Shift Left Testing
- Test Early
- Test Continuously
- Risk-Based Testing
- Automation First
- Independent Verification
- Deterministic Testing
- Security by Design
- Quality by Design

5. Testing Goals

6. Testing Strategy

Describe overall testing philosophy for:

- Business Logic
- APIs
- Infrastructure
- Mobile Applications
- AI Services
- Offline Synchronization
- Multi-Tenant Platform

7. Test Architecture

Describe architecture layers:

- Unit Testing
- Component Testing
- Integration Testing
- Contract Testing
- End-to-End Testing
- Acceptance Testing
- Exploratory Testing

8. Test Pyramid

Describe:

- Unit Tests
- Integration Tests
- API Tests
- UI Tests
- End-to-End Tests

9. Backend Testing

Describe testing for:

- Domain Layer
- Application Layer
- API Layer
- Infrastructure Layer
- Background Workers

10. Mobile Testing

Describe testing for:

- UI
- Offline Mode
- Synchronization
- Device Compatibility
- Network Conditions

11. API Testing

Describe:

- Functional Validation
- Authentication
- Authorization
- Error Handling
- Version Compatibility

12. Integration Testing

Describe testing between:

- Modules
- AI Gateway
- Payment Providers
- Notification Services
- Authentication Services
- File Storage

13. Contract Testing

Describe:

- Internal APIs
- External APIs
- Event Contracts
- Version Compatibility

14. Performance Testing

Describe:

- Load Testing
- Stress Testing
- Spike Testing
- Endurance Testing
- Scalability Validation

15. Security Testing

Describe:

- Authentication
- Authorization
- Input Validation
- OWASP Readiness
- Dependency Scanning
- Secret Detection

16. AI Testing

Describe:

- Prompt Validation
- AI Provider Compatibility
- Provider Failover
- Response Validation
- Hallucination Risk Monitoring
- Cost Validation

17. Offline Testing

Describe:

- Sync Reliability
- Queue Recovery
- Conflict Resolution
- Retry Strategy
- Local Storage Validation

18. Multi-Tenant Testing

Describe:

- Tenant Isolation
- Data Isolation
- Permission Isolation
- Configuration Isolation

19. Test Data Management

20. Test Environment Strategy

Describe environments:

- Local
- Development
- QA
- Staging
- Production Validation

21. CI/CD Testing Pipeline

Describe:

- Pull Request Validation
- Automated Testing
- Release Validation
- Deployment Verification

22. Quality Gates

23. Code Coverage Strategy

24. Regression Testing

25. Smoke Testing

26. Sanity Testing

27. Release Readiness

28. Defect Management

29. Risk-Based Testing

30. Testing Metrics

Describe metrics including:

- Test Coverage
- Pass Rate
- Failure Rate
- Defect Density
- Escaped Defects
- Mean Time to Detect

31. Testing Governance

32. Assumptions

33. Risks

34. Future Evolution

Describe evolution from:

Basic Testing

→ Automated Testing

→ Continuous Quality

→ AI-Assisted Quality Engineering

without changing business modules.

35. Testing Checklist

36. Glossary

37. Summary

--------------------------------------------------
Architecture Goals

The testing architecture MUST support:

- Enterprise Quality
- Continuous Delivery
- AI Ready
- Offline First
- Multi-Tenant
- Security Validation
- High Reliability
- Risk Reduction
- Vendor Neutrality
- Long-Term Maintainability

--------------------------------------------------
Mandatory Rules

Every business rule MUST be testable.

Every API MUST be testable.

Critical business workflows MUST have automated tests.

Every release MUST pass quality gates.

Testing MUST support Offline First.

Testing MUST support AI services.

Testing MUST support Multi-Tenant SaaS.

Tests MUST be deterministic whenever possible.

Test environments MUST remain isolated.

Production data MUST NOT be used in testing unless properly anonymized.

Quality MUST be measurable.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

No implementation examples

No source code

Long-term maintainable

AI Vendor Neutral

Written for enterprise software teams and AI coding assistants

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)
where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants