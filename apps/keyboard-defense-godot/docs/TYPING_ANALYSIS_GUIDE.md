# Typing Analysis Guide

Utilities for typing performance analysis, trends, and lesson health.

## Overview

This guide covers analytics utilities for typing performance:
- `mini_trend.gd` - Trend visualization and delta calculation
- `goal_theme.gd` - Practice goal color theming
- `lesson_health.gd` - Per-lesson performance scoring
- `lessons_sort.gd` - Dynamic lesson sorting by performance

## MiniTrend (game/mini_trend.gd)

Trend analysis and visualization utilities.

### Delta Calculation

```gdscript
# Simple difference
static func delta(a: float, b: float) -> float:
    return b - a

# Arrow indicator for change direction
static func arrow_for_delta(d: float, eps: float = 0.01) -> String:
    # Returns: "+" (improved), "-" (declined), "=" (unchanged)
```

### Compact Badge Formatting

```gdscript
static func format_compact_badge(value: float, arrow: String, pct: bool = false) -> String:
    # Examples:
    # format_compact_badge(95.5, "+", false) -> "95.5 +"
    # format_compact_badge(45.0, "-", true)  -> "45% -"
```

### ASCII Sparklines

```gdscript
static func sparkline(values: Array, width: int = 3, charset: String = " .:-=+*#%@") -> String:
    # Creates ASCII visualization of trend
    # charset: 10 characters from low to high
    # Examples: ":+=*" for upward trend, "@#=." for downward

static func sparkline_from_recent(recent: Array, key: String, width: int = 3) -> String:
    # Extracts metric from history entries and creates sparkline
```

### Comprehensive Trend Analysis

```gdscript
static func format_last3_delta(recent: Array) -> Dictionary:
    # Compares newest vs oldest entry in recent history
    # Returns:
    # {
    #     "acc_delta": float,
    #     "acc_arrow": String,
    #     "hit_delta": float,
    #     "hit_arrow": String,
    #     "back_delta": float,
    #     "back_arrow": String,
    #     "text": "acc 95.2 (+1.50) | hit 80% (+5%) | back 2% (-1%)"
    # }
```

### Usage Example

```gdscript
var recent = profile.get_recent_for_lesson(lesson_id)
var trend = MiniTrend.format_last3_delta(recent)

# Display trend arrows
accuracy_label.text = "Accuracy: %s" % trend.acc_arrow
hit_label.text = "Hit Rate: %s" % trend.hit_arrow

# Display sparkline
var spark = MiniTrend.sparkline_from_recent(recent, "accuracy", 5)
sparkline_label.text = spark  # e.g., ".:-=+"
```

## GoalTheme (game/goal_theme.gd)

Color theming for practice goals.

### Goal Colors

```gdscript
const GOAL_HEX: Dictionary = {
    "balanced": "#B0B0B0",   # Gray
    "accuracy": "#0072B2",   # Blue
    "backspace": "#CC79A7",  # Purple/Pink
    "speed": "#D55E00"       # Orange
}

const PASS_HEX: String = "#009E73"  # Green
const FAIL_HEX: String = "#D55E00"  # Orange
```

### Functions

```gdscript
# Get Color object for goal type
static func color_for_goal(goal_id: String) -> Color

# Get hex string for goal type
static func hex_for_goal(goal_id: String) -> String

# Get pass/fail color
static func color_for_pass(passed: bool) -> Color
static func hex_for_pass(passed: bool) -> String
```

### Usage Example

```gdscript
# Style goal indicator
var goal_id = "accuracy"
goal_label.add_theme_color_override("font_color", GoalTheme.color_for_goal(goal_id))

# Style result
var passed = accuracy >= 0.95
result_label.add_theme_color_override("font_color", GoalTheme.color_for_pass(passed))
```

## LessonHealth (game/lesson_health.gd)

Per-lesson performance scoring.

### Health Score

```gdscript
static func score_recent(recent: Array, eps: float = 0.01) -> int:
    # Scores improvement based on:
    # +1 if accuracy improved
    # +1 if hit rate improved
    # +1 if backspace rate decreased
    # Returns: 0-3 score
```

