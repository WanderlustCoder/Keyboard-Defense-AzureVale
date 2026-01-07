# Balance Targets (P0-BAL-001)

## Scope and usage
This document defines numeric balance targets for days 1-7 to remove ambiguity during tuning. Use these ranges when running fixed-seed scenarios and when validating deterministic balance changes. These targets are planning guidance and should be validated by the scenario harness later.

## Definitions
- Day N: the start of day N after Dawn, before spending AP.
- Resources: wood/stone/food totals at the start of the day.
- Buildings: total placed structures on the map at the start of the day.
- Towers: tower count and level distribution at the start of the day.
- Enemy counts: night wave total computed at end-of-day (night_wave_total).
- Word lengths: expected ranges by enemy kind for the active lesson.
- Typing metrics:
  - accuracy = typing_stats.avg_accuracy
  - hit_rate = hits / defend_attempts
  - backspace_rate = deleted_chars / max(typed_chars + deleted_chars, 1)
  - incomplete_rate = incomplete_enters / max(enter_presses, 1)

## Targets by day bucket
| Day | Survival | Resources total (wood/stone/food) | Buildings / Towers | Night wave notes | Word lengths (scout/raider/armored) | Typing metrics (accuracy/hit/backspace/incomplete) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | High | wood 5-20, stone 0-5, food 4-12 | 1-2 buildings, 0-1 tower (L1) | wave_total 2-3 | 3-4 / 4-6 / n/a | acc 0.75-0.90, hit 0.55-0.75, back 0.10-0.25, inc 0.15-0.35 |
| 3 | High | wood 10-30, stone 4-12, food 8-20 | 2-4 buildings, 1-2 towers (L1-2) | wave_total 3-5 | 3-4 / 4-6 / 6-8 | acc 0.72-0.88, hit 0.55-0.75, back 0.10-0.22, inc 0.15-0.30 |
| 5 | Medium | wood 15-40, stone 8-20, food 12-25 | 3-6 buildings, 2-3 towers (L1-2) | wave_total 4-6 | 3-4 / 4-6 / 6-8 | acc 0.70-0.85, hit 0.52-0.70, back 0.12-0.22, inc 0.15-0.30 |
| 7 | Medium | wood 20-50, stone 12-30, food 15-30 | 4-8 buildings, 2-4 towers (L1-3) | wave_total 5-8 | 3-4 / 4-7 / 6-9 | acc 0.68-0.82, hit 0.50-0.68, back 0.12-0.25, inc 0.15-0.30 |

## Tuning levers (file references)
- Enemy stats and spawn mix: `res://sim/enemies.gd`, `res://sim/apply_intent.gd`
- Tower costs and stats: `res://sim/buildings.gd`
- Lesson word lengths: `res://sim/lessons.gd`, `res://data/lessons.json`
- Explore reward pacing: `res://sim/apply_intent.gd`, `res://sim/map.gd`

## Validation plan
- Scenario harness: `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md`
- Scenario catalog: `docs/plans/p1/SCENARIO_CATALOG.md`
