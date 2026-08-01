# HBT Release Roadmap — v1

**Generated:** 2026-07-29
**Author:** Engineering Release Manager
**Current Status:** Phase 1 (Business Feature Completion)

---

## Current State Assessment

### Backend API Completion

| Module | Status | Notes |
|--------|--------|-------|
| Identity (auth) | ✅ Complete | Registration, JWT, profile |
| Tenant & Organization | ✅ Complete | Provisioning, membership, invitations |
| Roles & Permissions | ✅ Complete | System/custom roles, delegation guard, scopes |
| Locations & Counters | ✅ Complete | Branches, terminals, counters |
| Network | ✅ Complete | Routes, stops |
| Fleet & Workforce | ✅ Complete | Vehicles, layouts, staff profiles |
| Schedule & Trip | ✅ Complete | Schedules, trips, assignments, arrival/departure |
| Passenger | ✅ Complete | Self profile, org-managed, encrypted NRC |
| Boarding | ✅ Complete | Ticket validation, boarding recording |
| Feedback | ✅ Complete | Submission, triage, response |
| OpenAPI | ✅ Complete | Generated schema, Swagger, ReDoc |
| Booking | 🔶 Partial | No corporate booking/invoice, no reschedule |
| Fare & Corporate | 🔶 Partial | No discount limits, no invoice payment allocation |
| Promotion & Coupon | 🔶 Partial | No approval thresholds, no public discovery |
| Ticketing | 🔶 Partial | No share-image contract, no inspection separation |
| Payment | 🔶 Partial | No online provider adapter, no cancellation settlement |
| Cargo Lite | 🔶 Partial | No closing/export/print contracts |
| Printing & Operations | 🔶 Partial | No ESC/POS rendering, no device certification |
| Notification | 🔶 Partial | No FCM/APNs live adapter, no delivery receipts |
| Offline Sync | 🔶 Partial | No conflict UI localization, no sustained load evidence |
| SaaS Subscription | 🔶 Partial | No cancellation/reactivation API polish |
| Operator Branding | 🔶 Partial | No image verification, no object-storage |
| Media & Advertising | 🔶 Partial | No video transcoding, no impression anti-abuse |
| Reporting | 🔶 Partial | No scheduled delivery, no PDF rendering |
| Privacy Rights | 🔶 Partial | No automated anonymization, no retention schedule |

### Flutter App Completion

| Feature | Status | Notes |
|---------|--------|-------|
| App shell & auth | ✅ Done | Secure storage, JWT flow, login screen |
| Org context & permissions | ✅ Done | Context API integration, permission gating |
| Ticket worklist (view) | ✅ Done | Read-only list of bookings and tickets |
| Counter booking + fare quote | ✅ Done | Passenger select, trip/seat, booking, lock quote |
| Manual payment decision | ✅ Done | Evidence upload, approve/reject, ticket issue |
| Cargo acceptance | ✅ Done | Contact create, shipment create |
| Cargo worklist | ✅ Done | Shipment list, transitions, handover |
| Offline sync | ❌ Not built | No local DB, no upload queue, no conflict resolution |
| Push notifications | ❌ Not built | No FCM token registration, no notification display |
| QR scanning | ❌ Not built | `mobile_scanner` declared, never imported |
| Bluetooth printing | ❌ Not built | No print service, no queue |
| Subscription management UI | ❌ Not built | No plan list, no subscription status |
| Operator branding UI | ❌ Not built | No brand config screen |
| Full reporting | ❌ Not built | Dashboard is static placeholders |
| Passenger self-service app | ❌ Entire app missing | No trip search, no booking, no e-tickets |

---

## Phase 1: Business Feature Completion

**Goal:** Every MVP business feature is functional in at least one client.
**Policy:** No infrastructure work until features are complete.

### P0 — Musts Before Anything Else

