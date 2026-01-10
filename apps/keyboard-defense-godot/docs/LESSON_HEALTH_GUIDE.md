# Lesson Health Guide

This document explains the lesson health scoring, sorting, and mini-trend formatting systems that track per-lesson proficiency.

## Overview

The lesson health system tracks improvement per-lesson using recent performance:

```
Recent History → Score Deltas → Health Label → Sort Lessons → HUD Display
      ↓              ↓              ↓              ↓             ↓
  [reports]      +1 per metric   GOOD/OK/WARN    by score    acc + hit +
```

## Health Scoring

### Score Recent Performance

```gdscript
# game/lesson_health.gd:6
static func score_recent(recent: Array, eps: float = 0.01) -> int:
    if not (recent is Array) or recent.size() < 2:
        return 0

    var newest = recent[0]
    var oldest = recent[recent.size() - 1]
    if typeof(newest) != TYPE_DICTIONARY or typeof(oldest) != TYPE_DICTIONARY:
        return 0

    var score: int = 0
    var acc_d: float = float(newest.get("avg_accuracy", 0.0)) - float(oldest.get("avg_accuracy", 0.0))
    var hit_d: float = float(newest.get("hit_rate", 0.0)) - float(oldest.get("hit_rate", 0.0))
    var back_d: float = float(newest.get("backspace_rate", 0.0)) - float(oldest.get("backspace_rate", 0.0))

    if acc_d > eps:
        score += 1      # Accuracy improving
    if hit_d > eps:
        score += 1      # Hit rate improving
    if back_d < -eps:
        score += 1      # Backspace rate decreasing (good)

    return score
```

### Scoring Rules

| Metric | Delta | Points | Meaning |
|--------|-------|--------|---------|
| avg_accuracy | > +0.01 | +1 | Accuracy improving |
| hit_rate | > +0.01 | +1 | Hit rate improving |
| backspace_rate | < -0.01 | +1 | Less backspacing |

**Score Range:** 0-3 points

### Health Labels

```gdscript
# game/lesson_health.gd:25
static func label_for_score(score: int, has_delta: bool) -> String:
    if not has_delta:
        return "--"
    if score >= 2:
        return "GOOD"
    if score == 1:
        return "OK"
    return "WARN"
```

| Score | Label | Meaning |
|-------|-------|---------|
| 0 | WARN | Performance slipping |
| 1 | OK | Mixed results |
| 2-3 | GOOD | Improving |
| N/A | -- | Not enough data |

### Legend Text

```gdscript
static func legend_line() -> String:
    return "Health: GOOD=improving, OK=mixed, WARN=slipping"
```

## HUD Text Building

```gdscript
# game/lesson_health.gd:37
static func build_hud_text(lesson_name: String, lesson_id: String, recent: Array, sparkline_enabled: bool) -> String:
    var name_text: String = lesson_name if lesson_name != "" else lesson_id
    var has_delta: bool = recent is Array and recent.size() >= 2

    if not has_delta:
        return "Lesson: %s (%s) | Health: --" % [name_text, lesson_id]

    var trend: Dictionary = MiniTrend.format_last3_delta(recent)
    if not bool(trend.get("has_delta", false)):
        return "Lesson: %s (%s) | Health: --" % [name_text, lesson_id]

    var score: int = score_recent(recent)
    var label: String = label_for_score(score, true)
    var acc_arrow: String = str(trend.get("acc_arrow", ""))
    var hit_arrow: String = str(trend.get("hit_arrow", ""))
    var back_arrow: String = str(trend.get("back_arrow", ""))

    var line: String = "Lesson: %s | Health: %s | acc %s hit %s back %s" % [
        name_text, label, acc_arrow, hit_arrow, back_arrow
    ]

    if sparkline_enabled and recent.size() > 0:
        var width: int = min(3, recent.size())
        var spark: String = MiniTrend.sparkline_from_recent(recent, "avg_accuracy", width)
        line = "%s | acc %s" % [line, spark]

    return line
```

**Example Output:**
```
Lesson: Home Row | Health: GOOD | acc + hit + back - | acc =+*
```

## Lesson Sorting

### Sort by Health Score

```gdscript
# game/lessons_sort.gd:23
static func sort_ids(ids: PackedStringArray, progress: Dictionary, mode: String, lessons_by_id: Dictionary = {}) -> PackedStringArray:
    if mode == "default":
        return ids

    var records: Array = []
    for i in range(ids.size()):
        var lesson_id: String = str(ids[i])
        var entry: Dictionary = progress.get(lesson_id, {})
        var recent: Array = entry.get("recent", [])
        var nights: int = int(entry.get("nights", 0))
        var name_text: String = _lesson_name(lessons_by_id, lesson_id)

        records.append({
            "id": lesson_id,
            "score": score_recent(recent),
            "recent_count": recent.size() if recent is Array else 0,
            "nights": nights,
            "name": name_text,
            "name_key": name_text.to_lower(),
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
```

