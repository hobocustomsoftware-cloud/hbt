# Release Candidate v1

**Date:** 2026-07-29
**Status:** ✅ RELEASE CANDIDATE

---

## Verification Summary

| Check | Result | Details |
|-------|--------|---------|
| `dart analyze` Business App | ✅ PASS | 0 issues |
| `dart analyze` Passenger App | ✅ PASS | 0 issues |
| `flutter test` Business App | ✅ PASS | 25/25 tests (11 existing + 14 new integration) |
| API field mismatches | ✅ FIXED | M-001, M-004 in sync layer; others verified correct |
| Integration tests added | ✅ 3 files | Booking → Quote → Lock, Payment → Issue, Refund full lifecycle |
| Release documentation | ✅ GENERATED | `release/release-candidate.md` (audit) + this document |

---

## What Changed This Sprint

### API Mismatch Fixes (3 files)

| File | Change | Issue |
|------|--------|-------|
| `lib/core/offline/sync_manager.dart` | `payload['booking_reference']` → `payload['authorization_reference']` | M-001 |
| `lib/core/offline/sync_manager.dart` | `payload['first_name']`/`payload['last_name']` → `payload['full_name']` | M-004 |
| `lib/core/database/app_database.dart` | Column rename + v3 migration + schema bump 2→3 | M-001, M-004 |
| `lib/core/models/hbt_models.dart` | Updated misleading comment | M-001, M-002 |

### Verified NOT Bugs (5 items excluded after OpenAPI contract check)

| Issue | Finding | Evidence |
|-------|---------|----------|
| M-002 (monetary fields) | Screen reads from FareQuote correctly ✅ | `widget.quote['total_amount']`, `_quote!['total_amount']` in screen code |
| M-003 (`organization_name`) | PublicTripSearch has this field ✅ | OpenAPI `PublicTripSearch.organization_name` exists |
| M-005 (`phone`→`phone_number`) | Screen uses `phone_number` correctly ✅ | `counter_booking_page.dart` sends `'phone_number': phone.text.trim()` |
| M-006 (`ticket['status']` String) | Ticket has `status` as TicketStatusEnum string enum ✅ | OpenAPI `TicketStatusEnum` |
| M-007 (`passenger_name` flat) | Ticket has `passenger_name` as flat string ✅ | OpenAPI `Ticket.passenger_name` |

### Integration Tests Added (3 files, 14 new tests)

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `test/features/booking/booking_integration_test.dart` | 4 | Booking → Quote → Lock with API call ordering |
| `test/features/payment/payment_integration_test.dart` | 5 | Evidence upload → Payment record → Decision → Ticket issue |
| `test/features/refund/refund_full_flow_test.dart` | 5 | Full refund lifecycle: request→approve→paid→complete |

### Passenger App Cleanup (4 fixes)

| File | Change |
|------|--------|
| `booking_screen.dart` | Doc comment: backtick `<T>` |
| `trip_search_screen.dart` | Doc comments: backtick `<T>` |
| `trip_search_screen.dart` | String interpolation: `${city}` → `$city` |

---

## Known Remaining Gaps (Low Risk)

| Gap | Impact | Mitigation |
|-----|--------|------------|
| No widget tests for UI screens | UI regressions manual-detectable | 14 integration tests cover data flow |
| Online-only (offline infrastructure unused) | No offline fallback on network error | Documented MVP caveat |
| No MFA, no cert pinning | Single-factor auth for pilot | Acceptable for supervised pilot |
| No staging environment | Pre-production validation manual | Use CI for automated validation |

---

## Artifacts

```
release/
├── release-candidate.md       # Full Release Readiness Audit
├── release-candidate-v1.md    # This document (sprint summary)
└── README.md                  # Release directory overview

flutter/hbt_business_app/
├── lib/core/offline/sync_manager.dart          # FIXED: API field names
├── lib/core/database/app_database.dart         # FIXED: column names + v3 migration
├── lib/core/models/hbt_models.dart             # FIXED: comments
├── test/features/booking/booking_integration_test.dart    # NEW
├── test/features/payment/payment_integration_test.dart    # NEW
├── test/features/refund/refund_full_flow_test.dart        # NEW

flutter/hbt_passenger_app/
├── lib/features/booking/presentation/booking_screen.dart    # FIXED
├── lib/features/trip/presentation/trip_search_screen.dart   # FIXED
```

---

*End of Release Candidate v1*
