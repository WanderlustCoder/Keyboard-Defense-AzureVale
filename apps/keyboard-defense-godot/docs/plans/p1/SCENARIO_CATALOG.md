# Scenario Catalog

## Purpose and relationship
This catalog summarizes the executable scenario set that supports balance work (P0-BAL-001) and QA automation (P1-QA-001). The executable source of truth is `res://data/scenarios.json`; this document mirrors those IDs and adds planning notes.

## Scenario format (executable)
Scenario IDs in this catalog must match the JSON ids in `res://data/scenarios.json`.
Fields:
- id
- seed
- tags (array of strings; include `early`/`mid`/`long` for balance suites)
- priority (P0/P1)
- script (ordered list of exact command lines)
- stop (type + max_steps)
- expect_baseline (optional; gating; supports nested keys like `resources.wood`)
- expect_target (optional; tracked, not enforced by default)
- expect (legacy; treated as expect_baseline)

Example snippet:
```
{
  "id": "day1_baseline",
  "seed": 2001,
  "tags": ["p0", "balance"],
  "priority": "P0",
  "script": ["gather wood 10", "explore", "build farm 8 6"],
  "stop": { "type": "after_commands", "max_steps": 5000 },
  "expect_baseline": { "resources.wood": { "min": 0 } },
  "expect_target": { "resources.wood": { "min": 5, "max": 20 } }
}
```

Workflow note:
- Baselines are tightened against observed metrics and are expected to pass.
- Targets are derived from `docs/plans/p0/BALANCE_TARGETS.md` and may fail until balance changes land.

## Catalog (Phase 2 executable set)
| ID | Goal | Phase | Tags | Priority |
| --- | --- | --- | --- | --- |
| determinism_smoke | Minimal deterministic smoke | Day | smoke, p0, balance, early | P0 |
| day1_baseline | Day 1 build + explore | Day | p0, balance, day, early | P0 |
| first_night_smoke | First night entry + typing | Night | p0, balance, night, early | P0 |
| enter_night_stop | Stop condition sanity | Night | p0, balance, stop, early | P0 |
| day3_pacing | Day 3 resource pacing | Both | p0, balance, pacing, early | P0 |
| explore_forward | Exploration-focused day | Day | p0, balance, explore, early | P0 |
| tower_upgrade_day2 | Tower build + upgrades | Day | p0, balance, tower, early | P0 |
| wall_build_day2 | Wall build after night | Day | p0, balance, defense, early | P0 |
| invalid_action_smoke | Graceful failure handling | Day | p0, balance, robustness, early | P0 |
| lesson_goal_prefs_smoke | Goal/lesson regression | Day | prefs, regression, smoke | P1 |
| map_inspect_smoke | Inspect + map smoke | Day | ui, smoke | P1 |
| lumber_build_day2 | Lumber mill build | Day | p0, balance, economy, early | P0 |
| day5_pacing_basic | Day 5 steady gather pacing | Day | p0, balance, mid, pacing | P0 |
| day5_explore_focus | Day 5 exploration pressure | Day | p0, balance, mid, explore | P0 |
| day5_economy_focus | Day 5 upper-range gathers | Day | p0, balance, mid, economy | P0 |
| day7_pacing_basic | Day 7 steady gather pacing | Day | p0, balance, mid, pacing, long | P0 |
| day7_explore_focus | Day 7 exploration pressure | Day | p0, balance, mid, explore, long | P0 |
| day7_economy_focus | Day 7 upper-range gathers | Day | p0, balance, mid, economy, long | P0 |
| day7_defense_smoke | Day 7 defense smoke | Night | p0, balance, mid, defense, long | P0 |

## Scenario selection for CI
- PR gate (fast): `--tag p0 --tag balance --exclude-tag long`
- Balance targets view: `--tag p0 --tag balance --targets`
- Nightly (full): `--all`

## Mapping notes
- Balance curve days 1-3: day1_baseline, day3_pacing, tower_upgrade_day2, wall_build_day2, lumber_build_day2.
- Balance curve days 5-7: day5_pacing_basic, day5_explore_focus, day5_economy_focus, day7_pacing_basic, day7_explore_focus, day7_economy_focus, day7_defense_smoke.
- Determinism regression: determinism_smoke, enter_night_stop.
- UX/command regression: map_inspect_smoke, invalid_action_smoke.
