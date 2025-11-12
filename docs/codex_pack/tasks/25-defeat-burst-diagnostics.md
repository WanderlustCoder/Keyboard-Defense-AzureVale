---
id: defeat-burst-diagnostics
title: "Expose defeat burst metrics in diagnostics & smoke"
priority: P2
effort: S
depends_on: []
produces:
  - diagnostics overlay updates showing burst counts
  - smoke/analytics fields capturing defeat burst metrics
status_note: docs/status/2025-11-07_enemy_defeat_animation.md
backlog_refs:
  - "#41"
---

**Context**  
We added defeat bursts but have no diagnostics metrics to ensure they keep
firing. Exposing counts in the overlay + smoke artifacts helps visual regression.

## Steps

1. **Diagnostics overlay**
   - Add a section listing recent defeat bursts (count per minute, last burst time).
   - Highlight if bursts stop firing unexpectedly.
2. **Telemetry/smoke**
   - Update smoke analytics to log burst counts for quick regression checks.
3. **CI summary**
   - Extend `scripts/ci/emit-summary.mjs` to surface burst stats when available.

## Acceptance criteria

- Diagnostics panel shows defeat burst metrics.
- Smoke artifacts record counts.
- CI summary surfaces the numbers.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run diagnostics overlay locally to confirm metrics display.
