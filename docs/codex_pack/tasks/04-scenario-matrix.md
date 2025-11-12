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
---

**Context**  
Scale tutorial smoke and breach drills across multiple seeds/variants and aggregate medians/p90s.

## Steps

1) Add `scripts/ci/run-matrix.mjs` (template provided).  
2) Schedule a nightly workflow that calls it and uploads `artifacts/ci-matrix-summary.json`.  
3) Print the aggregated numbers in the CI Step Summary.

## Acceptance criteria

- Matrix runs complete within time budget, artifacts uploaded, summary shows medians/p90s.