### Sort Modes

| Mode | Sort Order |
|------|------------|
| `default` | Original order |
| `name` | Alphabetical by name |
| `recent` (else) | By health score, then activity |

### Recent Sort Priority

```gdscript
# game/lessons_sort.gd:55
static func _sort_record_recent(a: Dictionary, b: Dictionary) -> bool:
    # 1. Higher health score first
    var score_a: int = int(a.get("score", 0))
    var score_b: int = int(b.get("score", 0))
    if score_a != score_b:
        return score_a > score_b

    # 2. More recent activity first
    var recent_a: int = int(a.get("recent_count", 0))
    var recent_b: int = int(b.get("recent_count", 0))
    if recent_a != recent_b:
        return recent_a > recent_b

    # 3. More total nights first
    var nights_a: int = int(a.get("nights", 0))
    var nights_b: int = int(b.get("nights", 0))
    if nights_a != nights_b:
        return nights_a > nights_b

    # 4. Alphabetical by name
    var name_a: String = str(a.get("name_key", ""))
    var name_b: String = str(b.get("name_key", ""))
    if name_a != name_b:
        return name_a < name_b

    # 5. Original index as tiebreaker
    return int(a.get("orig_index", 0)) < int(b.get("orig_index", 0))
```

## Mini-Trend Formatting

### Delta Calculation

```gdscript
# game/mini_trend.gd:4
static func delta(a: float, b: float) -> float:
    return float(a) - float(b)
```

### Arrow Indicators

```gdscript
# game/mini_trend.gd:7
static func arrow_for_delta(d: float, eps: float = 0.01) -> String:
    if d > eps:
        return "+"    # Improving
    if d < -eps:
        return "-"    # Declining
    return "="        # Stable
```

| Delta | Arrow | Meaning |
|-------|-------|---------|
| > +0.01 | + | Improving |
| < -0.01 | - | Declining |
| else | = | Stable |

### Compact Badge Format

```gdscript
# game/mini_trend.gd:14
static func format_compact_badge(value: float, arrow: String, pct: bool = false) -> String:
    var base: String = ""
    if pct:
        base = "%d%%" % int(round(value * 100.0))
    else:
        base = "%.2f" % value
    if arrow == "":
        return base
    return "%s %s" % [base, arrow]
```

**Examples:**
- `format_compact_badge(0.85, "+", false)` → `"0.85 +"`
- `format_compact_badge(0.75, "-", true)` → `"75% -"`

### Sparkline Generation

```gdscript
# game/mini_trend.gd:24
static func sparkline(values: Array, width: int = 3, charset: String = " .:-=+*#%@") -> String:
    if values.is_empty():
        return "---"
    if width <= 0:
        return ""

    var chars: Array[String] = []
    for i in range(charset.length()):
        chars.append(charset.substr(i, 1))

    var take_count: int = min(width, values.size())
    var output: Array[String] = []
    for i in range(take_count):
        var value: float = float(values[i])
        var clamped: float = clamp(value, 0.0, 1.0)
        var index: int = int(round(clamped * float(chars.size() - 1)))
        index = clamp(index, 0, chars.size() - 1)
        output.append(chars[index])
    return "".join(output)
```

**Charset mapping (0.0-1.0 → character):**
```
0.0 = " " (space)
0.1 = "."
0.2 = ":"
0.3 = "-"
0.4 = "="
0.5 = "+"
0.6 = "*"
0.7 = "#"
0.8 = "%"
1.0 = "@"
```

### Sparkline from Recent

```gdscript
# game/mini_trend.gd:44
static func sparkline_from_recent(recent: Array, key: String, width: int = 3) -> String:
    if not (recent is Array) or recent.is_empty():
        return "---"
    var values: Array = []
    for i in range(recent.size() - 1, -1, -1):  # Reverse order (oldest first)
        if typeof(recent[i]) != TYPE_DICTIONARY:
            continue
        values.append(float(recent[i].get(key, 0.0)))
    return sparkline(values, width)
```

### Format Last 3 Delta

