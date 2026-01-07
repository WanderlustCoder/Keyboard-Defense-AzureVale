class_name ScenarioLoader
extends RefCounted

const ScenarioTypes = preload("res://tools/scenario_harness/scenario_types.gd")

static func load_scenarios(path: String = "res://data/scenarios.json") -> Dictionary:
    if not FileAccess.file_exists(path):
        return {
            "ok": false,
            "error": "Scenario file not found: %s" % path
        }
    var raw_text: String = FileAccess.get_file_as_string(path)
    if raw_text.strip_edges() == "":
        return {
            "ok": false,
            "error": "Scenario file is empty: %s" % path
        }
    var parsed: Variant = JSON.parse_string(raw_text)
    if parsed == null or not (parsed is Dictionary):
        return {
            "ok": false,
            "error": "Scenario file must be a JSON object: %s" % path
        }
    var data: Dictionary = parsed
    if not data.has("scenarios") or not (data.get("scenarios") is Array):
        return {
            "ok": false,
            "error": "Scenario file missing scenarios array: %s" % path
        }
    var errors: Array[String] = []
    var scenarios: Array = data.get("scenarios", [])
    for scenario in scenarios:
        if not (scenario is Dictionary):
            errors.append("scenario entry must be an object")
            continue
        var scenario_errors: Array[String] = ScenarioTypes.validate_scenario(scenario)
        for err in scenario_errors:
            errors.append("%s (%s)" % [err, str(scenario.get("id", "unknown"))])
    if not errors.is_empty():
        return {
            "ok": false,
            "error": "Scenario validation failed",
            "errors": errors
        }
    return {
        "ok": true,
        "data": data
    }

