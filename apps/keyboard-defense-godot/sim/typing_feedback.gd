class_name SimTypingFeedback
extends RefCounted

const CommandKeywords = preload("res://sim/command_keywords.gd")

static func normalize_input(s: String) -> String:
    return s.strip_edges().to_lower()

static func prefix_len(typed: String, word: String) -> int:
    var left: String = normalize_input(typed)
    var right: String = normalize_input(word)
    var limit: int = min(left.length(), right.length())
    var count: int = 0
    while count < limit:
        if left[count] != right[count]:
            break
        count += 1
    return count

static func edit_distance(a: String, b: String) -> int:
    var left: String = normalize_input(a)
    var right: String = normalize_input(b)
    var n: int = left.length()
    var m: int = right.length()
    if n == 0:
        return m
    if m == 0:
        return n
    var prev: Array[int] = []
    var curr: Array[int] = []
    prev.resize(m + 1)
    curr.resize(m + 1)
    for j in range(m + 1):
        prev[j] = j
    for i in range(1, n + 1):
        curr[0] = i
        var left_char: String = left.substr(i - 1, 1)
        for j in range(1, m + 1):
            var right_char: String = right.substr(j - 1, 1)
            var cost: int = 0 if left_char == right_char else 1
            curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
        var tmp: Array[int] = prev
        prev = curr
        curr = tmp
    return prev[m]

static func enemy_candidates(enemies: Array, typed_raw: String) -> Dictionary:
    var typed: String = normalize_input(typed_raw)
    var candidate_ids: Array[int] = []
    var best_prefix_len: int = 0
    var best_ids: Array[int] = []
    var exact_id: int = -1
    var exact_count: int = 0
    var suggestions: Array = []

    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var enemy_id: int = int(enemy.get("id", -1))
        var word: String = normalize_input(str(enemy.get("word", "")))
        var match_len: int = prefix_len(typed, word)

        if typed != "" and word == typed:
            exact_count += 1
            if exact_count == 1:
                exact_id = enemy_id

        if typed != "" and word.begins_with(typed):
            candidate_ids.append(enemy_id)

        if typed != "" and match_len > 0:
            if match_len > best_prefix_len:
                best_prefix_len = match_len
                best_ids = [enemy_id]
            elif match_len == best_prefix_len:
                best_ids.append(enemy_id)

        if typed != "":
            suggestions.append({
                "id": enemy_id,
                "word": word,
                "prefix_len": match_len,
                "dist": int(enemy.get("dist", 9999))
            })

    if exact_count > 1:
        exact_id = -1

    var expected_next_chars: Array[String] = []
    if typed != "" and best_prefix_len > 0 and not best_ids.is_empty():
        var next_chars: Dictionary = {}
        for enemy in enemies:
            if typeof(enemy) != TYPE_DICTIONARY:
                continue
            var enemy_id: int = int(enemy.get("id", -1))
            if not best_ids.has(enemy_id):
                continue
            var word: String = normalize_input(str(enemy.get("word", "")))
            if best_prefix_len < word.length():
                var next_char: String = word.substr(best_prefix_len, 1)
                next_chars[next_char] = true
        expected_next_chars.clear()
        for key in next_chars.keys():
            expected_next_chars.append(str(key))
        expected_next_chars.sort()

    if typed != "" and not suggestions.is_empty():
        suggestions.sort_custom(Callable(SimTypingFeedback, "_sort_suggestions"))
        if suggestions.size() > 3:
            suggestions = suggestions.slice(0, 3)
    else:
        suggestions = []

    return {
        "typed": typed,
        "exact_id": exact_id,
        "candidate_ids": candidate_ids,
        "best_prefix_len": best_prefix_len,
        "best_ids": best_ids,
        "expected_next_chars": expected_next_chars,
        "suggestions": suggestions
    }

static func route_night_input(parse_ok: bool, intent_kind: String, typed_raw: String, enemies: Array) -> Dictionary:
    var candidates: Dictionary = enemy_candidates(enemies, typed_raw)
    if parse_ok:
        return {"action": "command", "reason": "parsed command", "candidates": candidates}

    var typed: String = str(candidates.get("typed", ""))
    if typed == "":
        return {"action": "incomplete", "reason": "empty", "candidates": candidates}

    if int(candidates.get("exact_id", -1)) != -1:
        return {"action": "defend", "reason": "exact match", "candidates": candidates}

    if Array(candidates.get("candidate_ids", [])).size() > 0:
        return {"action": "incomplete", "reason": "prefix match; keep typing", "candidates": candidates}

    if _is_command_prefix(typed):
        return {"action": "incomplete", "reason": "command prefix; keep typing", "candidates": candidates}

    return {"action": "defend", "reason": "no match; miss attempt", "candidates": candidates}

static func _is_command_prefix(typed: String) -> bool:
    for keyword in CommandKeywords.KEYWORDS:
        if str(keyword).begins_with(typed):
            return true
    return false

static func _sort_suggestions(a: Dictionary, b: Dictionary) -> bool:
    var a_len: int = int(a.get("prefix_len", 0))
    var b_len: int = int(b.get("prefix_len", 0))
    if a_len != b_len:
        return a_len > b_len
    var a_dist: int = int(a.get("dist", 9999))
    var b_dist: int = int(b.get("dist", 9999))
    if a_dist != b_dist:
        return a_dist < b_dist
    return int(a.get("id", 0)) < int(b.get("id", 0))
