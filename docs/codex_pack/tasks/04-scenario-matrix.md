---
id: scenario-matrix
title: "Nightly deterministic scenario matrix"
priority: P2
effort: M
depends_on: [ci-step-summary, ci-guards]
produces:
  - scripts/ci/run-matrix.mjs
  - artifacts/ci-matrix-summary.json (CI output)
status_note: docs/status/2025-11-06_ci_pipeline.md
backlog_refs:
  - "#71"
  - "#95"
traceability:
  tests:
    - path: apps/keyboard-defense/tests/tutorialSmoke.test.js
      description: Tutorial smoke CLI fixtures
    - path: apps/keyboard-defense/tests/castleBreachSummary.test.js
      description: Castle breach nightly summary
  commands:
    - npm run smoke:tutorial -- --ci
    - node scripts/ci/castleBreachSummary.mjs --mode warn docs/codex_pack/fixtures/castle-breach
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Scale tutorial smoke and breach drills across multiple seeds/variants and aggregate medians/p90s.

## Steps

1) Add `scripts/ci/run-matrix.mjs` (template provided).  
2) Schedule a nightly workflow that calls it and uploads `artifacts/ci-matrix-summary.json`.  
3) Print the aggregated numbers in the CI Step Summary.

## Acceptance criteria

- Matrix runs complete within time budget, artifacts uploaded, summary shows medians/p90s.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- node scripts/ci/run-matrix.mjs --dry-run --output artifacts/ci-matrix-summary.json
## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- node scripts/ci/run-matrix.mjs --dry-run (or CI job) to ensure summary JSON writes correctly







