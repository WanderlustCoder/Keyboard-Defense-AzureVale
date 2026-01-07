class_name SimLessons
extends RefCounted

const LESSONS_PATH := "res://data/lessons.json"
const DEFAULT_LESSON_ID := "full_alpha"
const KINDS := ["scout", "raider", "armored"]
static var _cache: Dictionary = {}

static func load_data() -> Dictionary:
    if not _cache.is_empty():
        return _cache
    if not FileAccess.file_exists(LESSONS_PATH):
        _cache = {"ok": false, "error": "Lessons file not found.", "data": {}}
        return _cache
    var file: FileAccess = FileAccess.open(LESSONS_PATH, FileAccess.READ)
    if file == null:
        _cache = {"ok": false, "error": "Lessons load failed: %s" % error_string(FileAccess.get_open_error()), "data": {}}
        return _cache
    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        _cache = {"ok": false, "error": "Lessons file is invalid JSON.", "data": {}}
        return _cache
    _cache = _normalize_data(parsed)
    return _cache

static func lesson_ids() -> PackedStringArray:
    var data: Dictionary = load_data()
    if not data.get("ok", false):
        return PackedStringArray([DEFAULT_LESSON_ID])
    var lessons: Array = data.get("data", {}).get("lessons", [])
    var ids: PackedStringArray = PackedStringArray()
    for entry in lessons:
        if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
            ids.append(str(entry.get("id", "")))
    return ids

static func default_lesson_id() -> String:
    var data: Dictionary = load_data()
    if data.get("ok", false):
        var default_id: String = str(data.get("data", {}).get("default_lesson", ""))
        if default_id != "":
            return default_id
    return DEFAULT_LESSON_ID

static func is_valid(lesson_id: String) -> bool:
    var data: Dictionary = load_data()
    if not data.get("ok", false):
        return false
    return data.get("data", {}).get("by_id", {}).has(lesson_id)

static func normalize_lesson_id(lesson_id: String) -> String:
    var cleaned: String = lesson_id.strip_edges().to_lower()
    if cleaned == "":
        return default_lesson_id()
    if is_valid(cleaned):
        return cleaned
    return default_lesson_id()

static func get_lesson(lesson_id: String) -> Dictionary:
    var data: Dictionary = load_data()
    if not data.get("ok", false):
        return {}
    var lesson_map: Dictionary = data.get("data", {}).get("by_id", {})
    var resolved: String = normalize_lesson_id(lesson_id)
    if lesson_map.has(resolved):
        return lesson_map[resolved]
    return {}

static func lesson_label(lesson_id: String) -> String:
    var lesson: Dictionary = get_lesson(lesson_id)
    if lesson.is_empty():
        return "Lesson"
    return str(lesson.get("name", lesson.get("id", "Lesson")))

static func lesson_description(lesson_id: String) -> String:
    var lesson: Dictionary = get_lesson(lesson_id)
    if lesson.is_empty():
        return ""
    return str(lesson.get("description", ""))

static func _normalize_data(raw: Dictionary) -> Dictionary:
    var lessons_raw: Variant = raw.get("lessons", [])
    var lessons: Array = []
    var by_id: Dictionary = {}
    if lessons_raw is Array:
        for entry in lessons_raw:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var id: String = str(entry.get("id", "")).strip_edges().to_lower()
            if id == "":
                continue
            var name: String = str(entry.get("name", id))
            var description: String = str(entry.get("description", ""))
            var mode: String = str(entry.get("mode", "charset"))
            var charset: String = _normalize_charset(str(entry.get("charset", "")))
            var lengths: Dictionary = _normalize_lengths(entry.get("lengths", {}))
            var lesson := {
                "id": id,
                "name": name,
                "description": description,
                "mode": mode,
                "charset": charset,
                "lengths": lengths
            }
            lessons.append(lesson)
            by_id[id] = lesson
    var default_id: String = str(raw.get("default_lesson", "")).strip_edges().to_lower()
    if not by_id.has(default_id):
        if lessons.is_empty():
            default_id = DEFAULT_LESSON_ID
        else:
            default_id = str(lessons[0].get("id", DEFAULT_LESSON_ID))
    var ok: bool = not lessons.is_empty()
    var error_text: String = "" if ok else "Lessons list is empty."
    return {
        "ok": ok,
        "error": error_text,
        "data": {
            "version": int(raw.get("version", 1)),
            "default_lesson": default_id,
            "lessons": lessons,
            "by_id": by_id
        }
    }

static func _normalize_charset(raw: String) -> String:
    var cleaned: String = raw.to_lower()
    var seen: Dictionary = {}
    var output: String = ""
    for i in range(cleaned.length()):
        var ch: String = cleaned.substr(i, 1)
        if ch == " " or ch == "\t" or ch == "\n" or ch == "\r":
            continue
        if seen.has(ch):
            continue
        seen[ch] = true
        output += ch
    return output

static func _normalize_lengths(raw: Variant) -> Dictionary:
    var defaults := {
        "scout": [3, 4],
        "raider": [4, 6],
        "armored": [6, 8]
    }
    var output: Dictionary = {}
    for kind in KINDS:
        var range_value: Variant = defaults[kind]
        if typeof(raw) == TYPE_DICTIONARY and raw.has(kind):
            range_value = raw.get(kind)
        var min_len: int = int(defaults[kind][0])
        var max_len: int = int(defaults[kind][1])
        if range_value is Array and range_value.size() >= 2:
            min_len = int(range_value[0])
            max_len = int(range_value[1])
        if min_len < 1:
            min_len = 1
        if max_len < min_len:
            max_len = min_len
        output[kind] = [min_len, max_len]
    return output
