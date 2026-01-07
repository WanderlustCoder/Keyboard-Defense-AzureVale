class_name SimBalanceReport
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBalance = preload("res://sim/balance.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimTick = preload("res://sim/tick.gd")

const SCHEMA_ID := "typing-defense.balance-export"
const SCHEMA_VERSION := 1
const GAME_NAME := "Keyboard Defense"
const AXIS_NAME := "days"
const SAMPLE_DAYS := [1, 2, 3, 4, 5, 6, 7]
const SAVE_PATH := "user://balance_export.json"
const SAVE_LINE := "Saved to user://balance_export.json"
const EXPORT_GROUPS := {
    "all": [],
    "wave": ["night_wave_"],
    "enemies": ["enemy_"],
    "towers": ["tower_", "tower_upgrade"],
    "buildings": ["building_"],
    "midgame": ["midgame_"]
}
const SUMMARY_TITLE := "Balance summary (days):"
const SUMMARY_HEADER := "id | night_wave_total_base | night_wave_total_threat2 | night_wave_total_threat4 | enemy_scout_speed | tower_level1_damage"
const SUMMARY_METRICS := [
    "night_wave_total_base",
    "night_wave_total_threat2",
    "night_wave_total_threat4",
    "enemy_scout_speed",
    "tower_level1_damage"
]
const SUMMARY_WAVE_TITLE := "Balance summary (days/wave):"
const SUMMARY_WAVE_HEADER := "id | night_wave_total_base | night_wave_total_threat2 | night_wave_total_threat4"
const SUMMARY_WAVE_METRICS := [
    "night_wave_total_base",
    "night_wave_total_threat2",
    "night_wave_total_threat4"
]
const SUMMARY_ENEMIES_TITLE := "Balance summary (days/enemies):"
const SUMMARY_ENEMIES_HEADER := "id | enemy_scout_hp_bonus | enemy_raider_hp_bonus | enemy_armored_hp_bonus | enemy_scout_speed | enemy_raider_speed | enemy_armored_speed"
const SUMMARY_ENEMIES_METRICS := [
    "enemy_scout_hp_bonus",
    "enemy_raider_hp_bonus",
    "enemy_armored_hp_bonus",
    "enemy_scout_speed",
    "enemy_raider_speed",
    "enemy_armored_speed"
]
const SUMMARY_TOWERS_TITLE := "Balance summary (days/towers):"
const SUMMARY_TOWERS_HEADER := "id | tower_level1_damage | tower_level1_shots | tower_level2_damage | tower_level2_shots | tower_level3_damage | tower_level3_shots"
const SUMMARY_TOWERS_METRICS := [
    "tower_level1_damage",
    "tower_level1_shots",
    "tower_level2_damage",
    "tower_level2_shots",
    "tower_level3_damage",
    "tower_level3_shots"
]
const SUMMARY_BUILDINGS_TITLE := "Balance summary (days/buildings):"
const SUMMARY_BUILDINGS_HEADER := "id | building_farm_cost_wood | building_farm_production_food | building_lumber_cost_food | building_lumber_cost_wood | building_lumber_production_wood | building_quarry_cost_food | building_quarry_cost_wood | building_quarry_production_stone | building_tower_cost_stone | building_tower_cost_wood | building_wall_cost_stone | building_wall_cost_wood"
const SUMMARY_BUILDINGS_METRICS := [
    "building_farm_cost_wood",
    "building_farm_production_food",
    "building_lumber_cost_food",
    "building_lumber_cost_wood",
    "building_lumber_production_wood",
    "building_quarry_cost_food",
    "building_quarry_cost_wood",
    "building_quarry_production_stone",
    "building_tower_cost_stone",
    "building_tower_cost_wood",
    "building_wall_cost_stone",
    "building_wall_cost_wood"
]
const SUMMARY_MIDGAME_TITLE := "Balance summary (days/midgame):"
const SUMMARY_MIDGAME_HEADER := "id | midgame_caps_food | midgame_caps_wood | midgame_caps_stone | midgame_food_bonus_day | midgame_food_bonus_amount | midgame_food_bonus_threshold | midgame_food_bonus | midgame_stone_catchup_day | midgame_stone_catchup_min"
const SUMMARY_MIDGAME_METRICS := [
    "midgame_caps_food",
    "midgame_caps_wood",
    "midgame_caps_stone",
    "midgame_food_bonus_day",
    "midgame_food_bonus_amount",
    "midgame_food_bonus_threshold",
    "midgame_food_bonus",
    "midgame_stone_catchup_day",
    "midgame_stone_catchup_min"
]

static func balance_verify_output() -> String:
    var failures: Array[String] = run_balance_checks()
    if failures.is_empty():
        return "Balance verify: OK"
    var lines: Array[String] = ["Balance verify: FAIL"]
    for failure in failures:
        lines.append("FAIL: %s" % str(failure))
    return "\n".join(lines)

static func balance_export_json(group: String = "all") -> String:
    var normalized: String = _normalize_group(group)
    if normalized == "":
        return "Balance export: unknown group %s" % group
    var payload: Dictionary = build_balance_export_payload(normalized)
    return format_balance_export_json(payload)

static func save_balance_export(group: String = "all") -> Dictionary:
    var normalized: String = _normalize_group(group)
    if normalized == "":
        return {"ok": false, "line": "Balance export save: unknown group %s" % group}
    var payload: Dictionary = build_balance_export_payload(normalized)
    var json_text: String = format_balance_export_json(payload)
    var path: String = _export_path_for_group(normalized)
    var line: String = "Saved to %s" % path
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(json_text)
        file.close()
    return {"ok": true, "path": path, "json": json_text, "line": line}

static func balance_diff_output(group: String = "all") -> String:
    var normalized: String = _normalize_group(group)
    if normalized == "":
        return "Balance diff: unknown group %s" % group
    var path: String = _baseline_path_for_group(normalized)
    if not FileAccess.file_exists(path):
        return "Balance diff: missing baseline %s" % path
    var baseline_text: String = FileAccess.get_file_as_string(path)
    var baseline_parsed: Variant = JSON.parse_string(baseline_text)
    if typeof(baseline_parsed) != TYPE_DICTIONARY:
        return "Balance diff: invalid baseline %s" % path
    var baseline: Dictionary = baseline_parsed
    var current: Dictionary = build_balance_export_payload(normalized)
    if not _baseline_shape_matches(baseline, current):
        return "Balance diff: invalid baseline %s" % path
    var diff_lines: Array[String] = _build_balance_diff_lines(baseline, current)
    if diff_lines.is_empty():
        return "Balance diff: no changes"
    var lines: Array[String] = ["Balance diff: %d changes" % diff_lines.size()]
    lines.append_array(diff_lines)
    return "\n".join(lines)

static func balance_summary_output(group: String = "") -> String:
    return "\n".join(build_balance_summary_lines(group))

static func build_balance_summary_lines(group: String = "") -> Array[String]:
    var normalized: String = group.strip_edges().to_lower()
    if normalized == "":
        return _build_summary_lines(SUMMARY_TITLE, SUMMARY_HEADER, SUMMARY_METRICS)
    if normalized == "wave":
        return _build_summary_lines(SUMMARY_WAVE_TITLE, SUMMARY_WAVE_HEADER, SUMMARY_WAVE_METRICS)
    if normalized == "enemies":
        return _build_summary_lines(SUMMARY_ENEMIES_TITLE, SUMMARY_ENEMIES_HEADER, SUMMARY_ENEMIES_METRICS)
    if normalized == "towers":
        return _build_summary_lines(SUMMARY_TOWERS_TITLE, SUMMARY_TOWERS_HEADER, SUMMARY_TOWERS_METRICS)
    if normalized == "buildings":
        return _build_summary_lines(SUMMARY_BUILDINGS_TITLE, SUMMARY_BUILDINGS_HEADER, SUMMARY_BUILDINGS_METRICS)
    if normalized == "midgame":
        return _build_summary_lines(SUMMARY_MIDGAME_TITLE, SUMMARY_MIDGAME_HEADER, SUMMARY_MIDGAME_METRICS)
    return ["Balance summary: unknown group %s" % group]

static func build_balance_export_payload(group: String = "all") -> Dictionary:
    var normalized: String = _normalize_group(group)
    if normalized == "":
        normalized = "all"
    var base_metrics: Dictionary = _base_metrics()
    var samples: Array = []
    for day in SAMPLE_DAYS:
        var values: Dictionary = base_metrics.duplicate(true)
        var day_metrics: Dictionary = _day_metrics(day)
        for key in day_metrics.keys():
            values[key] = day_metrics[key]
        samples.append({"id": _day_id(day), "values": values})
    samples.sort_custom(Callable(SimBalanceReport, "_sort_sample_entry"))
    var metrics: Array[String] = _sorted_metric_keys(base_metrics, _day_metrics(1))
    metrics = _filter_metrics(metrics, normalized)
    for sample in samples:
        var values: Dictionary = sample.get("values", {})
        var filtered: Dictionary = {}
        for key in metrics:
            if values.has(key):
                filtered[key] = values[key]
            else:
                filtered[key] = 0
        sample["values"] = filtered
    return {
        "schema": SCHEMA_ID,
        "schema_version": SCHEMA_VERSION,
        "game": {"name": GAME_NAME, "version": read_game_version()},
        "axis": AXIS_NAME,
        "metrics": metrics,
        "samples": samples
    }

static func format_balance_export_json(payload: Dictionary) -> String:
    var ordered: Dictionary = {}
    ordered["schema"] = str(payload.get("schema", SCHEMA_ID))
    ordered["schema_version"] = int(payload.get("schema_version", SCHEMA_VERSION))
    var game_raw: Variant = payload.get("game", {})
    var game_ordered: Dictionary = {}
    if typeof(game_raw) == TYPE_DICTIONARY:
        game_ordered["name"] = str(game_raw.get("name", GAME_NAME))
        game_ordered["version"] = str(game_raw.get("version", read_game_version()))
    else:
        game_ordered["name"] = GAME_NAME
        game_ordered["version"] = read_game_version()
    ordered["game"] = game_ordered
    ordered["axis"] = str(payload.get("axis", AXIS_NAME))
    var metrics: Array[String] = []
    var metrics_raw: Variant = payload.get("metrics", [])
    if typeof(metrics_raw) == TYPE_ARRAY:
        for entry in metrics_raw:
            metrics.append(str(entry))
    metrics.sort()
    ordered["metrics"] = metrics
    var samples_out: Array = []
    var samples_raw: Variant = payload.get("samples", [])
    if typeof(samples_raw) == TYPE_ARRAY:
        for entry in samples_raw:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var sample_id: String = str(entry.get("id", ""))
            var values_raw: Variant = entry.get("values", {})
            var values_ordered: Dictionary = {}
            for key in metrics:
                var value: Variant = 0
                if typeof(values_raw) == TYPE_DICTIONARY and values_raw.has(key):
                    value = values_raw.get(key)
                values_ordered[key] = _numeric_value(value)
            samples_out.append({"id": sample_id, "values": values_ordered})
    samples_out.sort_custom(Callable(SimBalanceReport, "_sort_sample_entry"))
    ordered["samples"] = samples_out
    return JSON.stringify(ordered, "  ")

static func run_balance_checks() -> Array[String]:
    var payload: Dictionary = build_balance_export_payload()
    var metrics: Array[String] = []
    var raw_metrics: Variant = payload.get("metrics", [])
    if typeof(raw_metrics) == TYPE_ARRAY:
        for entry in raw_metrics:
            metrics.append(str(entry))
    metrics.sort()
    var samples: Array = payload.get("samples", [])
    samples.sort_custom(Callable(SimBalanceReport, "_sort_sample_entry"))
    var failures: Array[String] = []
    if samples.is_empty():
        failures.append("No samples defined.")
        return failures
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            failures.append("Invalid sample entry.")
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        for key in metrics:
            if not values.has(key):
                failures.append("Missing %s in %s." % [key, sample_id])
                continue
            var value: Variant = values.get(key)
            var value_type: int = typeof(value)
            if value_type != TYPE_INT and value_type != TYPE_FLOAT:
                failures.append("Non-numeric %s in %s." % [key, sample_id])
            elif value_type == TYPE_FLOAT and (is_nan(float(value)) or is_inf(float(value))):
                failures.append("Non-finite %s in %s." % [key, sample_id])

    _check_non_decreasing("night_wave_total_base", samples, failures)
    _check_non_decreasing("midgame_caps_wood", samples, failures)
    _check_non_decreasing("midgame_caps_stone", samples, failures)
    _check_non_decreasing("midgame_caps_food", samples, failures)
    _check_non_decreasing("enemy_armored_hp_bonus", samples, failures)
    _check_non_decreasing("enemy_raider_hp_bonus", samples, failures)
    _check_non_decreasing("enemy_scout_hp_bonus", samples, failures)
    _check_wave_threat_order(samples, failures)
    _check_wave_threat_offsets(samples, failures)
    _check_wave_base_min(samples, failures)
    _check_wave_day07_base_min(samples, failures)
    _check_enemy_hp_bonus_min(samples, failures)
    _check_enemy_armored_hp_bonus_day07_min(samples, failures)
    _check_enemy_raider_hp_bonus_day07_min(samples, failures)
    _check_enemy_scout_hp_bonus_day07_min(samples, failures)
    _check_enemy_armored_armor_day07_min(samples, failures)
    _check_enemy_raider_armor_day07_min(samples, failures)
    _check_enemy_scout_armor_day07_min(samples, failures)
    _check_enemy_armored_speed_day07_min(samples, failures)
    _check_enemy_raider_speed_day07_min(samples, failures)
    _check_enemy_scout_speed_day07_min(samples, failures)
    _check_tower_damage_progression(samples, failures)
    _check_tower_damage_min(samples, failures)
    _check_tower_shots_progression(samples, failures)
    _check_tower_upgrade_cost_min(samples, failures)
    _check_tower_upgrade_cost_order(samples, failures)
    _check_food_bonus(samples, failures)
    _check_midgame_food_bonus_day_exact(samples, failures)
    _check_midgame_food_bonus_boundary(samples, failures)
    _check_midgame_caps_stone_floor(samples, failures)
    _check_midgame_caps_food_floor(samples, failures)
    _check_midgame_stone_catchup_min_floor(samples, failures)
    _check_building_quarry_production_min(samples, failures)
    _check_building_lumber_production_min(samples, failures)
    _check_building_farm_production_min(samples, failures)
    _check_building_tower_cost_max(samples, failures)
    _check_building_tower_cost_wood_max(samples, failures)
    _check_building_wall_cost_max(samples, failures)
    _check_building_wall_cost_wood_max(samples, failures)
    return failures

static func read_game_version() -> String:
    var path: String = "res://VERSION.txt"
    if not FileAccess.file_exists(path):
        return "0.0.0"
    var text: String = FileAccess.get_file_as_string(path)
    if text == "":
        return "0.0.0"
    var first_line: String = text.split("\n", false)[0].strip_edges()
    if first_line == "":
        return "0.0.0"
    return first_line

static func _base_metrics() -> Dictionary:
    var metrics: Dictionary = {}
    var farm_cost: Dictionary = SimBuildings.cost_for("farm")
    var lumber_cost: Dictionary = SimBuildings.cost_for("lumber")
    var quarry_cost: Dictionary = SimBuildings.cost_for("quarry")
    var wall_cost: Dictionary = SimBuildings.cost_for("wall")
    var tower_cost: Dictionary = SimBuildings.cost_for("tower")
    metrics["building_farm_cost_wood"] = _resource_value(farm_cost, "wood")
    metrics["building_farm_production_food"] = _resource_value(SimBuildings.production_for("farm"), "food")
    metrics["building_lumber_cost_food"] = _resource_value(lumber_cost, "food")
    metrics["building_lumber_cost_wood"] = _resource_value(lumber_cost, "wood")
    metrics["building_lumber_production_wood"] = _resource_value(SimBuildings.production_for("lumber"), "wood")
    metrics["building_quarry_cost_food"] = _resource_value(quarry_cost, "food")
    metrics["building_quarry_cost_wood"] = _resource_value(quarry_cost, "wood")
    metrics["building_quarry_production_stone"] = _resource_value(SimBuildings.production_for("quarry"), "stone")
    metrics["building_wall_cost_stone"] = _resource_value(wall_cost, "stone")
    metrics["building_wall_cost_wood"] = _resource_value(wall_cost, "wood")
    metrics["building_wall_defense"] = int(SimBuildings.defense_for("wall"))
    metrics["building_tower_cost_stone"] = _resource_value(tower_cost, "stone")
    metrics["building_tower_cost_wood"] = _resource_value(tower_cost, "wood")
    metrics["building_tower_defense"] = int(SimBuildings.defense_for("tower"))

    var tower_1: Dictionary = SimBuildings.tower_stats(1)
    var tower_2: Dictionary = SimBuildings.tower_stats(2)
    var tower_3: Dictionary = SimBuildings.tower_stats(3)
    metrics["tower_level1_damage"] = int(tower_1.get("damage", 0))
    metrics["tower_level1_range"] = int(tower_1.get("range", 0))
    metrics["tower_level1_shots"] = int(tower_1.get("shots", 0))
    metrics["tower_level2_damage"] = int(tower_2.get("damage", 0))
    metrics["tower_level2_range"] = int(tower_2.get("range", 0))
    metrics["tower_level2_shots"] = int(tower_2.get("shots", 0))
    metrics["tower_level3_damage"] = int(tower_3.get("damage", 0))
    metrics["tower_level3_range"] = int(tower_3.get("range", 0))
    metrics["tower_level3_shots"] = int(tower_3.get("shots", 0))

    var upgrade_1: Dictionary = SimBuildings.upgrade_cost_for(1)
    var upgrade_2: Dictionary = SimBuildings.upgrade_cost_for(2)
    metrics["tower_upgrade1_cost_stone"] = _resource_value(upgrade_1, "stone")
    metrics["tower_upgrade1_cost_wood"] = _resource_value(upgrade_1, "wood")
    metrics["tower_upgrade2_cost_stone"] = _resource_value(upgrade_2, "stone")
    metrics["tower_upgrade2_cost_wood"] = _resource_value(upgrade_2, "wood")

    var raider: Dictionary = SimEnemies.ENEMY_KINDS.get("raider", {})
    var scout: Dictionary = SimEnemies.ENEMY_KINDS.get("scout", {})
    var armored: Dictionary = SimEnemies.ENEMY_KINDS.get("armored", {})
    metrics["enemy_armored_armor"] = int(armored.get("armor", 0))
    metrics["enemy_armored_speed"] = int(armored.get("speed", 0))
    metrics["enemy_raider_armor"] = int(raider.get("armor", 0))
    metrics["enemy_raider_speed"] = int(raider.get("speed", 0))
    metrics["enemy_scout_armor"] = int(scout.get("armor", 0))
    metrics["enemy_scout_speed"] = int(scout.get("speed", 0))

    metrics["midgame_food_bonus_amount"] = int(SimBalance.MIDGAME_FOOD_BONUS_AMOUNT)
    metrics["midgame_food_bonus_day"] = int(SimBalance.MIDGAME_FOOD_BONUS_DAY)
    metrics["midgame_food_bonus_threshold"] = int(SimBalance.MIDGAME_FOOD_BONUS_THRESHOLD)
    metrics["midgame_stone_catchup_day"] = int(SimBalance.MIDGAME_STONE_CATCHUP_DAY)
    metrics["midgame_stone_catchup_min"] = int(SimBalance.MIDGAME_STONE_CATCHUP_MIN)
    return metrics

static func _day_metrics(day: int) -> Dictionary:
    var metrics: Dictionary = {}
    var state: GameState = GameState.new()
    state.day = day
    state.threat = 0
    var caps: Dictionary = SimBalance.caps_for_day(day)
    metrics["midgame_caps_food"] = int(caps.get("food", 0))
    metrics["midgame_caps_stone"] = int(caps.get("stone", 0))
    metrics["midgame_caps_wood"] = int(caps.get("wood", 0))
    metrics["midgame_food_bonus"] = int(SimBalance.midgame_food_bonus(state))
    metrics["enemy_armored_armor"] = int(SimEnemies.armor_for_day("armored", day))
    metrics["enemy_raider_armor"] = int(SimEnemies.armor_for_day("raider", day))
    metrics["enemy_scout_armor"] = int(SimEnemies.armor_for_day("scout", day))
    metrics["enemy_armored_speed"] = int(SimEnemies.speed_for_day("armored", day))
    metrics["enemy_raider_speed"] = int(SimEnemies.speed_for_day("raider", day))
    metrics["enemy_scout_speed"] = int(SimEnemies.speed_for_day("scout", day))
    metrics["enemy_armored_hp_bonus"] = int(SimEnemies.hp_bonus_for_day("armored", day))
    metrics["enemy_raider_hp_bonus"] = int(SimEnemies.hp_bonus_for_day("raider", day))
    metrics["enemy_scout_hp_bonus"] = int(SimEnemies.hp_bonus_for_day("scout", day))
    metrics["night_wave_total_base"] = int(SimTick.compute_night_wave_total(state, 0))
    state.threat = 2
    metrics["night_wave_total_threat2"] = int(SimTick.compute_night_wave_total(state, 0))
    state.threat = 4
    metrics["night_wave_total_threat4"] = int(SimTick.compute_night_wave_total(state, 0))
    return metrics

static func _sorted_metric_keys(base_metrics: Dictionary, day_metrics: Dictionary) -> Array[String]:
    var seen: Dictionary = {}
    for key in base_metrics.keys():
        seen[str(key)] = true
    for key in day_metrics.keys():
        seen[str(key)] = true
    var metrics: Array[String] = []
    for key in seen.keys():
        metrics.append(str(key))
    metrics.sort()
    return metrics

static func _normalize_group(group: String) -> String:
    if group == "":
        return "all"
    var normalized: String = group.to_lower()
    if EXPORT_GROUPS.has(normalized):
        return normalized
    return ""

static func _filter_metrics(metrics: Array[String], group: String) -> Array[String]:
    if group == "all":
        return metrics.duplicate()
    var prefixes: Array = EXPORT_GROUPS.get(group, [])
    var filtered: Array[String] = []
    for key in metrics:
        for prefix in prefixes:
            if key.begins_with(str(prefix)):
                filtered.append(key)
                break
    filtered.sort()
    return filtered

static func _export_path_for_group(group: String) -> String:
    if group == "all":
        return SAVE_PATH
    return "user://balance_export_%s.json" % group

static func _baseline_path_for_group(group: String) -> String:
    return _export_path_for_group(group)

static func _summary_value_text(value: Variant) -> String:
    var value_type: int = typeof(value)
    if value_type == TYPE_INT:
        return str(int(value))
    if value_type == TYPE_FLOAT:
        return str(float(value))
    return str(value)

static func _resource_value(source: Dictionary, key: String) -> int:
    return int(source.get(key, 0))

static func _numeric_value(value: Variant) -> Variant:
    var value_type: int = typeof(value)
    if value_type == TYPE_INT or value_type == TYPE_FLOAT:
        return value
    return 0

static func _day_id(day: int) -> String:
    return "day_%02d" % day

static func _build_summary_lines(title: String, header: String, metric_keys: Array) -> Array[String]:
    var lines: Array[String] = [title, header]
    var base_metrics: Dictionary = _base_metrics()
    for day in SAMPLE_DAYS:
        var values: Dictionary = base_metrics.duplicate(true)
        var day_metrics: Dictionary = _day_metrics(day)
        for key in day_metrics.keys():
            values[key] = day_metrics[key]
        var row: Array[String] = [_day_id(day)]
        for metric_key in metric_keys:
            var key_text: String = str(metric_key)
            if values.has(key_text):
                row.append(_summary_value_text(values.get(key_text)))
            else:
                row.append("(missing)")
        lines.append(" | ".join(row))
    return lines

static func _day_from_id(sample_id: String) -> int:
    if not sample_id.begins_with("day_"):
        return -1
    var raw: String = sample_id.substr(4, sample_id.length() - 4)
    if not raw.is_valid_int():
        return -1
    return int(raw)

static func _sort_sample_entry(a: Variant, b: Variant) -> bool:
    var a_id: String = ""
    var b_id: String = ""
    if typeof(a) == TYPE_DICTIONARY:
        a_id = str(a.get("id", ""))
    if typeof(b) == TYPE_DICTIONARY:
        b_id = str(b.get("id", ""))
    return a_id < b_id

static func _baseline_shape_matches(baseline: Dictionary, current: Dictionary) -> bool:
    if str(baseline.get("schema", "")) != SCHEMA_ID:
        return false
    if int(baseline.get("schema_version", 0)) != SCHEMA_VERSION:
        return false
    if str(baseline.get("axis", "")) != str(current.get("axis", AXIS_NAME)):
        return false
    var baseline_metrics: Array[String] = _metrics_from_payload(baseline)
    var current_metrics: Array[String] = _metrics_from_payload(current)
    if baseline_metrics != current_metrics:
        return false
    var baseline_samples_raw: Variant = baseline.get("samples", [])
    var current_samples_raw: Variant = current.get("samples", [])
    if typeof(baseline_samples_raw) != TYPE_ARRAY or typeof(current_samples_raw) != TYPE_ARRAY:
        return false
    var baseline_samples: Array = baseline_samples_raw
    var current_samples: Array = current_samples_raw
    var baseline_ids: Array[String] = _sample_ids_from_samples(baseline_samples)
    var current_ids: Array[String] = _sample_ids_from_samples(current_samples)
    if baseline_ids != current_ids:
        return false
    for sample in baseline_samples:
        if typeof(sample) != TYPE_DICTIONARY:
            return false
        var values: Variant = sample.get("values", {})
        if typeof(values) != TYPE_DICTIONARY:
            return false
        var values_dict: Dictionary = values
        for metric in baseline_metrics:
            if not values_dict.has(metric):
                return false
            var value_type: int = typeof(values_dict.get(metric))
            if value_type != TYPE_INT and value_type != TYPE_FLOAT:
                return false
    return true

static func _metrics_from_payload(payload: Dictionary) -> Array[String]:
    var metrics: Array[String] = []
    var metrics_raw: Variant = payload.get("metrics", [])
    if typeof(metrics_raw) == TYPE_ARRAY:
        for entry in metrics_raw:
            metrics.append(str(entry))
    metrics.sort()
    return metrics

static func _sample_ids_from_samples(samples: Array) -> Array[String]:
    var ids: Array[String] = []
    var seen: Dictionary = {}
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            return []
        var sample_id: String = str(sample.get("id", ""))
        if sample_id == "":
            return []
        if seen.has(sample_id):
            return []
        seen[sample_id] = true
        ids.append(sample_id)
    ids.sort()
    return ids

static func _build_balance_diff_lines(baseline: Dictionary, current: Dictionary) -> Array[String]:
    var metrics: Array[String] = _metrics_from_payload(current)
    var baseline_index: Dictionary = _index_payload_values(baseline, metrics)
    var current_index: Dictionary = _index_payload_values(current, metrics)
    var sample_ids: Array[String] = _sample_ids_from_samples(current.get("samples", []))
    var lines: Array[String] = []
    for sample_id in sample_ids:
        var baseline_values: Dictionary = baseline_index.get(sample_id, {})
        var current_values: Dictionary = current_index.get(sample_id, {})
        for metric in metrics:
            var old_value: Variant = baseline_values.get(metric, 0)
            var new_value: Variant = current_values.get(metric, 0)
            if not _values_equal(old_value, new_value):
                lines.append("%s %s: %s -> %s" % [
                    sample_id,
                    metric,
                    _diff_value_text(old_value),
                    _diff_value_text(new_value)
                ])
    return lines

static func _index_payload_values(payload: Dictionary, metrics: Array[String]) -> Dictionary:
    var index: Dictionary = {}
    var samples_raw: Variant = payload.get("samples", [])
    if typeof(samples_raw) != TYPE_ARRAY:
        return index
    var samples: Array = samples_raw
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id == "":
            continue
        var values_raw: Variant = sample.get("values", {})
        var values: Dictionary = {}
        if typeof(values_raw) == TYPE_DICTIONARY:
            for metric in metrics:
                if values_raw.has(metric):
                    values[metric] = _numeric_value(values_raw.get(metric))
                else:
                    values[metric] = 0
        index[sample_id] = values
    return index

static func _values_equal(a: Variant, b: Variant) -> bool:
    var a_type: int = typeof(a)
    var b_type: int = typeof(b)
    if (a_type == TYPE_INT or a_type == TYPE_FLOAT) and (b_type == TYPE_INT or b_type == TYPE_FLOAT):
        return float(a) == float(b)
    return a == b

static func _diff_value_text(value: Variant) -> String:
    var value_type: int = typeof(value)
    if value_type == TYPE_INT:
        return str(int(value))
    if value_type == TYPE_FLOAT:
        var float_value: float = float(value)
        if float_value == floor(float_value):
            return str(int(float_value))
        return str(float_value)
    return str(value)

static func _check_non_decreasing(metric_key: String, samples: Array, failures: Array[String]) -> void:
    var last_set: bool = false
    var last_value: float = 0.0
    var last_id: String = ""
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var current: float = float(values.get(metric_key, 0))
        if last_set and current < last_value:
            failures.append("%s decreases at %s." % [metric_key, sample_id])
            return
        last_set = true
        last_value = current
        last_id = sample_id

static func _check_wave_threat_order(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var base_value: float = float(values.get("night_wave_total_base", 0))
        var threat2: float = float(values.get("night_wave_total_threat2", 0))
        var threat4: float = float(values.get("night_wave_total_threat4", 0))
        if threat2 < base_value or threat4 < threat2:
            failures.append("night_wave_total_threat ordering invalid at %s." % sample_id)
            return

static func _check_wave_threat_offsets(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var base_value: float = float(values.get("night_wave_total_base", 0))
        var threat2: float = float(values.get("night_wave_total_threat2", 0))
        var threat4: float = float(values.get("night_wave_total_threat4", 0))
        if threat2 != base_value + 2.0:
            failures.append("night_wave_total_threat2 offset invalid at %s." % sample_id)
            return
        if threat4 != base_value + 4.0:
            failures.append("night_wave_total_threat4 offset invalid at %s." % sample_id)
            return

static func _check_wave_base_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        var base_value: float = float(values.get("night_wave_total_base", 0))
        if base_value < 6.0:
            failures.append("night_wave_total_base below 6 at %s." % sample_id)
        return

static func _check_wave_day07_base_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        var base_value: float = float(values.get("night_wave_total_base", 0))
        if base_value < 7.0:
            failures.append("night_wave_total_base day_07 must be >= 7")
        return

static func _check_enemy_hp_bonus_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_armored_hp_bonus", 0)) < 2.0:
            failures.append("enemy_armored_hp_bonus below 2 at %s." % sample_id)
            return
        if float(values.get("enemy_raider_hp_bonus", 0)) < 1.0:
            failures.append("enemy_raider_hp_bonus below 1 at %s." % sample_id)
            return
        if float(values.get("enemy_scout_hp_bonus", 0)) < 0.0:
            failures.append("enemy_scout_hp_bonus below 0 at %s." % sample_id)
            return
        return

static func _check_enemy_armored_hp_bonus_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_armored_hp_bonus", 0)) < 4.0:
            failures.append("enemy_armored_hp_bonus day_07 must be >= 4")
        return

static func _check_enemy_raider_hp_bonus_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_raider_hp_bonus", 0)) < 2.0:
            failures.append("enemy_raider_hp_bonus day_07 must be >= 2")
        return

static func _check_enemy_scout_hp_bonus_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_scout_hp_bonus", 0)) < 1.0:
            failures.append("enemy_scout_hp_bonus day_07 must be >= 1")
        return

static func _check_enemy_armored_armor_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_armored_armor", 0)) < 2.0:
            failures.append("enemy_armored_armor day_07 must be >= 2")
        return

static func _check_enemy_raider_armor_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_raider_armor", 0)) < 1.0:
            failures.append("enemy_raider_armor day_07 must be >= 1")
        return

static func _check_enemy_scout_armor_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_scout_armor", 0)) < 1.0:
            failures.append("enemy_scout_armor day_07 must be >= 1")
        return

static func _check_enemy_armored_speed_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_armored_speed", 0)) < 2.0:
            failures.append("enemy_armored_speed day_07 must be >= 2")
        return

static func _check_enemy_scout_speed_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_scout_speed", 0)) < 3.0:
            failures.append("enemy_scout_speed day_07 must be >= 3")
        return

static func _check_enemy_raider_speed_day07_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("enemy_raider_speed", 0)) < 2.0:
            failures.append("enemy_raider_speed day_07 must be >= 2")
        return

static func _check_food_bonus(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var bonus: float = float(values.get("midgame_food_bonus", 0))
        var amount: float = float(values.get("midgame_food_bonus_amount", 0))
        if bonus != 0 and bonus != amount:
            failures.append("midgame_food_bonus unexpected at %s." % sample_id)
            return
        var day_value: int = _day_from_id(sample_id)
        if day_value < 0:
            failures.append("Invalid sample id %s." % sample_id)
            return
        var bonus_day: int = int(values.get("midgame_food_bonus_day", 0))
        if day_value >= bonus_day and bonus != amount:
            failures.append("midgame_food_bonus missing at %s." % sample_id)
            return

static func _check_midgame_food_bonus_day_exact(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        var bonus_day: int = int(values.get("midgame_food_bonus_day", 0))
        if bonus_day != 4:
            failures.append("midgame_food_bonus_day must be 4")
            return

static func _check_midgame_food_bonus_boundary(samples: Array, failures: Array[String]) -> void:
    var day03: Dictionary = _values_for_sample(samples, "day_03")
    var day04: Dictionary = _values_for_sample(samples, "day_04")
    if day03.is_empty() or day04.is_empty():
        failures.append("midgame_food_bonus boundary (day_03/day_04) mismatch")
        return
    var day03_bonus: float = float(day03.get("midgame_food_bonus", 0))
    if day03_bonus != 0.0:
        failures.append("midgame_food_bonus boundary (day_03/day_04) mismatch")
        return
    var day04_bonus: float = float(day04.get("midgame_food_bonus", 0))
    var day04_amount: float = float(day04.get("midgame_food_bonus_amount", 0))
    if day04_bonus != day04_amount:
        failures.append("midgame_food_bonus boundary (day_03/day_04) mismatch")
        return

static func _values_for_sample(samples: Array, sample_id: String) -> Dictionary:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        if str(sample.get("id", "")) != sample_id:
            continue
        var values: Variant = sample.get("values", {})
        if typeof(values) == TYPE_DICTIONARY:
            return values
        return {}
    return {}

static func _check_midgame_caps_stone_floor(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("midgame_caps_stone", 0)) < 35.0:
            failures.append("midgame_caps_stone day_07 must be >= 35")
        return

static func _check_midgame_caps_food_floor(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("midgame_caps_food", 0)) < 35.0:
            failures.append("midgame_caps_food day_07 must be >= 35")
        return

static func _check_midgame_stone_catchup_min_floor(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("midgame_stone_catchup_min", 0)) < 10.0:
            failures.append("midgame_stone_catchup_min must be >= 10")
            return

static func _check_building_quarry_production_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_quarry_production_stone", 0)) < 3.0:
            failures.append("building_quarry_production_stone must be >= 3")
            return

static func _check_building_lumber_production_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_lumber_production_wood", 0)) < 3.0:
            failures.append("building_lumber_production_wood must be >= 3")
            return

static func _check_building_farm_production_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_farm_production_food", 0)) < 3.0:
            failures.append("building_farm_production_food must be >= 3")
            return

static func _check_building_tower_cost_max(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_tower_cost_stone", 0)) > 8.0:
            failures.append("building_tower_cost_stone must be <= 8")
            return

static func _check_building_tower_cost_wood_max(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_tower_cost_wood", 0)) > 4.0:
            failures.append("building_tower_cost_wood must be <= 4")
            return

static func _check_building_wall_cost_max(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_wall_cost_stone", 0)) > 4.0:
            failures.append("building_wall_cost_stone must be <= 4")
            return

static func _check_building_wall_cost_wood_max(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var values: Dictionary = sample.get("values", {})
        if float(values.get("building_wall_cost_wood", 0)) > 4.0:
            failures.append("building_wall_cost_wood must be <= 4")
            return

static func _check_tower_damage_progression(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var level1: float = float(values.get("tower_level1_damage", 0))
        var level2: float = float(values.get("tower_level2_damage", 0))
        var level3: float = float(values.get("tower_level3_damage", 0))
        if level2 < level1 or level3 < level2:
            failures.append("tower_damage progression invalid at %s." % sample_id)
            return

static func _check_tower_damage_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        if float(values.get("tower_level2_damage", 0)) < 2.0:
            failures.append("tower_level2_damage below 2 at %s." % sample_id)
            return
        if float(values.get("tower_level3_damage", 0)) < 3.0:
            failures.append("tower_level3_damage below 3 at %s." % sample_id)
            return

static func _check_tower_shots_progression(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var level1: float = float(values.get("tower_level1_shots", 0))
        var level2: float = float(values.get("tower_level2_shots", 0))
        var level3: float = float(values.get("tower_level3_shots", 0))
        if level2 < level1 or level3 < level2:
            failures.append("tower_shots progression invalid at %s." % sample_id)
            return

static func _check_tower_upgrade_cost_min(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        if float(values.get("tower_upgrade1_cost_stone", 0)) < 1.0:
            failures.append("tower_upgrade1_cost_stone below 1 at %s." % sample_id)
            return
        if float(values.get("tower_upgrade1_cost_wood", 0)) < 1.0:
            failures.append("tower_upgrade1_cost_wood below 1 at %s." % sample_id)
            return
        if float(values.get("tower_upgrade2_cost_stone", 0)) < 1.0:
            failures.append("tower_upgrade2_cost_stone below 1 at %s." % sample_id)
            return
        if float(values.get("tower_upgrade2_cost_wood", 0)) < 1.0:
            failures.append("tower_upgrade2_cost_wood below 1 at %s." % sample_id)
            return

static func _check_tower_upgrade_cost_order(samples: Array, failures: Array[String]) -> void:
    for sample in samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        var values: Dictionary = sample.get("values", {})
        var upgrade1_stone: float = float(values.get("tower_upgrade1_cost_stone", 0))
        var upgrade1_wood: float = float(values.get("tower_upgrade1_cost_wood", 0))
        var upgrade2_stone: float = float(values.get("tower_upgrade2_cost_stone", 0))
        var upgrade2_wood: float = float(values.get("tower_upgrade2_cost_wood", 0))
        if upgrade2_stone < upgrade1_stone:
            failures.append("tower_upgrade_cost_stone order invalid at %s." % sample_id)
            return
        if upgrade2_wood < upgrade1_wood:
            failures.append("tower_upgrade_cost_wood order invalid at %s." % sample_id)
            return

