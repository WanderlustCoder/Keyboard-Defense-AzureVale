class_name TypingProfile
extends RefCounted

const PracticeGoals = preload("res://sim/practice_goals.gd")
const SimLessons = preload("res://sim/lessons.gd")
const ControlsFormatter = preload("res://game/controls_formatter.gd")
const PROFILE_PATH := "user://profile.json"
const VERSION := 1
const DEFAULT_CYCLE_GOAL_BIND := {"keycode": KEY_F7, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_SETTINGS_BIND := {"keycode": KEY_F1, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_LESSONS_BIND := {"keycode": KEY_F2, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_TREND_BIND := {"keycode": KEY_F3, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_COMPACT_BIND := {"keycode": KEY_F4, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_HISTORY_BIND := {"keycode": KEY_F5, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_REPORT_BIND := {"keycode": KEY_F6, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_ONBOARDING := {"enabled": true, "completed": false, "step": 0, "ever_shown": false}
const UI_SCALE_VALUES := [80, 90, 100, 110, 120, 130, 140]
const DEFAULT_UI_SCALE := 100
const SPEED_MULTIPLIER_VALUES := [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
const DEFAULT_UI_PREFS := {
    "lessons_sort": "default",
    "lessons_sparkline": true,
    "onboarding": DEFAULT_ONBOARDING,
    "economy_note_shown": false,
    "ui_scale_percent": DEFAULT_UI_SCALE,
    "compact_panels": false,
    "reduced_motion": false,
    "speed_multiplier": 1.0
}
const DEFAULT_LESSON_PROGRESS := {
    "nights": 0,
    "goal_passes": 0,
    "sum_accuracy": 0.0,
    "sum_hit_rate": 0.0,
    "sum_backspace_rate": 0.0,
    "best_accuracy": 0.0,
    "best_hit_rate": 0.0,
    "last_day": 0,
    "recent": []
}

static func default_binding_for_action(action_name: String) -> Dictionary:
    match action_name:
        "cycle_goal":
            return DEFAULT_CYCLE_GOAL_BIND.duplicate()
        "toggle_settings":
            return DEFAULT_TOGGLE_SETTINGS_BIND.duplicate()
        "toggle_lessons":
            return DEFAULT_TOGGLE_LESSONS_BIND.duplicate()
        "toggle_trend":
            return DEFAULT_TOGGLE_TREND_BIND.duplicate()
        "toggle_compact":
            return DEFAULT_TOGGLE_COMPACT_BIND.duplicate()
        "toggle_history":
            return DEFAULT_TOGGLE_HISTORY_BIND.duplicate()
        "toggle_report":
            return DEFAULT_TOGGLE_REPORT_BIND.duplicate()
        _:
            return DEFAULT_CYCLE_GOAL_BIND.duplicate()

static func default_keybinds() -> Dictionary:
    return {
        "cycle_goal": default_binding_for_action("cycle_goal"),
        "toggle_settings": default_binding_for_action("toggle_settings"),
        "toggle_lessons": default_binding_for_action("toggle_lessons"),
        "toggle_trend": default_binding_for_action("toggle_trend"),
        "toggle_compact": default_binding_for_action("toggle_compact"),
        "toggle_history": default_binding_for_action("toggle_history"),
        "toggle_report": default_binding_for_action("toggle_report")
    }

static func default_onboarding_state() -> Dictionary:
    return DEFAULT_ONBOARDING.duplicate(true)

static func default_profile() -> Dictionary:
    return {
        "version": VERSION,
        "practice_goal": "balanced",
        "preferred_lesson": SimLessons.default_lesson_id(),
        "keybinds": default_keybinds(),
        "ui_prefs": DEFAULT_UI_PREFS.duplicate(true),
        "lesson_progress": default_lesson_progress_map(),
        "typing_history": [],
        "lifetime": {
            "nights": 0,
            "defend_attempts": 0,
            "hits": 0,
            "misses": 0
        }
    }

static func load_profile(path: String = PROFILE_PATH) -> Dictionary:
    var load_path: String = path
    if load_path == "":
        load_path = PROFILE_PATH
    if not FileAccess.file_exists(load_path):
        return {"ok": true, "profile": default_profile()}
    var file: FileAccess = FileAccess.open(load_path, FileAccess.READ)
    if file == null:
        return {"ok": false, "error": "Profile load failed: %s" % error_string(FileAccess.get_open_error())}
    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {"ok": false, "error": "Profile file is invalid JSON."}
    var data: Dictionary = parsed
    var version: int = int(data.get("version", 1))
    if version > VERSION:
        return {"ok": false, "error": "Profile version is too new."}
    var profile: Dictionary = default_profile()
    if data.has("typing_history") and typeof(data.get("typing_history")) == TYPE_ARRAY:
        profile["typing_history"] = data.get("typing_history")
    if data.has("lifetime") and typeof(data.get("lifetime")) == TYPE_DICTIONARY:
        profile["lifetime"] = data.get("lifetime")
    var goal_value: String = str(data.get("practice_goal", "balanced"))
    profile["practice_goal"] = PracticeGoals.normalize_goal(goal_value)
    var lesson_value: String = str(data.get("preferred_lesson", SimLessons.default_lesson_id()))
    profile["preferred_lesson"] = SimLessons.normalize_lesson_id(lesson_value)
    profile["lesson_progress"] = _merge_lesson_progress(data.get("lesson_progress", {}))
    profile["keybinds"] = _merge_keybinds(data.get("keybinds", {}))
    profile["ui_prefs"] = _merge_ui_prefs(data.get("ui_prefs", {}))
    return {"ok": true, "profile": profile}

static func get_keybind(profile: Dictionary, action_name: String) -> Dictionary:
    if profile.has("keybinds") and typeof(profile.get("keybinds")) == TYPE_DICTIONARY:
        var keybinds: Dictionary = profile.get("keybinds")
        if keybinds.has(action_name):
            return _normalize_keybind(keybinds.get(action_name), action_name)
    return _normalize_keybind({}, action_name)

static func set_keybind(profile: Dictionary, action_name: String, keybind: Dictionary) -> Dictionary:
    var normalized: Dictionary = _normalize_keybind(keybind, action_name)
    if not profile.has("keybinds") or typeof(profile.get("keybinds")) != TYPE_DICTIONARY:
        profile["keybinds"] = {}
    profile["keybinds"][action_name] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_goal(profile: Dictionary) -> String:
    return PracticeGoals.normalize_goal(str(profile.get("practice_goal", "balanced")))

static func set_goal(profile: Dictionary, goal_id: String) -> Dictionary:
    var normalized: String = PracticeGoals.normalize_goal(goal_id)
    profile["practice_goal"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_lesson(profile: Dictionary) -> String:
    return SimLessons.normalize_lesson_id(str(profile.get("preferred_lesson", SimLessons.default_lesson_id())))

static func set_lesson(profile: Dictionary, lesson_id: String) -> Dictionary:
    var normalized: String = SimLessons.normalize_lesson_id(lesson_id)
    profile["preferred_lesson"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_lessons_sort(profile: Dictionary) -> String:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return _normalize_lessons_sort(str(prefs.get("lessons_sort", "default")))
    return _normalize_lessons_sort("default")

static func get_onboarding(profile: Dictionary) -> Dictionary:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return _normalize_onboarding(prefs.get("onboarding", {}))
    return default_onboarding_state()

static func set_onboarding(profile: Dictionary, onboarding: Dictionary) -> Dictionary:
    var normalized: Dictionary = _normalize_onboarding(onboarding)
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["onboarding"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func reset_onboarding(profile: Dictionary) -> Dictionary:
    var onboarding: Dictionary = default_onboarding_state()
    onboarding["enabled"] = true
    onboarding["completed"] = false
    onboarding["step"] = 0
    onboarding["ever_shown"] = true
    return set_onboarding(profile, onboarding)

static func complete_onboarding(profile: Dictionary) -> Dictionary:
    var onboarding: Dictionary = get_onboarding(profile)
    onboarding["enabled"] = false
    onboarding["completed"] = true
    onboarding["ever_shown"] = true
    return set_onboarding(profile, onboarding)

static func set_lessons_sort(profile: Dictionary, mode: String) -> Dictionary:
    var normalized: String = _normalize_lessons_sort(mode)
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["lessons_sort"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_lessons_sparkline(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("lessons_sparkline", true))
    return true

static func set_lessons_sparkline(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["lessons_sparkline"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_economy_note_shown(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("economy_note_shown", false))
    return false

static func set_economy_note_shown(profile: Dictionary, shown: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["economy_note_shown"] = bool(shown)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_ui_scale_percent(profile: Dictionary) -> int:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return _normalize_ui_scale(int(prefs.get("ui_scale_percent", DEFAULT_UI_SCALE)))
    return _normalize_ui_scale(DEFAULT_UI_SCALE)

static func set_ui_scale_percent(profile: Dictionary, value: int) -> Dictionary:
    var normalized: int = _normalize_ui_scale(value)
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["ui_scale_percent"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_compact_panels(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("compact_panels", false))
    return false

static func set_compact_panels(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["compact_panels"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_reduced_motion(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("reduced_motion", false))
    return false

static func set_reduced_motion(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["reduced_motion"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_speed_multiplier(profile: Dictionary) -> float:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        var val: float = float(prefs.get("speed_multiplier", 1.0))
        if val > 0.0 and val <= 2.0:
            return val
    return 1.0

static func set_speed_multiplier(profile: Dictionary, multiplier: float) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    var clamped: float = clamp(multiplier, 0.5, 2.0)
    profile["ui_prefs"]["speed_multiplier"] = clamped
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func cycle_speed_multiplier(profile: Dictionary, direction: int) -> Dictionary:
    var current: float = get_speed_multiplier(profile)
    var current_index: int = 0
    for i in range(SPEED_MULTIPLIER_VALUES.size()):
        if abs(SPEED_MULTIPLIER_VALUES[i] - current) < 0.01:
            current_index = i
            break
    var next_index: int = (current_index + direction) % SPEED_MULTIPLIER_VALUES.size()
    if next_index < 0:
        next_index = SPEED_MULTIPLIER_VALUES.size() - 1
    return set_speed_multiplier(profile, SPEED_MULTIPLIER_VALUES[next_index])

static func default_lesson_progress_entry() -> Dictionary:
    return DEFAULT_LESSON_PROGRESS.duplicate(true)

static func normalize_lesson_progress_entry(raw: Variant) -> Dictionary:
    return _normalize_lesson_progress_entry(raw)

static func default_lesson_progress_map() -> Dictionary:
    var result: Dictionary = {}
    var lesson_ids: PackedStringArray = SimLessons.lesson_ids()
    if lesson_ids.is_empty():
        result[SimLessons.default_lesson_id()] = default_lesson_progress_entry()
        return result
    for lesson_id in lesson_ids:
        result[str(lesson_id)] = default_lesson_progress_entry()
    return result

static func get_lesson_progress_map(profile: Dictionary) -> Dictionary:
    if profile.has("lesson_progress") and typeof(profile.get("lesson_progress")) == TYPE_DICTIONARY:
        return _merge_lesson_progress(profile.get("lesson_progress"))
    return default_lesson_progress_map()

static func update_lesson_progress(progress_map: Dictionary, lesson_id: String, report: Dictionary, goal_met: bool) -> Dictionary:
    var result: Dictionary = progress_map.duplicate(true)
    var normalized: String = SimLessons.normalize_lesson_id(lesson_id)
    var entry: Dictionary = _normalize_lesson_progress_entry(result.get(normalized, {}))
    entry["nights"] = int(entry.get("nights", 0)) + 1
    entry["goal_passes"] = int(entry.get("goal_passes", 0)) + (1 if goal_met else 0)
    var accuracy: float = float(report.get("avg_accuracy", 0.0))
    var hit_rate: float = float(report.get("hit_rate", 0.0))
    var backspace_rate: float = float(report.get("backspace_rate", 0.0))
    var incomplete_rate: float = float(report.get("incomplete_rate", 0.0))
    entry["sum_accuracy"] = float(entry.get("sum_accuracy", 0.0)) + accuracy
    entry["sum_hit_rate"] = float(entry.get("sum_hit_rate", 0.0)) + hit_rate
    entry["sum_backspace_rate"] = float(entry.get("sum_backspace_rate", 0.0)) + backspace_rate
    entry["best_accuracy"] = max(float(entry.get("best_accuracy", 0.0)), accuracy)
    entry["best_hit_rate"] = max(float(entry.get("best_hit_rate", 0.0)), hit_rate)
    entry["last_day"] = int(report.get("night_day", entry.get("last_day", 0)))
    var recent_list: Array = []
    if typeof(entry.get("recent")) == TYPE_ARRAY:
        recent_list = entry.get("recent").duplicate(true)
    var recent_entry: Dictionary = _normalize_recent_entry({
        "day": int(report.get("night_day", entry.get("last_day", 0))),
        "avg_accuracy": accuracy,
        "hit_rate": hit_rate,
        "backspace_rate": backspace_rate,
        "incomplete_rate": incomplete_rate,
        "goal_met": goal_met
    })
    recent_list.insert(0, recent_entry)
    while recent_list.size() > 3:
        recent_list.pop_back()
    entry["recent"] = recent_list
    result[normalized] = entry
    return result

static func reset_lesson_progress(progress_map: Dictionary, lesson_id: String) -> Dictionary:
    var result: Dictionary = progress_map.duplicate(true)
    var normalized: String = SimLessons.normalize_lesson_id(lesson_id)
    result[normalized] = default_lesson_progress_entry()
    return result
static func save_profile(profile: Dictionary, path: String = PROFILE_PATH) -> Dictionary:
    var data: Dictionary = profile.duplicate(true)
    data["version"] = VERSION
    data["keybinds"] = _serialize_keybinds(profile.get("keybinds", {}))
    var json_text: String = JSON.stringify(data, "  ")
    var save_path: String = path
    if save_path == "":
        save_path = PROFILE_PATH
    var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Profile save failed: %s" % error_string(FileAccess.get_open_error())}
    file.store_string(json_text)
    return {"ok": true, "path": save_path}

static func _merge_keybinds(raw: Variant) -> Dictionary:
    var result: Dictionary = default_keybinds()
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    for key in raw.keys():
        if typeof(key) != TYPE_STRING:
            continue
        var value = raw.get(key)
        result[key] = _normalize_keybind(value, str(key))
    return result

static func _serialize_keybinds(raw: Variant) -> Dictionary:
    var result: Dictionary = {}
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    var keys: Array = raw.keys()
    keys.sort()
    for key in keys:
        if typeof(key) != TYPE_STRING:
            continue
        var value: Variant = raw.get(key)
        var canonical: String = ""
        if typeof(value) == TYPE_STRING:
            canonical = ControlsFormatter.canonicalize_key_text(str(value))
        elif typeof(value) == TYPE_DICTIONARY:
            canonical = ControlsFormatter.keybind_to_text(value)
        if canonical == "":
            canonical = ""
        result[str(key)] = canonical
    return result

static func _merge_lesson_progress(raw: Variant) -> Dictionary:
    var result: Dictionary = default_lesson_progress_map()
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    for key in raw.keys():
        if typeof(key) != TYPE_STRING:
            continue
        var lesson_id: String = str(key)
        if not SimLessons.is_valid(lesson_id):
            continue
        var value = raw.get(key)
        result[lesson_id] = _normalize_lesson_progress_entry(value)
    return result

static func _merge_ui_prefs(raw: Variant) -> Dictionary:
    var result: Dictionary = DEFAULT_UI_PREFS.duplicate(true)
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    var raw_sort: String = str(raw.get("lessons_sort", "default"))
    result["lessons_sort"] = _normalize_lessons_sort(raw_sort)
    result["lessons_sparkline"] = bool(raw.get("lessons_sparkline", true))
    result["onboarding"] = _normalize_onboarding(raw.get("onboarding", {}))
    result["economy_note_shown"] = bool(raw.get("economy_note_shown", false))
    result["ui_scale_percent"] = _normalize_ui_scale(int(raw.get("ui_scale_percent", DEFAULT_UI_SCALE)))
    result["compact_panels"] = bool(raw.get("compact_panels", false))
    return result

static func _normalize_lessons_sort(mode: String) -> String:
    var normalized: String = mode.strip_edges().to_lower()
    if normalized == "name":
        return "name"
    if normalized == "recent":
        return "recent"
    return "default"

static func _normalize_ui_scale(value: int) -> int:
    var normalized: int = int(value)
    if UI_SCALE_VALUES.has(normalized):
        return normalized
    normalized = clamp(normalized, int(UI_SCALE_VALUES[0]), int(UI_SCALE_VALUES[UI_SCALE_VALUES.size() - 1]))
    normalized = int(round(float(normalized) / 10.0) * 10.0)
    if UI_SCALE_VALUES.has(normalized):
        return normalized
    return DEFAULT_UI_SCALE

static func _normalize_lesson_progress_entry(raw: Variant) -> Dictionary:
    var defaults: Dictionary = default_lesson_progress_entry()
    if typeof(raw) != TYPE_DICTIONARY:
        return defaults
    return {
        "nights": int(raw.get("nights", defaults.get("nights", 0))),
        "goal_passes": int(raw.get("goal_passes", defaults.get("goal_passes", 0))),
        "sum_accuracy": float(raw.get("sum_accuracy", defaults.get("sum_accuracy", 0.0))),
        "sum_hit_rate": float(raw.get("sum_hit_rate", defaults.get("sum_hit_rate", 0.0))),
        "sum_backspace_rate": float(raw.get("sum_backspace_rate", defaults.get("sum_backspace_rate", 0.0))),
        "best_accuracy": float(raw.get("best_accuracy", defaults.get("best_accuracy", 0.0))),
        "best_hit_rate": float(raw.get("best_hit_rate", defaults.get("best_hit_rate", 0.0))),
        "last_day": int(raw.get("last_day", defaults.get("last_day", 0))),
        "recent": _normalize_recent_list(raw.get("recent", defaults.get("recent", [])))
    }

static func _normalize_recent_list(raw: Variant) -> Array:
    if typeof(raw) != TYPE_ARRAY:
        return []
    var output: Array = []
    for entry in raw:
        if output.size() >= 3:
            break
        output.append(_normalize_recent_entry(entry))
    return output

static func _normalize_recent_entry(raw: Variant) -> Dictionary:
    if typeof(raw) != TYPE_DICTIONARY:
        return {
            "day": 0,
            "avg_accuracy": 0.0,
            "hit_rate": 0.0,
            "backspace_rate": 0.0,
            "incomplete_rate": 0.0,
            "goal_met": false
        }
    return {
        "day": int(raw.get("day", 0)),
        "avg_accuracy": float(raw.get("avg_accuracy", 0.0)),
        "hit_rate": float(raw.get("hit_rate", 0.0)),
        "backspace_rate": float(raw.get("backspace_rate", 0.0)),
        "incomplete_rate": float(raw.get("incomplete_rate", 0.0)),
        "goal_met": bool(raw.get("goal_met", false))
    }

static func format_recent_entry(entry: Dictionary) -> String:
    if typeof(entry) != TYPE_DICTIONARY:
        return ""
    var day: int = int(entry.get("day", 0))
    var acc: float = float(entry.get("avg_accuracy", 0.0)) * 100.0
    var hit: float = float(entry.get("hit_rate", 0.0)) * 100.0
    var back: float = float(entry.get("backspace_rate", 0.0)) * 100.0
    var inc: float = float(entry.get("incomplete_rate", 0.0)) * 100.0
    var met: bool = bool(entry.get("goal_met", false))
    var status: String = "PASS" if met else "NOT YET"
    return "Day %d | acc %.0f%% | hit %.0f%% | back %.0f%% | inc %.0f%% | %s" % [
        day,
        acc,
        hit,
        back,
        inc,
        status
    ]
static func _normalize_onboarding(raw: Variant) -> Dictionary:
    var defaults: Dictionary = default_onboarding_state()
    if typeof(raw) != TYPE_DICTIONARY:
        return defaults
    return {
        "enabled": bool(raw.get("enabled", defaults.get("enabled", true))),
        "completed": bool(raw.get("completed", defaults.get("completed", false))),
        "step": max(0, int(raw.get("step", defaults.get("step", 0)))),
        "ever_shown": bool(raw.get("ever_shown", defaults.get("ever_shown", false)))
    }

static func _normalize_keybind(raw: Variant, action_name: String) -> Dictionary:
    var defaults: Dictionary = default_binding_for_action(action_name)
    if typeof(raw) == TYPE_STRING:
        var parsed: Dictionary = ControlsFormatter.keybind_from_text(str(raw))
        if parsed.is_empty():
            return defaults.duplicate()
        raw = parsed
    if typeof(raw) != TYPE_DICTIONARY:
        return defaults.duplicate()
    var keycode: int = int(raw.get("keycode", defaults.get("keycode", 0)))
    if keycode <= 0:
        keycode = int(defaults.get("keycode", KEY_F7))
    return {
        "keycode": keycode,
        "shift": bool(raw.get("shift", defaults.get("shift", false))),
        "alt": bool(raw.get("alt", defaults.get("alt", false))),
        "ctrl": bool(raw.get("ctrl", defaults.get("ctrl", false))),
        "meta": bool(raw.get("meta", defaults.get("meta", false)))
    }


