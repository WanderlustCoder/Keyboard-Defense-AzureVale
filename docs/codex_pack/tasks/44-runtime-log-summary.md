---
id: runtime-log-summary
title: "Runtime log summary for breaches/accuracy"
priority: P2
effort: S
depends_on: []
produces:
  - apps/keyboard-defense/scripts/ci/runtimeLogSummary.mjs
  - apps/keyboard-defense/tests/runtimeLogSummary.test.js
  - docs/status/2025-12-04_runtime_log_summary.md
status_note: docs/status/2025-12-04_runtime_log_summary.md
backlog_refs:
  - "#79"
---

**Context**  
CI and local smoke runs emit monitor/dev-server logs but we lack an aggregated view of breaches and accuracy. A lightweight log summarizer should scan log files, extract breach/accuracy metrics, and emit JSON/Markdown for dashboards.

## Steps

1. Create `scripts/ci/runtimeLogSummary.mjs` that scans default monitor/dev-server logs (glob/directory aware), parses JSON + text lines, extracts breach/accuracy counts, and tallies warnings/errors. Emit JSON + Markdown summaries with file counts and a small metrics table.
2. Add `npm run logs:summary` wiring to package.json; ensure help text documents flags for inputs/output overrides.
3. Add Vitest coverage for arg parsing and aggregation behavior (breach sums/max, last accuracy, warnings/errors).
4. Publish a status note, mark backlog #79 done, and refresh Codex portal/dashboard references.

## Acceptance criteria

- `npm run logs:summary` scans default locations, errors if no files found, and writes JSON/Markdown summaries under `artifacts/summaries/`.
- Aggregation handles JSON arrays, single objects, JSON lines, and plain text with `breach=`/`accuracy=` tokens; warnings/errors counted from text lines.
- Tests cover parsing + aggregation path; Codex docs/manifest/task status updated and linked to backlog #79.

## Verification

- `npm run logs:summary -- --input ./artifacts/monitor --out-json temp/log-summary.json --out-md temp/log-summary.md`
- `npm test`
- `npm run codex:dashboard`
