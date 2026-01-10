# Dialogue Box Guide

This document explains the dialogue box component used for story conversations and narrative sequences.

## Overview

The dialogue box displays multi-line conversations with optional auto-advance:

```
show_dialogue() → Display Line → Wait for Input → Advance → Finish
       ↓              ↓              ↓              ↓          ↓
   set lines      show text     Enter/click    next line   emit signal
```

## Scene Structure

```gdscript
# game/dialogue_box.gd
extends Control

signal dialogue_finished

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/VBox/TextLabel
@onready var continue_label: Label = $Panel/VBox/ContinueLabel
```

## State Variables

```gdscript
var dialogue_lines: Array[String] = []     # All lines to display
var current_line_index: int = 0            # Current line being shown
var is_active: bool = false                # Whether dialogue is running
var auto_advance_timer: float = 0.0        # Timer for auto-advance
var auto_advance_delay: float = 0.0        # 0 = manual advance only
```

## Showing Dialogue

### Main Entry Point

```gdscript
# game/dialogue_box.gd:25
func show_dialogue(speaker: String, lines: Array[String], auto_delay: float = 0.0) -> void:
    if lines.is_empty():
        return

    dialogue_lines = lines
    current_line_index = 0
    auto_advance_delay = auto_delay

    if speaker_label:
        speaker_label.text = speaker
        speaker_label.visible = not speaker.is_empty()

    _show_current_line()
    visible = true
    is_active = true

    # Grab focus to capture input
    grab_focus()
```

**Parameters:**
- `speaker` - Character name to display (empty string hides speaker label)
- `lines` - Array of dialogue text lines
- `auto_delay` - Seconds between auto-advances (0 = manual only)

### Display Current Line

```gdscript
# game/dialogue_box.gd:44
func _show_current_line() -> void:
    if current_line_index >= dialogue_lines.size():
        _finish_dialogue()
        return

    var line: String = dialogue_lines[current_line_index]
    if text_label:
        text_label.text = line

    auto_advance_timer = 0.0
```

## Advancing Dialogue

### Manual Advance

```gdscript
# game/dialogue_box.gd:55
func advance_line() -> void:
    if not is_active:
        return

    current_line_index += 1
    if current_line_index >= dialogue_lines.size():
        _finish_dialogue()
    else:
        _show_current_line()
```

### Auto-Advance

```gdscript
# game/dialogue_box.gd:75
func _process(delta: float) -> void:
    if not is_active:
        return

    # Auto-advance if enabled
    if auto_advance_delay > 0:
        auto_advance_timer += delta
        if auto_advance_timer >= auto_advance_delay:
            advance_line()
```

## Input Handling

### GUI Input

```gdscript
# game/dialogue_box.gd:85
func _gui_input(event: InputEvent) -> void:
    if not is_active:
        return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
            advance_line()
            accept_event()
        elif event.keycode == KEY_ESCAPE:
            skip_dialogue()
            accept_event()

    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            advance_line()
            accept_event()
```

### Global Input Fallback

```gdscript
# game/dialogue_box.gd:102
func _input(event: InputEvent) -> void:
    if not is_active:
        return

    # Global input handler for when focus isn't on the dialogue box
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
            advance_line()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_ESCAPE:
            skip_dialogue()
            get_viewport().set_input_as_handled()
```

## Finishing Dialogue

### Normal Finish

```gdscript
# game/dialogue_box.gd:65
func _finish_dialogue() -> void:
    visible = false
    is_active = false
    dialogue_lines.clear()
    current_line_index = 0
    emit_signal("dialogue_finished")
```

### Skip Dialogue

```gdscript
# game/dialogue_box.gd:72
func skip_dialogue() -> void:
    _finish_dialogue()
```

Escape key skips entire dialogue sequence.

## Input Controls

| Input | Action |
|-------|--------|
| Enter | Advance to next line |
| Space | Advance to next line |
| Left Click | Advance to next line |
| Escape | Skip all remaining lines |

## Integration Examples

### Story Event

