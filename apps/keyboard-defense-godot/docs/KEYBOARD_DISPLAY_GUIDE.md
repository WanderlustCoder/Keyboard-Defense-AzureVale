# Keyboard Display Guide

This document explains the on-screen keyboard visualization component used for typing tutor feedback.

## Overview

The keyboard display provides visual feedback for touch typing:

```
Active Keys → Finger Zones → Next Key Highlight → Flash on Input
     ↓             ↓               ↓                   ↓
  charset      zone colors      yellow border      green/red
```

## Key Layout

### QWERTY Rows

```gdscript
# game/keyboard_display.gd:7
const ROWS := [
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="],
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"],
    ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"],
    [" "]  # Spacebar
]
```

### Row Stagger Offsets

```gdscript
const ROW_OFFSETS := [0.0, 15.0, 25.0, 40.0, 120.0]
```

Simulates the staggered layout of a real keyboard.

## Finger Zone System

### Zone Assignments

```gdscript
# game/keyboard_display.gd:19
const FINGER_ZONES := {
    # Left hand - pinky
    "1": "left_pinky", "`": "left_pinky",
    "q": "left_pinky", "a": "left_pinky", "z": "left_pinky",
    # Left hand - ring
    "2": "left_ring",
    "w": "left_ring", "s": "left_ring", "x": "left_ring",
    # Left hand - middle
    "3": "left_middle",
    "e": "left_middle", "d": "left_middle", "c": "left_middle",
    # Left hand - index (includes reach keys)
    "4": "left_index", "5": "left_index",
    "r": "left_index", "f": "left_index", "v": "left_index",
    "t": "left_index", "g": "left_index", "b": "left_index",
    # Right hand - index (includes reach keys)
    "6": "right_index", "7": "right_index",
    "y": "right_index", "h": "right_index", "n": "right_index",
    "u": "right_index", "j": "right_index", "m": "right_index",
    # Right hand - middle
    "8": "right_middle",
    "i": "right_middle", "k": "right_middle", ",": "right_middle",
    # Right hand - ring
    "9": "right_ring",
    "o": "right_ring", "l": "right_ring", ".": "right_ring",
    # Right hand - pinky
    "0": "right_pinky", "-": "right_pinky", "=": "right_pinky",
    "p": "right_pinky", ";": "right_pinky", "'": "right_pinky",
    "[": "right_pinky", "]": "right_pinky", "/": "right_pinky",
    # Thumbs
    " ": "thumb"
}
```

### Zone Colors

```gdscript
const FINGER_COLORS := {
    "left_pinky": Color(0.7, 0.5, 0.8, 1.0),    # Purple
    "left_ring": Color(0.4, 0.6, 0.9, 1.0),     # Blue
    "left_middle": Color(0.4, 0.8, 0.5, 1.0),   # Green
    "left_index": Color(0.9, 0.6, 0.3, 1.0),    # Orange
    "right_index": Color(0.9, 0.6, 0.3, 1.0),   # Orange
    "right_middle": Color(0.4, 0.8, 0.5, 1.0),  # Green
    "right_ring": Color(0.4, 0.6, 0.9, 1.0),    # Blue
    "right_pinky": Color(0.7, 0.5, 0.8, 1.0),   # Purple
    "thumb": Color(0.5, 0.5, 0.55, 1.0)         # Gray
}
```

Colors are symmetric between left and right hands for easy learning.

## Display State

```gdscript
# Display state
var active_charset: String = ""   # Keys currently in lesson
var next_key: String = ""         # Next key to press
var pressed_key: String = ""      # Currently pressed key
var pressed_correct: bool = false # Was the press correct?
var key_rects: Dictionary = {}    # Calculated key positions

# Visual settings
var key_size := Vector2(36, 36)
var key_gap := 4.0
var spacebar_width := 180.0
var font: Font
```

## State Updates

### Update Active Keys

```gdscript
# game/keyboard_display.gd:80
func update_state(charset: String, next: String) -> void:
    active_charset = charset.to_lower()
    next_key = next.to_lower() if next.length() > 0 else ""
    queue_redraw()
```

**Parameters:**
- `charset` - Characters available in current lesson (e.g., "asdfghjkl")
- `next` - The next key the player should press

### Flash Key Feedback

```gdscript
# game/keyboard_display.gd:85
func flash_key(key: String, correct: bool) -> void:
    pressed_key = key.to_lower()
    pressed_correct = correct
    queue_redraw()

    # Clear flash after short delay
    var timer := get_tree().create_timer(0.12)
    await timer.timeout
    if pressed_key == key.to_lower():
        pressed_key = ""
        queue_redraw()
```

Flash duration: 120ms

## Drawing

### Main Draw Function

```gdscript
# game/keyboard_display.gd:96
func _draw() -> void:
    key_rects.clear()
    var y := 0.0

    # Center the keyboard horizontally
    var total_width := 12.0 * (key_size.x + key_gap)
    var start_x := (size.x - total_width) / 2.0

    for row_idx in range(ROWS.size()):
        var row: Array = ROWS[row_idx]
        var x: float = start_x + ROW_OFFSETS[row_idx]

        for key in row:
            var rect: Rect2
            if key == " ":
                # Spacebar is wider and centered
                var spacebar_x := start_x + (total_width - spacebar_width) / 2.0
                rect = Rect2(Vector2(spacebar_x, y), Vector2(spacebar_width, key_size.y))
            else:
                rect = Rect2(Vector2(x, y), key_size)

            key_rects[key] = rect
            _draw_key(key, rect)
            x += key_size.x + key_gap

        y += key_size.y + key_gap
