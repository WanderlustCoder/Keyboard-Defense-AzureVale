# Settings Manager Guide

Autoload singleton for game settings persistence and state management.

## Overview

`SettingsManager` (game/settings_manager.gd) handles user preferences for audio, visual effects, and HUD display. Settings are persisted using Godot's ConfigFile to `user://settings.cfg`.

## Constants

```gdscript
const SETTINGS_PATH := "user://settings.cfg"

# Audio defaults
const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_MUSIC_ENABLED := true
const DEFAULT_SFX_ENABLED := true
const DEFAULT_TYPING_SOUNDS := true

# Gameplay defaults
const DEFAULT_SCREEN_SHAKE := true
const DEFAULT_SHOW_WPM := true
const DEFAULT_SHOW_ACCURACY := true
```

## State Variables

```gdscript
# Audio settings
var music_volume: float = DEFAULT_MUSIC_VOLUME    # 0.0 - 1.0
var sfx_volume: float = DEFAULT_SFX_VOLUME        # 0.0 - 1.0
var music_enabled: bool = DEFAULT_MUSIC_ENABLED
var sfx_enabled: bool = DEFAULT_SFX_ENABLED
var typing_sounds: bool = DEFAULT_TYPING_SOUNDS

# Gameplay settings
var screen_shake: bool = DEFAULT_SCREEN_SHAKE
var show_wpm: bool = DEFAULT_SHOW_WPM
var show_accuracy: bool = DEFAULT_SHOW_ACCURACY
```

## Signals

```gdscript
signal settings_changed
```

Emitted after any setting is modified via setter functions.

## Core Functions

### Lifecycle

```gdscript
func _ready() -> void:
    load_settings()
    _apply_audio_settings()
```

### Persistence

```gdscript
# Load settings from disk (called on _ready)
func load_settings() -> void

# Save current settings to disk
func save_settings() -> void

# Reset all settings to defaults
func reset_to_defaults() -> void
```

### Audio Setters

```gdscript
func set_music_volume(value: float) -> void
func set_sfx_volume(value: float) -> void
func set_music_enabled(value: bool) -> void
func set_sfx_enabled(value: bool) -> void
func set_typing_sounds(value: bool) -> void
```

### Gameplay Setters

```gdscript
func set_screen_shake(value: bool) -> void
func set_show_wpm(value: bool) -> void
func set_show_accuracy(value: bool) -> void
```

## ConfigFile Format

Settings are stored in INI-style format:

```ini
[audio]
music_volume=0.8
sfx_volume=1.0
music_enabled=true
sfx_enabled=true
typing_sounds=true

[gameplay]
screen_shake=true
show_wpm=true
show_accuracy=true
```

## Integration with AudioManager

Audio settings are automatically applied to AudioManager:

```gdscript
func _apply_audio_settings() -> void:
    var audio_manager = get_node_or_null("/root/AudioManager")
    if audio_manager == null:
        return
    audio_manager.set_music_volume(music_volume)
    audio_manager.set_sfx_volume(sfx_volume)
    audio_manager.set_music_enabled(music_enabled)
    audio_manager.set_sfx_enabled(sfx_enabled)
```

## Usage Examples

### Accessing Settings

```gdscript
# Get reference to autoload
var settings = get_node("/root/SettingsManager")

# Read current values
var music_vol = settings.music_volume
var shake_enabled = settings.screen_shake
```

### Modifying Settings

```gdscript
# Change a setting (auto-saves to AudioManager, emits signal)
settings.set_music_volume(0.5)

# Manually save to disk (call after batch changes)
settings.save_settings()
```

### Listening for Changes

```gdscript
func _ready() -> void:
    var settings = get_node("/root/SettingsManager")
    settings.settings_changed.connect(_on_settings_changed)

func _on_settings_changed() -> void:
    # Update UI or apply visual settings
    _update_hud_visibility()
```

### Building Settings UI

```gdscript
func _ready() -> void:
    var settings = get_node("/root/SettingsManager")

    # Initialize sliders
    music_slider.value = settings.music_volume
    sfx_slider.value = settings.sfx_volume

    # Initialize checkboxes
    music_toggle.button_pressed = settings.music_enabled
    shake_toggle.button_pressed = settings.screen_shake

func _on_music_slider_changed(value: float) -> void:
    settings.set_music_volume(value)
    settings.save_settings()

func _on_shake_toggle_pressed() -> void:
    settings.set_screen_shake(shake_toggle.button_pressed)
    settings.save_settings()

func _on_reset_pressed() -> void:
    settings.reset_to_defaults()
    settings.save_settings()
    _refresh_ui()
```

### Checking Settings in Game Code

```gdscript
# In battle controller
func _on_hit() -> void:
    var settings = get_node("/root/SettingsManager")
    if settings.screen_shake:
        _apply_screen_shake()

# In HUD
func _update_hud() -> void:
    var settings = get_node("/root/SettingsManager")
    wpm_label.visible = settings.show_wpm
    accuracy_label.visible = settings.show_accuracy

# In typing input
func _on_key_typed() -> void:
    var settings = get_node("/root/SettingsManager")
    if settings.typing_sounds:
        audio_manager.play_typing_sound()
```

## Adding New Settings

To add a new setting:

1. Add default constant:
```gdscript
const DEFAULT_NEW_SETTING := true
```

2. Add state variable:
```gdscript
var new_setting: bool = DEFAULT_NEW_SETTING
```

3. Add to load_settings():
```gdscript
new_setting = config.get_value("section", "new_setting", DEFAULT_NEW_SETTING)
```

4. Add to save_settings():
```gdscript
config.set_value("section", "new_setting", new_setting)
```

5. Add setter function:
```gdscript
func set_new_setting(value: bool) -> void:
    new_setting = value
    settings_changed.emit()
```

6. Add to reset_to_defaults():
```gdscript
new_setting = DEFAULT_NEW_SETTING
```

## Setting Categories

### Audio Section
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| music_volume | float | 0.8 | Background music volume (0-1) |
| sfx_volume | float | 1.0 | Sound effects volume (0-1) |
| music_enabled | bool | true | Enable/disable music playback |
| sfx_enabled | bool | true | Enable/disable sound effects |
| typing_sounds | bool | true | Play sounds on keystrokes |

### Gameplay Section
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| screen_shake | bool | true | Enable screen shake effects |
| show_wpm | bool | true | Show WPM counter in HUD |
| show_accuracy | bool | true | Show accuracy % in HUD |

## File Location

Settings file is saved to user data directory:
- Windows: `%APPDATA%\Godot\app_userdata\Keyboard Defense\settings.cfg`
- macOS: `~/Library/Application Support/Godot/app_userdata/Keyboard Defense/settings.cfg`
- Linux: `~/.local/share/godot/app_userdata/Keyboard Defense/settings.cfg`

## Error Handling

Loading gracefully handles missing file:

```gdscript
func load_settings() -> void:
    var config := ConfigFile.new()
    var err := config.load(SETTINGS_PATH)
    if err != OK:
        # No settings file yet, use defaults
        return
```

Saving warns on failure but doesn't crash:

```gdscript
var err := config.save(SETTINGS_PATH)
if err != OK:
    push_warning("Failed to save settings: %s" % error_string(err))
```

## File Dependencies

- `game/settings_manager.gd` - This file (autoload singleton)
- `game/audio_manager.gd` - AudioManager autoload (receives volume updates)
- `project.godot` - Registers SettingsManager as autoload
