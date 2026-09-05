# HoBo Transport Incident Response Runbook

## Severity

- **SEV-1**: confirmed cross-tenant compromise, destructive access, ransomware/extortion, material payment/data exposure or active account takeover with production impact.
- **SEV-2**: credible privileged-account compromise, repeated authorization bypass attempts, suspicious bulk extraction or significant operational abuse without confirmed material impact.
- **SEV-3**: isolated suspicious authentication/access behavior with no evidence of material compromise.

## 1. Detect and declare

Capture: first-seen time, last-seen time, affected organization/account, suspected resource, request/correlation IDs, relevant audit/security events, deployment/configuration changes and customer impact hypothesis.

Do not edit or delete original evidence while investigating.

## 2. Contain

Use the least disruptive effective control first:

- revoke affected refresh tokens/sessions;
- invalidate compromised credentials/API keys where applicable;
- increase or apply rate restrictions to abusive actors;
- disable affected account access;
- isolate an affected tenant only when the evidence and blast radius justify it;
- pause risky administrative operations if necessary.

Do not retaliate against external infrastructure or attackers.

## 3. Preserve evidence

Preserve audit/security logs, application logs, relevant request IDs, deployment records, authentication events, database timestamps and infrastructure alerts. Keep timestamps in a consistent timezone and record who collected each evidence item.

Never copy passwords, raw JWTs, payment secrets or unnecessary PII into tickets or chat.

## 4. Assess scope

Answer:

1. Which account(s) were controlled?
2. Which organization(s) were reachable?
3. Which permissions/scopes were active?
4. Which resources were read or mutated?
5. Was data exported?
6. Was data altered/deleted?
7. Were offline operations replayed?
8. Did the incident cross a tenant boundary?
9. Which customers and records may be affected?

Correlate by actor, organization, permission, request ID, resource and time.

## 5. Eradicate and recover

- remove malicious/unauthorized access;
- rotate compromised credentials/secrets;
- deploy the verified fix;
- verify migrations and application integrity;
- restore from a known-good backup when required;
- run database/application integrity checks;
- confirm authorization and tenant-isolation regression tests;
- monitor closely after recovery.

## 6. Customer notification and escalation

For confirmed customer impact, identify affected tenants/data first, then follow applicable contractual, legal and regulatory notification requirements. Communications must distinguish confirmed facts from hypotheses and must not disclose sensitive evidence unnecessarily.

## 7. Closure

Record root cause, attack path, affected assets, controls that worked/failed, timeline, evidence locations, remediation commits, customer impact, recovery validation and follow-up actions. Add a regression test for every preventable application-level failure.

## Recovery validation checklist

- [ ] Sessions/tokens/credentials contained
- [ ] Compromised access removed
- [ ] Known-good backup identified
- [ ] Restore completed where required
- [ ] Integrity checks passed
- [ ] Tenant/RBAC tests passed
- [ ] Offline-sync tests passed
- [ ] Security scans passed
- [ ] Monitoring active
- [ ] Customer impact assessed
- [ ] Incident record completed