```gdscript
# game/mini_trend.gd:54
static func format_last3_delta(recent: Array) -> Dictionary:
    var output := {
        "has_delta": false,
        "acc_d": 0.0, "hit_d": 0.0, "back_d": 0.0,
        "acc_arrow": "", "hit_arrow": "", "back_arrow": "",
        "text": "Last3: --"
    }

    if not (recent is Array) or recent.size() < 2:
        return output

    var newest = recent[0]
    var oldest = recent[recent.size() - 1]

    var acc_d: float = float(newest.get("avg_accuracy", 0.0)) - float(oldest.get("avg_accuracy", 0.0))
    var hit_d: float = float(newest.get("hit_rate", 0.0)) - float(oldest.get("hit_rate", 0.0))
    var back_d: float = float(newest.get("backspace_rate", 0.0)) - float(oldest.get("backspace_rate", 0.0))

    output["has_delta"] = true
    output["acc_d"] = acc_d
    output["hit_d"] = hit_d
    output["back_d"] = back_d
    output["acc_arrow"] = arrow_for_delta(acc_d)
    output["hit_arrow"] = arrow_for_delta(hit_d)
    output["back_arrow"] = arrow_for_delta(back_d)
    output["text"] = "acc %s | hit %s | back %s" % [...]

    return output
```

## Integration Examples

### Lesson Selection UI

```gdscript
func _refresh_lesson_list() -> void:
    var ids: PackedStringArray = get_all_lesson_ids()
    var sorted_ids: PackedStringArray = LessonsSort.sort_ids(
        ids,
        profile.lesson_progress,
        sort_mode,
        lessons_by_id
    )

    for lesson_id in sorted_ids:
        var recent: Array = profile.lesson_progress.get(lesson_id, {}).get("recent", [])
        var hud_text: String = LessonHealth.build_hud_text(
            lessons_by_id[lesson_id].name,
            lesson_id,
            recent,
            true  # Enable sparkline
        )
        _add_lesson_item(lesson_id, hud_text)
```

### Post-Night Update

```gdscript
func _on_night_complete(lesson_id: String, report: Dictionary) -> void:
    var progress: Dictionary = profile.lesson_progress.get(lesson_id, {})
    var recent: Array = progress.get("recent", [])

    # Add new report to front
    recent.insert(0, report)

    # Keep last 3
    while recent.size() > 3:
        recent.pop_back()

    progress["recent"] = recent
    progress["nights"] = int(progress.get("nights", 0)) + 1
    profile.lesson_progress[lesson_id] = progress
```

### Health Summary Display

```gdscript
func _show_lesson_health(lesson_id: String) -> void:
    var recent: Array = profile.lesson_progress.get(lesson_id, {}).get("recent", [])
    var score: int = LessonHealth.score_recent(recent)
    var label: String = LessonHealth.label_for_score(score, recent.size() >= 2)

    health_label.text = "Health: %s" % label

    var trend: Dictionary = MiniTrend.format_last3_delta(recent)
    if trend.has_delta:
        trend_label.text = trend.text
        sparkline_label.text = MiniTrend.sparkline_from_recent(recent, "avg_accuracy", 3)
```

## Testing

```gdscript
func test_score_recent():
    # Improving on all metrics
    var recent := [
        {"avg_accuracy": 0.90, "hit_rate": 0.85, "backspace_rate": 0.05},
        {"avg_accuracy": 0.80, "hit_rate": 0.75, "backspace_rate": 0.15}
    ]
    assert(LessonHealth.score_recent(recent) == 3)

    # Mixed results
    recent = [
        {"avg_accuracy": 0.85, "hit_rate": 0.80, "backspace_rate": 0.10},
        {"avg_accuracy": 0.85, "hit_rate": 0.75, "backspace_rate": 0.10}
    ]
    assert(LessonHealth.score_recent(recent) == 1)  # Only hit improved

    _pass("test_score_recent")

func test_health_labels():
    assert(LessonHealth.label_for_score(3, true) == "GOOD")
    assert(LessonHealth.label_for_score(2, true) == "GOOD")
    assert(LessonHealth.label_for_score(1, true) == "OK")
    assert(LessonHealth.label_for_score(0, true) == "WARN")
    assert(LessonHealth.label_for_score(3, false) == "--")

    _pass("test_health_labels")

func test_sparkline():
    var values := [0.0, 0.5, 1.0]
    var spark := MiniTrend.sparkline(values, 3)
    assert(spark.length() == 3)
    assert(spark[0] == " ")   # 0.0
    assert(spark[1] == "+")   # 0.5
    assert(spark[2] == "@")   # 1.0

    _pass("test_sparkline")

func test_arrow_for_delta():
    assert(MiniTrend.arrow_for_delta(0.05) == "+")
    assert(MiniTrend.arrow_for_delta(-0.05) == "-")
    assert(MiniTrend.arrow_for_delta(0.005) == "=")

    _pass("test_arrow_for_delta")
```
