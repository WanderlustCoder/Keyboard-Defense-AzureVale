# Scenario Harness Implementation Spec (P1-QA-001)

## Purpose and non-goals
Build a deterministic, headless scenario runner that executes scripted command sequences against the sim layer and evaluates outcomes. This is a tooling spec only and must not change gameplay, data formats, or RNG behavior.

Non-goals:
- No balance adjustments or new gameplay features.
- No UI instantiation or input focus dependencies.
- No mandatory CI gate changes until the harness is stable.

## References
- `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md`
- `docs/plans/p1/SCENARIO_CATALOG.md`
- `docs/plans/p0/BALANCE_TARGETS.md`
- `docs/QUALITY_GATES.md`

## Runner architecture
Implemented location: `res://tools/scenario_harness/` (headless, versioned tooling).

Modules:
- `res://tools/scenario_harness/scenario_loader.gd`
  - Loads and validates scenario definitions.
- `res://tools/scenario_harness/scenario_runner.gd`
  - Applies command scripts to a `GameState` deterministically.
- `res://tools/scenario_harness/scenario_eval.gd`
  - Evaluates metric expectations (range/exact).
- `res://tools/scenario_harness/scenario_report.gd`
  - Builds and writes JSON reports.
- `res://tools/run_scenarios.gd`
  - Entrypoint (similar to `run_tests.gd`), writes summary and exit code.

Scenario files:
- Stored in `res://data/scenarios.json` (single source of truth).

## Scenario file format (implemented)
`res://data/scenarios.json` stores a single versioned catalog:
```json
{
  "version": 2,
  "scenarios": [
    {
      "id": "day1_baseline",
      "seed": 2001,
      "description": "Day 1 baseline smoke.",
      "tags": ["p0", "balance", "smoke"],
      "priority": "P0",
      "script": ["status", "explore", "end"],
      "stop": { "type": "after_commands", "max_steps": 5000 },
      "expect_baseline": { "day": { "eq": 1 }, "phase": { "eq": "day" } },
      "expect_target": { "resources.wood": { "min": 5, "max": 20 } }
    }
  ]
}
```
Notes:
- `seed` is numeric but converted to a string for `DefaultState.create()`.
- `script` lines are exactly what a player would type.
- `stop` types are `after_commands`, `until_day`, `until_phase`.
- `tags` and `priority` enable CLI filtering (`--tag`, `--exclude-tag`, `--priority`).
- Balance scenarios should include stage tags like `early`, `mid`, and `long` for suite selection.
- `stop.max_steps` caps how many commands are executed before failing the scenario.
- `expect_baseline` is gating; baseline failures fail the scenario.
- `expect_target` is informational unless `--enforce-targets` is set.
- Legacy `expect` is treated as `expect_baseline` for backward compatibility.

CLI filters (implemented):
- `--tag <tag>` (repeatable) selects scenarios that contain all requested tags.
- `--exclude-tag <tag>` (repeatable) excludes any scenario that contains a listed tag.
- `--priority <P0|P1>` selects scenarios by priority.
- `--out-dir <path>` writes the report JSON and `last_summary.txt` into a project-relative folder (e.g., `Logs/ScenarioReports`).
- `--enforce-targets` treats target failures as scenario failures.
- `--targets` evaluates target expectations and prints a target summary without failing.
- `--print-metrics` prints a compact per-scenario metrics line to stdout and `last_summary.txt`.

## Command execution model
- Parse each command using `res://sim/parse_command.gd`.
- Apply intents using `res://sim/apply_intent.gd`.
- Do not call UI-only code; UI intents are ignored or logged.
- Night steps are advanced by commands that already do so (`wait`, `defend_input`).
- Stop conditions are evaluated after each command.
- For `until_*` stop types, the runner repeats the script until the stop condition
  is met or `max_steps` is hit. Scripts should be safe to repeat (or short enough
  to reach the stop condition in one pass).

## Metrics extraction contract
Metrics should map to existing structures without inventing new systems:
- From `GameState`:
  - `day`, `phase`, `hp`, `threat`, `resources`, `buildings_by_type`, `structures_count`,
    `enemies_alive`, `enemies_spawned`, `enemies_killed`.
- From typing stats (UI-only but pure):
  - Instantiate `res://sim/typing_stats.gd` and call `record_defend_attempt` for any defend input in scripts.
  - Use `to_report_dict()` for `avg_accuracy`, `hit_rate`, `backspace_rate`, `incomplete_rate` if the script includes typing attempts.
- Use `res://sim/typing_trends.gd` only for summary formatting, not required for pass/fail.
Metric keys can be evaluated using dotted paths (e.g., `resources.wood`) or flattened keys (e.g., `resources_wood`).

## Output artifacts
- JSON report saved under `user://scenario_reports/` unless `--out` or `--out-dir` is supplied.
- When `--out-dir` is set, the report JSON and `last_summary.txt` are written to that directory (recommended: `Logs/ScenarioReports`).
- `last_summary.txt` is written every run with the report path, `[scenarios]` summary, optional `[targets]` summary, and optional metrics lines.
- Top-level fields:
  - `meta` (timestamp, engine_version, scenario_ids, filters)
  - `summary` (total/ok/fail/failed_ids, baseline_pass_count, target_met_count, target_total_count)
  - `report_path` (where the JSON was written)
- `results` (array of per-scenario dicts)

Example report fragment:
```json
{
  "meta": { "timestamp": "...", "engine_version": "4.2.2", "scenario_ids": ["day1_baseline"] },
  "summary": { "total": 1, "ok": 1, "fail": 0, "failed_ids": [], "baseline_pass_count": 1, "target_met_count": 1, "target_total_count": 1 },
  "results": [
    { "id": "day1_baseline", "pass": true, "metrics": { "day": 1, "hp": 9 } }
  ]
}
```

## Pass/fail evaluation rules
- Baseline (`expect_baseline`) failures always fail the scenario.
- Target (`expect_target`) failures only fail when `--enforce-targets` is set.
- Exact comparisons for stable values (seed, scenario_id, phase).
- Range comparisons for metrics tied to balance targets (resources, hp, kills).
- Missing keys fail with a clear error message.

## Golden baseline strategy
- Use `expect_baseline` for deterministic regressions (exact matches or tight ranges).
- Track `expect_target` for balance targets; enforce later via `--enforce-targets`.
- Store baselines under `res://tests/scenarios/baselines/` as `baseline_<id>.json`.
- Update baselines by explicit command (manual script or documented process).

## Determinism guardrails
- Never call `RandomNumberGenerator.randomize()`.
- Always use stored `rng_state` for sim randomness.
- Run a duplicate-seed replay check for select scenarios.

## Test strategy
- Unit tests:
  - Parser/executor handles valid commands and stop rules.
  - Metrics extraction returns required keys.
- Integration smoke:
  - Run 1-2 P0 scenarios on every PR.
- Scenario suite:
  - Full catalog on nightly or pre-release runs.

## Implementation phases
- Phase 1: minimal runner, 2-3 scenarios, JSON output, no baselines.
- Phase 2: catalog coverage + tolerance checks.
- Phase 3: baseline gating + CI integration.
