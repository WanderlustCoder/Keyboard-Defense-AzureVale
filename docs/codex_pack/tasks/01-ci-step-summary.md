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
3) **Verify** the summary shows: server ready ms, tutorial status, gold percentiles, breach drill, links to artifacts.

## Acceptance criteria

- CI job summary displays 5–10 key metrics with ✅/❌ and deep links to artifacts.
- Missing artifacts don’t crash the step (they render as `—`).

## Snippet

See `snippets/emit-summary.mjs`.
