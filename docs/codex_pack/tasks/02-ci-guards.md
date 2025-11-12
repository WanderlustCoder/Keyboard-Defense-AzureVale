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

## Snippets

- `snippets/guards.example.yml` → copy to `ci/guards.yml` and tweak.
- `snippets/validate.mjs` → copy to `scripts/ci/validate.mjs`.
