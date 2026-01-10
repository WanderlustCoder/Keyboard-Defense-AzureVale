# Scenario Testing Guide

This document explains the scenario testing harness used for automated game balance testing, regression testing, and headless verification of game mechanics.

## Overview

The scenario harness runs predefined command scripts against the sim:

```
Load Scenarios → Filter by Tags → Run Scripts → Evaluate Expectations → Generate Report
       ↓              ↓               ↓                  ↓                    ↓
  scenarios.json   --tag/--priority  Intent loop      baseline/target     JSON + summary
```

## Running Scenarios

### Command Line Usage

```bash
# Run all scenarios
godot --headless --path . --script res://tools/run_scenarios.gd

# Run specific scenario
godot --headless --path . --script res://tools/run_scenarios.gd -- --scenario early_game_build

# Filter by tag
godot --headless --path . --script res://tools/run_scenarios.gd -- --tag economy

# Filter by priority
godot --headless --path . --script res://tools/run_scenarios.gd -- --priority P0

# Exclude tag
godot --headless --path . --script res://tools/run_scenarios.gd -- --exclude-tag slow

# Output to file
godot --headless --path . --script res://tools/run_scenarios.gd -- --out reports/test.json

# Print per-scenario metrics
godot --headless --path . --script res://tools/run_scenarios.gd -- --print-metrics

# List available scenarios
godot --headless --path . --script res://tools/run_scenarios.gd -- --list
```

### CLI Options

| Option | Description |
|--------|-------------|
| `--list` | List scenario IDs without running |
| `--scenario <id>` | Run a single scenario by ID |
| `--tag <tag>` | Filter to scenarios with tag (repeatable) |
| `--exclude-tag <tag>` | Exclude scenarios with tag (repeatable) |
| `--priority <P0\|P1>` | Filter by priority level |
| `--out <path>` | Write report JSON to path |
| `--out-dir <path>` | Write report + summary to directory |
| `--enforce-targets` | Treat target expectations as failures |
| `--targets` | Evaluate and print target summary |
| `--print-metrics` | Print compact per-scenario metrics |

## Scenario JSON Schema

### Basic Structure

```json
{
  "scenarios": [
    {
      "id": "early_game_build",
      "seed": "test_seed_123",
      "description": "Verifies early game building sequence",
      "tags": ["economy", "buildings"],
      "priority": "P0",
      "script": [
        "build farm 3 3",
        "build tower 4 4",
        "# Comments are ignored",
        "end_day"
      ],
      "stop": {
        "type": "after_commands"
      },
      "expect_baseline": {
        "buildings_count": {"min": 2},
        "day": 2
      },
      "expect_target": {
        "resources_food": {"min": 50}
      }
    }
  ]
}
```

### Required Fields

```gdscript
# tools/scenario_harness/scenario_types.gd:8
static func required_keys() -> Array[String]:
    return ["id", "seed", "description", "tags", "priority", "script", "stop"]
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique scenario identifier |
| `seed` | String | RNG seed for determinism |
| `description` | String | Human-readable description |
| `tags` | Array | Tags for filtering |
| `priority` | String | "P0" or "P1" |
| `script` | Array | Command strings to execute |
| `stop` | Dictionary | Stop condition configuration |

### Stop Conditions

```gdscript
# tools/scenario_harness/scenario_types.gd:4
const VALID_STOP_TYPES := ["after_commands", "until_day", "until_phase"]
const DEFAULT_MAX_STEPS := 5000
```

| Type | Parameters | Description |
|------|------------|-------------|
| `after_commands` | - | Stop after script completes |
| `until_day` | `day: int` | Loop script until day reached |
| `until_phase` | `phase: String` | Loop script until phase reached |

```json
// Stop after script executes once
"stop": {"type": "after_commands"}

// Loop script until day 10
"stop": {"type": "until_day", "day": 10}

// Loop script until night phase
"stop": {"type": "until_phase", "phase": "night"}