### Health Labels

```gdscript
static func label_for_score(score: int, has_delta: bool) -> String:
    # Returns:
    # "GOOD" for score >= 2
    # "OK" for score == 1
    # "WARN" for score == 0
    # "--" if no delta data available

static func legend_line() -> String:
    # Returns: "Health: GOOD=improving, OK=mixed, WARN=slipping"
```

### HUD Text Builder

```gdscript
static func build_hud_text(lesson_name: String, lesson_id: String, recent: Array, sparkline_enabled: bool) -> String:
    # Returns comprehensive status line:
    # "Lesson: Home Row | Health: GOOD | acc + hit + back - | acc :-="
    #
    # Components:
    # - Lesson name
    # - Health score label
    # - Arrow indicators for each metric
    # - Optional accuracy sparkline
```

### Usage Example

```gdscript
var recent = profile.get_recent_for_lesson(lesson_id)
var health_score = LessonHealth.score_recent(recent)
var health_label = LessonHealth.label_for_score(health_score, recent.size() >= 2)

# Full HUD line
var hud_text = LessonHealth.build_hud_text(
    lesson_name,
    lesson_id,
    recent,
    settings.sparkline_enabled
)
status_label.text = hud_text
```

## LessonsSort (game/lessons_sort.gd)

Dynamic lesson list sorting.

### Sorting Modes

```gdscript
static func sort_ids(ids: PackedStringArray, progress: Dictionary, mode: String, lessons_by_id: Dictionary = {}) -> PackedStringArray:
    # Modes:
    # "default" - Original order (no sorting)
    # "recent" - By health score, then recent count, then nights played
    # "name" - Alphabetical by lesson name
```

### Recent Mode Sorting

Sorts by:
1. Health score (descending) - prioritize lessons needing attention
2. Recent session count (descending) - active lessons first
3. Nights played (descending) - more played lessons first
4. Name (ascending) - alphabetical tiebreaker

### Usage Example

```gdscript
# Get all lesson IDs
var all_ids = lessons_data.keys()

# Sort by current mode
var sorted_ids = LessonsSort.sort_ids(
    PackedStringArray(all_ids),
    profile.lesson_progress,
    current_sort_mode,
    lessons_data
)

# Build lesson list
for lesson_id in sorted_ids:
    _add_lesson_row(lesson_id)
```

## Integration Example

Complete lesson panel with health and sorting:

```gdscript
extends PanelContainer

var sort_mode: String = "default"
var sparkline_enabled: bool = true

func _build_lesson_list() -> void:
    # Get and sort lessons
    var lesson_ids = lessons_data.keys()
    var sorted = LessonsSort.sort_ids(
        PackedStringArray(lesson_ids),
        profile.lesson_progress,
        sort_mode,
        lessons_data
    )

    # Build rows with health indicators
    for lesson_id in sorted:
        var lesson = lessons_data[lesson_id]
        var recent = profile.get_recent_for_lesson(lesson_id)

        # Health score
        var score = LessonHealth.score_recent(recent)
        var label = LessonHealth.label_for_score(score, recent.size() >= 2)

        # Trend sparkline
        var spark = ""
        if sparkline_enabled and recent.size() >= 2:
            spark = MiniTrend.sparkline_from_recent(recent, "accuracy", 3)

        # Add row
        _add_lesson_row(lesson.name, label, spark)

func _on_sort_button_pressed() -> void:
    # Cycle through modes
    match sort_mode:
        "default": sort_mode = "recent"
        "recent": sort_mode = "name"
        "name": sort_mode = "default"
    _build_lesson_list()
```

## File Dependencies

- `game/mini_trend.gd` - No dependencies (pure utility)
- `game/goal_theme.gd` - No dependencies (pure constants)
- `game/lesson_health.gd` - Depends on mini_trend.gd
- `game/lessons_sort.gd` - Depends on mini_trend.gd (for score_recent)
