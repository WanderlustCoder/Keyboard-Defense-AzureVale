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
traceability:
  tests:
    - path: apps/keyboard-defense/tests/traceabilityReport.test.js
      description: Traceability CLI behavior
  commands:
    - node scripts/ci/traceabilityReport.mjs --test-report docs/codex_pack/fixtures/traceability-tests.json --out-json temp/traceability.fixture.json --mode warn
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

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

## Implementation Notes

- **Data sources**
  - Leverage existing metadata:
    - `docs/codex_pack/manifest.yml` (task ids, backlog refs, status notes).
    - `apps/keyboard-defense/docs/season1_backlog.md` (item numbers + descriptions).
    - Potential `traceability` blocks inside task files (optional) mapping to specific test files or commands.
    - Recent CI artifacts (JUnit/Vitest JSON, Playwright results) to capture pass/fail status.
  - Store a lightweight cache (`artifacts/traceability/matrix.json`) so reruns don’t reparse large logs unless requested.
- **Report structure**
  - JSON schema:
    ```json
    {
      "generatedAt": "2025-11-20T12:00:00Z",
      "backlogItems": [
        {
          "id": "#53",
          "title": "Reflow layout",
          "tasks": ["responsive-condensed-audit"],
          "tests": [
            { "path": "apps/.../tests/hudResponsive.test.ts", "status": "pass", "lastRun": "2025-11-20T11:50:00Z" }
          ],
          "coverageStatus": "partial",
          "notes": "Missing Playwright smoke"
        }
      ],
      "unmappedTests": [...],
      "unmappedBacklog": [...]
    }
    ```
  - Markdown summary should include:
    - Coverage table (Backlog ID → tasks → tests → status).
    - Missing coverage list.
    - Links to relevant artifacts/logs.
- **CLI behavior**
  - Flags: `--manifest`, `--backlog`, `--tests <globs>`, `--out-json`, `--out-md`, `--mode info|warn|fail`.
  - Provide `--fixtures docs/codex_pack/fixtures/traceability-report.json` for dry-runs.
  - Support `--filter "#53,#71"` to narrow the report when debugging.
- **CI integration**
  - Run after tests complete (so JUnit/Vitest JSON exists).
  - Upload JSON to `artifacts/traceability/traceability-report.ci.json` and append Markdown to `$GITHUB_STEP_SUMMARY`.
  - Fail (or warn) CI when backlog items lack mapped tests or when previously covered items lose coverage.
- **Metadata enhancements**
  - Encourage tasks to add a `traceability` block:
    ```yaml
    traceability:
      tests:
        - apps/.../tests/hudResponsive.test.ts
      commands:
        - npm run test -- hudResponsive
    ```
  - Script should fall back to heuristics (e.g., match backlog `#53` to tests containing `responsive`).
- **Docs & portal**
  - Document the workflow in `CODEX_GUIDE.md` (command table) and `CODEX_PLAYBOOKS.md` (Automation).
  - Add a “Traceability” tile to `docs/CODEX_PORTAL.md` linking to the latest CI artifact and explaining how to interpret coverage states.
  - Update `docs/status/2025-11-06_ci_pipeline.md` once the report ships.
- **Testing**
  - Create fixtures representing:
    - Full coverage.
    - Missing tests for a backlog item.
    - Tests without backlog mapping.
  - Add Vitest tests verifying parsing logic, JSON/Markdown output, filtering, and failure modes.

## Deliverables & Artifacts

- `scripts/ci/traceabilityReport.mjs` + unit tests + fixtures.
- Optional `traceability` metadata blocks added to key tasks (or documented format).
- CI workflow update uploading JSON/Markdown + Codex dashboard/portal references.
- Documentation updates (guide, playbook, portal, status).

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
- node scripts/ci/traceabilityReport.mjs --manifest docs/codex_pack/manifest.yml --backlog apps/keyboard-defense/docs/season1_backlog.md --test-report docs/codex_pack/fixtures/traceability-tests.json --out-json docs/codex_pack/fixtures/traceability-report.json --out-md docs/codex_pack/fixtures/traceability-report.md






