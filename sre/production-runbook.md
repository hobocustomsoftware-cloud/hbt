# HBT Production Runbook / HBT Production လည်ပတ်မှုလမ်းညွှန်

## Release gate / Release မတင်မီ

`scripts/release-gates.ps1` must pass against a disposable PostgreSQL database.
Production secrets must come from the deployment secret store and must never be
committed. A failed schema, migration, test, SAST, dependency or Django deploy
check blocks release.

`scripts/release-gates.ps1` ကို သီးခြား PostgreSQL test database ဖြင့်
အောင်မြင်မှ release တင်ရမည်။ Production secret များကို secret store မှသာ
ထည့်ရမည်။ Schema, migration, test, security scan တစ်ခုခုပျက်လျှင် release
ရပ်ရမည်။

## Service objectives / ဝန်ဆောင်မှုရည်မှန်းချက်

| Signal | Initial target | Page when |
|---|---:|---:|
| API availability | 99.9% monthly | 5-minute success rate < 99% |
| API latency | p95 < 800 ms | p95 > 1.5 s for 10 minutes |
| Server errors | < 1% | 5xx > 2% for 5 minutes |
| Push queue age | < 2 minutes | oldest queued item > 10 minutes |
| Offline sync conflicts | business baseline | > 3x 7-day baseline |
| Database storage | < 75% | > 80% |
| Backup age | < 24 hours | no verified backup for 26 hours |

## Health and alert routing / Health နှင့် alert

- `/health/live/` checks process liveness only.
- `/health/ready/` checks whether the database is ready to serve traffic.
- Alerts route to on-call operations; security alerts also route to the
  security owner. Do not put NRC, wallet references, credentials or push tokens
  in alerts or logs.
- `/health/live/` သည် process အသက်ရှင်မှု၊ `/health/ready/` သည် database
  အသင့်ဖြစ်မှုကို စစ်သည်။ NRC နှင့် secret အချက်အလက်ကို log/alert မထည့်ရ။

## Incident sequence / Incident ဖြစ်လျှင်

1. Declare severity and incident commander.
2. Preserve logs and audit evidence; never edit audit records.
3. Stop the harmful path with a feature flag, connector disable or ingress
   rule. Keep unaffected booking/cargo operations running.
4. Communicate impact and workarounds in Myanmar and English.
5. Recover, validate data invariants, then reopen gradually.
6. Complete a blameless review with detection, timeline, root cause and actions.

## Backup and recovery / Backup နှင့် ပြန်လည်ရယူခြင်း

- Run `scripts/backup-postgres.sh` daily and before migrations.
- Encrypt backup storage, keep copies in a separate failure domain and apply
  retention policy.
- Perform a restore drill at least monthly using
  `scripts/restore-postgres.sh` against a disposable environment.
- Initial objectives: RPO 24 hours, RTO 4 hours. Tighten after observed usage.
- Restore အစမ်းကို လစဉ်လုပ်ပြီး row counts, booking-seat uniqueness, payment
  totals, ticket state နှင့် audit continuity ကိုစစ်ရမည်။

## Rollback

Application rollback uses the previously signed image. Database migrations must
be backward-compatible; destructive schema removal requires a later release
after old code is gone. Never use an unverified database dump for rollback.
