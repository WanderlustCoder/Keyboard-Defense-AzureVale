# Keyboard Layout Support

**Created:** 2026-01-08

Complete specification for supporting multiple keyboard layouts and input methods.

---

## Overview

### Supported Layouts

```
┌─────────────────────────────────────────────────────────────┐
│                 KEYBOARD LAYOUT SUPPORT                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PRIMARY SUPPORT (Full feature parity)                      │
│  ├── QWERTY (US)                                           │
│  ├── QWERTY (UK)                                           │
│  ├── QWERTZ (German)                                       │
│  ├── AZERTY (French)                                       │
│  └── Dvorak                                                │
│                                                             │
│  SECONDARY SUPPORT (Basic functionality)                    │
│  ├── Colemak                                               │
│  ├── Workman                                               │
│  ├── QWERTY (International variants)                       │
│  └── Custom user-defined                                   │
│                                                             │
│  PLANNED FUTURE SUPPORT                                     │
│  ├── Cyrillic layouts                                      │
│  ├── Asian language support                                │
│  └── Mobile/touch layouts                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Layout Definitions

### QWERTY (US) - Reference Layout

```json
{
  "layout_id": "qwerty_us",
  "name": "QWERTY (US)",
  "region": "United States",
  "default": true,
  "rows": [
    {
      "row": "number",
      "keys": ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="],
      "shift": ["~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+"]
    },
    {
      "row": "top",
      "keys": ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\"],
      "shift": ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}", "|"],
      "fingers": [4, 3, 2, 1, 1, 1, 1, 2, 3, 4, 4, 4, 4]
    },
    {
      "row": "home",
      "keys": ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"],
      "shift": ["A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "\""],
      "fingers": [4, 3, 2, 1, 1, 1, 1, 2, 3, 4, 4],
      "home_keys": true
    },
    {
      "row": "bottom",
      "keys": ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"],
      "shift": ["Z", "X", "C", "V", "B", "N", "M", "<", ">", "?"],
      "fingers": [4, 3, 2, 1, 1, 1, 1, 2, 3, 4]
    },
    {
      "row": "space",
      "keys": [" "],
      "fingers": [0]
    }
  ],
  "finger_names": {
    "0": "thumb",
    "1": "index",
    "2": "middle",
    "3": "ring",
    "4": "pinky"
  },
  "hand_assignment": {
    "left": ["q", "w", "e", "r", "t", "a", "s", "d", "f", "g", "z", "x", "c", "v", "b"],
    "right": ["y", "u", "i", "o", "p", "h", "j", "k", "l", ";", "'", "n", "m", ",", ".", "/"]
  }
}
```

### QWERTZ (German)

```json
{
  "layout_id": "qwertz_de",
  "name": "QWERTZ (German)",
  "region": "Germany",
  "rows": [
    {
      "row": "number",
      "keys": ["^", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "ß", "´"],
      "shift": ["°", "!", "\"", "§", "$", "%", "&", "/", "(", ")", "=", "?", "`"]
    },
    {
      "row": "top",
      "keys": ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p", "ü", "+"],
      "shift": ["Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "Ü", "*"],
      "note": "Y and Z are swapped from QWERTY"
    },
    {
      "row": "home",
      "keys": ["a", "s", "d", "f", "g", "h", "j", "k", "l", "ö", "ä", "#"],
      "shift": ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ö", "Ä", "'"]
    },
    {
      "row": "bottom",
      "keys": ["<", "y", "x", "c", "v", "b", "n", "m", ",", ".", "-"],
      "shift": [">", "Y", "X", "C", "V", "B", "N", "M", ";", ":", "_"]
    }
  ],
  "special_characters": {
    "umlauts": ["ä", "ö", "ü", "ß"],
    "default_in_lessons": false,
    "advanced_lessons_only": true
  }
}
```

### AZERTY (French)

```json
{
  "layout_id": "azerty_fr",
  "name": "AZERTY (French)",
  "region": "France",
  "rows": [
    {
      "row": "number",
      "keys": ["²", "&", "é", "\"", "'", "(", "-", "è", "_", "ç", "à", ")", "="],
      "shift": ["", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "°", "+"]
    },
    {
      "row": "top",
      "keys": ["a", "z", "e", "r", "t", "y", "u", "i", "o", "p", "^", "$"],
      "shift": ["A", "Z", "E", "R", "T", "Y", "U", "I", "O", "P", "¨", "£"],
      "note": "A and Q swapped, Z and W swapped"
    },
    {
      "row": "home",
      "keys": ["q", "s", "d", "f", "g", "h", "j", "k", "l", "m", "ù", "*"],
      "shift": ["Q", "S", "D", "F", "G", "H", "J", "K", "L", "M", "%", "µ"]
    },
    {
      "row": "bottom",
      "keys": ["<", "w", "x", "c", "v", "b", "n", ",", ";", ":", "!"],
      "shift": [">", "W", "X", "C", "V", "B", "N", "?", ".", "/", "§"]
    }
  ],
  "special_characters": {
    "accents": ["é", "è", "ê", "ë", "à", "â", "ù", "û", "ô", "î", "ï", "ç"],
    "accent_dead_keys": ["^", "¨"],
    "note": "Dead keys modify next character"
  }
}
```

### Dvorak

```json
{
  "layout_id": "dvorak",
  "name": "Dvorak Simplified",
  "region": "International",
  "rows": [
    {
      "row": "number",
      "keys": ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "[", "]"],
      "shift": ["~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "{", "}"]
    },
    {
      "row": "top",
      "keys": ["'", ",", ".", "p", "y", "f", "g", "c", "r", "l", "/", "=", "\\"],
      "shift": ["\"", "<", ">", "P", "Y", "F", "G", "C", "R", "L", "?", "+", "|"]
    },
    {
      "row": "home",
      "keys": ["a", "o", "e", "u", "i", "d", "h", "t", "n", "s", "-"],
      "shift": ["A", "O", "E", "U", "I", "D", "H", "T", "N", "S", "_"],
      "home_keys": true,
      "note": "Home row contains most common letters"
    },
    {
      "row": "bottom",
      "keys": [";", "q", "j", "k", "x", "b", "m", "w", "v", "z"],
      "shift": [":", "Q", "J", "K", "X", "B", "M", "W", "V", "Z"]
    }
  ],
  "benefits": [
    "70% of typing on home row (vs 32% QWERTY)",
    "Reduced finger travel",
    "Alternating hand patterns"
  ]
}
```

### Colemak

```json
{
  "layout_id": "colemak",
  "name": "Colemak",
  "region": "International",
  "rows": [
    {
      "row": "top",
      "keys": ["q", "w", "f", "p", "g", "j", "l", "u", "y", ";", "[", "]", "\\"],
      "shift": ["Q", "W", "F", "P", "G", "J", "L", "U", "Y", ":", "{", "}", "|"]
    },
    {
      "row": "home",
      "keys": ["a", "r", "s", "t", "d", "h", "n", "e", "i", "o", "'"],
      "shift": ["A", "R", "S", "T", "D", "H", "N", "E", "I", "O", "\""],
      "home_keys": true
    },
    {
      "row": "bottom",
      "keys": ["z", "x", "c", "v", "b", "k", "m", ",", ".", "/"],
      "shift": ["Z", "X", "C", "V", "B", "K", "M", "<", ">", "?"]
    }
  ],
  "qwerty_similarity": "17 keys unchanged from QWERTY",
  "benefits": [
    "Easier transition from QWERTY",
    "Better ergonomics than QWERTY",
    "Caps Lock becomes Backspace"
  ]
}
```

---

## Layout Detection

### Auto-Detection System

```json
{
  "layout_detection": {
    "methods": [
      {
        "priority": 1,
        "method": "os_keyboard_layout",
        "description": "Read from operating system settings"
      },
      {
        "priority": 2,
        "method": "input_test",
        "description": "Test keycode to character mapping"
      },
      {
        "priority": 3,
        "method": "user_selection",
        "description": "Manual selection from settings"
      }
    ],
    "test_keys": {
      "qwerty_vs_dvorak": ["KEY_Q", "KEY_SEMICOLON"],
      "qwerty_vs_azerty": ["KEY_A", "KEY_Q"],
      "qwerty_vs_qwertz": ["KEY_Y", "KEY_Z"]
    }
  }
}
```

### Layout Detection Code

```gdscript
# keyboard_layout_detector.gd

class_name KeyboardLayoutDetector
extends Node

signal layout_detected(layout_id: String)

func detect_layout() -> String:
    # Try OS detection first
    var os_layout := _detect_from_os()
    if os_layout != "":
        return os_layout

    # Fall back to saved preference
    var saved := Settings.get("keyboard_layout", "")
    if saved != "":
        return saved

    # Default to QWERTY US
    return "qwerty_us"

func _detect_from_os() -> String:
    var locale := OS.get_locale_language()

    match locale:
        "de":
            return "qwertz_de"
        "fr":
            return "azerty_fr"
        "en":
            return "qwerty_us"

    return ""

func run_detection_test() -> String:
    # Prompt user to press specific keys
    # Compare scancodes to expected characters
    pass
```

---

## Lesson Adaptation

### Layout-Specific Lessons

```json
{
  "lesson_adaptation": {
    "home_row": {
      "qwerty_us": {
        "left_hand": ["a", "s", "d", "f"],
        "right_hand": ["j", "k", "l", ";"]
      },
      "dvorak": {
        "left_hand": ["a", "o", "e", "u"],
        "right_hand": ["h", "t", "n", "s"],
        "note": "More vowels on left, consonants on right"
      },
      "azerty_fr": {
        "left_hand": ["q", "s", "d", "f"],
        "right_hand": ["j", "k", "l", "m"]
      }
    },
    "lesson_generation": {
      "method": "layout_aware",
      "considerations": [
        "Use only keys available in current layout",
        "Adjust finger assignments per layout",
        "Special characters differ by layout"
      ]
    }
  }
}
```

### Finger Guide Adaptation

```json
{
  "finger_guides": {
    "qwerty_us": {
      "description": "Standard QWERTY finger placement",
      "home_position": "F and J have bumps",
      "guide_image": "guides/qwerty_fingers.png"
    },
    "dvorak": {
      "description": "Dvorak finger placement",
      "home_position": "U and H are home keys",
      "guide_image": "guides/dvorak_fingers.png",
      "note": "Most common letters on home row"
    },
    "azerty_fr": {
      "description": "AZERTY finger placement",
      "home_position": "F and J have bumps",
      "guide_image": "guides/azerty_fingers.png",
      "note": "Numbers require Shift key"
    }
  }
}
```

---

## Word Lists Per Layout

### Layout-Optimized Words

```json
{
  "layout_word_lists": {
    "qwerty_home_row": {
      "letters": ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
      "words": ["sad", "ash", "all", "fall", "glass", "flash", "salad"]
    },
    "dvorak_home_row": {
      "letters": ["a", "o", "e", "u", "i", "d", "h", "t", "n", "s"],
      "words": ["the", "and", "that", "this", "into", "said", "then", "than"]
    },
    "azerty_home_row": {
      "letters": ["q", "s", "d", "f", "g", "h", "j", "k", "l", "m"],
      "words": ["shall", "glass", "flash", "small", "skill"]
    }
  }
}
```

### Language-Specific Content

```json
{
  "language_content": {
    "english": {
      "layouts": ["qwerty_us", "qwerty_uk", "dvorak", "colemak"],
      "word_sources": ["common_english.json"],
      "includes_special": false
    },
    "german": {
      "layouts": ["qwertz_de"],
      "word_sources": ["common_german.json"],
      "includes_special": true,
      "special_chars": ["ä", "ö", "ü", "ß"]
    },
    "french": {
      "layouts": ["azerty_fr"],
      "word_sources": ["common_french.json"],
      "includes_special": true,
      "special_chars": ["é", "è", "ê", "à", "ç"]
    }
  }
}
```

---

## Keyboard Display

### Visual Keyboard Rendering

```json
{
  "keyboard_display": {
    "render_options": {
      "show_layout": true,
      "highlight_next_key": true,
      "show_finger_colors": true,
      "animate_key_press": true
    },
    "layout_specific": {
      "qwertz_de": {
        "extra_keys": ["ä", "ö", "ü"],
        "key_labels": "German labels"
      },
      "azerty_fr": {
        "number_row": "symbols_default",
        "shift_for_numbers": true
      }
    },
    "finger_colors": {
      "left_pinky": "#E74C3C",
      "left_ring": "#E67E22",
      "left_middle": "#F1C40F",
      "left_index": "#2ECC71",
      "right_index": "#2ECC71",
      "right_middle": "#F1C40F",
      "right_ring": "#E67E22",
      "right_pinky": "#E74C3C",
      "thumbs": "#3498DB"
    }
  }
}
```

### Key Label System

```gdscript
# keyboard_display.gd

func get_key_label(scancode: int, layout: String) -> String:
    var layout_data := LayoutManager.get_layout(layout)

    # Find the key in layout data
    for row in layout_data.rows:
        var key_index := _find_key_by_scancode(row, scancode)
        if key_index >= 0:
            return row.keys[key_index]

    return ""

func render_keyboard(layout: String) -> void:
    var layout_data := LayoutManager.get_layout(layout)

    for row_data in layout_data.rows:
        var row_node := _create_row_node(row_data.row)

        for i in range(row_data.keys.size()):
            var key := row_data.keys[i]
            var finger := row_data.fingers[i] if row_data.has("fingers") else -1
            var key_node := _create_key_node(key, finger)
            row_node.add_child(key_node)
```

---

## Input Handling

### Layout-Aware Input

```gdscript
# input_handler.gd

class_name LayoutAwareInput
extends Node

var current_layout: String = "qwerty_us"
var layout_data: Dictionary = {}

func _ready() -> void:
    current_layout = KeyboardLayoutDetector.detect_layout()
    layout_data = LayoutManager.get_layout(current_layout)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        var character := _get_character_for_event(event)
        if character != "":
            emit_signal("character_typed", character)

func _get_character_for_event(event: InputEventKey) -> String:
    # Get the actual character based on layout
    var scancode := event.keycode
    var shift := event.shift_pressed

    return _scancode_to_char(scancode, shift)

func _scancode_to_char(scancode: int, shift: bool) -> String:
    # Map scancode to character based on current layout
    for row in layout_data.rows:
        var index := _find_scancode_in_row(row, scancode)
        if index >= 0:
            if shift and row.has("shift"):
                return row.shift[index]
            return row.keys[index]

    return ""
```

---

## Custom Layout Support

### Custom Layout Definition

```json
{
  "custom_layout": {
    "name": "User Custom",
    "base_layout": "qwerty_us",
    "modifications": [
      {"from": "caps_lock", "to": "backspace"},
      {"from": "right_ctrl", "to": "enter"},
      {"swap": ["a", ";"]}
    ],
    "created_by": "user",
    "created_at": "2026-01-08"
  }
}
```

### Custom Layout Editor

```
┌─────────────────────────────────────────────────────────────┐
│ CUSTOM KEYBOARD LAYOUT                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Base Layout: [QWERTY US ▼]                                 │
│                                                             │
│ Click a key to modify:                                      │
│                                                             │
│ [Q][W][E][R][T][Y][U][I][O][P]                             │
│  [A][S][D][F][G][H][J][K][L][;]                            │
│   [Z][X][C][V][B][N][M][,][.][/]                           │
│            [SPACE BAR]                                      │
│                                                             │
│ Modifications:                                              │
│ • Caps Lock → Backspace                                    │
│ • [Remove]                                                 │
│                                                             │
│ [Add Modification] [Reset to Base]                         │
│                                                             │
│ [Save Layout] [Cancel]                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Checklist

- [ ] Create layout definition files
- [ ] Implement layout detection
- [ ] Build keyboard display component
- [ ] Add layout-aware input handling
- [ ] Adapt lessons per layout
- [ ] Create layout-specific word lists
- [ ] Build finger guide per layout
- [ ] Add layout selection in settings
- [ ] Implement custom layout editor
- [ ] Test all supported layouts
- [ ] Add layout switching UI
- [ ] Document layout differences

---

## References

- `docs/FINGER_GUIDE_REFERENCE.md` - Finger assignments
- `data/lessons.json` - Lesson definitions
- `game/keyboard_display.gd` - Keyboard renderer
- `sim/words.gd` - Word generation