#### F-001: Flutter passenger self-service app
**Effort:** 5-7 days
**Dependencies:** None (all passenger APIs are complete)
**Why P0:** The MVP requires TWO applications: HBT Business AND HBT Passenger. HBT Passenger (trip search, booking, purchase, e-tickets) does not exist. Without it, passengers cannot buy tickets — the entire revenue model fails.
**Acceptance:** Passenger can register, search trips, book seats, make payment (manual), receive e-ticket with QR.

#### F-002: Flutter push notification integration
**Effort:** 2 days
**Dependencies:** Backend notification APIs complete
**Why P0:** The MVP scope explicitly requires push notifications for: payment submitted, payment confirmed/rejected, booking expiry, ticket issued, trip change, cargo exception. Without this, operators miss critical operational events.
**Acceptance:** FCM token registered on login. Notifications received and displayed in-app when app is foregrounded. Deep-link navigates to relevant screen.

#### F-003: Flutter offline sync layer
**Effort:** 3-4 days
**Dependencies:** `sqflite_sqlcipher` already declared in pubspec
**Why P0:** The core architecture principle is "Offline First." Without offline sync, counter staff, conductors, and drivers cannot work in areas with poor connectivity. The backend already supports the sync bootstrap API (`/api/v1/organizations/{id}/sync/bootstrap/`).
**Acceptance:** Bookings, cargo acceptances, and payment records created while offline are queued locally and sync when connectivity returns. Conflicts are surfaced for manual resolution.

#### F-004: Complete booking lifecycle (backend)
**Effort:** 2-3 days
**Why P0:** Corporate booking + approval workflow + invoice generation is listed as P0 in the backlog. Without it, transport companies cannot use the platform for group bookings.
**Acceptance:** Company can create group booking, approval workflow routes to authorized approver, invoice generated on approval.

#### F-005: Complete payment lifecycle (backend + Flutter)
**Effort:** 3-4 days
**Why P0:** Refund/cancellation/reissue workflow is P0 in the backlog. Without it, operators cannot handle ticket cancellations or refunds — a basic operational requirement.
**Acceptance:** Passenger can request refund. Operator can approve/reject. Ticket is revoked and reissued if applicable.

### P1 — Required for Pilot

#### F-006: QR scanning (Flutter)
**Effort:** 1 day
**Why P1:** Ticket validation via QR is required for conductors. The `mobile_scanner` package is already declared.
**Acceptance:** Conductor scans passenger e-ticket QR. App displays ticket validity and journey details.

#### F-007: Bluetooth printing (Flutter)
**Effort:** 3-4 days
**Why P1:** MVP requires counter staff to print tickets and cargo receipts. Backend print API is complete.
**Acceptance:** Counter can print ticket on Bluetooth thermal printer. Cargo receipt prints with QR.

#### F-008: Online payment connector (backend)
**Effort:** 2-3 days
**Why P1:** Encrypted provider credential model, sandbox test, signed webhook. Required before real payment providers can integrate.
**Acceptance:** KBZPay/AYA Pay connector integrated in sandbox mode. Webhook signature verified.

#### F-009: Push delivery live adapter (backend)
**Effort:** 1-2 days
**Why P1:** FCM/APNs provider worker is marked as "Missing" in the completion matrix. Notifications cannot be delivered without it.
**Acceptance:** FCM adapter sends notifications to Android devices. APNs adapter sends to iOS.

---

## Phase 2: Code Quality

**Goal:** The codebase is maintainable and follows HEOS standards.
**Entry gate:** Phase 1 features deployed to staging.

- Extract 5 shared Flutter widgets (ErrorCard, LoadingIndicator, SectionHeader, EmptyStateCard, DynamicDropdown)
- Create design token file (`lib/core/theme/spacing.dart`)
- Fix all hardcoded color violations
- Remove 5 unused pubspec dependencies
- Add linting rules to `analysis_options.yaml`
- Fix naming inconsistencies across Flutter feature files

