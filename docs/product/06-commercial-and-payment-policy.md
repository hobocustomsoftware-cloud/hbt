# HBT Commercial, Subscription and Payment Connector Policy

**Status:** Recommended product decision pending final commercial, accounting
and legal approval  
**Languages:** Myanmar and English  
**Currency:** MMK

---

# မြန်မာဘာသာ

## ၁။ စီးပွားရေးမူဝါဒ

HBT သည် transaction fee မယူသော multi-tenant SaaS platform ဖြစ်ရမည်။
ဝင်ငွေကို လစဉ်/နှစ်စဉ် subscription၊ add-on module၊ integration၊ onboarding
နှင့် premium support တို့မှရယူမည်။ Payment provider က ကောက်ခံသော fee ရှိပါက
HBT transaction fee အဖြစ်မဖော်ပြဘဲ third-party provider fee အဖြစ် သီးခြားပြရမည်။

## ၂။ Subscription plans

| Plan | လစဉ်အခြေခံကြေး | ဥပမာ ၅% ထည့်ပြီး | အဓိကကန့်သတ်ချက် |
|---|---:|---:|---|
| Starter | 75,000 | 78,750 | Branch ၁၊ Counter ၁၊ Staff ၅၊ Vehicle ၅ |
| Growth | 150,000 | 157,500 | Branch ၃၊ Counter ၅၊ Staff ၂၀၊ Vehicle ၂၀ |
| Pro | 300,000 | 315,000 | Branch ၁၀၊ Counter ၂၅၊ Staff ၇၅၊ Vehicle ၁၀၀ |
| Enterprise | Custom | သက်ဆိုင်ရာအခွန် | Custom limits နှင့် SLA |

၅% သည် pricing illustration သာဖြစ်သည်။ Invoice ထုတ်သည့်အချိန်တွင် HBT ၏
အခွန်မှတ်ပုံတင်အခြေအနေ၊ သက်ဆိုင်ရာနှစ်၏ Union Taxation Law နှင့် tax adviser
အတည်ပြုချက်အတိုင်းသာ ကောက်ခံရမည်။

Annual subscription ကို ၁၀ လစာနှုန်းဖြင့် ၁၂ လအသုံးပြုနိုင်သော default offer
အဖြစ်ထားနိုင်သည်။ Discount ကို invoice snapshot ထဲသိမ်းရမည်။

## ၃။ Plan အလိုက် မပိတ်ရမည့်အရာများ

အောက်ပါအချက်များကို plan ဈေးနှုန်းကြောင့် မပိတ်ရ—

- Authentication နှင့် individual accounts
- Tenant isolation
- Audit log
- Security controls
- Offline recovery နှင့် idempotency
- Ticket integrity
- Payment-state integrity
- Cargo custody integrity
- Required backups နှင့် incident evidence

## ၄။ Add-ons

- Additional branch/counter packs
- Additional active staff packs
- Extra storage
- Advanced report/export
- Custom print template
- Branded booking website/widget
- Payment provider connector
- Accounting integration
- Data migration/onboarding
- Premium support/training
- Future Cargo Pro၊ pickup/delivery၊ GPS/fleet tracking

Shared account အသုံးပြုရန်အားပေးမည့် per-user pricing မလုပ်ရ။ Active-user pack၊
branch နှင့် counter capacity ပေါ်မူတည်၍ တန်ဖိုးနှင့်ကုန်ကျစရိတ်ညီမျှစေရမည်။

## ၅။ Payment connector

Payment domain သည် provider-neutral ဖြစ်ရမည်။ Manual Cash၊ Static QR၊ MMQR၊
KBZPay၊ AYA Pay၊ Bank နှင့် aggregator တို့သည် တူညီသော HBT payment lifecycle
ကိုအသုံးပြုရမည်။

Connector setup တွင် အောက်ပါအချက်များပါနိုင်သည်—

- Environment: sandbox/production
- Merchant ID နှင့် service code
- Public/API key
- Encrypted secret/webhook secret
- Certificate or signing configuration
- Callback/webhook configuration
- Allowed branch/counter scope
- Test connection result
- Activation၊ rotation၊ revocation history

Credential ဖြည့်ရုံဖြင့် provider onboarding၊ KYC၊ contract၊ whitelist သို့မဟုတ်
production approval ကိုကျော်လွှား၍မရ။ Test connection နှင့် signed webhook test
အောင်မြင်မှ connector ကို active လုပ်ရမည်။

Secret များကို API response တွင် ပြန်မပေးရ၊ log/audit metadata ထဲ မထည့်ရ၊
encrypted storage သို့မဟုတ် secrets vault တွင်သိမ်းရမည်။ Webhook signature၊
amount၊ currency၊ merchant၊ provider reference နှင့် idempotency ကို စစ်ပြီးမှ
payment state ပြောင်းရမည်။

---

# English

## 1. Commercial model

HBT SHALL operate as a multi-tenant SaaS platform without charging an HBT
transaction commission. Revenue shall come from monthly or annual
subscriptions, add-on modules, integrations, onboarding and premium support.
Any fee charged by a payment provider must be identified separately as a
third-party provider fee.

## 2. Subscription plans

| Plan | Monthly base | Example including 5% | Principal limit |
|---|---:|---:|---|
| Starter | 75,000 | 78,750 | 1 branch, 1 counter, 5 staff, 5 vehicles |
| Growth | 150,000 | 157,500 | 3 branches, 5 counters, 20 staff, 20 vehicles |
| Pro | 300,000 | 315,000 | 10 branches, 25 counters, 75 staff, 100 vehicles |
| Enterprise | Custom | Applicable tax | Custom limits and SLA |

The 5% figure is a pricing illustration only. Tax may be charged only after
confirming HBT's registration status, the applicable annual tax law and advice
from a qualified tax professional.

The recommended annual offer provides twelve months for the price of ten.
Every discount and tax calculation must be preserved in the invoice snapshot.

## 3. Controls that must never be paywalled

Authentication, tenant isolation, auditability, security, offline recovery,
idempotency, ticket integrity, payment-state integrity, cargo custody integrity
and required operational evidence MUST NOT be weakened by subscription tier.

## 4. Add-ons

Add-ons may include extra branches, counters, active-user packs, storage,
advanced reports, custom print templates, a branded booking channel, payment or
accounting connectors, migration, training, premium support and future
transport modules. Pricing must not encourage shared human credentials.

## 5. Payment connector

All provider connectors shall implement the same provider-neutral HBT payment
lifecycle. Connector configuration may include environment, merchant ID,
service code, public key, encrypted secret, webhook secret, certificates,
scope, test status and credential lifecycle history.

Provider onboarding, KYC, contracts, whitelisting and production approval
remain mandatory where required. Credentials alone do not guarantee activation.
HBT shall activate a connector only after connection and signed-webhook tests
succeed.

Secrets must never be returned by the API or written to application logs.
Payment state may change only after validating signature, amount, currency,
merchant, provider reference and idempotency.

