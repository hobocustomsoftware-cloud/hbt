# Public Web, Subscription, Promotion and Media Policy

**Status:** Approved product decision  
**Reviewed:** 2026-07-26  
**Scope:** Myanmar-first HBT MVP and pilot

## 1. Product surfaces

HBT MUST provide:

- HBT Passenger through a responsive booking website and a passenger mobile
  application.
- HBT Business through a phone-first business application and an authorized
  business web portal where appropriate.
- HBT Platform Administration through a separately authenticated platform
  administration surface.

The responsive booking website is the web surface of HBT Passenger. It is not
a separate business product and MUST use the same canonical booking, fare,
promotion, payment and ticket APIs as the passenger mobile application.

## 2. Main website information architecture

The HBT main website MUST be booking-first. The primary home-page action is
trip search. Passenger booking MUST NOT be obscured by subscription sales or
advertising.

Recommended public routes:

- `/` — booking-first home
- `/book` and `/trips` — discovery and booking
- `/operators` and `/operators/{public-slug}` — verified operator pages
- `/promotions` — eligible passenger promotions
- `/media` — approved operator, sponsored and HBT media
- `/business` — HBT Business product information
- `/business/pricing` — public plan comparison
- `/help`, `/privacy`, `/terms` and `/contact`

The booking journey MUST NOT show SaaS subscription pricing. The main home page
MAY show a compact HBT Business call-to-action below passenger content.

## 3. Public operator presence

Every eligible operator, including Starter, MUST be able to have a public
booking presence and basic branding. The public profile MAY contain:

- Myanmar and English display names
- logo and cover image
- verified-operator state
- public contact details
- public description and social links
- routes, schedules, starting fares and promotions

Logo and cover uploads MUST be type- and size-validated, tenant-isolated and
audited. Verification state is platform-controlled, not tenant-controlled.

## 4. Subscription catalogue

The approved plan catalogue is:

1. Starter
2. Growth
3. Pro
4. Enterprise

Public booking and basic operator branding MUST remain available in all plans.
Starter does not include Media Channel publishing. Growth, Pro and Enterprise
include Media Channel with increasing limits.

Pricing MUST be returned from a server-managed plan catalogue rather than
hard-coded independently in web and mobile clients. The price response MUST
distinguish subtotal, tax and total. Enterprise MAY use contact-sales pricing.

Subscription suspension MUST NOT block active-trip safety, existing ticket
validation, cargo handover, reconciliation, invoice payment, recovery or
lawful data export.

## 5. Promotions and coupons

Fare discounts MUST be calculated by the backend inside the canonical Fare
Quote. A client-provided calculated discount MUST NOT be trusted.

Supported initial rules include:

- percentage discount
- fixed-amount discount
- minimum passenger count
- a limited number of discounted passenger fares
- buy-X-get-Y behavior
- route, schedule and booking-channel eligibility
- coupon validity window
- total and per-account redemption limits
- maximum discount

A promotion snapshot MUST be preserved in the quote. Redemption occurs when
the quote is locked, not merely displayed. Quote locking MUST serialize usage
checks to prevent oversubscription. Promotion creation, exceptional override
and redemption MUST be auditable.

Corporate negotiated pricing is a commercial fare agreement or approved fare
override, not a public coupon.

## 6. Media Channel and advertising

Media Channel contains three distinct content types:

- Operator Media — operator announcements and promotions
- Sponsored Media — paid advertising by operators or verified advertisers
- Platform Media — HBT announcements

An external advertiser does not require a bus-operator SaaS subscription. The
advertiser requires an individual login, advertiser account verification,
campaign review and payment verification for sponsored placement.

Sponsored content MUST be labelled as advertising. It MUST NOT appear on
payment confirmation, ticket QR, boarding validation, inspection or urgent
operational screens.

MVP sponsored billing is manual:

`Draft → Submitted → Payment Confirmed → Approved → Scheduled/Active → Completed`

Campaign payment confirmation and editorial approval are separate actions.
Uploaded content MUST NOT become public before approval.

## 7. Video limits

Video limits are plan entitlements and MUST be server-controlled:

| Plan | Active campaigns | Monthly videos | Maximum duration | Upload ceiling |
|---|---:|---:|---:|---:|
| Starter | 0 | 0 | Not available | Not available |
| Growth | 2 | 5 | 15 seconds | 100 MB |
| Pro | 5 | 20 | 30 seconds | 200 MB |
| Enterprise | Contract limit | Contract limit | 60 seconds default | 500 MB default |

Only approved formats are accepted. Production delivery SHOULD use a
provider-neutral video adapter supporting signed direct/resumable upload,
transcoding, poster generation, adaptive delivery and delivery receipts.
Clients MUST avoid automatic high-bandwidth playback on constrained networks.

## 8. Authorization and audit

- Owner and Company Administrator MAY manage branding.
- Owner, Company Administrator and delegated Operations Manager MAY manage
  promotions and operator media.
- Platform media reviewers MUST use separately granted platform authority.
- Advertisers MAY manage only their own advertiser account and campaigns.
- Tenant membership MUST never grant platform review authority.
- Branding, promotion, media submission, payment confirmation, approval,
  rejection and plan changes MUST be audited.

## 9. API ownership

- Subscription owns plan catalogue, tenant commercial state, entitlement and
  subscription invoices.
- Branding owns public operator presentation assets.
- Fare owns promotion eligibility, coupon redemption and quote calculation.
- Media Channel owns advertiser accounts, campaigns, creative assets, review,
  delivery state and engagement counts.
- Booking remains the owner of passenger booking state.
- Payment remains the owner of canonical payment records; Media Channel may
  reference verified advertising payment without inventing provider-specific
  payment states.

## 10. Deferred closure

The following remain required before production:

- video provider adapter and verified transcoder metadata
- malware scanning for every uploaded creative
- campaign impression/click idempotency and abuse controls
- subscription activation, renewal, upgrade, downgrade and manual payment APIs
- privacy retention and advertiser terms
- public website and Flutter user interfaces
- full OpenAPI contracts and production monitoring

