---
id: gold-percentile-ingestion-guard
title: "Enforce gold summary percentile metadata before dashboards ingest"
priority: P2
effort: M
depends_on: [gold-percentile-dashboard-alerts, gold-summary-dashboard-integration]
produces:
  - scripts/ci/goldPercentileGuard.mjs
  - ci step that runs gold summary checks on every artifact
status_note: docs/status/2025-11-13_gold_summary_checker.md
backlog_refs:
  - "#103"
  - "#104"
  - "#105"
  - "#106"
---

**Context**  
Percentile flags/metadata now exist across `goldSummary.mjs`, smoke runs, and the standalone
`analytics:gold:check` CLI (see status notes 2025-11-10 through 2025-11-13). CI still uploads
artifacts without verifying the metadata before dashboards ingest them, so a misconfigured
percentile list could silently corrupt dashboards/alerts. We need a dedicated guard step that
runs the validator, compares the embedded percentile list with the canonical configuration, and
blocks ingestion when they diverge.

## Steps

1. **Guard script**
   - Add `scripts/ci/goldPercentileGuard.mjs` that:
     - Locates smoke/e2e gold summary artifacts (JSON + CSV).
     - Invokes `node scripts/goldSummaryCheck.mjs` with the expected percentile list (default from config).
     - Parses the results and emits a normalized report (`artifacts/summaries/gold-percentile-guard.ci.json`)
       plus Markdown for CI dashboards.
     - Supports overrides via env vars (`GOLD_PERCENTILES`, `GOLD_GUARD_MODE`) for future tuning.
2. **Workflow integration**
   - Wire the guard script into tutorial smoke + e2e workflows after the gold summary artifacts are produced,
     failing the job on guard errors (or warning in soft mode).
   - Upload the JSON summary and append the Markdown to `$GITHUB_STEP_SUMMARY`.
   - Ensure the guard runs before dashboards/alerts consume the artifact.
3. **Documentation + troubleshooting**
   - Update `CODEX_PLAYBOOKS.md` / `CODEX_GUIDE.md` with instructions for running the guard locally.
   - Add guidance to `docs/codex_dashboard.md` describing how to interpret guard failures and how to
     refresh fixtures when the canonical percentile list changes.

## Implementation Notes

- **Guard CLI behavior**
  - Accept explicit artifact paths via flags (`--summary`, `--csv`, `--baseline`, `--thresholds`) plus `--out-json`, `--out-md`.
  - Default to scanning `artifacts/smoke/**/gold-summary*.json` when paths omitted.
  - Emit JSON shaped as `{scenario, file, percentiles:{requested:[], actual:[]}, status, issues:[...]}` plus Markdown tables summarizing mismatches.
  - Provide `--mode info|warn|fail` and `--strict` (treat warnings as failures).
- **Validation logic**
  - Compare both the percentile _set_ and ordering against the canonical list.
  - Ensure each artifact includes the `percentiles` array in metadata and that CSV columns align (gainPercentile50, etc.).
  - Cross-check config drift by hashing the canonical percentile list; include hash in the guard output so dashboards quickly identify stale configs.
- **Workflow integration**
  - Place the guard step immediately after gold summary generation but before dashboards/alerts (gold summary report, analytics board) run.
  - Upload JSON/Markdown to `artifacts/summaries/gold-percentile-guard*.{json,md}` and append Markdown to `$GITHUB_STEP_SUMMARY`.
  - Fail CI when guard status is `fail` (missing metadata, wrong list) and optionally warn when percentiles mismatch but `--mode warn`.
- **Fixtures & testing**
  - Store positive/negative fixtures under `docs/codex_pack/fixtures/gold/percentile-guard/` (correct metadata, missing column, wrong order).
  - Add Vitest tests verifying CLI flag parsing, report formatting, threshold/mode handling, and failure messaging.
- **Docs & troubleshooting**
  - Document the guard workflow in `CODEX_PLAYBOOKS.md` (Analytics) and `CODEX_GUIDE.md` command table.
  - Add a “Guard failure checklist” to `docs/codex_dashboard.md` (e.g., “Regenerate `gold-summary.json`, confirm `percentiles` array, rerun guard”).
  - Update the Nov-13 status note once the guard lands, detailing how to re-run locally.

## Deliverables & Artifacts

- `scripts/ci/goldPercentileGuard.mjs` + tests + fixtures.
- CI workflow step uploading guard JSON/Markdown + summary entry on dashboard.
- Updated docs (guide, playbook, dashboard, status) covering command usage + troubleshooting.

## Acceptance criteria

- CI fails (or emits a clear warning) whenever a gold summary artifact lacks metadata or lists the wrong percentiles.
- Guard output is available as JSON + Markdown and linked from the Codex dashboard for quick triage.
- Developers can reproduce guard failures locally using documented commands.

## Verification

- npm run analytics:gold -- --percentiles 25,50,90 --out temp/gold.json
- node scripts/goldSummaryCheck.mjs temp/gold.json
- node scripts/ci/goldPercentileGuard.mjs docs/codex_pack/fixtures/gold-summary.json
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
