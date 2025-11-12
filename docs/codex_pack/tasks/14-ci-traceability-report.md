---
id: ci-traceability-report
title: "Publish spec-to-test traceability report from CI artifacts"
priority: P2
effort: M
depends_on: [ci-step-summary]
produces:
  - scripts/ci/traceabilityReport.mjs
  - docs/codex_pack/fixtures/traceability-report.json
  - README/portal updates showing how to consume the report
status_note: docs/status/2025-11-06_ci_pipeline.md
backlog_refs:
  - "#71"
  - "#95"
---

**Context**  
CI already runs tutorial smoke + e2e suites and uploads artifacts, but reviewers
still have to correlate specs/backlog items to the tests that cover them. We need
an automated traceability report summarizing which scripts back which backlog IDs.

## Steps

1. **Implement generator**
   - Create `scripts/ci/traceabilityReport.mjs` that:
     - Reads a manifest (e.g., `docs/codex_pack/manifest.yml` and `apps/.../docs/season1_backlog.md`)
     - Maps backlog IDs to scripts/tests (use metadata from Codex tasks or a new
       `traceability` section in the tasks)
     - Outputs JSON + Markdown summarizing coverage (tests per backlog item,
       missing coverage, links to artifacts)
   - Accept CLI flags:
     - `--manifest docs/codex_pack/manifest.yml`
     - `--backlog apps/keyboard-defense/docs/season1_backlog.md`
     - `--output artifacts/traceability/traceability-report.json`
2. **CI integration**
   - Call the script at the end of the Build/Test or E2E job (after tests run).
   - Publish the Markdown summary to `$GITHUB_STEP_SUMMARY` and upload the JSON.
3. **Fixtures & docs**
   - Check in `docs/codex_pack/fixtures/traceability-report.json` (sample) so Codex can dry-run.
   - Update `docs/CODEX_PORTAL.md` (and/or README) describing how to interpret the report.
4. **Metadata**
   - Extend Codex tasks with an optional `traceability` field listing relevant backlog IDs/tests
     (or derive automatically from `backlog_refs` + naming). Ensure the script understands this.

## Acceptance criteria

- Running `node scripts/ci/traceabilityReport.mjs --manifest ... --backlog ... --output /tmp/report.json`
  produces deterministic JSON + Markdown with:
  - Backlog ID → tests/scripts → latest CI status (pass/fail)
  - Missing coverage list (backlog items without linked tests)
- CI publishes the summary on every run and uploads the JSON artifact.
- Docs explain how to consume the report locally and in CI.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- node scripts/ci/traceabilityReport.mjs --manifest docs/codex_pack/manifest.yml --backlog apps/keyboard-defense/docs/season1_backlog.md --output docs/codex_pack/fixtures/traceability-report.json
