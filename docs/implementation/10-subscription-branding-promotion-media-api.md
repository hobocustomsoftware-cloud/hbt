# Subscription, Branding, Promotion and Media API

**Implemented:** 2026-07-26  
**Base path:** `/api/v1/`

## Public website contracts

| Method | Path | Purpose |
|---|---|---|
| GET | `public/subscription-plans/` | Starter/Growth/Pro/Enterprise prices, tax, totals, entitlements and limits |
| GET | `public/operators/` | Published operator branding |
| GET | `public/operators/{public_slug}/` | Public operator profile |
| GET | `public/media/` | Approved in-window media by optional placement |

The public subscription response is the source for `/business/pricing`. Web and
mobile clients MUST NOT duplicate commercial price calculations.

## Organization contracts

| Method | Path | Permission |
|---|---|---|
| GET | `organizations/{org}/subscription/` | `subscription.view` |
| GET | `organizations/{org}/subscription/invoices/` | `subscription.view` |
| GET/PUT/PATCH | `organizations/{org}/branding/` | `branding.view` / `branding.manage` |
| GET/POST | `organizations/{org}/promotions/` | `promotion.view` / `promotion.manage` |
| GET/PUT/PATCH | `organizations/{org}/promotions/{promotion}/` | `promotion.view` / `promotion.manage` |
| GET/POST | `organizations/{org}/media-campaigns/` | `media.view` / `media.manage` |
| POST | `organizations/{org}/media-campaigns/{campaign}/creatives/` | `media.manage` |
| POST | `organizations/{org}/media-campaigns/{campaign}/submit/` | `media.manage` plus plan entitlement |

Fare quote creation accepts optional `coupon_code`. Eligibility and amounts are
calculated by the backend and returned in the quote snapshot.

## Advertiser contracts

| Method | Path | Rule |
|---|---|---|
| POST | `advertiser/register/` | Individual authenticated user |
| GET/PATCH | `advertiser/me/` | Account owner only |
| GET/POST | `advertiser/campaigns/` | Account owner |
| POST | `advertiser/campaigns/{campaign}/creatives/` | Campaign owner |
| POST | `advertiser/campaigns/{campaign}/submit/` | Verified advertiser |

## Platform contracts

| Method | Path | Rule |
|---|---|---|
| POST | `platform/advertisers/{advertiser}/review/` | Active Platform Super Admin grant |
| POST | `platform/media-campaigns/{campaign}/confirm-payment/` | Active Platform Super Admin grant |
| POST | `platform/media-campaigns/{campaign}/review/` | Active Platform Super Admin grant |

Tenant roles never satisfy platform review authority.

## Security and release notes

- Tenant querysets filter by organization.
- Sponsored payment confirmation and editorial approval are separate.
- Public feed returns only approved/active, currently valid content.
- File extension, declared MIME type and upload size are checked.
- Coupons are consumed on quote lock under a database transaction.
- Quote snapshots preserve applied promotion terms.
- Malware scanning, binary signature inspection, verified video transcoding,
  engagement anti-fraud and the complete subscription write lifecycle remain
  production closure items.

## Client implementation order

1. Use public plans on `/business/pricing`.
2. Build operator listing and detail pages.
3. Use canonical trip search and booking APIs already owned by Booking.
4. Add promotion display and coupon entry to Fare Quote.
5. Build Media feed with advertising labels and low-data poster behavior.
6. Build Business plan usage, branding and campaign screens.

