# Balance Constants

## Purpose and scope
This document lists the numeric balance constants currently in use so tuning work can reference a single source of truth. Values here reflect the deterministic sim as of this milestone and should be updated alongside any balance changes.

## Constants index
| Area | Constant / description | Value | File + symbol | Notes |
| --- | --- | --- | --- | --- |
| Explore economy | Base explore reward amount | 8 (water: 5) | `res://sim/apply_intent.gd` `_explore_reward` | Drives early pacing in day1_baseline and explore_forward scenarios. |
| Explore economy | Terrain reward weighting | forest favors wood; mountain favors stone; plains favors food | `res://sim/apply_intent.gd` `_explore_reward` | Picks from weighted arrays; deterministic via RNG state. |
| Economy guardrails | MIDGAME_STONE_CATCHUP_DAY | 4 | `res://sim/balance.gd` `MIDGAME_STONE_CATCHUP_DAY` | Enables stone catch-up logic on explores. |
| Economy guardrails | MIDGAME_STONE_CATCHUP_MIN | 10 | `res://sim/balance.gd` `MIDGAME_STONE_CATCHUP_MIN` | If stone < min, explore reward forces stone. |
| Economy guardrails | MIDGAME_FOOD_BONUS_DAY | 4 | `res://sim/balance.gd` `MIDGAME_FOOD_BONUS_DAY` | Enables low-food bonus check. |
| Economy guardrails | MIDGAME_FOOD_BONUS_THRESHOLD | 12 | `res://sim/balance.gd` `MIDGAME_FOOD_BONUS_THRESHOLD` | If food < threshold, add bonus. |
| Economy guardrails | MIDGAME_FOOD_BONUS_AMOUNT | 2 | `res://sim/balance.gd` `MIDGAME_FOOD_BONUS_AMOUNT` | Added in `res://sim/tick.gd` after production. |
| Economy guardrails | MIDGAME_CAPS_DAY5 | wood 40, stone 20, food 25 | `res://sim/balance.gd` `MIDGAME_CAPS_DAY5` | Applied via `SimBalance.apply_resource_caps`. |
| Economy guardrails | MIDGAME_CAPS_DAY7 | wood 50, stone 35, food 35 | `res://sim/balance.gd` `MIDGAME_CAPS_DAY7` | Applied via `SimBalance.apply_resource_caps`. |
| Night waves | Day 7 wave totals | base 7; threat2 9; threat4 11 | `res://sim/tick.gd` `NIGHT_WAVE_BASE_BY_DAY` | Threat offsets remain +2/+4. |
| Enemies | Day 7 armored hp bonus | 4 | `res://sim/enemies.gd` `ENEMY_HP_BONUS_BY_DAY` | Day 1 remains 1. |
| Enemies | Day 7 raider hp bonus | 2 | `res://sim/enemies.gd` `ENEMY_HP_BONUS_BY_DAY` | Day 1 remains 0. |
| Enemies | Day 7 scout hp bonus | 1 | `res://sim/enemies.gd` `ENEMY_HP_BONUS_BY_DAY` | Day 1 remains -1. |
| Enemies | Day 7 armored armor | 2 | `res://sim/enemies.gd` `ENEMY_ARMOR_BY_DAY` | Day 1 remains 1. |
| Enemies | Day 7 raider armor | 1 | `res://sim/enemies.gd` `ENEMY_ARMOR_BY_DAY` | Day 1 remains 0. |
| Enemies | Day 7 scout armor | 1 | `res://sim/enemies.gd` `ENEMY_ARMOR_BY_DAY` | Day 1 remains 0. |
| Enemies | Day 7 scout speed | 3 | `res://sim/enemies.gd` `ENEMY_SPEED_BY_DAY` | Day 1 remains 2. |
| Enemies | Day 7 raider speed | 2 | `res://sim/enemies.gd` `ENEMY_SPEED_BY_DAY` | Day 1 remains 1. |
| Enemies | Day 7 armored speed | 2 | `res://sim/enemies.gd` `ENEMY_SPEED_BY_DAY` | Day 1 remains 1. |
| Production baseline | Daily baseline food | +1 food/day | `res://sim/buildings.gd` `daily_production` | Baseline independent of buildings. |
| Building costs | Farm/Lumber/Quarry | farm: wood 10; lumber: wood 5 + food 2; quarry: wood 5 + food 2 | `res://sim/buildings.gd` `BUILDINGS` | Core day economy costs. |
| Building costs | Wall/Tower | wall: wood 4 + stone 4; tower: wood 4 + stone 8 | `res://sim/buildings.gd` `BUILDINGS` | Wall blocks path; tower enables defense. |
| Building production | Farm base food production | 3 | `res://sim/buildings.gd` `BUILDINGS` | Base daily food before adjacency. |
| Building production | Lumber base wood production | 3 | `res://sim/buildings.gd` `BUILDINGS` | Base daily wood before adjacency. |
| Building production | Quarry base stone production | 3 | `res://sim/buildings.gd` `BUILDINGS` | Base daily stone before adjacency. |
| Tower stats | Level 1-3 stats | L1 range 3 dmg 1 shots 1; L2 range 4 dmg 1 shots 2; L3 range 5 dmg 2 shots 2 | `res://sim/buildings.gd` `TOWER_STATS` | Used in night tower attacks and inspector. |
| Tower upgrades | Upgrade costs | L1->2: wood 5 stone 10; L2->3: wood 10 stone 15 | `res://sim/buildings.gd` `TOWER_UPGRADE_COSTS` | Also used for demolish refunds. |
