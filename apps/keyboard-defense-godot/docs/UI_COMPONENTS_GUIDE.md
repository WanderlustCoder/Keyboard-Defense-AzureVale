# UI Components Guide

Reusable UI components and theming utilities.

## Overview

This guide covers:
- `theme_colors.gd` - Centralized color palette
- `rebindable_actions.gd` - Hotkey action registry
- `command_bar.gd` - Command input with history
- `stat_bar.gd` - Label+value display
- `threat_bar.gd` - Threat and health display
- `achievement_popup.gd` - Achievement notification

## ThemeColors (ui/theme_colors.gd)

Centralized UI color palette for visual consistency.

### Background Colors

```gdscript
const BG_DARK := Color(0.04, 0.035, 0.06, 1)
const BG_PANEL := Color(0.08, 0.07, 0.12, 0.95)
const BG_CARD := Color(0.14, 0.12, 0.22, 1)
const BG_CARD_DISABLED := Color(0.11, 0.1, 0.17, 1)
const BG_BUTTON := Color(0.18, 0.16, 0.28, 1)
const BG_BUTTON_HOVER := Color(0.22, 0.2, 0.35, 1)
const BG_INPUT := Color(0.06, 0.055, 0.09, 1)
```

### Border Colors

```gdscript
const BORDER := Color(0.24, 0.22, 0.36, 1)
const BORDER_HIGHLIGHT := Color(0.35, 0.32, 0.52, 1)
const BORDER_FOCUS := Color(0.45, 0.42, 0.62, 1)
const BORDER_DISABLED := Color(0.2, 0.18, 0.28, 1)
```

### Text Colors

```gdscript
const TEXT := Color(0.94, 0.94, 0.98, 1)
const TEXT_DIM := Color(0.94, 0.94, 0.98, 0.55)
const TEXT_DISABLED := Color(0.5, 0.5, 0.55, 0.6)
const TEXT_PLACEHOLDER := Color(0.5, 0.5, 0.55, 0.8)
```

### Accent Colors

```gdscript
const ACCENT := Color(0.98, 0.84, 0.44, 1)       # Gold
const ACCENT_BLUE := Color(0.65, 0.86, 1, 1)     # Sky blue
const ACCENT_CYAN := Color(0.45, 0.75, 0.95, 1)  # Cyan
```

### Status Colors

```gdscript
const SUCCESS := Color(0.45, 0.82, 0.55, 1)  # Green
const WARNING := Color(0.98, 0.84, 0.44, 1)  # Gold/yellow
const ERROR := Color(0.96, 0.45, 0.45, 1)    # Red
const INFO := Color(0.65, 0.86, 1, 1)        # Blue
```

### Gameplay Colors

```gdscript
const THREAT := Color(0.9, 0.4, 0.35, 1)
const CASTLE_HEALTHY := Color(0.45, 0.82, 0.55, 1)
const CASTLE_DAMAGED := Color(0.96, 0.45, 0.45, 1)
const BUFF_ACTIVE := Color(0.98, 0.84, 0.44, 1)
const TYPED_CORRECT := Color(0.65, 0.86, 1, 1)
const TYPED_ERROR := Color(0.96, 0.45, 0.45, 1)
const TYPED_PENDING := Color(0.94, 0.94, 0.98, 0.4)
```

### Utility Functions

```gdscript
static func text_alpha(alpha: float) -> Color
static func accent_alpha(alpha: float) -> Color
static func error_alpha(alpha: float) -> Color
static func success_alpha(alpha: float) -> Color
```

### Usage Example

```gdscript
# Apply to label
label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

# Apply to panel
panel.add_theme_stylebox_override("panel", _make_stylebox(ThemeColors.BG_CARD))

# Conditional color
var color = ThemeColors.SUCCESS if passed else ThemeColors.ERROR
result_label.add_theme_color_override("font_color", color)
```

## RebindableActions (game/rebindable_actions.gd)

Registry of rebindable hotkey actions.

### Action List

```gdscript
static func actions() -> PackedStringArray:
    return [
        "toggle_settings",
        "toggle_lessons",
        "toggle_trend",
        "toggle_compact",
        "toggle_history",
        "toggle_report",
        "cycle_goal"
    ]
```

### Display Names

```gdscript
static func display_name(action: String) -> String:
    # Returns human-readable names:
    # "toggle_settings" -> "Toggle Settings Panel"
    # "toggle_lessons" -> "Toggle Lessons Panel"
    # "cycle_goal" -> "Cycle Practice Goal"
```

### Help Text

```gdscript
static func help_line(action: String) -> String:
    # Returns: "Display Name (action_name)"

static func format_actions_hint() -> String:
    # Returns comma-separated list of all action help lines
```

### Usage Example

```gdscript
# Build keybind settings UI
for action in RebindableActions.actions():
    var display = RebindableActions.display_name(action)
    var binding = ControlsFormatter.binding_text_for_action(action)
    _add_keybind_row(display, action, binding)
```

## CommandBar (ui/command_bar.gd)

Text input field with command history navigation.

### Signals

```gdscript
signal command_submitted(command: String)
signal input_changed(text: String)
```

### Constants

```gdscript
const HISTORY_BG_COLOR := Color(0.15, 0.18, 0.25, 1.0)
const NORMAL_BG_COLOR := Color(0.1, 0.1, 0.12, 1.0)
```

### State

```gdscript
var history: Array[String] = []
var history_index: int = 0
```

### Core Functions

```gdscript
func accept_submission(entry: String) -> void:
    # Adds entry to history
    # Resets history index
    # Clears input field

func _history_prev() -> void:
    # Navigate backward (UP arrow)
    # Shows previous command

func _history_next() -> void:
    # Navigate forward (DOWN arrow)
    # Shows next command or clears
```

