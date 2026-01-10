# Controls Formatter Guide

Utility classes for keybind parsing, formatting, and display.

## Overview

The controls system provides bidirectional conversion between:
- `InputEventKey` - Godot's native key event
- `Dictionary` keybind - Serializable keybind representation
- `String` text - Human-readable key representation (e.g., "Ctrl+Shift+A")

## ControlsFormatter (game/controls_formatter.gd)

Main utility class for keybind conversion and display.

### Keybind Dictionary Format

```gdscript
{
    "keycode": int,      # Godot KEY_* constant
    "shift": bool,       # Shift modifier
    "alt": bool,         # Alt modifier
    "ctrl": bool,        # Ctrl modifier
    "meta": bool         # Meta/Cmd/Win modifier
}
```

### Conversion Functions

#### Event to Keybind

```gdscript
# Convert InputEventKey to keybind dictionary
static func keybind_from_event(event: InputEventKey) -> Dictionary
# Returns: {"keycode": 65, "shift": false, "alt": false, "ctrl": true, "meta": false}
```

#### Keybind to Event

```gdscript
# Convert keybind dictionary to InputEventKey
static func event_from_keybind(keybind: Dictionary) -> InputEventKey
# Returns: InputEventKey with keycode and modifiers set
```

#### Event to Text

```gdscript
# Convert InputEventKey to display string
static func key_text_from_event(event: InputEventKey) -> String
# Returns: "Ctrl+A"
```

#### Keybind to Text

```gdscript
# Convert keybind dictionary to display string
static func keybind_to_text(keybind: Dictionary) -> String
# Returns: "Ctrl+Shift+F1"
```

### Text Parsing Functions

#### Parse Key Text

```gdscript
# Parse text into keybind with error handling
static func parse_key_text(text: String) -> Dictionary
# Returns: {"ok": bool, "keybind": Dictionary, "error": String}

# Example success:
# {"ok": true, "keybind": {"keycode": 65, "shift": true, ...}, "error": ""}

# Example failure:
# {"ok": false, "keybind": {}, "error": "Unknown key."}
```

#### Text to Keybind

```gdscript
# Parse text directly to keybind (ignores errors)
static func keybind_from_text(text: String) -> Dictionary

# Parse text to InputEventKey
static func event_from_text(text: String) -> InputEventKey

# Normalize text through parse/format cycle
static func canonicalize_key_text(text: String) -> String
# "ctrl+shift+a" -> "Ctrl+Shift+A"
```

#### Key Name to Keycode

```gdscript
# Convert key name to Godot keycode
static func keycode_from_text(text: String) -> int
# "A" -> 65 (KEY_A)
# "F1" -> 4194332 (KEY_F1)
# "Delete" -> 4194312 (KEY_DELETE)
```

### Action Display Functions

```gdscript
# Get display text for an InputMap action
static func binding_text_for_action(action_name: String) -> String
# Returns: "A / Ctrl+B" (multiple bindings separated by " / ")
# Returns: "Unbound" if no bindings
# Returns: "Missing (InputMap)" if action doesn't exist

# Format multiple actions as aligned list
static func format_controls_list(actions: PackedStringArray) -> String
# Returns:
# "Move Up (move_up):     W / Up
#  Move Down (move_down): S / Down"
```

## ControlsAliases (game/controls_aliases.gd)

Helper class for key name normalization and alias resolution.

### Modifier Aliases

```gdscript
const MODIFIER_ALIASES := {
    "CTRL": "ctrl",
    "CONTROL": "ctrl",
    "ALT": "alt",
    "OPTION": "alt",      # macOS
    "SHIFT": "shift",
    "META": "meta",
    "CMD": "meta",        # macOS
    "COMMAND": "meta",
    "SUPER": "meta",
    "WIN": "meta",        # Windows
    "WINDOWS": "meta"
}
```

### Key Aliases

```gdscript
const KEY_ALIASES := {
    "INS": KEY_INSERT,
    "INSERT": KEY_INSERT,
    "DEL": KEY_DELETE,
    "DELETE": KEY_DELETE,
    "HOME": KEY_HOME,
    "END": KEY_END,
    "PAGEUP": KEY_PAGEUP,
    "PGUP": KEY_PAGEUP,
    "PAGEDOWN": KEY_PAGEDOWN,
    "PGDN": KEY_PAGEDOWN,
    "PRINTSCREEN": KEY_PRINT,
    "PRTSC": KEY_PRINT,
    "PAUSE": KEY_PAUSE,
    "BREAK": KEY_PAUSE,
    ...
}
```