```

### Key Rendering

```gdscript
# game/keyboard_display.gd:123
func _draw_key(key: String, rect: Rect2) -> void:
    var bg_color: Color
    var border_color := Color(0.3, 0.3, 0.35, 1.0)
    var border_width := 1.5
    var text_color := Color(0.9, 0.9, 0.9, 1.0)

    # Determine key state
    var is_active := active_charset.find(key) >= 0
    var is_next := (key == next_key)
    var is_pressed := (key == pressed_key)

    # Background color based on state
    if is_pressed:
        if pressed_correct:
            bg_color = Color(0.2, 0.75, 0.3, 1.0)  # Green
        else:
            bg_color = Color(0.85, 0.25, 0.25, 1.0)  # Red
        border_color = bg_color.lightened(0.3)
        border_width = 2.5
    elif not is_active:
        # Inactive/dimmed key
        bg_color = Color(0.12, 0.12, 0.15, 1.0)
        text_color = Color(0.35, 0.35, 0.4, 1.0)
        border_color = Color(0.2, 0.2, 0.22, 1.0)
    else:
        # Active key - show finger zone color (subtle)
        var finger: String = FINGER_ZONES.get(key, "")
        var zone_color: Color = FINGER_COLORS.get(finger, Color(0.25, 0.25, 0.3, 1.0))
        bg_color = zone_color.lerp(Color(0.18, 0.18, 0.22, 1.0), 0.65)

    # Highlight border for next key
    if is_next:
        border_color = Color(1.0, 0.85, 0.2, 1.0)  # Bright yellow
        border_width = 3.0
        bg_color = bg_color.lightened(0.15)

    # Draw background and border
    draw_rect(rect, bg_color)
    draw_rect(rect, border_color, false, border_width)

    # Draw key label
    var label: String = "SPACE" if key == " " else key.to_upper()
    var font_size: int = 12 if key == " " else 14
    var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
    var text_pos := rect.position + (rect.size - text_size) / 2.0 + Vector2(0, text_size.y * 0.75)
    draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
```

### Home Row Indicators

```gdscript
# F and J keys have tactile bumps
if key == "f" or key == "j":
    var bump_y := rect.position.y + rect.size.y - 8
    var bump_x := rect.position.x + rect.size.x / 2.0
    draw_line(Vector2(bump_x - 6, bump_y), Vector2(bump_x + 6, bump_y), text_color.darkened(0.2), 2.0)
```

## Key States

| State | Background | Border | Text |
|-------|------------|--------|------|
| Inactive | Dark gray | Dark | Dim |
| Active | Zone color (subtle) | Gray | White |
| Next | Zone color (bright) | Yellow (thick) | White |
| Pressed (correct) | Green | Light green | White |
| Pressed (wrong) | Red | Light red | White |

## Integration Examples

### Typing Tutor Integration

```gdscript
@onready var keyboard_display: Control = $KeyboardDisplay

var current_word: String = "castle"
var typed_so_far: String = ""

func _ready() -> void:
    _update_keyboard()

func _update_keyboard() -> void:
    # Get next character to type
    var next_char: String = ""
    if typed_so_far.length() < current_word.length():
        next_char = current_word[typed_so_far.length()]

    # Update display with lesson charset and next key
    keyboard_display.update_state("asdfghjkl", next_char)

func _on_key_pressed(key: String) -> void:
    var expected: String = current_word[typed_so_far.length()]
    var correct: bool = (key == expected)

    keyboard_display.flash_key(key, correct)

    if correct:
        typed_so_far += key
        _update_keyboard()
```

### Lesson-Based Charset

```gdscript
var lesson_charsets: Dictionary = {
    "home_row": "asdfghjkl;",
    "top_row": "qwertyuiop",
    "bottom_row": "zxcvbnm,./",
    "numbers": "1234567890",
    "full": "abcdefghijklmnopqrstuvwxyz1234567890"
}

func set_lesson(lesson_id: String) -> void:
    var charset: String = lesson_charsets.get(lesson_id, "")
    keyboard_display.update_state(charset, "")
```

### Real-Time Feedback

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        var key: String = OS.get_keycode_string(event.keycode).to_lower()
        if key.length() == 1:
            var expected: String = get_next_expected_key()
            var correct: bool = (key == expected)
            keyboard_display.flash_key(key, correct)
```

## Testing

```gdscript
func test_finger_zone_coverage():
    # Verify all keys have zone assignments
    var all_keys: Array[String] = []
    for row in KeyboardDisplay.ROWS:
        for key in row:
            all_keys.append(key)

    for key in all_keys:
        assert(KeyboardDisplay.FINGER_ZONES.has(key),
            "Missing zone for key: %s" % key)

    _pass("test_finger_zone_coverage")

func test_zone_color_symmetry():
    # Verify left/right matching colors
    var pairs := [
        ["left_pinky", "right_pinky"],
        ["left_ring", "right_ring"],
        ["left_middle", "right_middle"],
        ["left_index", "right_index"]
    ]

    for pair in pairs:
        var left_color: Color = KeyboardDisplay.FINGER_COLORS[pair[0]]
        var right_color: Color = KeyboardDisplay.FINGER_COLORS[pair[1]]
        assert(left_color == right_color,
            "Color mismatch: %s vs %s" % [pair[0], pair[1]])

    _pass("test_zone_color_symmetry")

func test_home_row_markers():
    # F and J should have home row markers
    var kb := KeyboardDisplay.new()
    # Verify these keys are in home row
    assert(KeyboardDisplay.FINGER_ZONES["f"] == "left_index")
    assert(KeyboardDisplay.FINGER_ZONES["j"] == "right_index")

    _pass("test_home_row_markers")
```
