You are a Distinguished Enterprise Solution Architect, Enterprise AI Systems Architect, Decision Support Systems Expert, Business Process Architect, Domain-Driven Design (DDD) Expert, Enterprise Workflow Architect, Principal Software Architect, and Technical Documentation Architect.

Create the file:

docs/workflows/013-ai-assistant-workflow.md

Purpose:

Define the AI Assistant Workflow for the HoBo Transport Platform (HBT).

This document describes the complete business workflow for providing AI-assisted business analysis, recommendations, explanations, and decision support using trusted business information.

This document defines business workflow governance only.

This document is NOT an implementation guide.

This document is NOT an AI model training guide.

This document is NOT an LLM integration guide.

This document is NOT an API specification.

This document is NOT a database design.

This document MUST remain technology-neutral.

This document MUST remain AI vendor-neutral.

No implementation details.

No framework-specific guidance.

No programming language examples.

No source code.

Compatible with:

- Cursor
- Claude Code
- OpenAI Codex
- GitHub Copilot
- Gemini CLI
- Kimi
- Future AI Coding Assistants

--------------------------------------------------
Include the following sections
--------------------------------------------------

# AI Assistant Workflow

## 1. Purpose

Explain the purpose of the AI Assistant and its role in helping business users understand information, identify patterns, evaluate options, and support informed decision-making.

---

## 2. Executive Summary

Describe how the AI Assistant consumes trusted business information and produces business insights, recommendations, explanations, summaries, and decision support.

Clearly distinguish:

- Business Transaction = Produces Data

- Report = Trusted Business Information

- AI Recommendation = Decision Support

- Human Decision = Organizational Responsibility

---

## 3. Scope

### In Scope

Include:

- Business analysis

- Operational analysis

- Financial analysis

- Cargo analysis

- Trend identification

- Recommendation generation

- Executive summaries

- Business explanations

- Question answering using trusted business information

### Out of Scope

Exclude:

- Automatic operational execution

- Automatic financial approval

- Automatic business approvals

- Autonomous business decision-making

- AI model implementation

- AI infrastructure

---

## 4. Workflow Objectives

Describe objectives including:

- Better decision support

- Faster business understanding

- Explainable recommendations

- Consistent analysis

- Operational visibility

- Executive productivity

---

## 5. Business Actors

Describe responsibilities of:

- Executive Management

- Operations Manager

- Branch Manager

- Finance Officer

- Customer Service

- Business Analyst

- System

- AI Assistant

Clearly state that the AI Assistant supports—not replaces—human decision-makers.

---

## 6. Trigger

Describe business events that initiate AI-assisted analysis, such as:

- User question

- Report published

- Performance threshold exceeded

- Operational anomaly detected

- Scheduled business review

- Executive analysis request

---

## 7. Preconditions

Describe conditions that SHOULD exist before AI-assisted analysis begins, including:

- Trusted business information available

- Relevant reporting completed

- Business context identified

- User authorized to access requested information

---

## 8. Main Workflow

Describe the normal business process from analysis request through information retrieval, interpretation, recommendation generation, explanation, and presentation.

Use business language only.

Avoid implementation details.

---

## 9. Alternative Flows

Examples include:

- Follow-up questions

- Comparative analysis

- Historical analysis

- Multi-domain analysis

- Executive summary generation

---

## 10. Exception Flows

Examples include:

- Insufficient business information

- Inconsistent source information

- Access restriction

- Unsupported request

- Ambiguous business question

---

## 11. Postconditions

Describe possible outcomes including:

- Recommendation Provided

- Analysis Completed

- Additional Information Required

- Human Review Recommended

- Request Declined

---

## 12. Business Rules

Every rule MUST include:

- Rule ID

- Description

- Priority

- Rationale

Include rules such as:

- AI recommendations MUST be based on trusted business information.

- AI MUST NOT replace required organizational approvals.

- AI explanations SHOULD identify supporting business information.

- Users MUST understand that recommendations are advisory.

- Sensitive business information MUST follow organizational access policy.

- AI interactions SHOULD remain auditable.

- Human decision-makers retain final authority.

---

## 13. AI Assistance State Transition

Describe conceptual states such as:

- Requested

- Gathering Information

- Analyzing

- Generating Recommendation

- Presented

- Follow-up Requested

- Closed

Explain valid business transitions without implementation.

---

## 14. Related Domain Events

Describe conceptual business events including:

- Analysis Requested

- Business Context Identified

- Recommendation Generated

- Executive Summary Produced

- Follow-up Requested

- Analysis Completed

---

## 15. Related Modules

Reference:

- Reporting

- Booking

- Payment

- Trip

- Cargo

- Refund

- Notification

- Audit

Explain how each module provides business information for AI-assisted analysis.

---

## 16. Related APIs

Reference conceptually:

- AI Assistant API

- Reporting API

- Notification API

Do not describe endpoints.

---

## 17. Security Considerations

Describe:

- User authorization

- Confidential information protection

- Recommendation traceability

- Data integrity

- Auditability

---

## 18. Audit Considerations

Describe why AI requests, recommendations, explanations, supporting information, and user interactions SHOULD be auditable.

---

## 19. Failure Recovery Considerations

Describe conceptual recovery expectations for:

- Missing business information

- Incomplete context

- Unsupported analysis

- Human escalation

- Recommendation regeneration

---

## 20. References

Reference:

- Workflow README

- Reporting Module

- Audit Module

- Notification Module

- Booking Module

- Payment Module

- Cargo Module

- Architecture Documentation

---

## 21. Glossary

Include definitions for:

- AI Assistant

- Business Insight

- Recommendation

- Explainability

- Decision Support

- Trusted Business Information

- Human-in-the-Loop

---

## 22. Summary

Summarize how the AI Assistant Workflow provides a controlled, explainable, auditable, and business-oriented decision support capability that enhances—rather than replaces—human decision-making across the HoBo Transport Platform.

--------------------------------------------------

Requirements

Enterprise-grade Markdown

Business-oriented

AI Governance-focused

Decision Support-focused

Architecture-focused

Workflow-focused

Documentation-first

Technology-neutral

AI Vendor-neutral

No implementation details

No framework-specific guidance

No programming language examples

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)