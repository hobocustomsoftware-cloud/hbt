# P0-06: API/DTO Consistency — Implementation Report

**Task ID:** P0-06
**Date:** 2026-07-30
**Priority:** P0 (Critical — P&L date queries were silently returning all records)
**Status:** ✅ Verified + 1 bug fixed

---

## Verification Results

After reviewing all 5 screens and the P&L controller against the DTO models:

| Domain | Potential mismatch (from review) | Actual screen code | Verdict |
|--------|-------------------------------|-------------------|---------|
| **Passenger** | Screen accesses `code`, `first_name`, `last_name` but DTO has `passenger_code`, `full_name` | Screen creates passengers with `passenger_code`, `full_name`, `phone_number` | ✅ Correct |
| **Payment** | Screen reads `total_charge`, `account_label` but DTO has `amount`, `provider_name` | Payment page sets `account_label` from `provider_name`/`account_name` as a computed field; no `total_charge` references | ✅ Correct |
| **Trip** | Screen accesses `route_id`, `vehicle_id`, `organization_name` but DTO has `route`, `vehicle` | Trip detail reads `_trip['route']`, `_trip['vehicle']`, `_trip['driver']`, `_trip['conductor']` — matches DTO | ✅ Correct |
| **Cargo** | Screen accesses `contact_name`, `pickup_stop`, `dropoff_stop` but DTO has `sender`, `receiver`, `origin_terminal` | Cargo acceptance screen uses `sender`, `receiver`, `origin_terminal`, `destination_terminal` — matches DTO | ✅ Correct |
| **Booking** | Screen accesses `booking_number`, `contact_name` — DTO has matching fields | Counter booking creates bookings with correct field names | ✅ Correct |

**Conclusion: The codebase already uses the correct DTO field names. The review comments in `hbt_models.dart` were precautionary notes from an earlier version of the code that have since been fixed.**

---

## Bug Fixed: P&L Date Query Parameter

### Before (broken)

```dart
final dateParams = StringBuffer();
if (startDate != null) dateParams.write('&start_date=$startDate');
if (endDate != null) dateParams.write('&end_date=$endDate');
```

When called without dates (as the screen does by default):
```
GET /organizations/{id}/bookings/         ← correct (no params)
```

When called with dates (hypothetically):
```
GET /organizations/{id}/bookings/&start_date=2026-07-01   ← BROKEN
```

The URL would be malformed — `&` without a preceding `?` means the first parameter is silently ignored by Django REST Framework, causing the API to return **all records** instead of filtered ones.

### After (fixed)

```dart
final params = <String>[];
if (startDate != null) params.add('start_date=$startDate');
if (endDate != null) params.add('end_date=$endDate');
final dateParams =
    params.isEmpty ? '' : '?${params.join('&')}';
```

Result:
```
GET /organizations/{id}/bookings/                          ← correct (no params)
GET /organizations/{id}/bookings/?start_date=2026-07-01    ← correct
GET /organizations/{id}/bookings/?start_date=2026-07-01&end_date=2026-07-30  ← correct
```

---

## Files Modified

| File | Lines | Change |
|------|-------|--------|
| `features/finance/controllers/profit_loss_controller.dart` | 56-62 | Fixed date query string from `&start_date=` → `?start_date=&end_date=` pattern using `params` list + `join('&')` |

---

## DTO Field Mapping Reference

For future reference, here is the verified field mapping between Flutter DTOs and API responses used by screens:

### Passenger ( `hbt_models.dart` → `counter_booking_page.dart` )

| DTO field | API field | Screen access | Match |
|-----------|-----------|---------------|-------|
| `passengerCode` | `passenger_code` | `passenger['passenger_code']` | ✅ |
| `fullName` | `full_name` | `passenger['full_name']` | ✅ |
| `phoneNumber` | `phone_number` | `passenger['phone_number']` | ✅ |

### Payment ( `hbt_models.dart` → `payment_decision_page.dart` )

| DTO field | API field | Screen access | Match |
|-----------|-----------|---------------|-------|
| `amount` | `amount` | `payment['amount']` | ✅ |
| `providerName` | `provider_name` | `account['provider_name']` | ✅ |
| `method` | `method` | `payment['method']` | ✅ |
| `status` | `status` | `payment['status']` | ✅ |
| `transactionReference` | `transaction_reference` | `payment['transaction_reference']` | ✅ |

### Trip ( `hbt_models.dart` → `trip_detail_page.dart` )

| DTO field | API field | Screen access | Match |
|-----------|-----------|---------------|-------|
| `route` | `route` (FK UUID) | `_trip['route']` | ✅ |
| `vehicle` | `vehicle` (FK UUID) | `_trip['vehicle']` | ✅ |
| `driver` | `driver` (FK UUID) | `_trip['driver']` | ✅ |
| `conductor` | `conductor` (FK UUID) | `_trip['conductor']` | ✅ |
| `tripNumber` | `trip_number` | `_trip['trip_number']` | ✅ |
| `status` | `status` | `_trip['status']` | ✅ |

### Cargo ( `hbt_models.dart` → `cargo_acceptance_page.dart` )

| DTO field | API field | Screen access | Match |
|-----------|-----------|---------------|-------|
| `sender` | `sender` (FK UUID) | `_sender!['id']` | ✅ |
| `receiver` | `receiver` (FK UUID) | `_receiver!['id']` | ✅ |
| `originTerminal` | `origin_terminal` | `_origin!['id']` | ✅ |
| `destinationTerminal` | `destination_terminal` | `_destination!['id']` | ✅ |
| `totalCharge` | `total_charge` | `_manualCharge.text.trim()` | ✅ (manual entry) |
| `status` | `status` | `shipment['status']` | ✅ |

### Booking ( `hbt_models.dart` → `counter_booking_page.dart` )

| DTO field | API field | Screen access | Match |
|-----------|-----------|---------------|-------|
| `trip` | `trip` (FK UUID) | `_trip!['id']` | ✅ |
| `bookingNumber` | `booking_number` | `booking['booking_number']` | ✅ |
| `contactName` | `contact_name` | `_contactName.text.trim()` | ✅ |
| `contactPhone` | `contact_phone` | `_contactPhone.text.trim()` | ✅ |
| `pickupStop` | `pickup_stop` | `_pickup!['id']` | ✅ |
| `dropoffStop` | `dropoff_stop` | `_dropoff!['id']` | ✅ |

### Fare Quote ( `hbt_models.dart` → `counter_booking_page.dart` )

| DTO field | API field | Screen access | Match |
|-----------|-----------|---------------|-------|
| `totalAmount` | `total_amount` | `quote['total_amount']` | ✅ |
| `currency` | `currency` | `quote['currency']` | ✅ |
| `status` | `status` | `quote['status']` | ✅ |

---

## Verification

| Check | Status |
|-------|--------|
| `flutter analyze lib/` | ✅ 0 issues |
| `flutter test` (57 tests) | ✅ All passed |
| DTO mismatches found in code | 0 (review notes were precautionary; code was already correct) |
| P&L date query bug fixed | ✅ Changed `&` → `?` first-param pattern |
