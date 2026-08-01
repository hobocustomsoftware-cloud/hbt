# Approved MVP Policy Decisions / အတည်ပြုပြီး MVP မူဝါဒများ

**Approved:** 2026-07-26  
**Scope:** HBT Passenger, HBT Business and backend APIs  
**Authority:** This file resolves the listed open questions in
`docs/product/01-mvp-scope.md`.

---

# မြန်မာဘာသာ

## ၁။ Company booking approval

- Company customer တစ်ခုစီက approver account များကို သီးခြားသတ်မှတ်ရမည်။
- Company ကခွင့်ပြုထားသော active approver သာ group booking ကို approve/reject
  လုပ်နိုင်သည်။
- Booking/request ဖန်တီးသူသည် မိမိ request ကို approve မလုပ်နိုင်။
- Approval account သည် individual human account ဖြစ်ရမည်။ Shared company login
  မသုံးရ။
- Approval၊ rejection၊ approver membership ပြောင်းလဲမှုနှင့် invoice issue/void
  တို့အားလုံး audit လုပ်ရမည်။
- Invoice ကို approved booking အတွက်သာ issue လုပ်ရမည်။
- Invoice number သည် operator တစ်ခုအတွင်း unique ဖြစ်ရမည်။ Issued invoice ကို
  ပြင်မည့်အစား void လုပ်ပြီး replacement ထုတ်ရမည်။

## ၂။ Refund၊ cancellation နှင့် reissue

- Fare rule၊ refund window၊ fee၊ percentage၊ approval threshold တို့ကို
  သက်ဆိုင်ရာကားဂိတ်/ကားကုမ္ပဏီက policy အဖြစ်သတ်မှတ်နိုင်သည်။
- Platform က confirmed payment ထက်ပို refund မလုပ်နိုင်ခြင်း၊ negative amount
  မဖြစ်ခြင်း၊ duplicate payout မဖြစ်ခြင်းနှင့် requester/approver ခွဲခြားခြင်းကို
  အမြဲအတင်းအကျပ်သတ်မှတ်ရမည်။
- Policy မရှိသေးလျှင် auto-refund မလုပ်ဘဲ manual review လိုအပ်သည်။
- Refund သည် Requested → Approved/Rejected → Paid → Completed lifecycle
  သုံးရမည်။
- Reissue လုပ်သောအခါ မူလ ticket QR ကို invalid လုပ်ပြီး ticket အသစ်က
  မူလ ticket ကို reference ပြန်ထားရမည်။
- Inspection သည် boarding မဟုတ်၍ ticket ကို consume မလုပ်ရ။

## ၃။ Subscription fairness

- Trial default ၃၀ ရက်၊ grace default ၇ ရက်ဖြစ်ပြီး commercial configuration
  ဖြင့်ပြောင်းနိုင်သည်။
- Past Due အဆင့်တွင် owner warning၊ invoice/payment access နှင့် normal
  operation ဆက်ပေးရမည်။
- Grace အတွင်း existing trip completion၊ ticket validation၊ cargo custody၊
  cash closing၊ report/export နှင့် payment reconciliation ကို မပိတ်ရ။
- Suspended အဆင့်တွင် booking/cargo အသစ်လက်ခံခြင်း၊ schedule အသစ်ထုတ်ခြင်း၊
  add-on အသုံးပြုခြင်းနှင့် configuration write ကိုပိတ်နိုင်သည်။
- Existing passenger ticket validation၊ active-trip safety operation၊ cargo
  handover၊ data export၊ invoice payment နှင့် account recovery ကိုမပိတ်ရ။
- Data ကို subscription ကြောင့် ချက်ချင်းမဖျက်ရ။
- Security၊ audit၊ tenant isolation နှင့် integrity control ကို plan အလိုက်
  မလျှော့ရ။

## ၄။ Device နှင့် shift

- Device အသစ်သည် owner/manager approval ရမှ Business offline operation
  လုပ်နိုင်မည်။
- Shared phone သုံးနိုင်သော်လည်း individual login/unlock မဖြစ်မနေလိုသည်။
- Shift ကို counter၊ staff၊ device၊ opening cash နှင့်ချိတ်ရမည်။
- Close မလုပ်မီ cash handover/reconciliation လုပ်ရမည်။
- Device ပျောက်/ခိုးခံရလျှင် revoke ပြုလုပ်ရာတွင် push token၊ authorization
  snapshot နှင့် offline write authority ကိုပိတ်ရမည်။
- MVP တွင် break-glass access မထည့်သေး။ နောက်ပိုင်းတွင် reason၊ time limit၊
  approval နှင့် enhanced audit ပါမှထည့်ရမည်။

