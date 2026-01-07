class_name ScenarioTypes
extends RefCounted

const VALID_STOP_TYPES := ["after_commands", "until_day", "until_phase"]
const VALID_PRIORITIES := ["P0", "P1"]
const DEFAULT_MAX_STEPS := 5000

static func required_keys() -> Array[String]:
    return ["id", "seed", "description", "tags", "priority", "script", "stop"]

static func validate_scenario(scenario: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    for key in required_keys():
        if not scenario.has(key):
            errors.append("missing key: %s" % key)
    if scenario.has("script") and not (scenario.get("script") is Array):
        errors.append("script must be an array")
    if scenario.has("stop") and not (scenario.get("stop") is Dictionary):
        errors.append("stop must be an object")
    if scenario.has("tags") and not (scenario.get("tags") is Array):
        errors.append("tags must be an array")
    if scenario.has("priority"):
        var priority: String = str(scenario.get("priority", "")).to_upper()
        if not VALID_PRIORITIES.has(priority):
            errors.append("priority must be one of: %s" % ", ".join(VALID_PRIORITIES))
    if scenario.has("stop"):
        var stop_type: String = str(scenario.get("stop", {}).get("type", "after_commands")).to_lower()
        if not VALID_STOP_TYPES.has(stop_type):
            errors.append("unsupported stop type: %s" % stop_type)
        if stop_type == "until_day":
            if not scenario.get("stop", {}).has("day"):
                errors.append("until_day requires day")
        if stop_type == "until_phase":
            if not scenario.get("stop", {}).has("phase"):
                errors.append("until_phase requires phase")
    return errors

static func normalize_stop(stop: Dictionary) -> Dictionary:
    var normalized: Dictionary = stop.duplicate(true)
    var stop_type: String = str(normalized.get("type", "after_commands")).to_lower()
    normalized["type"] = stop_type
    var max_steps: int = int(normalized.get("max_steps", DEFAULT_MAX_STEPS))
    if max_steps <= 0:
        max_steps = DEFAULT_MAX_STEPS
    normalized["max_steps"] = max_steps
    return normalized

static func normalize_tags(tags: Array) -> Array[String]:
    var normalized: Array[String] = []
    for tag in tags:
        normalized.append(str(tag).to_lower())
    return normalized

static func matches_filters(
    scenario: Dictionary,
    tags: Array[String],
    exclude_tags: Array[String],
    priority: String
) -> bool:
    if priority != "":
        var scenario_priority: String = str(scenario.get("priority", "")).to_upper()
        if scenario_priority != priority.to_upper():
            return false
    var scenario_tags: Array[String] = normalize_tags(scenario.get("tags", []))
    if not tags.is_empty():
        for tag in tags:
            if not scenario_tags.has(str(tag).to_lower()):
                return false
    if not exclude_tags.is_empty():
        for tag in exclude_tags:
            if scenario_tags.has(str(tag).to_lower()):
                return false
    return true

static func filter_scenarios(
    scenarios: Array,
    tags: Array[String],
    exclude_tags: Array[String],
    priority: String
) -> Array:
    var filtered: Array = []
    for scenario in scenarios:
        if typeof(scenario) != TYPE_DICTIONARY:
            continue
        if matches_filters(scenario, tags, exclude_tags, priority):
            filtered.append(scenario)
    return filtered

static func check_expect(metric_name: String, actual: Variant, spec: Variant) -> String:
    if spec is Dictionary:
        var dict: Dictionary = spec
        if dict.has("eq"):
            var expected: Variant = dict.get("eq")
            if actual != expected:
                return "expect %s eq %s (got %s)" % [metric_name, str(expected), str(actual)]
            return ""
        var has_min: bool = dict.has("min")
        var has_max: bool = dict.has("max")
        if has_min or has_max:
            if typeof(actual) != TYPE_INT and typeof(actual) != TYPE_FLOAT:
                return "expect %s range requires numeric actual (got %s)" % [metric_name, str(actual)]
            var actual_val: float = float(actual)
            if has_min and actual_val < float(dict.get("min", actual_val)):
                return "expect %s >= %s (got %s)" % [metric_name, str(dict.get("min")), str(actual)]
            if has_max and actual_val > float(dict.get("max", actual_val)):
                return "expect %s <= %s (got %s)" % [metric_name, str(dict.get("max")), str(actual)]
            return ""
        return "expect %s missing eq/min/max" % metric_name

    if actual != spec:
        return "expect %s eq %s (got %s)" % [metric_name, str(spec), str(actual)]
    return ""