// Custom step limit
"stop": {"type": "until_day", "day": 20, "max_steps": 10000}
```

### Expectations

Two expectation sets are supported:

| Set | Purpose | Failure Behavior |
|-----|---------|------------------|
| `expect_baseline` (or `expect`) | Minimum requirements | Always fail on mismatch |
| `expect_target` | Aspirational goals | Only fail with `--enforce-targets` |

#### Expectation Operators

```json
// Exact match
"day": 5

// Minimum value
"resources_wood": {"min": 100}

// Maximum value
"threat": {"max": 50}

// Range
"hp": {"min": 1, "max": 10}

// Exact match (explicit)
"phase": {"eq": "day"}
```

```gdscript
# tools/scenario_harness/scenario_types.gd:89
static func check_expect(metric_name: String, actual: Variant, spec: Variant) -> String:
    if spec is Dictionary:
        var dict: Dictionary = spec
        if dict.has("eq"):
            if actual != dict.get("eq"):
                return "expect %s eq %s (got %s)" % [metric_name, str(dict.eq), str(actual)]
            return ""
        var has_min: bool = dict.has("min")
        var has_max: bool = dict.has("max")
        if has_min and float(actual) < float(dict.get("min")):
            return "expect %s >= %s (got %s)" % [metric_name, str(dict.min), str(actual)]
        if has_max and float(actual) > float(dict.get("max")):
            return "expect %s <= %s (got %s)" % [metric_name, str(dict.max), str(actual)]
        return ""
    # Simple equality
    if actual != spec:
        return "expect %s eq %s (got %s)" % [metric_name, str(spec), str(actual)]
    return ""
```

## Available Metrics

The runner extracts these metrics from final game state:

```gdscript
# tools/scenario_harness/scenario_runner.gd:152
static func _extract_metrics(state: Object, typing_stats: SimTypingStats) -> Dictionary:
    return {
        "day": int(state.day),
        "phase": str(state.phase),
        "hp": int(state.hp),
        "ap": int(state.ap),
        "ap_max": int(state.ap_max),
        "threat": int(state.threat),
        "lesson_id": str(state.lesson_id),
        "night_wave_total": int(state.night_wave_total),
        "resources": state.resources.duplicate(true),
        "resources_wood": int(state.resources.get("wood", 0)),
        "resources_stone": int(state.resources.get("stone", 0)),
        "resources_food": int(state.resources.get("food", 0)),
        "buildings_count": _sum_buildings(state.buildings),
        "buildings_by_type": state.buildings.duplicate(true),
        "structures_count": int(state.structures.size()),
        "explored_count": max(0, int(state.discovered.size()) - 1),
        "enemies_alive": int(state.enemies.size()),
        "enemies_spawned": max(0, int(state.enemy_next_id) - 1),
        "enemies_killed": enemies_spawned - enemies_alive,
        "typing": typing_report,
        "typing_hit_rate": float,
        "typing_accuracy": float,
        "typing_backspace_rate": float,
        "typing_incomplete_rate": float
    }
```

### Nested Metric Access

Use dot notation for nested values:

```json
"expect_baseline": {
    "resources.wood": {"min": 100},
    "typing.hit_rate": {"min": 0.7}
}
```

```gdscript
# tools/scenario_harness/scenario_eval.gd:32
static func _lookup_metric(metrics: Dictionary, key: String) -> Dictionary:
    if metrics.has(key):
        return {"ok": true, "value": metrics.get(key)}
    if key.find(".") == -1:
        return {"ok": false}
    var current: Variant = metrics
    for part in key.split("."):
        if typeof(current) != TYPE_DICTIONARY:
            return {"ok": false}
        if not dict.has(part):
            return {"ok": false}
        current = dict.get(part)
    return {"ok": true, "value": current}
