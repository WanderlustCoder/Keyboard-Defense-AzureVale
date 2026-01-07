class_name LessonsSort
extends RefCounted

static func score_recent(recent: Array, eps: float = 0.01) -> int:
    if not (recent is Array) or recent.size() < 2:
        return 0
    var newest = recent[0]
    var oldest = recent[recent.size() - 1]
    if typeof(newest) != TYPE_DICTIONARY or typeof(oldest) != TYPE_DICTIONARY:
        return 0
    var acc_d: float = float(newest.get("avg_accuracy", 0.0)) - float(oldest.get("avg_accuracy", 0.0))
    var hit_d: float = float(newest.get("hit_rate", 0.0)) - float(oldest.get("hit_rate", 0.0))
    var back_d: float = float(newest.get("backspace_rate", 0.0)) - float(oldest.get("backspace_rate", 0.0))
    var score: int = 0
    if acc_d > eps:
        score += 1
    if hit_d > eps:
        score += 1
    if back_d < -eps:
        score += 1
    return score

static func sort_ids(ids: PackedStringArray, progress: Dictionary, mode: String, lessons_by_id: Dictionary = {}) -> PackedStringArray:
    if mode == "default":
        return ids
    var records: Array = []
    for i in range(ids.size()):
        var lesson_id: String = str(ids[i])
        var entry: Dictionary = {}
        if typeof(progress) == TYPE_DICTIONARY and progress.has(lesson_id):
            if typeof(progress.get(lesson_id)) == TYPE_DICTIONARY:
                entry = progress.get(lesson_id)
        var recent: Array = entry.get("recent", [])
        var nights: int = int(entry.get("nights", 0))
        var name_text: String = _lesson_name(lessons_by_id, lesson_id)
        var name_key: String = name_text.to_lower()
        records.append({
            "id": lesson_id,
            "score": score_recent(recent),
            "recent_count": recent.size() if recent is Array else 0,
            "nights": nights,
            "name": name_text,
            "name_key": name_key,
            "orig_index": i
        })
    if mode == "name":
        records.sort_custom(Callable(LessonsSort, "_sort_record_name"))
    else:
        records.sort_custom(Callable(LessonsSort, "_sort_record_recent"))
    var sorted: PackedStringArray = PackedStringArray()
    for record in records:
        sorted.append(str(record.get("id", "")))
    return sorted

static func _sort_record_recent(a: Dictionary, b: Dictionary) -> bool:
    var score_a: int = int(a.get("score", 0))
    var score_b: int = int(b.get("score", 0))
    if score_a != score_b:
        return score_a > score_b
    var recent_a: int = int(a.get("recent_count", 0))
    var recent_b: int = int(b.get("recent_count", 0))
    if recent_a != recent_b:
        return recent_a > recent_b
    var nights_a: int = int(a.get("nights", 0))
    var nights_b: int = int(b.get("nights", 0))
    if nights_a != nights_b:
        return nights_a > nights_b
    var name_a: String = str(a.get("name_key", ""))
    var name_b: String = str(b.get("name_key", ""))
    if name_a != name_b:
        return name_a < name_b
    return int(a.get("orig_index", 0)) < int(b.get("orig_index", 0))

static func _sort_record_name(a: Dictionary, b: Dictionary) -> bool:
    var name_a: String = str(a.get("name_key", ""))
    var name_b: String = str(b.get("name_key", ""))
    if name_a != name_b:
        return name_a < name_b
    return int(a.get("orig_index", 0)) < int(b.get("orig_index", 0))

static func _lesson_name(lessons_by_id: Dictionary, lesson_id: String) -> String:
    if typeof(lessons_by_id) != TYPE_DICTIONARY:
        return ""
    if not lessons_by_id.has(lesson_id):
        return ""
    var value = lessons_by_id.get(lesson_id)
    if typeof(value) == TYPE_DICTIONARY:
        return str(value.get("name", value.get("id", "")))
    return str(value)
