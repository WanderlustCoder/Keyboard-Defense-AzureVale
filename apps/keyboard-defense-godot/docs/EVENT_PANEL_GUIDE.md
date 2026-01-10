# Event Panel Guide

This document explains the Event Panel UI component that displays game events with choices and handles text input for event interactions.

## Overview

The Event Panel presents events with choices and optional typed input:

```
Show Event → Display Choices → User Selects → Input Mode (optional) → Emit Signal
     ↓             ↓                ↓                ↓                    ↓
  title/body    choice buttons   _on_choice_pressed  type text        choice_selected
```

## Signals

```gdscript
# ui/components/event_panel.gd
signal choice_selected(choice_id: String, input_text: String)
signal event_skipped
```

## Constants

```gdscript
const TITLE_FONT_SIZE := 22
const BODY_FONT_SIZE := 16
const CHOICE_FONT_SIZE := 14
const INPUT_FONT_SIZE := 18
const FADE_DURATION := 0.2
```

## UI Structure

```gdscript
# Node references
@onready var title_label: Label = $Content/TitleLabel
@onready var body_label: RichTextLabel = $Content/BodyLabel
@onready var choices_container: VBoxContainer = $Content/ChoicesContainer
@onready var input_container: HBoxContainer = $Content/InputContainer
@onready var input_prompt: Label = $Content/InputContainer/InputPrompt
@onready var input_display: Label = $Content/InputContainer/InputDisplay
@onready var skip_hint: Label = $Content/SkipHint
```

## State Variables

```gdscript
var _current_event: Dictionary = {}    # Active event data
var _current_choice_id: String = ""    # Selected choice awaiting input
var _input_text: String = ""           # Typed input buffer
var _panel_tween: Tween = null         # Fade animation
```

## Showing Events

```gdscript
# ui/components/event_panel.gd:59
func show_event(event_data: Dictionary) -> void:
    _current_event = event_data
    _current_choice_id = ""
    _input_text = ""

    # Set title and body
    if title_label:
        title_label.text = str(event_data.get("title", "Event"))
    if body_label:
        body_label.text = str(event_data.get("body", ""))

    # Build choice buttons
    _build_choices(event_data.get("choices", []))

    # Hide input container
    _hide_input()

    # Fade in
    _fade_in()
```

### Event Data Format

```json
{
    "title": "Merchant Encounter",
    "body": "A traveling merchant offers rare goods.",
    "choices": [
        {
            "id": "buy",
            "label": "Purchase wares",
            "input": {
                "mode": "code",
                "text": "confirm"
            }
        },
        {
            "id": "trade",
            "label": "Trade resources",
            "input": {
                "mode": "phrase",
                "text": "fair exchange"
            }
        },
        {
            "id": "decline",
            "label": "Decline offer"
        }
    ]
}
```

## Choice Building

```gdscript
# ui/components/event_panel.gd:75
func _build_choices(choices: Array) -> void:
    if choices_container == null:
        return

    # Clear existing choice buttons
    for child in choices_container.get_children():
        child.queue_free()

    # Create button for each choice
    for choice in choices:
        if typeof(choice) != TYPE_DICTIONARY:
            continue

        var choice_id: String = str(choice.get("id", ""))
        var label: String = str(choice.get("label", ""))
        var input_config: Dictionary = choice.get("input", {})

        var btn := Button.new()
        btn.text = "[%s] %s" % [choice_id.to_upper(), label]
        btn.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn.focus_mode = Control.FOCUS_ALL
        btn.pressed.connect(_on_choice_pressed.bind(choice_id, input_config))
        choices_container.add_child(btn)

    # Focus first button
    await get_tree().process_frame
    if choices_container.get_child_count() > 0:
        choices_container.get_child(0).grab_focus()
```

## Input Modes

### Choice Selection Handler

