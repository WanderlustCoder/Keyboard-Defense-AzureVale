class_name ScenarioEval
extends RefCounted

const ScenarioTypes = preload("res://tools/scenario_harness/scenario_types.gd")

static func evaluate(metrics: Dictionary, expect: Dictionary) -> Array[String]:
    var failures: Array[String] = []
    if expect.is_empty():
        return failures
    for key in expect.keys():
        var lookup: Dictionary = _lookup_metric(metrics, str(key))
        if not bool(lookup.get("ok", false)):
            failures.append("missing metric: %s" % key)
            continue
        var check: String = ScenarioTypes.check_expect(str(key), lookup.get("value"), expect.get(key))
        if check != "":
            failures.append(check)
    return failures

static func evaluate_sets(metrics: Dictionary, baseline: Variant, target: Variant) -> Dictionary:
    var baseline_dict: Dictionary = {}
    var target_dict: Dictionary = {}
    if baseline is Dictionary:
        baseline_dict = baseline
    if target is Dictionary:
        target_dict = target
    return {
        "baseline_failures": evaluate(metrics, baseline_dict),
        "target_failures": evaluate(metrics, target_dict)
    }

static func _lookup_metric(metrics: Dictionary, key: String) -> Dictionary:
    if metrics.has(key):
        return {"ok": true, "value": metrics.get(key)}
    if key.find(".") == -1:
        return {"ok": false}
    var current: Variant = metrics
    for part in key.split("."):
        if typeof(current) != TYPE_DICTIONARY:
            return {"ok": false}
        var dict: Dictionary = current
        if not dict.has(part):
            return {"ok": false}
        current = dict.get(part)
    return {"ok": true, "value": current}