```

## Scenario Runner

### Execution Flow

```gdscript
# tools/scenario_harness/scenario_runner.gd:11
static func run(scenario: Dictionary, options: Dictionary = {}) -> Dictionary:
    # 1. Validate scenario
    var failures: Array[String] = ScenarioTypes.validate_scenario(scenario)
    if not failures.is_empty():
        return {"id": scenario_id, "pass": false, "failures": failures, ...}

    # 2. Create initial state with seed
    var state = DefaultState.create(seed_value)
    var typing_stats = SimTypingStats.new()
    var events: Array[String] = []

    # 3. Execute script commands
    while script_index < script.size():
        if step_count >= max_steps:
            failures.append("Stop condition not reached (cap hit)")
            break

        var command: String = str(script[script_index]).strip_edges()
        if command == "" or command.begins_with("#"):
            continue

        # Parse and apply command
        var parse: Dictionary = CommandParser.parse(command)
        if parse.get("ok", false):
            var result: Dictionary = IntentApplier.apply(state, parse.intent)
            state = result.get("state", state)
            for event in result.get("events", []):
                events.append(str(event))
        else:
            if state.phase == "night":
                # Treat as defend input during night
                intent = {"kind": "defend_input", "text": command}
            else:
                failures.append("parse failed: %s" % parse.error)
                break

        # Check stop condition
        if _stop_condition_met(stop, state):
            stop_met = true
            break

        # Loop script for until_day/until_phase modes
        if stop_type != "after_commands" and script_index >= script.size():
            script_index = 0

    # 4. Extract metrics and evaluate expectations
    var metrics: Dictionary = _extract_metrics(state, typing_stats)
    var eval_result: Dictionary = ScenarioEval.evaluate_sets(metrics, baseline, target)

    return {
        "id": scenario_id,
        "pass": failures.is_empty(),
        "failures": failures,
        "metrics": metrics,
        "events": events,
        "baseline_failures": eval_result.baseline_failures,
        "target_failures": eval_result.target_failures,
        ...
    }
```

## Report Generation

### Report Structure

```gdscript
# tools/scenario_harness/scenario_report.gd:4
static func build_report(results: Array, meta: Dictionary) -> Dictionary:
    return {
        "meta": meta,
        "summary": {
            "total": results.size(),
            "ok": ok_count,
            "fail": fail_count,
            "failed_ids": ["scenario_1", "scenario_2"],
            "baseline_pass_count": baseline_pass_count,
            "target_met_count": target_met_count,
            "target_total_count": target_total_count
        },
        "results": results
    }
```

### Output Files

| File | Content |
|------|---------|
| `{timestamp}.json` | Full report with all results |
| `last_summary.txt` | Quick text summary |

```
[scenarios] report user://scenario_reports/1234567890.json
[targets] MET 5/8
[scenarios] OK 10
```

Or on failure:
```
[scenarios] FAIL early_game_build, night_defense
```

## Scenario Loader

```gdscript
# tools/scenario_harness/scenario_loader.gd:6
static func load_scenarios(path: String = "res://data/scenarios.json") -> Dictionary:
    if not FileAccess.file_exists(path):
        return {"ok": false, "error": "Scenario file not found"}

    var raw_text: String = FileAccess.get_file_as_string(path)
    var parsed: Variant = JSON.parse_string(raw_text)

    if not data.has("scenarios") or not (data.get("scenarios") is Array):
        return {"ok": false, "error": "Missing scenarios array"}

    # Validate each scenario
    var errors: Array[String] = []
    for scenario in scenarios:
        var scenario_errors: Array[String] = ScenarioTypes.validate_scenario(scenario)
        for err in scenario_errors:
            errors.append("%s (%s)" % [err, scenario.id])

    if not errors.is_empty():
        return {"ok": false, "error": "Validation failed", "errors": errors}

    return {"ok": true, "data": data}
```

## Filtering

```gdscript
# tools/scenario_harness/scenario_types.gd:54
static func matches_filters(
    scenario: Dictionary,
    tags: Array[String],
    exclude_tags: Array[String],
    priority: String
) -> bool:
    # Priority filter
    if priority != "":
        if scenario.priority != priority.to_upper():
            return false

    # Tag filters (must have ALL specified tags)
    var scenario_tags: Array[String] = normalize_tags(scenario.tags)
    for tag in tags:
        if not scenario_tags.has(tag.to_lower()):
            return false

    # Exclude filters (must not have ANY excluded tags)
    for tag in exclude_tags:
        if scenario_tags.has(tag.to_lower()):
            return false

    return true
