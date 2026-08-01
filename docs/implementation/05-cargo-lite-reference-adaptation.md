# Cargo Lite Reference Adaptation

## Purpose

This decision record defines how proven Myanmar express-bus cargo practices
observed in the Shwe Yoke Lay reference systems are adapted into HBT Cargo
Lite. It supplements, and does not replace, the Cargo module, Cargo workflow,
MVP scope, access-control matrix, and offline architecture.

## Adopted operational concepts

- A short sender → receiver → items → charges → review entry flow.
- Searchable regular sender and receiver profiles.
- Multiple cargo items within one shipment.
- Manual, unit, and per-kilogram pricing.
- Terminal, counter, agent, roadside, and conductor acceptance channels.
- Trip cargo manifests and scan-based lookup.
- Customer and office receipt/label printing.
- Outstanding-payment visibility and trip/counter reconciliation.

## HBT adaptations

1. Cargo and roadside cargo MUST use one `CargoShipment` lifecycle. Acceptance
   channel and custody events distinguish operational origin.
2. A shipment MAY contain multiple immutable item-pricing snapshots and charge
   lines.
3. The backend MUST calculate the authoritative shipment total. A mobile
   client total is never authoritative.
4. Charges and discounts MUST be explicit lines so organization policy can
   evolve without schema changes.
5. Regular contacts MUST remain tenant-owned. Missing identity MUST be
   represented by an explicit identity state and reason, never a fabricated
   `"N/A"` identity.
6. Roadside acceptance MUST be restricted to an active assigned trip and an
   effective scoped permission.
7. Cargo QR data MUST contain only a signed opaque reference. It MUST NOT
   contain sender, receiver, NRC, phone, address, or financial data.
8. Cargo state changes MUST use custody transitions and audit events. Normal
   CRUD deletion MUST NOT represent operational cancellation.
9. Confirmed cargo payments MUST NOT exceed the server-calculated shipment
   total. Payment, settlement, and cargo remain separate domains.
10. Offline creation and custody events MUST use client-generated idempotency
    identifiers and MUST reject cross-tenant reuse.

## Myanmar bus-terminal pricing modes

HBT supports the different practices used by Myanmar express-bus terminals
without forcing one company to use another company's formula.

### Manual total

The operator enters an agreed shipment amount directly. The backend stores the
manual amount and still calculates the final customer total after explicit
charges and discounts. HBT supports both a whole-shipment manual total and a
manual per-item rate multiplied by quantity. The pricing actor, time, and
reason are preserved.

### Per kilogram

The backend calculates:

`measured or declared weight × rate per kilogram`

The weight source remains visible so a roadside declared weight is not
misrepresented as a scale measurement.

### Company-defined base kilogram and excess rate

An authorized company user may configure a pricing rule containing base
weight, base price, and excess rate per kilogram. Decimal excess is calculated
proportionally and MUST NOT be rounded to the next whole kilogram unless a
future, explicitly approved company policy says otherwise.

For a 5 kg base price of MMK 20,000 and an excess rate of MMK 5,000/kg:

- 5 kg = MMK 20,000
- 5.5 kg = MMK 22,500
- 6 kg = MMK 25,000

The selected rule values are snapshotted onto the cargo item so later company
price changes do not rewrite historical shipments.

### Per item / station breakdown

This adapts the Shwe Yoke Lay terminal workflow:

`sum(item quantity × item rate) + customer charge lines - discounts`

Typical configurable customer charge lines include service/handling, transit,
short delivery, and last-mile delivery. HBT does not hard-code those labels
because terminology and usage differ between operators.

A destination-terminal or partner share is an `allocation`, not a customer
discount. Allocations are reported internally but MUST NOT change the amount
charged to the sender. A shipment containing different item pricing methods is
reported as `mixed`.

### Confirmed Shwe Yoke Lay fee meanings

- `service_charge` / တန်ဆာခ is the primary transport charge. It may be a
  manual whole-shipment amount, manual per-item rate, direct per-kg amount, or
  company-defined base-kg-plus-excess calculation.
- `short_deli_fee` / ခေါက်တိုကြေး is a customer charge for an additional short
  transport leg.
- `transit_fee` / တဆင့်သွားတန်ဆာ is a customer charge when cargo must transfer
  through an intermediate vehicle or terminal. It may be calculated per item
  times quantity.
- `border_fee` / ဘော်ဒါကြေး does **not** mean a geographic border charge. It is
  an internal payout from the terminal's collected revenue to the person who
  introduced or brought the sender/cargo to the terminal. The customer pays
  the full customer total; this payout MUST NOT reduce that total.
- `home_delivery_fee` / `final_deli_fee` is a customer charge for delivery to
  the destination address.

An internal payout records its recipient, amount, unpaid/paid state, payment
actor and payment time. This preserves exact terminal accounts and allows the
fee to be disabled later when direct passenger pickup ordering removes the
intermediary.

## Current API contracts

- `GET|POST /organizations/{organization_id}/cargo/categories/`
- `GET|POST /organizations/{organization_id}/cargo/contacts/`
- `GET|POST /organizations/{organization_id}/cargo/shipments/`
- `POST /organizations/{organization_id}/cargo/qr/resolve/`
- `GET /organizations/{organization_id}/trips/{trip_id}/cargo-manifest/`
- `POST /organizations/{organization_id}/trips/{trip_id}/cargo/roadside/`

Shipment creation accepts optional `items` and `charge_lines`. Legacy Cargo
Lite header pricing remains supported during migration.

## Deferred extensions

- Organization charge-policy templates and price overrides with approval.
- Receiver OTP/signature/photo delivery evidence.
- Damage, shortage, loss, and investigation records.
- Device-side encrypted outbox and delta synchronization.
- Bluetooth printer profiles and cargo label templates.
- Cargo revenue, outstanding, route, terminal, and owner dashboards.

## Specification compliance

| Requirement source | Implemented control |
|---|---|
| MVP Cargo Lite | Counter and assigned-crew acceptance, payment status, manifest, QR, printing integration |
| Cargo Module | Sender, receiver, terminals, items, weight, dimensions, declared value, charges, trip and lifecycle |
| Cargo Workflow | Controlled transitions, capacity/route checks, append-only custody history and verified handover |
| Module/Data Architecture | Cargo-owned records with tenant foreign keys; payment and trip remain separate modules |
| Offline Architecture | Idempotent shipment and custody identifiers, deferred-event marker and conflict-safe tenant checks |
| Access-Control Matrix | Deny-by-default organization permission plus assigned-trip scope for crew workflows |
| Payment/Settlement | Confirmed-payment allocation guard; cargo totals remain separately reportable in trip closing |
| Reporting | Tenant-scoped owner summary with channel, volume, charge, paid and outstanding totals |

### Intentional MVP boundary decisions

- A shipment may be accepted before a trip is assigned because terminal
  operations do not always know the final vehicle at acceptance time. It MUST
  have a valid company trip before the `assigned`/`loaded` lifecycle proceeds.
  This resolves the generic Cargo Module wording against the confirmed MVP
  acceptance → assignment workflow.
- Home delivery, multi-leg logistics, warehouse operations, cold-chain
  telemetry, claims processing, and public passenger cargo booking remain
  deferred.
- Device-local encryption, authorization snapshots, background sync, and
  Bluetooth transport are Flutter responsibilities. Backend idempotency,
  permission, document, and audit contracts are present for those clients.
