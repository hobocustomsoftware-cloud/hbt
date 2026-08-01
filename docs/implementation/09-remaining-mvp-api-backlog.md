# Remaining MVP API Backlog / ကျန်ရှိသော MVP API စာရင်း

**Reviewed:** 2026-07-26  
**Authority:** `docs/product/01-mvp-scope.md` and approved stakeholder decisions

---

# မြန်မာဘာသာ

## P0 — Flutter အပြည့်အဝမစမီ

1. **Company booking နှင့် invoice**
   - Company customer profile/membership
   - Group booking submit/approve/reject
   - Segregation of duties
   - Invoice issue/view/void
   - Invoice payment allocation

2. **Refund/cancellation/reissue**
   - Refund request/approve/reject/complete
   - Partial/full amount safeguards
   - Ticket revoke/reissue linkage
   - Inspection သီးခြား record
   - Booking expiry worker

3. **Online payment connector**
   - Encrypted provider credential model
   - Sandbox connection test
   - Payment initiation/status
   - Signed webhook
   - Credential rotation/revoke
   - Reconciliation

4. **Offline business mutations**
   - Trip/stop event
   - Ticket inspection/boarding
   - Cargo accept/custody
   - Cash/manual payment record
   - Walk-up booking နှင့် seat conflict

5. **Push delivery**
   - FCM/APNs provider worker
   - Token invalidation
   - Retry/backoff
   - Delivery receipt
   - Booking-expiry scheduler

6. **OpenAPI**
   - Stable operation IDs
   - Request/response/error schemas
   - Permission/scope information
   - Idempotency and offline metadata

## P1 — Pilot မတိုင်မီ

- Subscription plan/invoice/entitlement/grace/suspension APIs
- Printer profiles၊ Myanmar templates နှင့် offline print audit upload
- PDF/CSV report exports
- Privacy request/account closure workflow
- Device approval၊ shift open/handover/close
- Audit/security event search and export
- Monitoring metrics and alert endpoints

## မူဝါဒအတည်ပြုချက်လိုသောအချက်

Company approver၊ invoice/tax field၊ refund rate၊ reissue rule၊ booking expiry၊
delay threshold၊ crew offline visibility၊ subscription grace period၊ retention
နှင့် dispute/legal data တို့ကို အတည်ပြုပြီးမှ API acceptance test ကို final
လုပ်နိုင်မည်။

---

# English

## P0 — Before full Flutter implementation

1. Corporate customer, group approval and invoice operations.
2. Refund, cancellation, expiry, ticket revocation/reissue and separate
   inspection operations.
3. Encrypted online-payment connector configuration, test, initiation,
   signed webhook, rotation and reconciliation.
4. Domain-specific offline trip, ticket, cargo, payment and walk-up booking
   handlers with conflict rules.
5. FCM/APNs delivery worker, token invalidation, retry and receipts.
6. Stable OpenAPI operation IDs and complete contracts.

## P1 — Before pilot

- Complete subscription activation, renewal, upgrade, downgrade, manual
  payment confirmation and cross-module entitlement enforcement.
- Complete promotion approval/reporting, branding verification/upload security
  and Media Channel delivery/reporting.
- Printer profiles, Myanmar templates and offline print-audit upload.
- PDF/CSV reports.
- Privacy request and account-closure workflow.
- Device approval and shift handover.
- Audit/security search and exports.
- Production monitoring and alert evidence.

## Decisions required

Final acceptance requires approved corporate approvers, invoice/tax fields,
refund and reissue policies, booking expiry, delay thresholds, crew offline
visibility, subscription grace period, retention and legal/dispute details.
