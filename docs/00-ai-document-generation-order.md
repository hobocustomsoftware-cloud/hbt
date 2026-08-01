# HBT AI Document Generation Order

This file defines the recommended order for turning the repository's AI prompts into approved, implementation-ready documents.

## Phase 1 — Product decisions

1. `docs/product/01-mvp-scope.md`
2. `docs/product/02-users-and-use-cases.md`
3. `docs/business/13-domain-invariants.md`
4. `docs/product/03-functional-requirements.md`
5. `docs/product/04-non-functional-requirements.md`

Do not begin detailed implementation design until MVP scope and major open questions are approved.

## Phase 2 — Executable contracts

1. `docs/security/21-access-control-matrix.md`
2. Existing module specifications under `docs/modules/`
3. Existing workflow specifications under `docs/workflows/`
4. `docs/api/21-endpoint-catalog.md`
5. `docs/product/05-release-acceptance.md`

Resolve cross-document contradictions and maintain stable requirement and rule IDs.

## Phase 3 — Engineering plan

1. `docs/implementation/01-implementation-blueprint.md`
2. `docs/implementation/02-project-bootstrap.md`
3. `docs/implementation/04-test-data-and-seeding.md`
4. `docs/implementation/03-delivery-backlog.md`

## Phase 4 — Coding entry gate

Coding may begin when:

- MVP scope is approved.
- Blocking product questions have owners and decisions.
- The first vertical slice has testable acceptance criteria.
- Domain invariants and permissions for that slice are defined.
- API operations and data ownership for that slice are defined.
- Technology versions and repository structure are approved.
- Local bootstrap and CI validation are reproducible.
- Test data exists for the slice.

## AI generation rules

- Read upstream approved documents before generating a downstream document.
- Replace prompt instructions with the resulting document; do not append an answer below an unresolved prompt.
- Never present assumptions as confirmed facts.
- Use stable IDs and traceability links.
- Report contradictions instead of silently choosing one side.
- Keep country-specific law, payment providers, pricing, and organizational policies as explicit decision inputs.
- Require human approval for product, security, financial, legal, and architecture decisions.
- Regenerate dependent documents after an approved upstream decision changes.
