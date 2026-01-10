# Balance Report Guide

Developer tool for comprehensive game balance analysis, verification, and export.

## Overview

`SimBalanceReport` (sim/balance_report.gd) provides automated balance checking, data export, and diff comparison for game balance values. It collects metrics from multiple sim systems and validates them against progression rules.

## Constants

```gdscript
const SCHEMA_ID := "typing-defense.balance-export"
const SCHEMA_VERSION := 1
const GAME_NAME := "Keyboard Defense"
const AXIS_NAME := "days"
const SAMPLE_DAYS := [1, 2, 3, 4, 5, 6, 7]
const SAVE_PATH := "user://balance_export.json"
```

## Export Groups

Filter metrics by category:

```gdscript
const EXPORT_GROUPS := {
    "all": [],                          # All metrics
    "wave": ["night_wave_"],            # Wave totals
    "enemies": ["enemy_"],              # Enemy stats
    "towers": ["tower_", "tower_upgrade"], # Tower stats
    "buildings": ["building_"],         # Building costs/production
    "midgame": ["midgame_"]             # Resource caps, bonuses
}
```

## Core Functions

### Balance Verification

```gdscript
# Run all balance checks, return formatted result
static func balance_verify_output() -> String
# Returns "Balance verify: OK" or list of failures

# Run checks and get raw failure array
static func run_balance_checks() -> Array[String]
```

### Balance Export

```gdscript
# Export as formatted JSON string
static func balance_export_json(group: String = "all") -> String

# Save export to file
static func save_balance_export(group: String = "all") -> Dictionary
# Returns {"ok": bool, "path": String, "json": String, "line": String}

# Build raw export payload
static func build_balance_export_payload(group: String = "all") -> Dictionary
```

### Balance Diff

```gdscript
# Compare current values against saved baseline
static func balance_diff_output(group: String = "all") -> String
# Returns "Balance diff: no changes" or list of changes
```

### Balance Summary

```gdscript
# Get formatted summary table
static func balance_summary_output(group: String = "") -> String

# Build summary lines array
static func build_balance_summary_lines(group: String = "") -> Array[String]
```

## Metrics Collected

### Base Metrics (Day-Independent)

```gdscript
# Building costs
building_farm_cost_wood, building_lumber_cost_food, building_lumber_cost_wood
building_quarry_cost_food, building_quarry_cost_wood
building_wall_cost_stone, building_wall_cost_wood
building_tower_cost_stone, building_tower_cost_wood

# Building production
building_farm_production_food, building_lumber_production_wood
building_quarry_production_stone

# Building defense values
building_wall_defense, building_tower_defense

# Tower stats by level
tower_level1_damage, tower_level1_range, tower_level1_shots
tower_level2_damage, tower_level2_range, tower_level2_shots
tower_level3_damage, tower_level3_range, tower_level3_shots

# Tower upgrade costs
tower_upgrade1_cost_stone, tower_upgrade1_cost_wood
tower_upgrade2_cost_stone, tower_upgrade2_cost_wood

# Base enemy stats
enemy_armored_armor, enemy_armored_speed
enemy_raider_armor, enemy_raider_speed
enemy_scout_armor, enemy_scout_speed

# Midgame constants
midgame_food_bonus_amount, midgame_food_bonus_day
midgame_food_bonus_threshold
midgame_stone_catchup_day, midgame_stone_catchup_min
```

### Day Metrics (Per Sample Day)

```gdscript
# Resource caps
midgame_caps_food, midgame_caps_stone, midgame_caps_wood

# Food bonus (active after bonus day)
midgame_food_bonus

# Enemy scaling by day
enemy_armored_armor, enemy_raider_armor, enemy_scout_armor
enemy_armored_speed, enemy_raider_speed, enemy_scout_speed
enemy_armored_hp_bonus, enemy_raider_hp_bonus, enemy_scout_hp_bonus

# Wave totals at different threat levels
night_wave_total_base
night_wave_total_threat2
night_wave_total_threat4
```

## Balance Checks

The verification system runs these checks:

### Non-Decreasing Progressions
- Wave totals should not decrease over days
- Resource caps should not decrease
- Enemy HP bonuses should not decrease

### Wave Threat Ordering
```gdscript
# Must satisfy: base <= threat2 <= threat4
# And: threat2 = base + 2, threat4 = base + 4
```

### Day 7 Minimums
```gdscript
night_wave_total_base >= 7
enemy_armored_hp_bonus >= 4
enemy_raider_hp_bonus >= 2
enemy_scout_hp_bonus >= 1
enemy_armored_armor >= 2
enemy_raider_armor >= 1
enemy_scout_armor >= 1
enemy_armored_speed >= 2
enemy_raider_speed >= 2
enemy_scout_speed >= 3
midgame_caps_stone >= 35
midgame_caps_food >= 35
```