```gdscript
# ui/components/event_panel.gd:103
func _on_choice_pressed(choice_id: String, input_config: Dictionary) -> void:
    _current_choice_id = choice_id
    _input_text = ""
    var mode: String = str(input_config.get("mode", "code"))

    match mode:
        "code":
            var expected: String = str(input_config.get("text", ""))
            _show_input("Type: %s" % expected, expected)
        "phrase":
            var expected: String = str(input_config.get("text", ""))
            _show_input("Type phrase:", expected)
        "prompt_burst":
            var prompts: Array = input_config.get("prompts", [])
            var prompt_text: String = " ".join(prompts)
            _show_input("Type words:", prompt_text)
        "command":
            var expected: String = str(input_config.get("text", ""))
            _show_input("Command:", expected)
        _:
            # No input required, submit immediately
            choice_selected.emit(choice_id, "")
```

### Input Mode Types

| Mode | Description | Example |
|------|-------------|---------|
| `code` | Type exact code word | "confirm", "accept" |
| `phrase` | Type exact phrase | "fair exchange" |
| `prompt_burst` | Type multiple words | ["go", "fast", "now"] |
| `command` | Type game command | "build tower" |
| (none) | No input required | Immediate selection |

### Show/Hide Input

```gdscript
# ui/components/event_panel.gd:125
func _show_input(prompt: String, expected: String) -> void:
    if input_container:
        input_container.visible = true
    if input_prompt:
        input_prompt.text = prompt
    if input_display:
        input_display.text = "_"
    if choices_container:
        choices_container.visible = false
    if skip_hint:
        skip_hint.text = "Press Escape to cancel"

func _hide_input() -> void:
    if input_container:
        input_container.visible = false
    if choices_container:
        choices_container.visible = true
    if skip_hint:
        skip_hint.text = "Press Escape to skip event"
```

## Input Handling

```gdscript
# ui/components/event_panel.gd:145
func _input(event: InputEvent) -> void:
    if not visible:
        return

    # Handle escape to skip or cancel
    if event.is_action_pressed("ui_cancel"):
        if _current_choice_id != "":
            # Cancel current input, go back to choices
            _current_choice_id = ""
            _input_text = ""
            _hide_input()
            _build_choices(_current_event.get("choices", []))
        else:
            # Skip event entirely
            event_skipped.emit()
        accept_event()
        return

    # Handle text input when in input mode
    if _current_choice_id != "" and event is InputEventKey and event.is_pressed():
        match event.keycode:
            KEY_BACKSPACE:
                if _input_text.length() > 0:
                    _input_text = _input_text.substr(0, _input_text.length() - 1)
                    _update_input_display()
                accept_event()
            KEY_ENTER, KEY_KP_ENTER:
                # Submit input
                choice_selected.emit(_current_choice_id, _input_text)
                accept_event()
            _:
                if event.unicode > 0:
                    var char := String.chr(event.unicode)
                    if char.length() == 1:
                        _input_text += char
                        _update_input_display()
                    accept_event()
```

### Input Display Update

```gdscript
# ui/components/event_panel.gd:181
func _update_input_display() -> void:
    if input_display:
        if _input_text == "":
            input_display.text = "_"
        else:
            input_display.text = _input_text + "_"
```

## Result Display

```gdscript
# ui/components/event_panel.gd:188
func show_result(success: bool, message: String) -> void:
    if body_label:
        if success:
            body_label.text = "[color=#88cc88]%s[/color]" % message
        else:
            body_label.text = "[color=#cc8888]%s[/color]" % message

    # Hide choices and input
    if choices_container:
        choices_container.visible = false
    if input_container:
        input_container.visible = false
    if skip_hint:
        skip_hint.text = "Press any key to continue"
```

## Fade Animations

```gdscript
# ui/components/event_panel.gd:205
func _fade_in() -> void:
    if _panel_tween != null and _panel_tween.is_valid():
        _panel_tween.kill()
    visible = true
    modulate.a = 0.0
    _panel_tween = create_tween()
    _panel_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

func _fade_out() -> void:
    if _panel_tween != null and _panel_tween.is_valid():
        _panel_tween.kill()
    _panel_tween = create_tween()
    _panel_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
    _panel_tween.tween_callback(func(): visible = false)

func hide_panel() -> void:
    _fade_out()
```

## Utility Functions

```gdscript
func is_active() -> bool:
    return visible

func get_current_event() -> Dictionary:
    return _current_event

func clear() -> void:
    _current_event = {}
    _current_choice_id = ""
    _input_text = ""
    if title_label:
        title_label.text = ""
    if body_label:
        body_label.text = ""
    if choices_container:
        for child in choices_container.get_children():
            child.queue_free()
    _hide_input()
```

