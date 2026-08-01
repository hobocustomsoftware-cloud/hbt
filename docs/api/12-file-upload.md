You are a Distinguished Enterprise API Architect, Enterprise Security Architect, Enterprise Integration Architect, REST API Governance Expert, Principal Software Architect, Storage Architect, and Technical Documentation Architect.

Create the file:

docs/api/12-file-upload.md

Purpose:

Define the File Upload and File Management Standards for the HoBo Transport Platform (HBT).

This document establishes the governance, architectural principles, lifecycle, security policies, validation standards, and consistency requirements for file upload and file management across the platform.

This document defines governance only.

This document is NOT an API reference.

This document MUST remain technology-neutral.

No framework-specific guidance.

No programming language examples.

No source code.

No implementation details.

This standard applies to:

- Public APIs
- Internal APIs
- Mobile APIs
- Administrative APIs
- Partner APIs

The document MUST be AI Vendor Neutral and compatible with:

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

1. Purpose

2. Executive Summary

Explain why standardized file upload governance is essential for security, consistency, scalability, and interoperability.

3. Scope

Include:

- In Scope
- Out of Scope

4. File Management Philosophy

Describe principles including:

- Security by Default
- File Independence
- Reusability
- Traceability
- Long-Term Maintainability
- Storage Agnosticism

5. Core Concepts

Define:

- File
- Attachment
- Metadata
- File Identifier
- Storage Object
- File Lifecycle

6. Supported File Categories

Describe conceptual categories such as:

- Images
- Documents
- PDFs
- Office Documents
- Audio
- Video
- Archives
- AI Attachments

Explain business use cases without implementation guidance.

7. File Upload Principles

Describe:

- Upload Validation
- Metadata Capture
- Ownership
- File Association
- Duplicate Handling
- Integrity Verification

8. File Download Principles

Describe:

- Authorized Access
- Secure Delivery
- Temporary Access
- Auditability

9. File Lifecycle

Describe conceptual lifecycle stages such as:

- Uploaded
- Validated
- Associated
- Active
- Archived
- Deleted
- Retained

10. Validation Principles

Describe:

- File Type Validation
- File Size Validation
- Malware Scanning
- Content Validation
- Corruption Detection

11. Security Principles

Describe:

- Secure Storage
- Sensitive Files
- Encryption
- Access Control
- Virus Protection
- Audit Logging
- Data Retention

12. Multi-Tenant Considerations

Describe:

- Tenant Isolation
- Company Ownership
- Branch Ownership
- Shared Files
- Access Boundaries

13. Consumer Responsibilities

Describe expectations for API consumers regarding valid uploads, ownership, and responsible file usage.

14. Provider Responsibilities

Describe expectations for API providers regarding validation, protection, availability, traceability, and lifecycle management.

15. Governance

Describe:

- File Governance
- Retention Policies
- Storage Governance
- Compliance
- Documentation Review

16. Business Rules

Every rule MUST include:

- Rule ID
- Description
- Priority
- Rationale

Include rules such as:

- Uploaded files MUST undergo validation before acceptance.
- Sensitive files MUST be protected.
- Every uploaded file MUST have an identifiable owner.
- File lifecycle MUST be traceable.
- File retention MUST follow platform policy.
- Deleted files SHOULD follow retention policy where applicable.
- File access MUST be authorized.

17. References

Reference:

- API Principles
- Authentication
- Authorization
- Request and Response Standards
- API Security
- Architecture Documentation
- Module Specifications

18. Glossary

Include definitions for:

- File
- Attachment
- Metadata
- Storage
- File Identifier
- Retention
- Archive
- Ownership

19. Summary

Summarize how standardized file management improves security, governance, interoperability, auditability, scalability, and long-term maintainability across the HoBo Transport Platform.

--------------------------------------------------
Requirements

Enterprise-grade Markdown

Architecture-focused

Governance-focused

Security-focused

Storage-focused

Documentation-first

Technology-neutral

Vendor-neutral

Business-oriented

No implementation details

No framework-specific guidance

No source code

Long-term maintainable

Use RFC 2119 terminology (MUST, SHOULD, MAY, MUST NOT)