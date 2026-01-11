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
    "speed_multiplier": 1.0,
    "high_contrast": false,
    "nav_hints": true,
    "practice_mode": false
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

## Achievement IDs matching story.json definitions
const ACHIEVEMENT_IDS := [
    "first_blood",       # Defeat your first enemy
    "combo_starter",     # Achieve a 5-combo
    "combo_master",      # Achieve a 20-combo
    "speed_demon",       # Reach 60 WPM
    "perfectionist",     # Complete a wave with 100% accuracy
    "home_row_master",   # Master all home row lessons
    "alphabet_scholar",  # Learn all 26 letters
    "number_cruncher",   # Master the number row
    "keyboard_master",   # Complete all lessons
    "defender",          # Complete a day without losing health
    "survivor",          # Win a battle with only 1 HP remaining
    "boss_slayer",       # Defeat your first boss
    "void_vanquisher"    # Defeat the Void Tyrant
]

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

static func default_achievements() -> Dictionary:
    var result: Dictionary = {}
    for achievement_id in ACHIEVEMENT_IDS:
        result[achievement_id] = {
            "unlocked": false,
            "unlocked_at": 0  # Unix timestamp when unlocked, 0 if not unlocked
        }
    return result

static func default_profile() -> Dictionary:
    return {
        "version": VERSION,
        "practice_goal": "balanced",
        "preferred_lesson": SimLessons.default_lesson_id(),
        "difficulty_mode": "adventure",  # story, adventure, champion, nightmare, zen
        "keybinds": default_keybinds(),
        "ui_prefs": DEFAULT_UI_PREFS.duplicate(true),
        "lesson_progress": default_lesson_progress_map(),
        "achievements": default_achievements(),
        "typing_history": [],
        "lifetime": {
            "nights": 0,
            "defend_attempts": 0,
            "hits": 0,
            "misses": 0,
            "enemies_defeated": 0,
            "bosses_defeated": 0,
            "best_combo": 0,
            "best_wpm": 0.0
        },
        "streak": {
            "daily_streak": 0,
            "best_streak": 0,
            "last_play_date": ""  # ISO date string YYYY-MM-DD
        },
        "badges": [],  # Array of badge IDs earned
        "skill_points": 0,  # Available skill points to spend
        "learned_skills": {},  # {"tree_id:skill_id": ranks}
        "player_level": 1,  # Player level for XP system
        "player_xp": 0,  # Current XP
        "inventory": [],  # Array of item IDs in inventory
        "equipment": {  # Currently equipped items by slot
            "headgear": "",
            "armor": "",
            "gloves": "",
            "boots": "",
            "amulet": "",
            "ring": "",
            "belt": "",
            "cape": ""
        },
        "selected_hero": "",  # Selected hero ID (empty for no hero)
        "locale": "en"  # UI language (en, es, de, fr, pt)
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
    profile["achievements"] = _merge_achievements(data.get("achievements", {}))
    if data.has("streak") and typeof(data.get("streak")) == TYPE_DICTIONARY:
        profile["streak"] = _merge_streak(data.get("streak"))
    # Load skills data
    if data.has("skill_points"):
        profile["skill_points"] = int(data.get("skill_points", 0))
    if data.has("learned_skills") and typeof(data.get("learned_skills")) == TYPE_DICTIONARY:
        profile["learned_skills"] = data.get("learned_skills")
    if data.has("player_level"):
        profile["player_level"] = int(data.get("player_level", 1))
    if data.has("player_xp"):
        profile["player_xp"] = int(data.get("player_xp", 0))
    if data.has("badges") and typeof(data.get("badges")) == TYPE_ARRAY:
        profile["badges"] = data.get("badges")
    # Load inventory and equipment
    if data.has("inventory") and typeof(data.get("inventory")) == TYPE_ARRAY:
        profile["inventory"] = data.get("inventory")
    if data.has("equipment") and typeof(data.get("equipment")) == TYPE_DICTIONARY:
        var saved_equipment: Dictionary = data.get("equipment")
        for slot in profile["equipment"].keys():
            if saved_equipment.has(slot):
                profile["equipment"][slot] = str(saved_equipment.get(slot, ""))
    # Load hero selection
    if data.has("selected_hero"):
        profile["selected_hero"] = str(data.get("selected_hero", ""))
    # Load locale preference
    if data.has("locale"):
        profile["locale"] = str(data.get("locale", "en"))
    # Load bestiary data
    if data.has("bestiary") and typeof(data.get("bestiary")) == TYPE_DICTIONARY:
        profile["bestiary"] = data.get("bestiary")
    if data.has("bestiary_affixes") and typeof(data.get("bestiary_affixes")) == TYPE_DICTIONARY:
        profile["bestiary_affixes"] = data.get("bestiary_affixes")
    # Load materials data for crafting
    if data.has("materials") and typeof(data.get("materials")) == TYPE_DICTIONARY:
        profile["materials"] = data.get("materials")
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

static func get_high_contrast(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("high_contrast", false))
    return false

static func set_high_contrast(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["high_contrast"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_nav_hints(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("nav_hints", true))
    return true

static func set_nav_hints(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["nav_hints"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_practice_mode(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        return bool(prefs.get("practice_mode", false))
    return false

static func set_practice_mode(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["practice_mode"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

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
    result["reduced_motion"] = bool(raw.get("reduced_motion", false))
    result["speed_multiplier"] = float(raw.get("speed_multiplier", 1.0))
    result["high_contrast"] = bool(raw.get("high_contrast", false))
    result["nav_hints"] = bool(raw.get("nav_hints", true))
    result["practice_mode"] = bool(raw.get("practice_mode", false))
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

## Achievement System Functions

static func _merge_achievements(raw: Variant) -> Dictionary:
    var result: Dictionary = default_achievements()
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    for achievement_id in ACHIEVEMENT_IDS:
        if raw.has(achievement_id) and typeof(raw.get(achievement_id)) == TYPE_DICTIONARY:
            var entry: Dictionary = raw.get(achievement_id)
            result[achievement_id] = {
                "unlocked": bool(entry.get("unlocked", false)),
                "unlocked_at": int(entry.get("unlocked_at", 0))
            }
    return result

static func get_achievements(profile: Dictionary) -> Dictionary:
    if profile.has("achievements") and typeof(profile.get("achievements")) == TYPE_DICTIONARY:
        return _merge_achievements(profile.get("achievements"))
    return default_achievements()

static func is_achievement_unlocked(profile: Dictionary, achievement_id: String) -> bool:
    var achievements: Dictionary = get_achievements(profile)
    if achievements.has(achievement_id):
        var entry: Dictionary = achievements.get(achievement_id)
        return bool(entry.get("unlocked", false))
    return false

static func unlock_achievement(profile: Dictionary, achievement_id: String) -> Dictionary:
    if not ACHIEVEMENT_IDS.has(achievement_id):
        return {"ok": false, "profile": profile, "error": "Invalid achievement ID: %s" % achievement_id}

    # Check if already unlocked
    if is_achievement_unlocked(profile, achievement_id):
        return {"ok": true, "profile": profile, "already_unlocked": true}

    # Initialize achievements if needed
    if not profile.has("achievements") or typeof(profile.get("achievements")) != TYPE_DICTIONARY:
        profile["achievements"] = default_achievements()

    # Unlock the achievement
    profile["achievements"][achievement_id] = {
        "unlocked": true,
        "unlocked_at": int(Time.get_unix_time_from_system())
    }

    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile, "newly_unlocked": true}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func get_unlocked_achievements(profile: Dictionary) -> Array[String]:
    var result: Array[String] = []
    var achievements: Dictionary = get_achievements(profile)
    for achievement_id in ACHIEVEMENT_IDS:
        if achievements.has(achievement_id):
            var entry: Dictionary = achievements.get(achievement_id)
            if bool(entry.get("unlocked", false)):
                result.append(achievement_id)
    return result

static func get_achievement_count(profile: Dictionary) -> Dictionary:
    var unlocked: int = get_unlocked_achievements(profile).size()
    var total: int = ACHIEVEMENT_IDS.size()
    return {"unlocked": unlocked, "total": total}

static func get_lifetime_stat(profile: Dictionary, stat_name: String) -> Variant:
    if profile.has("lifetime") and typeof(profile.get("lifetime")) == TYPE_DICTIONARY:
        var lifetime: Dictionary = profile.get("lifetime")
        return lifetime.get(stat_name, 0)
    return 0

static func update_lifetime_stat(profile: Dictionary, stat_name: String, value: Variant) -> Dictionary:
    if not profile.has("lifetime") or typeof(profile.get("lifetime")) != TYPE_DICTIONARY:
        profile["lifetime"] = {
            "nights": 0,
            "defend_attempts": 0,
            "hits": 0,
            "misses": 0,
            "enemies_defeated": 0,
            "bosses_defeated": 0,
            "best_combo": 0,
            "best_wpm": 0.0
        }
    profile["lifetime"][stat_name] = value
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}

static func increment_lifetime_stat(profile: Dictionary, stat_name: String, amount: int = 1) -> Dictionary:
    var current: int = int(get_lifetime_stat(profile, stat_name))
    return update_lifetime_stat(profile, stat_name, current + amount)

static func update_best_stat(profile: Dictionary, stat_name: String, value: Variant) -> Dictionary:
    var current: Variant = get_lifetime_stat(profile, stat_name)
    if typeof(value) == TYPE_FLOAT:
        if float(value) > float(current):
            return update_lifetime_stat(profile, stat_name, value)
    elif typeof(value) == TYPE_INT:
        if int(value) > int(current):
            return update_lifetime_stat(profile, stat_name, value)
    return {"ok": true, "profile": profile}

## Daily Streak Functions

static func _merge_streak(raw: Variant) -> Dictionary:
    var result: Dictionary = {
        "daily_streak": 0,
        "best_streak": 0,
        "last_play_date": ""
    }
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    result["daily_streak"] = int(raw.get("daily_streak", 0))
    result["best_streak"] = int(raw.get("best_streak", 0))
    result["last_play_date"] = str(raw.get("last_play_date", ""))
    return result

static func get_streak(profile: Dictionary) -> Dictionary:
    if profile.has("streak") and typeof(profile.get("streak")) == TYPE_DICTIONARY:
        return _merge_streak(profile.get("streak"))
    return _merge_streak({})

static func get_daily_streak(profile: Dictionary) -> int:
    var streak: Dictionary = get_streak(profile)
    return int(streak.get("daily_streak", 0))

static func get_best_streak(profile: Dictionary) -> int:
    var streak: Dictionary = get_streak(profile)
    return int(streak.get("best_streak", 0))

## Get today's date as YYYY-MM-DD string
static func _get_today_date() -> String:
    var dt: Dictionary = Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

## Check if a date is yesterday (returns true if date is exactly 1 day before today)
static func _is_yesterday(date_str: String) -> bool:
    if date_str.is_empty():
        return false
    var today: String = _get_today_date()
    var today_unix: int = Time.get_unix_time_from_datetime_string(today + "T00:00:00")
    var date_unix: int = Time.get_unix_time_from_datetime_string(date_str + "T00:00:00")
    var diff_days: int = (today_unix - date_unix) / 86400
    return diff_days == 1

## Update daily streak - call when player starts a session
static func update_daily_streak(profile: Dictionary) -> Dictionary:
    var streak: Dictionary = get_streak(profile)
    var today: String = _get_today_date()
    var last_play: String = streak.get("last_play_date", "")
    var current_streak: int = int(streak.get("daily_streak", 0))
    var best_streak: int = int(streak.get("best_streak", 0))
    var streak_broken: bool = false
    var streak_extended: bool = false

    if last_play == today:
        # Already played today, no change
        return {"ok": true, "profile": profile, "streak": current_streak, "changed": false}

    if _is_yesterday(last_play):
        # Consecutive day - extend streak
        current_streak += 1
        streak_extended = true
    elif last_play.is_empty():
        # First time playing
        current_streak = 1
        streak_extended = true
    else:
        # Streak broken (missed a day or more)
        streak_broken = current_streak > 1
        current_streak = 1

    # Update best streak if needed
    if current_streak > best_streak:
        best_streak = current_streak

    # Update profile
    if not profile.has("streak"):
        profile["streak"] = {}
    profile["streak"]["daily_streak"] = current_streak
    profile["streak"]["best_streak"] = best_streak
    profile["streak"]["last_play_date"] = today

    return {
        "ok": true,
        "profile": profile,
        "streak": current_streak,
        "best_streak": best_streak,
        "extended": streak_extended,
        "broken": streak_broken,
        "changed": true
    }

# Badge functions
static func has_badge(profile: Dictionary, badge_id: String) -> bool:
    var badges: Array = profile.get("badges", [])
    return badge_id in badges

static func award_badge(profile: Dictionary, badge_id: String) -> bool:
    ## Award a badge if not already owned. Returns true if newly awarded.
    if badge_id.is_empty():
        return false
    if not profile.has("badges") or typeof(profile.get("badges")) != TYPE_ARRAY:
        profile["badges"] = []
    var badges: Array = profile.get("badges")
    if badge_id in badges:
        return false  # Already has badge
    badges.append(badge_id)
    return true

static func get_badges(profile: Dictionary) -> Array:
    return profile.get("badges", [])

# Difficulty mode functions
static func get_difficulty_mode(profile: Dictionary) -> String:
    var mode: String = str(profile.get("difficulty_mode", "adventure"))
    # Validate mode
    var valid_modes: Array[String] = ["story", "adventure", "champion", "nightmare", "zen"]
    if mode in valid_modes:
        return mode
    return "adventure"

static func set_difficulty_mode(profile: Dictionary, mode: String) -> bool:
    var valid_modes: Array[String] = ["story", "adventure", "champion", "nightmare", "zen"]
    if not mode in valid_modes:
        return false
    profile["difficulty_mode"] = mode
    return true

## Skill System Functions

static func get_skill_points(profile: Dictionary) -> int:
    return int(profile.get("skill_points", 0))

static func set_skill_points(profile: Dictionary, points: int) -> void:
    profile["skill_points"] = max(0, points)

static func add_skill_points(profile: Dictionary, points: int) -> void:
    var current: int = get_skill_points(profile)
    set_skill_points(profile, current + points)

static func get_learned_skills(profile: Dictionary) -> Dictionary:
    if profile.has("learned_skills") and typeof(profile.get("learned_skills")) == TYPE_DICTIONARY:
        return profile.get("learned_skills")
    return {}

static func set_learned_skills(profile: Dictionary, skills: Dictionary) -> void:
    profile["learned_skills"] = skills

static func get_player_level(profile: Dictionary) -> int:
    return max(1, int(profile.get("player_level", 1)))

## Alias for get_player_level (used by stats_dashboard)
static func get_level(profile: Dictionary) -> int:
    return get_player_level(profile)

static func get_player_xp(profile: Dictionary) -> int:
    return int(profile.get("player_xp", 0))

## Alias for get_player_xp (used by stats_dashboard)
static func get_xp(profile: Dictionary) -> int:
    return get_player_xp(profile)

static func set_player_level(profile: Dictionary, level: int) -> void:
    profile["player_level"] = max(1, level)

static func set_player_xp(profile: Dictionary, xp: int) -> void:
    profile["player_xp"] = max(0, xp)

## Calculate XP required for next level
static func xp_for_level(level: int) -> int:
    # Formula: base_xp * (level ^ 1.5)
    var base_xp: int = 100
    return int(float(base_xp) * pow(float(level), 1.5))

## Add XP and check for level up
static func add_xp(profile: Dictionary, xp: int) -> Dictionary:
    var current_xp: int = get_player_xp(profile) + xp
    var current_level: int = get_player_level(profile)
    var levels_gained: int = 0
    var skill_points_gained: int = 0

    # Check for level ups
    var xp_needed: int = xp_for_level(current_level)
    while current_xp >= xp_needed and current_level < 100:
        current_xp -= xp_needed
        current_level += 1
        levels_gained += 1
        skill_points_gained += 1  # 1 skill point per level
        xp_needed = xp_for_level(current_level)

    set_player_xp(profile, current_xp)
    set_player_level(profile, current_level)
    if skill_points_gained > 0:
        add_skill_points(profile, skill_points_gained)

    return {
        "xp_added": xp,
        "new_xp": current_xp,
        "new_level": current_level,
        "levels_gained": levels_gained,
        "skill_points_gained": skill_points_gained
    }

## Inventory System Functions

static func get_inventory(profile: Dictionary) -> Array:
    if profile.has("inventory") and typeof(profile.get("inventory")) == TYPE_ARRAY:
        return profile.get("inventory")
    return []

static func add_to_inventory(profile: Dictionary, item_id: String) -> void:
    if not profile.has("inventory") or typeof(profile.get("inventory")) != TYPE_ARRAY:
        profile["inventory"] = []
    profile["inventory"].append(item_id)

static func remove_from_inventory(profile: Dictionary, item_id: String) -> bool:
    var inventory: Array = get_inventory(profile)
    var index: int = inventory.find(item_id)
    if index >= 0:
        inventory.remove_at(index)
        profile["inventory"] = inventory
        return true
    return false

static func has_item(profile: Dictionary, item_id: String) -> bool:
    var inventory: Array = get_inventory(profile)
    return item_id in inventory

static func get_inventory_count(profile: Dictionary, item_id: String) -> int:
    var inventory: Array = get_inventory(profile)
    var count: int = 0
    for item in inventory:
        if str(item) == item_id:
            count += 1
    return count

## Equipment System Functions

static func get_equipment(profile: Dictionary) -> Dictionary:
    if profile.has("equipment") and typeof(profile.get("equipment")) == TYPE_DICTIONARY:
        return profile.get("equipment")
    return {
        "headgear": "", "armor": "", "gloves": "", "boots": "",
        "amulet": "", "ring": "", "belt": "", "cape": ""
    }

static func get_equipped_item(profile: Dictionary, slot: String) -> String:
    var equipment: Dictionary = get_equipment(profile)
    return str(equipment.get(slot, ""))

static func equip_item(profile: Dictionary, item_id: String, slot: String) -> Dictionary:
    var equipment: Dictionary = get_equipment(profile)
    var old_item: String = str(equipment.get(slot, ""))

    # Remove new item from inventory
    remove_from_inventory(profile, item_id)

    # Add old item back to inventory if there was one
    if not old_item.is_empty():
        add_to_inventory(profile, old_item)

    # Equip new item
    equipment[slot] = item_id
    profile["equipment"] = equipment

    return {"ok": true, "unequipped": old_item}

static func unequip_item(profile: Dictionary, slot: String) -> Dictionary:
    var equipment: Dictionary = get_equipment(profile)
    var old_item: String = str(equipment.get(slot, ""))

    if old_item.is_empty():
        return {"ok": false, "error": "Nothing equipped in that slot"}

    # Add old item back to inventory
    add_to_inventory(profile, old_item)

    # Clear slot
    equipment[slot] = ""
    profile["equipment"] = equipment

    return {"ok": true, "unequipped": old_item}


## Hero System Functions

static func get_selected_hero(profile: Dictionary) -> String:
    return str(profile.get("selected_hero", ""))


static func set_selected_hero(profile: Dictionary, hero_id: String) -> void:
    profile["selected_hero"] = hero_id


## Locale Functions

static func get_locale(profile: Dictionary) -> String:
    return str(profile.get("locale", "en"))


static func set_locale(profile: Dictionary, locale: String) -> void:
    profile["locale"] = locale


## Generic Profile Value Access Functions

## Get a value from the profile by key path (supports nested paths like "lifetime.best_combo")
static func get_profile_value(profile: Dictionary, key: String, default_value: Variant = null) -> Variant:
    # Handle nested paths
    if key.contains("."):
        var parts: PackedStringArray = key.split(".")
        var current: Variant = profile
        for part in parts:
            if typeof(current) != TYPE_DICTIONARY:
                return default_value
            current = current.get(part, null)
            if current == null:
                return default_value
        return current

    # Top-level keys
    if profile.has(key):
        return profile.get(key)

    # Check ui_prefs for common settings
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        var prefs: Dictionary = profile.get("ui_prefs")
        if prefs.has(key):
            return prefs.get(key)

    # Check lifetime stats
    if profile.has("lifetime") and typeof(profile.get("lifetime")) == TYPE_DICTIONARY:
        var lifetime: Dictionary = profile.get("lifetime")
        if lifetime.has(key):
            return lifetime.get(key)

    # Check streak
    if profile.has("streak") and typeof(profile.get("streak")) == TYPE_DICTIONARY:
        var streak: Dictionary = profile.get("streak")
        if streak.has(key):
            return streak.get(key)

    return default_value


## Set a value in the profile by key path (supports nested paths)
static func set_profile_value(profile: Dictionary, key: String, value: Variant) -> Dictionary:
    # Handle nested paths
    if key.contains("."):
        var parts: PackedStringArray = key.split(".")
        var current: Dictionary = profile
        for i in range(parts.size() - 1):
            var part: String = parts[i]
            if not current.has(part) or typeof(current.get(part)) != TYPE_DICTIONARY:
                current[part] = {}
            current = current.get(part)
        current[parts[parts.size() - 1]] = value
    else:
        # Check if this is a ui_pref key
        var ui_pref_keys: Array[String] = [
            "lessons_sort", "lessons_sparkline", "onboarding", "economy_note_shown",
            "ui_scale_percent", "compact_panels", "reduced_motion", "speed_multiplier",
            "high_contrast", "nav_hints", "practice_mode"
        ]
        if key in ui_pref_keys:
            if not profile.has("ui_prefs") or typeof(profile.get("ui_prefs")) != TYPE_DICTIONARY:
                profile["ui_prefs"] = {}
            profile["ui_prefs"][key] = value
        else:
            profile[key] = value

    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "unknown error")}
