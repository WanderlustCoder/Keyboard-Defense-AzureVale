---
id: castle-breach-analytics
title: "Surface castle breach replay telemetry in CI dashboards"
priority: P2
effort: M
depends_on: [ci-step-summary, static-dashboard]
produces:
  - artifacts/castle-breach.ci.json summary feed
  - docs/castle-breach-dashboard.md
status_note: docs/status/2025-11-06_castle_breach_replay.md
backlog_refs:
  - "#99"
  - "#41"
---

**Context**  
`scripts/castleBreachReplay.mjs` gives us deterministic drills, but the JSON it
writes is still raw simulation data. CI reviewers have to download artifacts to
learn time-to-breach deltas, countermeasure load-outs, or failure causes, and we
can’t correlate turret changes with analytics. Task #29 delivers the automation
layer Codex keeps requesting: richer CLI metadata, scenario controls, summary
generation, dashboards, and docs so breach regressions surface automatically.

## Steps

1. **CLI instrumentation upgrades**
   - Extend `scripts/castleBreachReplay.mjs` with:
     - `--turret <slot>:<type>` (repeatable) to pre-place defenses.
     - `--enemy <id>` (repeatable) for multi-enemy drills.
     - Derived metrics: `timeToBreachMs`, `castleHpStart`, `castleHpEnd`,
       `damageSource`, `lane`, `seed`, and `result` (pass/fail).
   - Persist the enriched payload to both local (`artifacts/castle-breach.json`)
     and CI (`artifacts/castle-breach.ci.json`) files. Include the CLI options
     used so dashboards can echo the run context.
2. **Summary generator CLI**
   - Author `scripts/ci/castleBreachSummary.mjs` that:
     - Accepts one or more breach artifacts or fixture directories.
     - Emits `artifacts/summaries/castle-breach.ci.json` (normalized metrics +
       scenario metadata) and Markdown with key rows (scenario, turrets, enemies,
       time-to-breach, castle HP delta, pass/fail).
     - Supports `--mode warn|fail|info` plus thresholds like
       `--max-time-to-breach-ms` to gate regressions.
     - Provides `--fixture docs/codex_pack/fixtures/castle-breach/*.json` so
       Codex can dry-run locally without rerunning the drill.
3. **CI + dashboard wiring**
   - Update the breach job inside `.github/workflows/ci-e2e-azure-vale.yml` to
     run the summary script after `task:breach`, upload the summary JSON, and
     append the Markdown to `$GITHUB_STEP_SUMMARY`.
   - Add a “Castle Breach Watch” tile to `docs/codex_dashboard.md` linking to the
     JSON + rendered Markdown. Include breach metrics in `docs/codex_dashboard.md`
     and ensure `npm run codex:dashboard` pulls them in.
4. **Docs + fixtures**
   - Capture representative fixtures under
     `docs/codex_pack/fixtures/castle-breach/` (baseline, turret variant, failure).
   - Document the new flags/summary CLI in `docs/CODEX_GUIDE.md`,
     `docs/CODEX_PLAYBOOKS.md` (new subsection), and `apps/keyboard-defense/docs/README.md`.
   - Update `docs/status/2025-11-06_castle_breach_replay.md` to describe the
     dashboards once implemented and keep the Follow-up block referencing this task.

## Implementation Notes

- **CLI instrumentation**
  - Support both inline turret specs (`slot-2:arcane@2`) and JSON loadouts via `--turrets-file <path>` so complex scenarios can be stored in fixtures.
  - Expose additional flags: `--enemy-seed`, `--lane`, `--start-wave`, `--duration-ms`, `--strict` (fails when breach data missing).
  - Persist metadata inside the artifact (`cliOptions`, `gitSha`, `timestamp`, `version`) for traceability.
  - Include per-turret stats (damage dealt, uptime) and per-enemy breakdown (hp, kill time, damage source) so dashboards can answer “which turret failed?”
- **Summary generator**
  - Normalize artifacts into `{scenario, turrets[], enemies[], metrics}` objects, calculating:
    - `timeToBreachMs`, `castleHpDelta`, `breachCount`, `damageSources`, `failures`.
    - Derived ratios (e.g., `turretCoveragePct`, `enemyKillRate`).
  - Markdown output should include:
    - Scenario header with seed/lane.
    - Table of metrics.
    - Bullet list of alerts (e.g., “Breach exceeded threshold by +1.2s”).
  - JSON output should be machine-friendly for future dashboards (`docs/codex_dashboard.md`, `goldAnalyticsBoard` cross-linking).
  - Provide `--threshold-max-breach-ms`, `--threshold-min-castle-hp`, `--threshold-max-failures` flags + `--mode info|warn|fail`.
- **Fixtures & testing**
  - Store baseline artifacts (pass/fail) plus derived summary snapshots under `docs/codex_pack/fixtures/castle-breach/`.
  - Add Vitest tests for both the replay CLI (ensuring new flags parse correctly) and the summary script (JSON/Markdown snapshot tests, threshold enforcement).
- **Docs + onboarding**
  - Add a “Castle Breach Watch” subsection to `CODEX_PLAYBOOKS.md` with command snippets for:
    - Generating loadouts (`scripts/castleBreachReplay.mjs ...`).
    - Summarizing artifacts.
    - Updating the dashboard tile.
  - Update `CODEX_GUIDE.md` command table with the new CLI invocation (if not already).
  - Expand the status note with instructions on where to find artifacts + dashboards.

