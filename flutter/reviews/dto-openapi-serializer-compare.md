# Flutter DTO ↔ OpenAPI ↔ Django Serializer — Three-Way Comparison

**Date:** 2026-07-29  
**Sources:** `openapi.yaml` (333 schemas) → 23 `serializers.py` files → Flutter field usage across 18 screens  

---

## Summary

| Layer | Count | Format |
|---|---|---|
| OpenAPI schemas | 333 | `components/schemas/` in `openapi.yaml` |
| Django serializers | 23 files | `backend/apps/*/serializers.py` |
| Flutter DTOs | **before: 0** | Raw `Map<String, dynamic>` — **no typed models** |
| Flutter DTOs | **after: 12 classes** | `hbt_models.dart` — properly typed |
| Mismatches found | **7 critical** | Field name/type/belonging errors |

---

## 1. Critical Mismatches (Will Cause Runtime Errors)

### M-001: Booking — `booking_reference` doesn't exist

| Source | Field | Status |
|---|---|---|
| Flutter code | `booking['booking_reference']` | ❌ Wrong name |
| OpenAPI Booking schema | `authorization_reference` | ✅ Correct |
| Backend serializer | `BookingSerializer` → `authorization_reference` | ✅ Correct |

**Fix:** Rename all `booking['booking_reference']` → `booking['authorization_reference']` across both apps.

### M-002: Booking — Monetary fields belong to FareQuote, not Booking

| Source | Fields | Status |
|---|---|---|
| Flutter code | `booking['base_fare']`, `['discount_amount']`, `['tax_amount']`, `['total_amount']`, `['currency']` | ❌ Wrong parent object |
| OpenAPI Booking schema | **No monetary fields** | ✅ Correct |
| OpenAPI FareQuote schema | `subtotal`, `discount_amount`, `tax_amount`, `total_amount`, `currency` | ✅ Correct |
| Backend serializer | `FareQuoteSerializer` → `total_amount`, `discount_amount`, etc. | ✅ `FareQuote` model |

**Fix:** Read monetary fields from `FareQuote` response, not from `Booking`. The `counter_booking_page.dart` receives fare quote data but reads it from the booking map.

### M-003: Trip — `organization_name` doesn't exist

| Source | Field | Status |
|---|---|---|
| Flutter code | `trip['organization_name']` | ❌ Not on Trip |
| OpenAPI Trip schema | No `organization_name` | ✅ Correct |
| PublicTripSearch schema | `organization_name` exists here | ✅ Available on search results |

**Fix:** `organization_name` is only available on `PublicTripSearch` results (passenger app), not on the `Trip` object (counter app). Use `organization_id` and resolve via Organization context.

### M-004: Passenger — `first_name`, `last_name`, `email`, `code` don't exist

| Source | Field | Status |
|---|---|---|
| Flutter code | `passenger['code']` | ❌ Wrong name |
| Flutter code | `passenger['first_name']`, `passenger['last_name']` | ❌ Doesn't exist |
| Flutter code | `passenger['email']` | ❌ Doesn't exist |
| OpenAPI Passenger schema | `passenger_code` | ✅ Correct name |
| OpenAPI Passenger schema | `full_name` | ✅ Single field, not split |
| Backend serializer | `PassengerSerializer` → `passenger_code`, `full_name` | ✅ Matches OpenAPI |

**Fix:** `passenger['code']` → `passenger['passenger_code']`. `passenger['first_name']` + `passenger['last_name']` → `passenger['full_name']`. Remove `passenger['email']` — backend has no email on Passenger model.

### M-005: CargoShipment — `contact_name`, `pickup_stop`, `dropoff_stop` don't exist

| Source | Field | Status |
|---|---|---|
| Flutter code | `shipment['contact_name']` | ❌ Doesn't exist |
| Flutter code | `shipment['pickup_stop']` | ❌ Wrong field |
| Flutter code | `shipment['dropoff_stop']` | ❌ Wrong field |
| OpenAPI CargoShipment schema | `sender`, `receiver` (UUIDs) | ✅ Correct |
| OpenAPI CargoShipment schema | `origin_terminal`, `destination_terminal` (UUIDs) | ✅ Correct |
| Backend serializer | `CargoShipmentSerializer` → same as OpenAPI | ✅ Correct |