### Tower Progressions
```gdscript
# Damage: level1 <= level2 <= level3
# Shots: level1 <= level2 <= level3
tower_level2_damage >= 2
tower_level3_damage >= 3

# Upgrade costs: level1 <= level2
```

### Building Production Minimums
```gdscript
building_quarry_production_stone >= 3
building_lumber_production_wood >= 3
building_farm_production_food >= 3
```

### Building Cost Maximums
```gdscript
building_tower_cost_stone <= 8
building_tower_cost_wood <= 4
building_wall_cost_stone <= 4
building_wall_cost_wood <= 4
```

### Food Bonus Logic
```gdscript
# Bonus activates on day 4
midgame_food_bonus_day == 4

# Before day 4: bonus = 0
# Day 4+: bonus = midgame_food_bonus_amount
```

## Export JSON Schema

```json
{
  "schema": "typing-defense.balance-export",
  "schema_version": 1,
  "game": {
    "name": "Keyboard Defense",
    "version": "1.0.0"
  },
  "axis": "days",
  "metrics": ["building_farm_cost_wood", "..."],
  "samples": [
    {
      "id": "day_01",
      "values": {
        "building_farm_cost_wood": 5,
        "...": 0
      }
    }
  ]
}
```

## Usage Examples

### Running Balance Verification

```gdscript
# In-game command or test
var result = SimBalanceReport.balance_verify_output()
print(result)
# Output: "Balance verify: OK"
# Or: "Balance verify: FAIL\nFAIL: tower_damage progression invalid at day_01."
```

### Exporting Balance Data

```gdscript
# Export all metrics
var json = SimBalanceReport.balance_export_json("all")

# Export only enemy metrics
var enemy_json = SimBalanceReport.balance_export_json("enemies")

# Save to file
var result = SimBalanceReport.save_balance_export("all")
if result.ok:
    print("Saved to: ", result.path)
```

### Comparing Balance Changes

```gdscript
# After changing balance values, compare to baseline
var diff = SimBalanceReport.balance_diff_output("all")
print(diff)
# Output: "Balance diff: 3 changes
# day_01 enemy_scout_speed: 3 -> 4
# day_02 enemy_scout_speed: 3 -> 4
# day_03 enemy_scout_speed: 3 -> 4"
```

### Getting Summary Tables

```gdscript
# Default summary (key metrics)
print(SimBalanceReport.balance_summary_output())

# Category-specific summaries
print(SimBalanceReport.balance_summary_output("wave"))
print(SimBalanceReport.balance_summary_output("enemies"))
print(SimBalanceReport.balance_summary_output("towers"))
print(SimBalanceReport.balance_summary_output("buildings"))
print(SimBalanceReport.balance_summary_output("midgame"))
```

## Integration with Commands

The balance report integrates with the command system:

```gdscript
# In parse_command.gd
"balance":
    if tokens.size() > 1:
        match tokens[1]:
            "verify": return SimIntents.make("balance_verify")
            "export": return SimIntents.make("balance_export", {"group": tokens.get(2, "all")})
            "diff": return SimIntents.make("balance_diff", {"group": tokens.get(2, "all")})
            "summary": return SimIntents.make("balance_summary", {"group": tokens.get(2, "")})
```

## Adding New Balance Checks

To add a new validation check:

```gdscript
# 1. Add check function
static func _check_new_requirement(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var metric_value: float = float(values.get("metric_key", 0))
        if metric_value < 10.0:
            failures.append("metric_key must be >= 10 at %s" % sample_id)
            return

# 2. Call in run_balance_checks()
_check_new_requirement(samples, failures)
```

## Adding New Metrics

To track a new balance metric:

```gdscript
# 1. For base metrics (day-independent), add to _base_metrics()
metrics["new_metric"] = int(SomeSystem.get_value())

# 2. For day metrics (day-dependent), add to _day_metrics()
metrics["new_metric_per_day"] = int(SomeSystem.get_value_for_day(day))
```

## Testing Balance

```bash
# Run headless balance verification
godot --headless --path . --script res://tools/run_balance_verify.gd

# Export and review
godot --headless --path . --script res://tools/run_balance_export.gd
```

## File Dependencies

- `sim/types.gd` - GameState for day metrics
- `sim/balance.gd` - SimBalance constants and caps
- `sim/buildings.gd` - Building costs and production
- `sim/enemies.gd` - Enemy base stats
- `sim/tick.gd` - Wave total computation

## Version Tracking

The export includes game version from `res://VERSION.txt`:

```gdscript
static func read_game_version() -> String:
    var path: String = "res://VERSION.txt"
    if not FileAccess.file_exists(path):
        return "0.0.0"
    var text: String = FileAccess.get_file_as_string(path)
    return text.split("\n", false)[0].strip_edges()
```
