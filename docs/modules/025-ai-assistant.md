You are a Distinguished Enterprise AI Architect, AI Platform Architect, Domain-Driven Design (DDD) Expert, Enterprise Business Analyst, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/modules/025-ai-assistant.md

Purpose:

Define the AI Assistant Module for the HoBo Transport Platform (HBT).

This document is the authoritative business module specification describing how Artificial Intelligence capabilities are integrated across the platform to assist users, analyze business data, provide recommendations, summarize information, and improve operational efficiency.

The AI Assistant is an enterprise cross-cutting capability.

The AI Assistant provides intelligence.

The AI Assistant MUST NOT execute business transactions.

The AI Assistant MUST NOT replace business rules.

Business modules remain the source of truth.

AI provides recommendations, predictions, summaries, and conversational assistance.

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

- What is an AI Assistant?
- Difference between AI and Business Rules
- Difference between AI and Reporting
- Difference between AI and Automation
- Relationship with Operational Data
- Relationship with Users

7. Responsibilities

The AI Assistant MUST support:

- Conversational Assistance
- Business Questions
- Operational Insights
- Report Summarization
- Recommendation Generation
- Anomaly Detection
- Forecasting
- Decision Support
- Knowledge Search
- Document Assistance

The AI Assistant MUST NOT perform:

- Ticket Issuance
- Payment Authorization
- Settlement Approval
- User Permission Changes
- Business Data Modification

8. AI Capabilities

Describe:

- Conversational AI
- Natural Language Search
- Report Summarization
- Predictive Analytics
- Recommendation Engine
- Intelligent Search
- Knowledge Assistant
- AI Translation
- OCR Assistance (Future)
- Voice Assistant (Future)

9. AI Use Cases

Describe examples such as:

Passenger Services

- Answer booking questions
- Explain ticket information
- Translate passenger messages

Operations

- Detect delayed trips
- Highlight overcrowded routes
- Suggest vehicle allocation

Finance

- Explain revenue trends
- Detect unusual settlements
- Summarize financial reports

Cargo

- Predict delivery delays
- Identify shipment exceptions

Management

- Executive summaries
- KPI explanations
- Daily operational briefings

10. Knowledge Sources

Describe:

- Documentation
- Policies
- Operational Data
- Reporting Data
- Audit Logs
- FAQs

11. Integrations

Describe interaction with:

- Reporting Module
- Audit Module
- Booking Module
- Trip Module
- Payment Module
- Cargo Module
- Notification Module

12. AI Events

Include:

- AI Request Received
- AI Response Generated
- Recommendation Produced
- Summary Generated
- Prediction Completed

13. Permissions

Describe who MAY:

- Ask Questions
- View AI Recommendations
- Configure AI
- Approve AI Features
- Access AI History

14. Validation Rules

Describe:

- Prompt Validation
- Permission Validation
- Data Scope Validation
- Sensitive Information Protection

15. AI Governance

Describe:

- Human Oversight
- Recommendation Review
- Confidence Levels
- Model Transparency
- Explainability
- Responsible AI

16. Offline Behavior

Describe:

- Cached Knowledge
- Limited Local AI
- Deferred AI Requests
- Synchronization

17. Audit Requirements

Every AI interaction MUST be auditable.

Every recommendation SHOULD be traceable.

AI-generated summaries SHOULD identify their source.

18. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- AI MUST NOT modify business data.
- AI MUST NOT override business rules.
- AI responses SHOULD include confidence where appropriate.
- Users MUST remain responsible for business decisions.
- Sensitive information MUST follow access permissions.

19. KPIs

Examples:

- AI Adoption Rate
- AI Response Time
- Recommendation Acceptance Rate
- User Satisfaction
- AI Accuracy
- Knowledge Coverage

20. Error Scenarios

Describe:

- Insufficient Data
- Unauthorized Request
- Hallucination Risk
- Ambiguous Question
- Model Unavailable
- Knowledge Outdated

21. Dependencies

Describe upstream and downstream dependencies.

22. Future Expansion

Describe support for:

- AI Agents
- Multi-Agent Collaboration
- Voice Operations
- Image Understanding
- Predictive Maintenance
- Fleet Optimization
- Dynamic Pricing Recommendations
- Autonomous Business Insights

23. References

Reference related Architecture documents, ADRs, and Module Specifications.

24. Glossary

25. Summary

--------------------------------------------------
Operational Workflows

Describe architecture for:

- User Question
- Context Collection
- Permission Validation
- Knowledge Retrieval
- AI Analysis
- Response Generation
- User Feedback
- Continuous Improvement

--------------------------------------------------
Mandatory Business Rules

AI MUST remain advisory.

Business rules MUST remain authoritative.

AI MUST respect user permissions.

AI interactions MUST be auditable.

AI MUST NOT perform business transactions directly.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Business-focused

AI Governance-focused

Documentation-focused

No implementation examples

No source code

AI Vendor Neutral

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT) where appropriate

Clear enough that any AI assistant can follow it consistently

Suitable for both human engineers and AI coding assistants