## Scenario library plan

1. **Baseline set**
   - `baseline.json`: tutorial-style run, no turrets, deterministic breach (~Wave 5) to validate failure alerts.
   - `turret-rush.json`: arcane/cannon loadout that should pass comfortably, used to confirm turret parsing + per-turret stats.
   - `multi-enemy.json`: witches + brutes with different HP pools to exercise per-enemy breakdowns and damage-source reporting.
2. **Variant backlog**
   - `shield-break.json`: spawns shielded casters to ensure the payload records `damageSource: "shield"` and `turretCoveragePct`.
   - `fail-fast.json`: intentionally malformed artifact for negative-testing `castleBreachSummary.mjs`.
   - `lane-pressure.json`: mixes lanes + seeds so dashboards can render scenario comparisons.
3. **Storage rules**
   - Every fixture includes a sibling `.meta.json` documenting CLI flags, expected metrics, and owning status note.
   - Keep the catalog table in `docs/codex_pack/snippets/castle-breach-scenarios.md` so other tasks can reuse the scenarios without re-reading fixtures.

## Summary schema (JSON + Markdown)

- JSON root:
  ```jsonc
  {
    "generatedAt": "2025-11-20T18:04:05.000Z",
    "gitSha": "abc123",
    "mode": "fail",
    "scenarios": [
      {
        "id": "baseline",
        "title": "Baseline (no turrets)",
        "cli": "node scripts/castleBreachReplay.mjs --seed 2025",
        "result": "fail",
        "timeToBreachMs": 48250,
        "castleHpDelta": -1200,
        "breachCount": 1,
        "turrets": [{ "slot": "slot-2", "type": "arcane", "level": 2 }],
        "enemies": [{ "id": "witch", "count": 4, "hp": 900 }],
        "alerts": [
          { "severity": "fail", "message": "Breach exceeded threshold by +2.1s", "recommendation": "Add slot-3 cannon" }
        ],
        "artifacts": {
          "replay": "artifacts/castle-breach.ci.json",
          "summary": "artifacts/summaries/castle-breach.e2e.json"
        }
      }
    ]
  }
  ```
- Markdown structure:
  1. H2 per scenario (`## Scenario: baseline (seed 2025, lane 1)`).
  2. Metrics table (time-to-breach, HP delta, breaches, turrets, enemies).
  3. Alerts table (Severity, Message, Recommendation).
  4. “Reproduce locally” fenced block with CLI invocation + fixture path.

## Dashboard integration timeline

| Milestone | Description |
| --- | --- |
| D1 | Append the Markdown report to `$GITHUB_STEP_SUMMARY` in both smoke + e2e breach jobs. |
| D2 | Add a “Castle Breach Watch” tile to `docs/codex_dashboard.md` and `scripts/generateCodexDashboard.mjs` showing result + top alert per scenario. |
| D3 | Include the JSON summary in `static-dashboard.yml` build output so published docs mirror CI. |
| D4 | Extend future `ci-matrix-nightly.yml` runs to execute `castleBreachSummary.mjs --mode warn` across archived fixtures for extra signal. |

## Testing matrix

- **Unit**
  - Flag parsing: table-driven tests ensuring repeated `--turret` + `--enemy` args merge properly.
  - Metrics: verify derived stats (`turretCoveragePct`, `enemyKillRate`, `timeToBreachMs`) with controlled inputs.
  - Markdown/JSON snapshots: keep fixtures under `tests/__snapshots__/castleBreachSummary.test.snap`.
- **Integration**
  - Replay CLI: run against each scenario fixture and diff the generated artifact.
  - Summary CLI: feed the fixture directory, confirm alerts fire based on thresholds.
  - Dashboard script: ensure `generateCodexDashboard.mjs` ingests the summary output without schema mismatches.
- **CI**
  - Build/Test job: add a dry-run step against `docs/codex_pack/fixtures/castle-breach` (mode=warn) to guard regressions early.
  - E2E job: run in `mode=fail` on live artifacts so breaches block merges when metrics exceed thresholds.

## Deliverables & Artifacts

- Enhanced `scripts/castleBreachReplay.mjs` + tests + fixtures.
- `scripts/ci/castleBreachSummary.mjs` + unit tests + Markdown/JSON outputs.
- CI workflow + dashboard updates referencing the new summary.
- Documentation updates (guide, playbook, README, status).

## Acceptance criteria

- Breach CLI accepts turret + multi-enemy flags and records derived metrics in
  the artifact.
- `scripts/ci/castleBreachSummary.mjs` produces JSON + Markdown that CI uploads
  and Codex dashboards render without manual artifact downloads.
- Status/docs/playbooks walk Codex through running the CLI, summary script, and
  fixtures locally.

## Verification

- node scripts/castleBreachReplay.mjs --seed 2025 --lane 1 --artifact temp/castle-breach.fixture.json --no-artifact
- node scripts/castleBreachReplay.mjs --seed 1337 --turret slot-2:arcane@2 --enemy brute:2 --enemy witch:1 --artifact temp/castle-breach-turrets.fixture.json --no-artifact
- node scripts/ci/castleBreachSummary.mjs docs/codex_pack/fixtures/castle-breach --summary temp/castle-breach-summary.fixture.json --mode warn
- npx vitest run tests/castleBreachReplay.test.js
- npx vitest run tests/castleBreachSummary.test.js
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
