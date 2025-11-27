---
id: schema-contracts
title: "Snapshot schema contracts as code"
priority: P2
effort: M
depends_on: []
produces:
  - analytics JSON Schema
  - CI validator step
status_note: docs/status/2025-11-08_gold_summary_cli.md
backlog_refs:
  - "#76"
---

**Context**\
`analytics_schema.md` documents the telemetry payload, but we still rely on docs +
spot checks. Automation needs machine-readable schemas, Ajv-based validation, and
CI hooks so analytics exports can’t drift silently.

## Steps

1. **Schema authoring**
   - Create `apps/keyboard-defense/schemas/analytics.schema.json` describing the
     snapshot root (metadata, `waves[]`, `events[]`, `uiSnapshot`, etc.).
   - Mirror any CSV columns (e.g., `comboWarningAccuracyDeltaAvg`) with `patternProperties`
     or explicit fields so both JSON + CSV exports stay in sync.
   - Version the schema via `$id` + `exportVersion`, and require that the CLI bumps
     the version when incompatible changes land.
2. **Validator CLI**
   - Build `scripts/analytics/validate-schema.mjs` that:
     - Loads the schema, compiles with Ajv, and validates one or more analytics artifacts.
     - Supports `--fixture` (pointing at `docs/codex_pack/fixtures/...`) and
       `--input artifacts/analytics/*.json` for CI usage.
     - Emits a Markdown + JSON summary (pass/fail per file, error paths) so CI can
       surface failures in `$GITHUB_STEP_SUMMARY`.
3. **CI wiring**
   - Add a step to Build/Test and analytics workflows running
     `node scripts/analytics/validate-schema.mjs --input artifacts/analytics/*.json`.
   - Fail CI on validation errors; allow `--mode warn` for optional nightly jobs.
4. **Documentation**
   - Update `docs/analytics_schema.md` to reference the canonical JSON Schema path
     and describe how to regenerate it.
   - Add instructions to `CODEX_GUIDE.md`/`CODEX_PLAYBOOKS.md` (Analytics section)
     covering the validator command and fixture workflow.
5. **Fixtures/tests**
   - Store representative analytics snapshots under
     `docs/codex_pack/fixtures/analytics/` (tutorial, breach, condensed HUD).
   - Add Vitest tests ensuring the schema compiles, fixtures validate, and invalid
     payloads produce actionable error messages.
   - Snapshot the Markdown output so formatting changes are intentional.

## Acceptance criteria

- Analytics artifacts are validated against the JSON Schema locally and in CI.
- Schema lives in version control with clear versioning guidance.
- Developers can run `node scripts/analytics/validate-schema.mjs --fixture ...`
  to reproduce CI failures.

## Phase plan

1. **Phase 0 – establish guardrails**
   - Finish aligning the JSON Schema with the prose reference from
     `docs/analytics_schema.md`, including enum docs, `$defs`, and comments for
     cross-checking CSV parity.
   - Stamp the first `$id`/`exportVersion` pair and add a CHANGELOG entry in the
     schema file so Codex can diff intent vs. generated payloads.
   - Land thin Vitest coverage (schema compiles + fixtures validate/fail) so we
     can iterate without running the full `npm run test` loop.
2. **Phase 1 – CLI + fixtures**
   - Harden `scripts/analytics/validate-schema.mjs` with Ajv formats, Markdown +
     JSON reporters, and per-file fail-fast summaries. The CLI should also
     support `--cwd` overrides for Build/Test and `--mode warn|fail`.
   - Seed fixtures representing tutorial, breach, condensed HUD, and intentionally
     broken payloads. Each fixture gets both `.json` and `.md` snapshots so
     formatter changes are reviewable.
3. **Phase 2 – CI + documentation**
   - Wire Build/Test and analytics workflows so schema validation blocks merges
     by default, while nightly/regression jobs can run in `warn` mode.
   - Update `CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md`, and `docs/codex_dashboard.md`
     with a “Schema Contracts” tile summarizing the most recent validation run.
   - Adopt `docs/status/...` entries for every incompatible schema bump so
     downstream consumers know when to refresh their clients.
   - Current wiring: `.github/workflows/ci-e2e-azure-vale.yml` now runs the
     validator inside both Build/Test (Node 18 + 20) and e2e orchestration jobs,
     writes JSON/Markdown summaries per job, uploads them as artifacts, and
     appends the Markdown to the GitHub Step Summary for quick triage.

## Validator reporting spec

- JSON report (`artifacts/summaries/analytics-validate.ci.json`)
  - `generatedAt`, `schemaPath`, `gitSha`, and `fixtures` metadata.
  - Array of `{ file, valid, errorCount, errors[] }` records; each error
    includes `instancePath`, `schemaPath`, `message`, and a friendly hint if one
    exists in the schema.
- Markdown report (`artifacts/summaries/analytics-validate.ci.md`)
  - Heading summarizing totals (✅/❌ counts).
  - Table with columns: File, Result, Errors (comma-separated paths).
  - “Triage” block linking to `docs/analytics_schema.md` anchors so reviewers can
    jump directly to the section describing the broken field.
- Standard exit codes
  - `0` when all files pass (or when `--mode warn` and failures exist).
  - `1` when any file fails in default mode, or when the CLI can’t find inputs.

## Risk log & follow-ups

- **Format drift** – Ajv warns on missing formats (e.g., `date-time`); keep
  `ajv-formats` wired in and add regression coverage when new string formats are
  introduced.
- **Fixture rot** – schedule a weekly `npm run analytics:validate-schema --fixture ...`
  job in CI that replays fixtures produced from the latest tutorial smoke run so
  we catch subtle schema changes before they ship.
- **CSV mismatch** – the JSON Schema must stay in sync with CSV exports; add a
  `--csv` flag to the validator that cross-checks header order once the JSON
  artifact passes validation.
- **Docs drift** – embed a `schema-version` badge in `docs/analytics_schema.md`
  (auto-generated by the CLI) so discrepancies are visible in PR diffs.

## Developer checklist

- [ ] Touch `docs/analytics_schema.md` whenever the JSON Schema changes.
- [ ] Update at least one fixture per schema change (valid + invalid).
- [ ] Re-run `npm run analytics:validate-schema` and snapshot the Markdown
      report before committing.
- [ ] Capture CI URLs (JSON + Markdown) inside the corresponding status doc so
      reviewers can audit the artifacts post-merge.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- node scripts/analytics/validate-schema.mjs --fixture docs/codex_pack/fixtures/analytics/tutorial.json