```gdscript
@onready var dialogue_box: Control = $DialogueBox

func _ready() -> void:
    dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func show_story_event(event_id: String) -> void:
    var dialogue: Dictionary = StoryManager.get_dialogue(event_id)
    var speaker: String = dialogue.get("speaker", "")
    var lines: Array[String] = dialogue.get("lines", [])

    dialogue_box.show_dialogue(speaker, lines)

func _on_dialogue_finished() -> void:
    # Resume gameplay
    _unpause_game()
```

### Tutorial Sequence

```gdscript
func show_tutorial() -> void:
    var lines: Array[String] = [
        "Welcome to Keyboard Defense!",
        "Type the words on screen to defeat enemies.",
        "The faster you type, the more damage you deal.",
        "Good luck, defender!"
    ]
    dialogue_box.show_dialogue("Guide", lines)
```

### Auto-Advancing Cutscene

```gdscript
func show_cutscene() -> void:
    var lines: Array[String] = [
        "The kingdom was peaceful...",
        "Until the Void Tyrant arrived.",
        "Now only you can save us."
    ]
    # Auto-advance every 3 seconds
    dialogue_box.show_dialogue("Narrator", lines, 3.0)
```

### Multiple Speakers

```gdscript
var conversation_queue: Array[Dictionary] = []

func queue_conversation() -> void:
    conversation_queue = [
        {"speaker": "King", "lines": ["Defender! The enemy approaches!"]},
        {"speaker": "Commander", "lines": ["We need you at the walls!"]},
        {"speaker": "King", "lines": ["Go now! And may fortune favor you."]}
    ]
    _show_next_part()

func _show_next_part() -> void:
    if conversation_queue.is_empty():
        _conversation_complete()
        return

    var part: Dictionary = conversation_queue.pop_front()
    dialogue_box.show_dialogue(part.speaker, part.lines)

func _on_dialogue_finished() -> void:
    _show_next_part()
```

### With Typing Pause

```gdscript
var typing_paused: bool = false

func show_important_message(message: String) -> void:
    typing_paused = true
    input_field.editable = false

    dialogue_box.show_dialogue("System", [message])

func _on_dialogue_finished() -> void:
    typing_paused = false
    input_field.editable = true
    input_field.grab_focus()
```

## Ready State

```gdscript
# game/dialogue_box.gd:19
func _ready() -> void:
    visible = false
    is_active = false
    if continue_label:
        continue_label.text = "Press [Enter] or click to continue..."
```

Dialogue box starts hidden and inactive.

## Testing

```gdscript
func test_dialogue_flow():
    var box := DialogueBox.new()
    add_child(box)

    var lines: Array[String] = ["Line 1", "Line 2", "Line 3"]
    box.show_dialogue("Speaker", lines)

    assert(box.is_active)
    assert(box.visible)
    assert(box.current_line_index == 0)

    box.advance_line()
    assert(box.current_line_index == 1)

    box.advance_line()
    assert(box.current_line_index == 2)

    box.advance_line()
    assert(not box.is_active)
    assert(not box.visible)

    box.queue_free()
    _pass("test_dialogue_flow")

func test_skip_dialogue():
    var box := DialogueBox.new()
    add_child(box)

    box.show_dialogue("Speaker", ["Line 1", "Line 2", "Line 3"])
    assert(box.is_active)

    box.skip_dialogue()
    assert(not box.is_active)
    assert(box.dialogue_lines.is_empty())

    box.queue_free()
    _pass("test_skip_dialogue")

func test_auto_advance():
    var box := DialogueBox.new()
    add_child(box)

    box.show_dialogue("Speaker", ["Line 1", "Line 2"], 0.1)
    assert(box.auto_advance_delay == 0.1)

    # Simulate time passing
    box._process(0.15)
    assert(box.current_line_index == 1)

    box.queue_free()
    _pass("test_auto_advance")

func test_empty_speaker():
    var box := DialogueBox.new()
    add_child(box)

    box.show_dialogue("", ["Narrator text"])
    # Speaker label should be hidden
    assert(not box.speaker_label.visible)

    box.queue_free()
    _pass("test_empty_speaker")
```