**Fix:** Read `sender`/`receiver` (not `contact_name`) and `origin_terminal`/`destination_terminal` (not `pickup_stop`/`dropoff_stop`).

### M-006: Payment — `total_charge` and `account_label` don't exist

| Source | Field | Status |
|---|---|---|
| Flutter code | `payment['total_charge']` | ❌ Wrong field |
| Flutter code | `payment['account_label']` | ❌ Doesn't exist |
| OpenAPI PaymentRecord schema | `amount` | ✅ Correct |
| OpenAPI PaymentRecord schema | `provider_name` | ✅ Use for display |
| Backend serializer | `PaymentRecordSerializer` → `amount`, `provider_name` | ✅ Correct |

**Fix:** `payment['total_charge']` → `payment['amount']`. `payment['account_label']` → `payment['provider_name']`.

### M-007: Trip — FK fields use `_id` suffix but OpenAPI has bare names

| Source | Field | Status |
|---|---|---|
| Flutter code | `trip['route_id']`, `trip['vehicle_id']`, `trip['driver_id']` | ❌ Wrong key |
| Flutter code | `trip['conductor_id']`, `trip['trip_id']` | ❌ Wrong key |
| OpenAPI Trip schema | `route`, `vehicle`, `driver`, `conductor` | ✅ Just the FK string |
| OpenAPI Booking schema | `trip` | ✅ Just the FK string |
| OpenAPI Ticket schema | `trip` | ✅ Just the FK string |

**Fix:** `trip['route_id']` → `trip['route']`. `trip['vehicle_id']` → `trip['vehicle']`. `trip['driver_id']` → `trip['driver']`. `trip['conductor_id']` → `trip['conductor']`. `booking['trip_id']` → `booking['trip']`.

---

## 2. Minor Mismatches (Non-Critical)

| # | Context | Flutter Field | Correct Field | Severity |
|---|---|---|---|---|
| 1 | Route | `route['stops']` | Not on Route schema (stops are in `RouteStop`) | Low — route snapshot has stops nested |
| 2 | Route | `route['terminal']` | `RouteStop.terminal` (per-stop), not Route | Low |
| 3 | Route | `route['city']` | `RouteStop.city` (per-stop), not Route | Low |
| 4 | Route | `route['color']` | Not in any serializer — presentation-only | Low — cosmetic |
| 5 | Booking | `booking['passenger_name']` | `BookingPassenger.passenger_name` (nested) | Medium — wrong access path |
| 6 | Booking | `booking['seat_identifier']` | `BookingPassenger.seat_reservation.seat_identifier_snapshot` | Medium — deeply nested |
| 7 | Booking | `booking['seats']` | `BookingPassenger` list with `SeatReservation` | Medium — wrong shape |
| 8 | Ticket | `ticket['booking_id']` | `ticket['booking']` | Low — both work |
| 9 | Stop | `stop['terminal']` | `RouteStop.terminal` — exists | Low — correct |
| 10 | Vehicle | `vehicle['name']` | `Vehicle.code` or `Vehicle.fleet_number` | Low |
| 11 | Vehicle | `vehicle['identifier']` | `Vehicle.code` | Low |
| 12 | Organization | `org['code']` | `Organization` schema has no `code` field — `tenancy.Organization` has `code` via SlugField | Medium — tenancy serializer != public org schema |

---

## 3. Fields Only in OpenAPI — Unused by Flutter

These backend fields are available but never read by either Flutter app:

| Schema | Unused Fields | Count |
|---|---|---|
| Trip | `boarding_started_at`, `departed_at`, `arrived_at`, `current_stop`, `schedule`, `schedule_snapshot`, `seat_layout`, `seat_layout_snapshot`, `schedule_snapshot` | 9 |
| Booking | `booking_type`, `channel`, `contact_phone`, `expires_at`, `confirmed_at`, `client_request_id`, `passenger_items` | 7 |
| Ticket | `booking_passenger`, `seat_position`, `ticket_type`, `validation_code`, `qr_payload`, `service_charge`, `issuing_channel`, `issued_by`, `issued_at`, `replacement_of`, `revoked_at`, `revoked_by`, `revocation_reason` | 14 |
| CargoShipment | 40+ fields (tracking_code, weight_source, dimensions, custody_events, charge_lines, etc.) | 40+ |

