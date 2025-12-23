---
id: ci-guards
title: "Unify CI guards behind a single config"
priority: P1
effort: S
depends_on: [ci-step-summary]
produces:
  - ci/guards.yml
  - scripts/ci/validate.mjs
  - .github/workflows/ci-e2e-azure-vale.yml (modified)
status_note: docs/status/2025-11-14_gold_summary_ci_guard.md
backlog_refs:
  - "#82"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
You already validate economy percentiles. Generalize this into a declarative guard file that enforces
thresholds for smoke/monitor/gold/breach/screenshots.

## Steps

1) **Add** `ci/guards.yml` (start with the example).  
2) **Add** `scripts/ci/validate.mjs` to evaluate the rules.  
3) **Wire** a workflow step that runs it after artifacts are produced.

## Acceptance criteria

- Guard violations **fail** the job on `main`, **warn** on PRs (optional).
- Clear list of failing rules in CI logs.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- node scripts/ci/validate.mjs --dry-run (once implemented) to confirm guards evaluate without throwing

## Snippets

- `snippets/guards.example.yml` → copy to `ci/guards.yml` and tweak.
- `snippets/validate.mjs` → copy to `scripts/ci/validate.mjs`.
## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- node scripts/ci/validate.mjs --dry-run (once implemented) to ensure guard failures report correctly