## Styling

```gdscript
# ui/components/event_panel.gd:39
func _apply_styling() -> void:
    if title_label:
        title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
        title_label.add_theme_color_override("font_color", ThemeColors.ACCENT)

    if body_label:
        body_label.add_theme_font_size_override("normal_font_size", BODY_FONT_SIZE)

    if input_prompt:
        input_prompt.add_theme_font_size_override("font_size", INPUT_FONT_SIZE)
        input_prompt.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

    if input_display:
        input_display.add_theme_font_size_override("font_size", INPUT_FONT_SIZE)
        input_display.add_theme_color_override("font_color", ThemeColors.ACCENT)

    if skip_hint:
        skip_hint.add_theme_font_size_override("font_size", 12)
        skip_hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
```

## Integration Example

```gdscript
# In main game controller
func _ready() -> void:
    if event_panel != null:
        event_panel.visible = false
        if event_panel.has_signal("choice_selected"):
            event_panel.choice_selected.connect(_on_event_choice_selected)
        if event_panel.has_signal("event_skipped"):
            event_panel.event_skipped.connect(_on_event_skipped)

func _show_event(event_data: Dictionary) -> void:
    event_visible = true
    event_panel.show_event(event_data)

func _on_event_choice_selected(choice_id: String, input_text: String) -> void:
    # Validate input if needed
    var event: Dictionary = event_panel.get_current_event()
    var choice: Dictionary = _find_choice(event, choice_id)
    var expected: String = str(choice.get("input", {}).get("text", ""))

    if expected != "" and input_text.to_lower() != expected.to_lower():
        event_panel.show_result(false, "Incorrect input. Try again.")
        return

    # Apply event effects
    var effects: Dictionary = choice.get("effects", {})
    _apply_event_effects(effects)

    event_panel.show_result(true, "Success!")
    await get_tree().create_timer(1.0).timeout
    event_panel.hide_panel()
    event_visible = false

func _on_event_skipped() -> void:
    event_panel.hide_panel()
    event_visible = false
    _append_log(["Event skipped."])
```

## Testing

```gdscript
func test_choice_button_creation():
    var panel := preload("res://ui/components/event_panel.gd").new()

    var choices := [
        {"id": "a", "label": "Option A"},
        {"id": "b", "label": "Option B"},
        {"id": "c", "label": "Option C"}
    ]

    panel._build_choices(choices)

    # Verify button count (after frame)
    await get_tree().process_frame
    assert(panel.choices_container.get_child_count() == 3)

    _pass("test_choice_button_creation")

func test_input_mode_switching():
    var panel := preload("res://ui/components/event_panel.gd").new()

    # Simulate code input mode
    panel._on_choice_pressed("test", {"mode": "code", "text": "confirm"})
    assert(panel._current_choice_id == "test")
    assert(panel.input_container.visible)
    assert(not panel.choices_container.visible)

    _pass("test_input_mode_switching")

func test_input_text_accumulation():
    var panel := preload("res://ui/components/event_panel.gd").new()
    panel._current_choice_id = "test"
    panel._input_text = ""

    # Simulate typing
    panel._input_text += "h"
    panel._input_text += "e"
    panel._input_text += "l"
    panel._input_text += "l"
    panel._input_text += "o"

    assert(panel._input_text == "hello")

    _pass("test_input_text_accumulation")
```

## User Flow

1. **Event Appears**: Panel fades in with title, body, and choice buttons
2. **Browse Choices**: User navigates with keyboard/mouse
3. **Select Choice**:
   - If no input required → emit `choice_selected` immediately
   - If input required → switch to input mode
4. **Input Mode**:
   - Type expected text
   - Press Enter to submit
   - Press Escape to cancel and return to choices
5. **Result Display**: Show success/failure message
6. **Close**: Panel fades out

### Input Flow States

```
[Choice View] --select--> [Input Mode] --enter--> [Submit]
      ^                         |
      |                         |
      +--------escape-----------+

[Choice View] --escape--> [Skip Event]
```