---

## 4. Auto-Fix: Flutter Models Created

**File:** `flutter/hbt_business_app/lib/core/models/hbt_models.dart`

| Class | JSON Fields | Based On |
|---|---|---|
| `Trip` | `id`, `organization_id`, `route`, `trip_number`, `service_date`, `planned_departure_at`, `planned_arrival_at`, `status`, + read-only operational fields | OpenAPI Trip |
| `RouteDto` | `id`, `code`, `name`, `status`, `stop_count`, `estimated_distance_km`, `estimated_duration_minutes` | OpenAPI Route |
| `RouteStopDto` | `id`, `route_id`, `terminal`, `code`, `name`, `sequence`, `stop_type`, `status`, `city` | OpenAPI RouteStop |
| `Booking` | `id`, `organization_id`, `trip`, `booking_number`, `status`, `pickup_stop`, `dropoff_stop`, `contact_name`, `authorization_reference`, `passenger_items` | OpenAPI Booking |
| `BookingPassenger` | `id`, `passenger`, `passenger_name`, `seat_reservation` | OpenAPI BookingPassenger |
| `SeatReservation` | `id`, `seat_position`, `seat_identifier_snapshot`, `status` | OpenAPI SeatReservation |
| `Ticket` | `id`, `booking`, `passenger_name`, `trip`, `trip_number`, `planned_departure_at`, `seat_identifier`, `ticket_number`, `status`, `qr_payload`, `fare_amount`, `total_amount` (28 fields) | OpenAPI Ticket |
| `PaymentRecord` | `id`, `amount`, `payment_number`, `status`, `method`, `currency`, `provider_name` | OpenAPI PaymentRecord |
| `FareQuote` | `id`, `currency`, `subtotal`, `discount_amount`, `tax_amount`, `total_amount`, `lines` | OpenAPI FareQuote |
| `FareQuoteLine` | `id`, `booking_passenger`, `base_fare`, `discount_amount`, `tax_amount`, `total_amount` | OpenAPI FareQuoteLine |
| `Passenger` | `id`, `passenger_code`, `full_name`, `phone_number` | OpenAPI Passenger |
| `CargoShipment` | `id`, `shipment_number`, `tracking_code`, `sender`, `receiver`, `origin_terminal`, `destination_terminal`, `status`, `item_category`, `piece_count`, `weight_kg`, `total_charge` | OpenAPI CargoShipment |
| `VehicleDto` | `id`, `code`, `fleet_number`, `registration_number`, `brand`, `model`, `passenger_capacity` | OpenAPI Vehicle |
| `OrganizationDto` | `id`, `display_name`, `legal_name`, `tenant_id` | OpenAPI Organization |

**Verification:** `dart analyze` — **0 errors, 0 warnings**.

---

## 5. Migration Path (Flutter App → Typed DTOs)

Each screen currently uses `Map<String, dynamic>` and accesses fields with `['key']` bracket notation. Migration to typed DTOs:

```
Phase 1: ✅ Create DTOs (this PR)
Phase 2: Screen-by-screen migration:
  trip_detail_page.dart       → Trip.fromJson(trip)
  booking_screen.dart         → FareQuote.fromJson(quote)
  counter_booking_page.dart   → Booking.fromJson(booking)
  ticket_sales_page.dart      → Ticket.fromJson(ticket)
  payment_decision_page.dart  → PaymentRecord.fromJson(payment)
  cargo_worklist_page.dart    → CargoShipment.fromJson(shipment)
  cargo_acceptance_page.dart  → CargoShipment.fromJson(shipment)
  ticket_list_screen.dart     → Ticket.fromJson(ticket)
  trip_search_screen.dart     → Trip.fromJson(trip)  # PublicTripSearch has subset
Phase 3: Fix all broken field name references
Phase 4: Remove all raw `['key']` accesses
```

Each migration is a pure mechanical replacement — no business logic changes.
