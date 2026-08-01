# Authorized Security Testing Runbook

Only test systems for which HBT has written authorization. Production denial of
service, destructive payloads, real-user credential attacks and data extraction
are prohibited.

## Automated gates

- Bandit and Semgrep: source-level unsafe patterns.
- pip-audit: known dependency CVEs.
- OpenAPI fuzzing: Schemathesis against a disposable staging database.
- DAST: OWASP ZAP baseline first; active scan only in isolated staging.
- Upload tests: EICAR test file and crafted image/video/document samples through
  the scanner-enabled staging upload endpoints.
- TLS and headers: SSL Labs or testssl.sh plus the expected ingress headers.

## Required attack cases

Test SQL injection in path, query, JSON and ordering/filter inputs; stored and
reflected XSS in bilingual text; IDOR across tenants; role escalation; JWT
reuse/rotation; CSRF on session-backed admin; malicious file names, MIME spoof,
double extensions, archive bombs and DOCX macro/polyglot samples; webhook
forgery/replay; race conditions for seats, coupons, refunds and invoices; mass
assignment; rate-limit bypass; sensitive-data leakage; SSRF and command/path
injection.

Every finding needs an ID, endpoint, role, tenant, reproducible steps, evidence,
impact, severity, owner, fix, retest and residual risk. Independent penetration
testing is required before public launch and after material authentication,
payment or tenancy changes.

Run `scripts/fuzz-authorized-staging.ps1` only after setting an HTTPS staging
URL, an exact confirmation value and a written-authorization reference. The
script excludes DELETE, bounds request rate/examples/timeouts and produces
JUnit/HAR evidence. Use a dedicated tenant and disposable data because POST and
PATCH requests may still mutate staging state.

Run `scripts/dast-authorized-staging.ps1` for ZAP testing. It requires
`HBT_DAST_BASE_URL`, `HBT_SECURITY_AUTHORIZATION_ID` and the exact
`HBT_DAST_CONFIRM=I_CONFIRM_AUTHORIZED_DISPOSABLE_STAGING`. `baseline` is the
default passive mode. `api-active` and `full-active` perform real attacks and
also require
`HBT_DAST_ACTIVE_CONFIRM=I_CONFIRM_ACTIVE_ATTACKS_AND_DATA_RESET`. API mode
requires `HBT_DAST_OPENAPI_URL` on the same host. Declare comma-separated
production hostnames in `HBT_PRODUCTION_HOSTS`; the runner refuses those
targets. Reports and authorization metadata are written under
`security/evidence/`. A ZAP exit code of 2 means warnings need triage, not that
the system passed. Never run active mode against production or retained data.

Run `scripts/tls-headers-authorized-staging.ps1` with an authorized HTTPS
staging URL. It executes testssl.sh 3.2.3 and records machine-readable TLS,
HTML, response-header and authorization evidence. The gate requires HSTS, CSP,
nosniff, Referrer-Policy, Permissions-Policy and a CSP/X-Frame-Options frame
defence. This automated configuration gate does not replace DAST or independent
penetration testing.

Run `scripts/upload-malware-authorized-staging.ps1` only against the disposable
staging tenant. It creates the harmless 68-byte EICAR test fixture, posts it to
the private payment-upload endpoint and passes only when the API returns a
scanner-specific rejection. A generic file-type rejection is not a pass. The
runner deletes its local fixture and retains authorization/response evidence.

## မြန်မာဘာသာ အကျဉ်း

စာဖြင့်ခွင့်ပြုထားသော staging စနစ်ကိုသာတိုက်ခိုက်စမ်းသပ်ရမည်။ Production ကို
DoS လုပ်ခြင်း၊ ဒေတာဖျက်ခြင်း၊ အသုံးပြုသူအစစ်၏အကောင့်ကို စမ်းခြင်းမပြုရ။
SQL injection, XSS, tenant ကျော် IDOR, permission တိုးယူခြင်း, JWT, upload
malware/DOCX, webhook replay, seat/payment race condition နှင့် data leakage
အားလုံးကို test ID နှင့် evidence ဖြင့်မှတ်တမ်းတင်ရမည်။ Public launch မတိုင်မီ
ပြင်ပလွတ်လပ်သော penetration tester ဖြင့် ထပ်မံစစ်ဆေးရမည်။

ZAP စစ်ဆေးမှုအတွက် `scripts/dast-authorized-staging.ps1` ကိုသုံးပါ။ ပုံမှန်
`baseline` သည် passive စစ်ဆေးမှုသာဖြစ်သည်။ `api-active` နှင့် `full-active`
တို့သည် တကယ့်တိုက်ခိုက်မှုများလုပ်သဖြင့် သီးသန့် active confirmation၊ စာဖြင့်
ခွင့်ပြုချက်နှင့် ပြန်ဖျက်နိုင်သော staging data ရှိမှသာ run ရမည်။ Production
hostname များကို `HBT_PRODUCTION_HOSTS` တွင်ထည့်ထားရမည်။ ထွက်လာသည့် warning
တိုင်းကို စစ်ဆေးဆုံးဖြတ်ရမည်ဖြစ်ပြီး warning ရှိနေခြင်းကို pass ဟုမယူရ။

`scripts/tls-headers-authorized-staging.ps1` သည် TLS protocol/cipher နှင့်
security header များကို စစ်ပေးသည်။ HSTS, CSP, nosniff, Referrer-Policy,
Permissions-Policy နှင့် clickjacking ကာကွယ်မှု မပြည့်လျှင် gate ကျမည်။
ဤ automated check တစ်ခုတည်းဖြင့် penetration test အစားထိုး၍မရပါ။

`scripts/upload-malware-authorized-staging.ps1` သည် virus အစစ်မဟုတ်သော EICAR
test file ကို staging upload endpoint သို့ပို့ပြီး malware scanner က
တိတိကျကျပယ်ချမှသာ pass သတ်မှတ်သည်။ File type မမှန်ဟုသာပယ်ချခြင်းကို pass
မသတ်မှတ်ပါ။ Production တွင် မစမ်းရပါ။