### Visual Feedback

When browsing history:
- Background changes to blue tint
- Shows indicator label: "↑3/10" (position/total)

### Usage Example

```gdscript
@onready var command_bar: CommandBar = $CommandBar

func _ready() -> void:
    command_bar.command_submitted.connect(_on_command_submitted)

func _on_command_submitted(command: String) -> void:
    var result = CommandParser.parse(command)
    if result.ok:
        _apply_intent(result.intent)
        command_bar.accept_submission(command)
    else:
        _show_error(result.error)
```

## StatBar (ui/components/stat_bar.gd)

Simple label+value display component.

### Exports

```gdscript
@export var stat_name: String = "Stat"
@export var stat_value: String = "0"
@export var suffix: String = ""
@export var value_color: Color = ThemeColors.TEXT
```

### Setters

```gdscript
func set_int(val: int) -> void:
    stat_value = str(val)

func set_float(val: float, decimals: int = 1) -> void:
    stat_value = str(snapped(val, pow(10, -decimals)))

func set_percent(val: float) -> void:
    stat_value = str(int(round(val * 100.0)))
    suffix = "%"
```

### Usage Example

```gdscript
# In scene: add StatBar node
# Set stat_name = "Accuracy" via inspector

func _update_display() -> void:
    accuracy_bar.set_percent(0.95)  # Shows "95%"
    wpm_bar.set_int(45)             # Shows "45"
    combo_bar.set_int(12)
    combo_bar.value_color = ThemeColors.ACCENT
```

## ThreatBar (ui/components/threat_bar.gd)

Visual threat level and castle health display.

### Constants

```gdscript
const THREAT_HIGH_THRESHOLD := 80.0
const THREAT_MEDIUM_THRESHOLD := 50.0
```

### Functions

```gdscript
func set_threat(value: float) -> void:
    # Sets progress bar (0-100)
    # Changes color:
    # - Red: >= 80
    # - Orange: >= 50
    # - Default: < 50

func set_castle_health(current: int, max_health: int = 3) -> void:
    # Updates "Castle: X / Y" label
    # Changes text color:
    # - Red: <= 1
    # - Orange: <= 2
    # - Green: > 2

func set_max_threat(value: float) -> void:
    # Sets progress bar max_value
```

### Usage Example

```gdscript
func _update_hud() -> void:
    threat_bar.set_threat(state.threat_level * 100.0)
    threat_bar.set_castle_health(state.hp, state.hp_max)
```

## AchievementPopup (ui/components/achievement_popup.gd)

Animated achievement notification popup.

### Signals

```gdscript
signal popup_finished
```

### Exports

```gdscript
@export var display_duration: float = 3.0
@export var fade_duration: float = 0.5
```

### State Machine

States: "hidden" -> "showing" -> "visible" -> "hiding" -> "hidden"

### Functions

```gdscript
func show_achievement(achievement_id: String, achievement_data: Dictionary) -> void:
    # Displays achievement with:
    # - Icon (emoji based on category)
    # - Title: "Achievement Unlocked!"
    # - Name: achievement_data.name
    # - Description: achievement_data.description
    # Starts fade-in animation
```

### Icon Mapping

```gdscript
# Icons based on achievement category or ID:
"combat" -> "⚔"
"typing" -> "⌨"
"streak" -> "🔥"
"mastery" -> "⭐"
"completion" -> "👑"
"defense" -> "🛡"
"health" -> "❤"
"defeat" -> "💀"
```

### Animation Flow

1. `show_achievement()` called
2. State = "showing", fade in over 0.5s
3. State = "visible", hold for 3.0s
4. State = "hiding", fade out over 0.5s
5. State = "hidden", emit `popup_finished`

### Usage Example

```gdscript
@onready var popup: AchievementPopup = $AchievementPopup

func _on_achievement_unlocked(achievement_id: String) -> void:
    var data = StoryManager.get_achievement(achievement_id)
    popup.show_achievement(achievement_id, data)

func _ready() -> void:
    popup.popup_finished.connect(_on_popup_finished)

func _on_popup_finished() -> void:
    # Check for queued achievements
    _show_next_achievement()
```

## Integration Example

Complete HUD with all components:

```gdscript
extends Control

@onready var command_bar: CommandBar = $CommandBar
@onready var threat_bar: ThreatBar = $ThreatBar
@onready var accuracy_stat: StatBar = $StatsPanel/Accuracy
@onready var wpm_stat: StatBar = $StatsPanel/WPM
@onready var achievement_popup: AchievementPopup = $AchievementPopup

func _ready() -> void:
    command_bar.command_submitted.connect(_on_command)
    achievement_popup.popup_finished.connect(_on_popup_done)

func _update_display(state: GameState, stats: Dictionary) -> void:
    # Threat and health
    threat_bar.set_threat(state.threat_level * 100.0)
    threat_bar.set_castle_health(state.hp)

    # Typing stats
    accuracy_stat.set_percent(stats.accuracy)
    accuracy_stat.value_color = ThemeColors.SUCCESS if stats.accuracy >= 0.95 else ThemeColors.TEXT

    wpm_stat.set_int(stats.wpm)
    wpm_stat.value_color = ThemeColors.ACCENT if stats.wpm >= 60 else ThemeColors.TEXT

func _on_command(command: String) -> void:
    # Process command...
    command_bar.accept_submission(command)
```

## File Dependencies

- `ui/theme_colors.gd` - No dependencies (pure constants)
- `game/rebindable_actions.gd` - No dependencies (pure data)
- `ui/command_bar.gd` - Extends LineEdit
- `ui/components/stat_bar.gd` - Depends on theme_colors.gd
- `ui/components/threat_bar.gd` - Depends on theme_colors.gd
- `ui/components/achievement_popup.gd` - Depends on theme_colors.gd
