class_name ScenarioRunner
extends RefCounted

const DefaultState = preload("res://sim/default_state.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const ScenarioTypes = preload("res://tools/scenario_harness/scenario_types.gd")
const ScenarioEval = preload("res://tools/scenario_harness/scenario_eval.gd")
const SimTypingStats = preload("res://sim/typing_stats.gd")

static func run(scenario: Dictionary, options: Dictionary = {}) -> Dictionary:
    var failures: Array[String] = ScenarioTypes.validate_scenario(scenario)
    var scenario_id: String = str(scenario.get("id", "unknown"))
    var enforce_targets: bool = bool(options.get("enforce_targets", false))
    if not failures.is_empty():
        return {
            "id": scenario_id,
            "pass": false,
            "failures": failures,
            "metrics": {},
            "events": [],
            "baseline_failures": [],
            "target_failures": [],
            "baseline_expected": false,
            "target_expected": false
        }

    var seed_value: String = str(scenario.get("seed", "default"))
    var state = DefaultState.create(seed_value)
    var typing_stats = SimTypingStats.new()
    var events: Array[String] = []
    var stop: Dictionary = ScenarioTypes.normalize_stop(scenario.get("stop", {}))
    var stop_type: String = str(stop.get("type", "after_commands"))
    var stop_met: bool = false
    var stop_reason: String = ""
    var script: Array = scenario.get("script", [])
    var command_index: int = 0
    var step_count: int = 0
    var max_steps: int = int(stop.get("max_steps", 0))
    var script_index: int = 0
    var has_command: bool = false

    for line in script:
        var command: String = str(line).strip_edges()
        if command != "" and not command.begins_with("#"):
            has_command = true
            break

    if max_steps <= 0:
        max_steps = 5000

    while script_index < script.size():
        if step_count >= max_steps:
            failures.append("Stop condition not reached (cap hit)")
            stop_reason = "cap_hit"
            break
        var line: Variant = script[script_index]
        script_index += 1
        var command: String = str(line).strip_edges()
        if command == "" or command.begins_with("#"):
            continue
        step_count += 1
        command_index += 1
        var parse: Dictionary = CommandParser.parse(command)
        var intent: Dictionary = {}
        if parse.get("ok", false):
            intent = parse.intent
        else:
            if state.phase == "night":
                intent = {"kind": "defend_input", "text": command}
            else:
                failures.append("parse failed: %s" % str(parse.get("error", "unknown")))
                break
        var kind: String = str(intent.get("kind", ""))
        if kind.begins_with("ui_"):
            events.append("ui intent skipped: %s" % kind)
        else:
            if kind == "defend_input":
                typing_stats.record_defend_attempt(str(intent.get("text", "")), state.enemies)
            var result: Dictionary = IntentApplier.apply(state, intent)
            state = result.get("state", state)
            var step_events: Array = result.get("events", [])
            for event in step_events:
                events.append(str(event))
        if _stop_condition_met(stop, state):
            stop_met = true
            stop_reason = stop_type
            break
        if stop_type != "after_commands" and script_index >= script.size() and has_command:
            script_index = 0

    if not has_command:
        failures.append("script contains no executable commands")
    elif stop_type == "after_commands":
        stop_met = true
        stop_reason = "after_commands"
    elif stop_type != "after_commands" and not stop_met and stop_reason == "":
        failures.append("stop condition not reached (cap hit)")
        stop_reason = "cap_hit"

    var metrics: Dictionary = _extract_metrics(state, typing_stats)
    var baseline_expect: Dictionary = {}
    if scenario.get("expect_baseline") is Dictionary:
        baseline_expect = scenario.get("expect_baseline", {})
    elif scenario.get("expect") is Dictionary:
        baseline_expect = scenario.get("expect", {})
    var target_expect: Dictionary = {}
    if scenario.get("expect_target") is Dictionary:
        target_expect = scenario.get("expect_target", {})
    var eval_result: Dictionary = ScenarioEval.evaluate_sets(metrics, baseline_expect, target_expect)
    var baseline_failures: Array = eval_result.get("baseline_failures", [])
    var target_failures: Array = eval_result.get("target_failures", [])
    for failure in baseline_failures:
        failures.append(str(failure))
    var target_expected: bool = not target_expect.is_empty()
    if enforce_targets and target_expected:
        for failure in target_failures:
            failures.append("target: %s" % str(failure))

    return {
        "id": scenario_id,
        "pass": failures.is_empty(),
        "failures": failures,
        "metrics": metrics,
        "events": events,
        "baseline_failures": baseline_failures,
        "target_failures": target_failures,
        "baseline_expected": not baseline_expect.is_empty(),
        "target_expected": target_expected,
        "stop": {
            "type": stop_type,
            "met": stop_met,
            "reason": stop_reason,
            "commands": command_index,
            "steps": step_count,
            "max_steps": max_steps
        }
    }

static func _stop_condition_met(stop: Dictionary, state: Object) -> bool:
    var stop_type: String = str(stop.get("type", "after_commands"))
    match stop_type:
        "until_day":
            return int(state.day) >= int(stop.get("day", 0))
        "until_phase":
            return str(state.phase) == str(stop.get("phase", ""))
        "after_commands":
            return false
        _:
            return false

static func _extract_metrics(state: Object, typing_stats: SimTypingStats) -> Dictionary:
    var metrics: Dictionary = {}
    metrics["day"] = int(state.day)
    metrics["phase"] = str(state.phase)
    metrics["hp"] = int(state.hp)
    metrics["ap"] = int(state.ap)
    metrics["ap_max"] = int(state.ap_max)
    metrics["threat"] = int(state.threat)
    metrics["lesson_id"] = str(state.lesson_id)
    metrics["night_wave_total"] = int(state.night_wave_total)
    metrics["resources"] = state.resources.duplicate(true)
    metrics["resources_wood"] = int(state.resources.get("wood", 0))
    metrics["resources_stone"] = int(state.resources.get("stone", 0))
    metrics["resources_food"] = int(state.resources.get("food", 0))
    metrics["buildings_count"] = _sum_buildings(state.buildings)
    metrics["buildings_by_type"] = state.buildings.duplicate(true)
    metrics["structures_count"] = int(state.structures.size())
    metrics["explored_count"] = max(0, int(state.discovered.size()) - 1)
    metrics["enemies_alive"] = int(state.enemies.size())
    metrics["enemies_spawned"] = max(0, int(state.enemy_next_id) - 1)
    metrics["enemies_killed"] = max(0, int(metrics["enemies_spawned"]) - int(metrics["enemies_alive"]))

    var typing_report: Dictionary = typing_stats.to_report_dict()
    metrics["typing"] = typing_report.duplicate(true)
    metrics["typing_hit_rate"] = float(typing_report.get("hit_rate", 0.0))
    metrics["typing_accuracy"] = float(typing_report.get("avg_accuracy", 0.0))
    metrics["typing_backspace_rate"] = float(typing_report.get("backspace_rate", 0.0))
    metrics["typing_incomplete_rate"] = float(typing_report.get("incomplete_rate", 0.0))
    return metrics

static func _sum_buildings(buildings: Dictionary) -> int:
    var total: int = 0
    for key in buildings.keys():
        total += int(buildings.get(key, 0))
    return total