```

## Example Scenarios

### Economy Test

```json
{
    "id": "resource_production",
    "seed": "economy_test",
    "description": "Verify resource production over 5 days",
    "tags": ["economy", "regression"],
    "priority": "P0",
    "script": [
        "build farm 3 3",
        "build lumberyard 4 3",
        "assign 3 3",
        "assign 4 3",
        "end_day"
    ],
    "stop": {"type": "until_day", "day": 5},
    "expect_baseline": {
        "day": 5,
        "resources_food": {"min": 20},
        "resources_wood": {"min": 30}
    }
}
```

### Combat Test

```json
{
    "id": "night_survival",
    "seed": "combat_test",
    "description": "Verify night defense with typing",
    "tags": ["combat", "typing"],
    "priority": "P0",
    "script": [
        "build tower 4 4",
        "end_day",
        "# Night phase - typing commands",
        "enemy",
        "attack",
        "defend"
    ],
    "stop": {"type": "until_phase", "phase": "day"},
    "expect_baseline": {
        "hp": {"min": 1},
        "typing_hit_rate": {"min": 0.5}
    }
}
```

### Balance Regression

```json
{
    "id": "day10_checkpoint",
    "seed": "balance_regression",
    "description": "Check economy state at day 10",
    "tags": ["balance", "regression", "slow"],
    "priority": "P1",
    "script": [
        "build farm 3 3",
        "build lumberyard 4 3",
        "build quarry 5 3",
        "end_day"
    ],
    "stop": {"type": "until_day", "day": 10, "max_steps": 10000},
    "expect_baseline": {
        "day": 10,
        "buildings_count": {"min": 5}
    },
    "expect_target": {
        "resources_wood": {"min": 200},
        "resources_stone": {"min": 150},
        "resources_food": {"min": 100}
    }
}
```

## CI Integration

```bash
#!/bin/bash
# ci/run_scenarios.sh

# Run P0 scenarios (must pass)
godot --headless --path apps/keyboard-defense-godot \
    --script res://tools/run_scenarios.gd -- \
    --priority P0 \
    --out-dir ci_reports

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "P0 scenarios failed!"
    cat ci_reports/last_summary.txt
    exit 1
fi

# Run P1 with target evaluation (informational)
godot --headless --path apps/keyboard-defense-godot \
    --script res://tools/run_scenarios.gd -- \
    --priority P1 \
    --targets \
    --out-dir ci_reports

echo "All scenarios complete"
cat ci_reports/last_summary.txt
```

## Testing the Harness

```gdscript
func test_scenario_validation():
    var valid := {
        "id": "test",
        "seed": "seed",
        "description": "Test",
        "tags": ["test"],
        "priority": "P0",
        "script": ["end_day"],
        "stop": {"type": "after_commands"}
    }
    var errors := ScenarioTypes.validate_scenario(valid)
    assert(errors.is_empty())

    var missing_id := valid.duplicate()
    missing_id.erase("id")
    errors = ScenarioTypes.validate_scenario(missing_id)
    assert(errors.has("missing key: id"))

    _pass("test_scenario_validation")

func test_expectation_check():
    # Exact match
    var result := ScenarioTypes.check_expect("day", 5, 5)
    assert(result == "")

    result = ScenarioTypes.check_expect("day", 5, 10)
    assert(result != "")

    # Min check
    result = ScenarioTypes.check_expect("wood", 100, {"min": 50})
    assert(result == "")

    result = ScenarioTypes.check_expect("wood", 30, {"min": 50})
    assert(result != "")

    _pass("test_expectation_check")

func test_tag_filtering():
    var scenario := {"tags": ["economy", "balance"], "priority": "P0"}

    assert(ScenarioTypes.matches_filters(scenario, ["economy"], [], ""))
    assert(ScenarioTypes.matches_filters(scenario, [], [], "P0"))
    assert(not ScenarioTypes.matches_filters(scenario, ["combat"], [], ""))
    assert(not ScenarioTypes.matches_filters(scenario, [], ["economy"], ""))

    _pass("test_tag_filtering")
```