---

## Phase 3: Testing

**Goal:** Automated tests cover critical paths.
**Entry gate:** Phase 2 complete (code quality baseline established).

- Backend coverage baseline (`coverage run`)
- Flutter widget tests: SignInScreen, BusinessHome, CargoWorklist, CounterBooking
- Backend integration tests: booking → payment → ticket, cargo lifecycle
- Flutter CI gate requires tests to pass
- Backend CI gate requires coverage not to decrease

---

## Phase 4: Production Infrastructure

**Goal:** Infrastructure supports safe deployment and operation.
**Entry gate:** Phases 1-3 complete. Feature-complete app with test safety net.

- Create gunicorn config + add to Docker entrypoint
- Add HEALTHCHECK to Dockerfile
- Create staging environment
- Create deploy CI workflow
- Configure PostgreSQL TLS
- Write root README.md
- Create .gitignore at root

---

## Phase 5: Security

**Goal:** Production deployment is not immediately exploitable.
**Entry gate:** Phase 4 complete (infrastructure deployed to staging).

- Add Sentry error tracking (backend)
- Add idle session timeout middleware
- Verify login rate limiting is active
- Add Flutter obfuscation to release build
- Add container image scanning (Trivy) to CI
- Add certificate pinning to Flutter
- Add SECURITY.md (exists but PGP key not published)

---

## Phase 6: Observability

**Goal:** Production operation is visible and measurable.
**Entry gate:** Phase 5 complete (security baseline established).

- Add Prometheus metrics endpoint
- Add structured JSON logging
- Add Sentry Flutter crash reporting
- Configure alerting rules
- Create Grafana dashboard
- Set up uptime monitoring
- Add load testing (k6) baseline

---

## Phase 7: Release Candidate

**Goal:** All gates pass. Decision to ship.
**Entry gate:** Phases 1-6 complete.

- Run full release checklist
- Deploy to staging
- Run E2E smoke tests
- Code freeze
- Final security review
- Generate coverage report (≥60%)
- Run load tests (p50/p95/p99 documented)
- Release candidate tagged

---

## Phase 8: Production

**Goal:** Application is live and monitored.
**Entry gate:** Phase 7 release candidate approved.

- Production deploy per runbook
- Verify Sentry: 0 critical errors
- Verify Prometheus: normal metrics
- Verify backup: automated cron running
- Smoke test all critical flows
- Monitor for 24h
- Release announced

---

## Summary

```
Phase 1: Business Features   ⬜⬜⬜⬜⬜  0/9  ← WE ARE HERE
Phase 2: Code Quality        ⬜⬜⬜⬜⬜
Phase 3: Testing             ⬜⬜⬜⬜⬜
Phase 4: Infrastructure      ⬜⬜⬜⬜⬜
Phase 5: Security            ⬜⬜⬜⬜⬜
Phase 6: Observability       ⬜⬜⬜⬜⬜
Phase 7: Release Candidate   ⬜⬜⬜⬜⬜
Phase 8: Production          ⬜⬜⬜⬜⬜
```

### First 5 Tasks

| ID | Task | Phase | Effort |
|----|------|-------|--------|
| F-001 | Flutter passenger self-service app | 1 | 5-7d |
| F-002 | Flutter push notification integration | 1 | 2d |
| F-003 | Flutter offline sync layer | 1 | 3-4d |
| F-004 | Complete booking lifecycle (corporate + invoice) | 1 | 2-3d |
| F-005 | Complete payment lifecycle (refund/cancel/reissue) | 1 | 3-4d |
| F-006 | QR scanning (Flutter) | 1 | 1d |
| F-007 | Bluetooth printing (Flutter) | 1 | 3-4d |
| F-008 | Online payment connector (backend) | 1 | 2-3d |
| F-009 | Push delivery live adapter (backend) | 1 | 1-2d |
| | **Total Phase 1** | | **22-34 days** |
