# HBT Remediation — Working Rules

**Mandated by project owner on 2026-08-01.** These rules govern all remediation
milestone work and are non-negotiable.

1. **Never introduce breaking changes unless absolutely required.**
2. **Keep the application runnable after every milestone.**
3. **Commit each milestone separately.**
4. **Write migration notes before changing architecture.**
5. **Update documentation after every milestone.**
6. **Add tests for every critical fix before moving to the next milestone.**
7. **If a prerequisite is missing, implement the prerequisite first.**
8. **Never refactor code only for style while critical production issues remain.**
9. **After each milestone, run all tests and verify that no existing functionality is broken.**

## How this maps to the roadmap

- **Milestone definition:** each row-group in `merged_audit_findings_roadmap.md`
  (M0, M1, M2, M3, M4, M5) is one commit unit.
- **Exit criteria:** the milestone's stated exit criteria + full test suite green
  (backend 118, business 57, passenger 9) + `flutter analyze` clean on both apps.
- **Migration notes:** for any architecture change (e.g., M4 repository layer,
  shared package extraction), write the design/migration note to
  `docs/remediation/migration-notes/` BEFORE touching code, commit it as its own
  commit, then implement.
- **Sequencing:** M4 requires its design note first (rule 4); F-20 repository
  layer is a prerequisite for F-13 passenger offline (rule 7).
