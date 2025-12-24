class_name TypingProfile
extends RefCounted

const PracticeGoals = preload("res://sim/practice_goals.gd")
const PROFILE_PATH := "user://profile.json"
const VERSION := 1
const DEFAULT_CYCLE_GOAL_BIND := {"keycode": KEY_F2, "shift": false, "alt": false, "ctrl": false, "meta": false}

static func default_keybinds() -> Dictionary:
    return {
        "cycle_goal": DEFAULT_CYCLE_GOAL_BIND.duplicate()
    }

static func default_profile() -> Dictionary:
    return {
        "version": VERSION,
        "practice_goal": "balanced",
        "keybinds": default_keybinds(),
        "typing_history": [],
        "lifetime": {
            "nights": 0,
            "defend_attempts": 0,
            "hits": 0,
            "misses": 0
        }
    }

static func load_profile() -> Dictionary:
    if not FileAccess.file_exists(PROFILE_PATH):
        return {"ok": true, "profile": default_profile()}
    var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.READ)
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
    profile["keybinds"] = _merge_keybinds(data.get("keybinds", {}))
    return {"ok": true, "profile": profile}

static func get_keybind(profile: Dictionary, action_name: String) -> Dictionary:
    if profile.has("keybinds") and typeof(profile.get("keybinds")) == TYPE_DICTIONARY:
        var keybinds: Dictionary = profile.get("keybinds")
        if keybinds.has(action_name) and typeof(keybinds.get(action_name)) == TYPE_DICTIONARY:
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

static func save_profile(profile: Dictionary) -> Dictionary:
    var data: Dictionary = profile.duplicate(true)
    data["version"] = VERSION
    var json_text: String = JSON.stringify(data, "  ")
    var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Profile save failed: %s" % error_string(FileAccess.get_open_error())}
    file.store_string(json_text)
    return {"ok": true, "path": PROFILE_PATH}

static func _merge_keybinds(raw: Variant) -> Dictionary:
    var result: Dictionary = default_keybinds()
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    for key in raw.keys():
        if typeof(key) != TYPE_STRING:
            continue
        var value = raw.get(key)
        if typeof(value) == TYPE_DICTIONARY:
            result[key] = _normalize_keybind(value, str(key))
    return result

static func _normalize_keybind(raw: Variant, action_name: String) -> Dictionary:
    var defaults: Dictionary = default_keybinds().get(action_name, DEFAULT_CYCLE_GOAL_BIND)
    if typeof(raw) != TYPE_DICTIONARY:
        return defaults.duplicate()
    var keycode: int = int(raw.get("keycode", defaults.get("keycode", 0)))
    if keycode <= 0:
        keycode = int(defaults.get("keycode", KEY_F2))
    return {
        "keycode": keycode,
        "shift": bool(raw.get("shift", defaults.get("shift", false))),
        "alt": bool(raw.get("alt", defaults.get("alt", false))),
        "ctrl": bool(raw.get("ctrl", defaults.get("ctrl", false))),
        "meta": bool(raw.get("meta", defaults.get("meta", false)))
    }