## ၅။ Provider-neutral payment

- Booking၊ ticket၊ cargo၊ invoice နှင့် refund တို့သည် provider-specific status
  မသုံးရ။ HBT canonical payment lifecycle သာသုံးရမည်။
- Provider တစ်ခုချင်းစီကို adapter/connector အဖြစ်ချိတ်ရမည်။
- Connector failure ဖြစ်လျှင် booking/cargo data မပျက်ရ၊ duplicate charge
  မဖြစ်ရ၊ pending state နှင့် manual reconciliation ဆက်လုပ်နိုင်ရမည်။
- Manual cash/static QR verification fallback ကို ဆက်ထားရမည်။
- Sandbox/production credential မရောရ။
- Secret ကို encrypted storage/vault တွင်သိမ်းပြီး API/log တွင်မပြရ။
- Signed webhook၊ amount၊ currency၊ merchant၊ provider reference၊ timestamp
  နှင့် idempotency စစ်ပြီးမှ state ပြောင်းရမည်။
- Unknown/late/duplicate webhook ကို audit quarantine ထားပြီး business record
  ကို မထင်ရာပြောင်းရ။
- Provider outage မှာ retry/backoff/circuit breaker သုံးပြီး staff pending-work
  queue ပြရမည်။

---

# English

## 6. Public website, subscriptions and media

- The HBT main website is booking-first and is the responsive web surface of
  HBT Passenger.
- Public booking and basic operator branding are included in Starter, Growth,
  Pro and Enterprise.
- Subscription comparison is presented under the HBT Business section, not in
  the passenger checkout journey.
- Starter does not include Media Channel publishing. Growth, Pro and
  Enterprise include controlled image and video publishing with server-side
  limits.
- External advertisers use verified advertiser accounts and campaign-based
  advertising payment; they do not require a bus-operator subscription.
- Sponsored content requires separate payment confirmation and platform
  editorial approval.
- Promotions and coupons are calculated and locked by the Fare Quote service.

Detailed authority: `docs/product/08-public-web-subscription-promotion-media.md`.

## 7. Myanmar NRC

- NRC entry uses state/region, valid state-scoped township code, citizenship
  type and six-digit serial components.
- Myanmar and English displays are supported from one canonical identity.
- Clients should use cascading selectors to reduce typing and invalid pairs.
- Full NRC values are sensitive PII and must not be exposed in ordinary API
  responses.
- Reference data is versioned and distinguishes community-derived from
  HBT-reviewed records.
- Detailed implementation authority is
  `docs/implementation/11-myanmar-nrc-reference-and-privacy.md`.

## 1. Corporate approval

Only an active individual account explicitly designated by the corporate
customer may approve or reject its group booking. The requester may not approve
their own request. Approval membership, decisions and invoice issue/void events
must be audited. An invoice may be issued only for an approved booking and an
issued invoice is replaced through void-and-reissue rather than mutation.

## 2. Refund and reissue

Each transport operator may configure refund windows, fees, percentages and
approval thresholds. The platform always enforces non-negative values, a
confirmed-payment ceiling, duplicate-payout prevention and separation of
requester and approver. Without an approved operator policy, refund is manual
review only. Reissue invalidates the original QR and links the replacement.
Inspection never consumes a ticket as boarding.

## 3. Fair subscription enforcement

Recommended defaults are a 30-day trial and seven-day grace period. Past-due
and grace states retain normal operation and prominent warnings. Suspension may
block new bookings, new cargo, new schedules, add-ons and configuration writes,
but never active-trip safety actions, existing ticket validation, cargo
handover, reconciliation, invoice payment, recovery or lawful data export.
Subscription state never weakens security, audit or tenant isolation and never
causes immediate data deletion.

## 4. Devices and shifts

An owner or manager must approve a new device before Business offline writes.
A physical phone may be shared but every session uses an individual identity.
Shifts bind counter, staff, device and opening cash and require handover and
reconciliation before closure. Device revocation disables push, cached
authorization and offline-write authority. Break-glass access is deferred.

## 5. Provider-neutral payments

Business modules use only the canonical HBT payment lifecycle. Every provider
is an adapter. Provider failure must not lose bookings or cargo, create
duplicate charges or prevent manual reconciliation. Secrets are encrypted,
sandbox and production are isolated, and state changes require verified
signatures, amount, currency, merchant, reference, timestamp and idempotency.
Unknown, late or duplicate webhooks are quarantined and audited. Provider
outages use bounded retry, backoff, circuit breaking and staff pending work.
