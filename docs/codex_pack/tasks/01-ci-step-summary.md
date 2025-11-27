---
id: ci-step-summary
title: "Add a single CI Step Summary from artifacts"
priority: P1
effort: S
depends_on: []
produces:
  - scripts/ci/emit-summary.mjs
  - .github/workflows/ci-e2e-azure-vale.yml (modified)
status_note: docs/status/2025-11-18_devserver_smoke_ci.md
backlog_refs:
  - "#79"
---

**Context**  
Your CI already emits rich JSON/CSV artifacts (smoke, monitor, screenshots, gold). This task prints a
human‑scanable Markdown summary to `$GITHUB_STEP_SUMMARY` so reviewers don’t have to download artifacts.

## Steps

1) **Add** `scripts/ci/emit-summary.mjs` (see snippet).  
2) **Call it** at the end of the Build/Test and Smoke jobs:  
   `node scripts/ci/emit-summary.mjs >> $GITHUB_STEP_SUMMARY`  
3) **Verify** the summary shows: server ready ms, tutorial status, gold percentiles, breach drill, responsive condensed coverage rows, and artifact links.

## Acceptance criteria

- CI job summary displays 5–10 key metrics with ✅/❌ and deep links to artifacts.
- Missing artifacts don’t crash the step (they render as `—`).

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- Dry-run `node scripts/ci/emit-summary.mjs --smoke docs/codex_pack/fixtures/smoke-summary.json --gold docs/codex_pack/fixtures/gold-summary.json --condensed-audit docs/codex_pack/fixtures/responsive/condensed-audit.json` (or run unit tests) so missing files render as `-` and the condensed audit rows appear when supplied

## Snippet

See `snippets/emit-summary.mjs`.