### Utility Functions

```gdscript
# Normalize token (uppercase, remove spaces/dashes/underscores)
static func normalize_token(raw: String) -> String
# "page down" -> "PAGEDOWN"
# "Page-Down" -> "PAGEDOWN"

# Check if token is a modifier
static func is_modifier_token(norm: String) -> bool

# Apply modifier to event
static func apply_modifier_token(event: InputEventKey, norm: String) -> void

# Get keycode from normalized token
static func keycode_from_token(norm: String) -> int
```

### Function Key Handling

Function keys F1-F12 are parsed specially:

```gdscript
static func _fn_keycode(n: int) -> int:
    match n:
        1: return KEY_F1
        2: return KEY_F2
        # ... through F12
```

## Usage Examples

### Parsing User Input

```gdscript
# User types "ctrl+shift+s" in rebind field
var result = ControlsFormatter.parse_key_text("ctrl+shift+s")
if result.ok:
    var keybind = result.keybind
    # Save keybind to settings
    profile.keybinds["save"] = keybind
else:
    # Show error to user
    print("Error: ", result.error)
```

### Displaying Current Binding

```gdscript
# Show current binding for an action
var text = ControlsFormatter.binding_text_for_action("game_pause")
label.text = "Pause: %s" % text
# Output: "Pause: Escape / P"
```

### Applying Keybind to InputMap

```gdscript
# Load keybind from settings and apply
var keybind = profile.keybinds.get("jump", {})
if not keybind.is_empty():
    var event = ControlsFormatter.event_from_keybind(keybind)
    if event != null:
        InputMap.action_erase_events("jump")
        InputMap.action_add_event("jump", event)
```

### Saving Keybinds to Profile

```gdscript
# When user presses a key during rebind
func _on_rebind_key_pressed(event: InputEventKey) -> void:
    var keybind = ControlsFormatter.keybind_from_event(event)
    current_profile.keybinds[current_action] = keybind

    # Update display
    var text = ControlsFormatter.keybind_to_text(keybind)
    rebind_label.text = text
```

### Formatting Controls Help

```gdscript
# Display all rebindable controls
var actions = RebindableActions.get_all()
var text = ControlsFormatter.format_controls_list(actions)
help_label.text = text
```

## Integration with Typing Profile

The keybind system integrates with `TypingProfile` for persistence:

```gdscript
# In TypingProfile
var keybinds: Dictionary = {}  # action_name -> keybind Dictionary

func save_to_disk() -> void:
    # Keybinds are serialized as Dictionary
    data["keybinds"] = keybinds

func load_from_disk() -> void:
    keybinds = data.get("keybinds", {})
    _apply_keybinds_to_inputmap()

func _apply_keybinds_to_inputmap() -> void:
    for action_name in keybinds.keys():
        var keybind = keybinds[action_name]
        var event = ControlsFormatter.event_from_keybind(keybind)
        if event != null:
            InputMap.action_erase_events(action_name)
            InputMap.action_add_event(action_name, event)
```

## Error Handling

Parse errors return specific messages:

| Error | Meaning |
|-------|---------|
| "Expected a key name." | Empty input or only modifiers |
| "Invalid key string." | Malformed syntax |
| "Multiple keys specified." | More than one non-modifier key |
| "Unknown key." | Key name not recognized |

## Text Format Specification

Valid key text format:
```
[Modifier+]...[Modifier+]Key

Examples:
  A
  Ctrl+A
  Ctrl+Shift+A
  Alt+F4
  Ctrl+Alt+Delete
```

Modifiers (case-insensitive):
- `Ctrl`, `Control`
- `Alt`, `Option`
- `Shift`
- `Meta`, `Cmd`, `Command`, `Super`, `Win`, `Windows`

Keys:
- Single letters: A-Z
- Numbers: 0-9
- Function keys: F1-F12
- Special keys: Space, Enter, Tab, Escape, Backspace
- Navigation: Home, End, PageUp, PageDown, Insert, Delete
- Arrows: Up, Down, Left, Right

## File Dependencies

- `game/controls_formatter.gd` - Main formatter class
- `game/controls_aliases.gd` - Alias definitions
- `game/rebindable_actions.gd` - Action display names
- `game/typing_profile.gd` - Keybind persistence
