class_name SimTypingStats
extends RefCounted

const SimTypingFeedback = preload("res://sim/typing_feedback.gd")

var night_day: int = 0
var wave_total: int = 0
var night_steps: int = 0
var enter_presses: int = 0
var incomplete_enters: int = 0
var command_enters: int = 0
var defend_attempts: int = 0
var wait_steps: int = 0
var hits: int = 0
var misses: int = 0
var typed_chars: int = 0
var deleted_chars: int = 0
var sum_accuracy: float = 0.0
var accuracy_attempts: int = 0
var sum_edit_distance: int = 0
var edit_distance_attempts: int = 0
var start_msec: int = -1

func start_night(day: int, wave_total_value: int, now_msec: int = -1) -> void:
    night_day = day
    wave_total = wave_total_value
    night_steps = 0
    enter_presses = 0
    incomplete_enters = 0
    command_enters = 0
    defend_attempts = 0
    wait_steps = 0
    hits = 0
    misses = 0
    typed_chars = 0
    deleted_chars = 0
    sum_accuracy = 0.0
    accuracy_attempts = 0
    sum_edit_distance = 0
    edit_distance_attempts = 0
    start_msec = now_msec

func on_text_changed(prev_text: String, new_text: String) -> void:
    var prev_len: int = prev_text.length()
    var new_len: int = new_text.length()
    if new_len > prev_len:
        typed_chars += new_len - prev_len
    elif new_len < prev_len:
        deleted_chars += prev_len - new_len

func on_enter_pressed() -> void:
    enter_presses += 1

func record_incomplete_enter(reason: String) -> void:
    incomplete_enters += 1

func record_command_enter(kind: String, advances_step: bool) -> void:
    command_enters += 1
    if advances_step:
        night_steps += 1
    if kind == "wait":
        wait_steps += 1

func record_defend_attempt(typed_raw: String, enemies: Array) -> void:
    defend_attempts += 1
    night_steps += 1
    var typed: String = SimTypingFeedback.normalize_input(typed_raw)
    var hit: bool = false
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var word: String = SimTypingFeedback.normalize_input(str(enemy.get("word", "")))
        if word != "" and typed == word:
            hit = true
            break
    if hit:
        hits += 1
    else:
        misses += 1

    if enemies.is_empty():
        return
    var best_dist: int = 999999
    var best_len: int = 0
    var best_id: int = 999999
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var enemy_id: int = int(enemy.get("id", 0))
        var word: String = SimTypingFeedback.normalize_input(str(enemy.get("word", "")))
        if word == "":
            continue
        var dist: int = SimTypingFeedback.edit_distance(typed, word)
        if dist < best_dist or (dist == best_dist and enemy_id < best_id):
            best_dist = dist
            best_len = word.length()
            best_id = enemy_id
    if best_dist != 999999:
        sum_edit_distance += best_dist
        edit_distance_attempts += 1
        var max_len: int = max(max(best_len, typed.length()), 1)
        var acc: float = 1.0 - float(best_dist) / float(max_len)
        if acc < 0.0:
            acc = 0.0
        if acc > 1.0:
            acc = 1.0
        sum_accuracy += acc
        accuracy_attempts += 1

func to_report_dict() -> Dictionary:
    var attempt_div: float = float(max(defend_attempts, 1))
    var backspace_div: float = float(max(typed_chars + deleted_chars, 1))
    var accuracy_div: float = float(max(accuracy_attempts, 1))
    var edit_div: float = float(max(edit_distance_attempts, 1))
    var hit_rate: float = float(hits) / attempt_div
    var backspace_rate: float = float(deleted_chars) / backspace_div
    var incomplete_rate: float = float(incomplete_enters) / float(max(enter_presses, 1))
    var avg_accuracy: float = sum_accuracy / accuracy_div
    var avg_edit_distance: float = float(sum_edit_distance) / edit_div
    return {
        "night_day": night_day,
        "wave_total": wave_total,
        "night_steps": night_steps,
        "enter_presses": enter_presses,
        "incomplete_enters": incomplete_enters,
        "command_enters": command_enters,
        "defend_attempts": defend_attempts,
        "wait_steps": wait_steps,
        "hits": hits,
        "misses": misses,
        "typed_chars": typed_chars,
        "deleted_chars": deleted_chars,
        "hit_rate": hit_rate,
        "backspace_rate": backspace_rate,
        "incomplete_rate": incomplete_rate,
        "avg_accuracy": avg_accuracy,
        "avg_edit_distance": avg_edit_distance
    }

func to_report_text() -> String:
    var report: Dictionary = to_report_dict()
    var hit_rate: float = float(report.get("hit_rate", 0.0)) * 100.0
    var backspace_rate: float = float(report.get("backspace_rate", 0.0)) * 100.0
    var avg_accuracy: float = float(report.get("avg_accuracy", 0.0)) * 100.0
    var avg_edit_distance: float = float(report.get("avg_edit_distance", 0.0))
    var lines: Array[String] = []
    lines.append("Typing Report (Day %d)" % int(report.get("night_day", 0)))
    lines.append("Wave total: %d" % int(report.get("wave_total", 0)))
    lines.append("Steps: %d | Enters: %d | Incomplete: %d | Commands: %d | Waits: %d" % [
        int(report.get("night_steps", 0)),
        int(report.get("enter_presses", 0)),
        int(report.get("incomplete_enters", 0)),
        int(report.get("command_enters", 0)),
        int(report.get("wait_steps", 0))
    ])
    lines.append("Defend: %d attempts | Hits %d | Misses %d | Hit rate %.1f%%" % [
        int(report.get("defend_attempts", 0)),
        int(report.get("hits", 0)),
        int(report.get("misses", 0)),
        hit_rate
    ])
    lines.append("Input: typed %d | backspace %d (%.1f%%)" % [
        int(report.get("typed_chars", 0)),
        int(report.get("deleted_chars", 0)),
        backspace_rate
    ])
    lines.append("Incomplete enter rate: %.1f%%" % float(report.get("incomplete_rate", 0.0) * 100.0))
    lines.append("Accuracy: avg %.1f%% | avg edit distance %.2f" % [
        avg_accuracy,
        avg_edit_distance
    ])
    return "\n".join(lines)
