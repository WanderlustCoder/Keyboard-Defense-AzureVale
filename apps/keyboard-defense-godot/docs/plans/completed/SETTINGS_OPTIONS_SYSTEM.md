# Settings and Options System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The settings system provides comprehensive control over gameplay, audio, visual, and accessibility options. Settings persist across sessions and can be exported/imported for sharing configurations.

---

## Settings Categories

### Gameplay Settings

```json
{
  "gameplay_settings": {
    "category": "Gameplay",
    "icon": "gamepad",
    "options": [
      {
        "id": "difficulty",
        "name": "Default Difficulty",
        "type": "dropdown",
        "options": ["Story", "Adventure", "Champion", "Nightmare"],
        "default": "Adventure",
        "description": "Starting difficulty for new games"
      },
      {
        "id": "auto_pause_waves",
        "name": "Auto-Pause Between Waves",
        "type": "toggle",
        "default": false,
        "description": "Pause automatically when a wave ends"
      },
      {
        "id": "confirm_tower_sell",
        "name": "Confirm Tower Sell",
        "type": "toggle",
        "default": true,
        "description": "Require confirmation before selling towers"
      },
      {
        "id": "show_tower_ranges",
        "name": "Show Tower Ranges",
        "type": "dropdown",
        "options": ["Never", "On Hover", "Selected", "Always"],
        "default": "On Hover",
        "description": "When to display tower attack ranges"
      },
      {
        "id": "show_enemy_paths",
        "name": "Show Enemy Paths",
        "type": "toggle",
        "default": false,
        "description": "Display the path enemies will follow"
      },
      {
        "id": "auto_start_waves",
        "name": "Auto-Start Waves",
        "type": "toggle",
        "default": false,
        "description": "Automatically start next wave after delay"
      },
      {
        "id": "wave_auto_start_delay",
        "name": "Wave Start Delay",
        "type": "slider",
        "min": 3,
        "max": 30,
        "step": 1,
        "default": 10,
        "unit": "seconds",
        "visible_if": "auto_start_waves == true",
        "description": "Delay before automatically starting next wave"
      },
      {
        "id": "tutorial_hints",
        "name": "Tutorial Hints",
        "type": "dropdown",
        "options": ["Off", "Minimal", "Standard", "Detailed"],
        "default": "Standard",
        "description": "How often to show gameplay hints"
      },
      {
        "id": "skip_tutorials",
        "name": "Skip Completed Tutorials",
        "type": "toggle",
        "default": true,
        "description": "Don't show tutorials you've already completed"
      }
    ]
  }
}
```

### Typing Settings

```json
{
  "typing_settings": {
    "category": "Typing",
    "icon": "keyboard",
    "options": [
      {
        "id": "keyboard_layout",
        "name": "Keyboard Layout",
        "type": "dropdown",
        "options": ["QWERTY", "DVORAK", "AZERTY", "COLEMAK", "Custom"],
        "default": "QWERTY",
        "description": "Your keyboard layout for proper finger guidance"
      },
      {
        "id": "show_keyboard",
        "name": "Show Keyboard Display",
        "type": "toggle",
        "default": true,
        "description": "Display on-screen keyboard during gameplay"
      },
      {
        "id": "keyboard_position",
        "name": "Keyboard Position",
        "type": "dropdown",
        "options": ["Bottom", "Bottom-Left", "Bottom-Right"],
        "default": "Bottom",
        "visible_if": "show_keyboard == true",
        "description": "Position of the on-screen keyboard"
      },
      {
        "id": "keyboard_opacity",
        "name": "Keyboard Opacity",
        "type": "slider",
        "min": 0.2,
        "max": 1.0,
        "step": 0.1,
        "default": 0.8,
        "visible_if": "show_keyboard == true",
        "description": "Transparency of the on-screen keyboard"
      },
      {
        "id": "keyboard_size",
        "name": "Keyboard Size",
        "type": "slider",
        "min": 0.5,
        "max": 1.5,
        "step": 0.1,
        "default": 1.0,
        "visible_if": "show_keyboard == true",
        "description": "Size of the on-screen keyboard"
      },
      {
        "id": "finger_guide",
        "name": "Finger Guide",
        "type": "dropdown",
        "options": ["Off", "On Hover", "Always"],
        "default": "On Hover",
        "description": "Show which finger to use for each key"
      },
      {
        "id": "next_key_highlight",
        "name": "Highlight Next Key",
        "type": "toggle",
        "default": true,
        "description": "Highlight the next key to press"
      },
      {
        "id": "typing_sounds",
        "name": "Typing Sounds",
        "type": "toggle",
        "default": true,
        "description": "Play sounds when pressing keys"
      },
      {
        "id": "error_feedback",
        "name": "Error Feedback Style",
        "type": "dropdown",
        "options": ["None", "Visual Only", "Audio Only", "Both"],
        "default": "Both",
        "description": "How to indicate typing errors"
      },
      {
        "id": "case_sensitive",
        "name": "Case Sensitive Typing",
        "type": "toggle",
        "default": false,
        "description": "Require correct capitalization"
      }
    ]
  }
}
```

### Audio Settings

```json
{
  "audio_settings": {
    "category": "Audio",
    "icon": "speaker",
    "options": [
      {
        "id": "master_volume",
        "name": "Master Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 80,
        "unit": "%",
        "description": "Overall game volume"
      },
      {
        "id": "music_volume",
        "name": "Music Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 70,
        "unit": "%",
        "description": "Background music volume"
      },
      {
        "id": "sfx_volume",
        "name": "Sound Effects Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 80,
        "unit": "%",
        "description": "Sound effects volume"
      },
      {
        "id": "typing_volume",
        "name": "Typing Sound Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 60,
        "unit": "%",
        "description": "Volume of keyboard typing sounds"
      },
      {
        "id": "ui_volume",
        "name": "UI Sound Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 50,
        "unit": "%",
        "description": "Menu and interface sounds"
      },
      {
        "id": "voice_volume",
        "name": "Voice/Dialogue Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 80,
        "unit": "%",
        "description": "NPC dialogue and announcements"
      },
      {
        "id": "ambient_volume",
        "name": "Ambient Sound Volume",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 50,
        "unit": "%",
        "description": "Environmental ambient sounds"
      },
      {
        "id": "mute_on_focus_loss",
        "name": "Mute When Unfocused",
        "type": "toggle",
        "default": true,
        "description": "Mute game when window loses focus"
      },
      {
        "id": "dynamic_music",
        "name": "Dynamic Music",
        "type": "toggle",
        "default": true,
        "description": "Music changes based on gameplay intensity"
      }
    ]
  }
}
```

### Graphics Settings

```json
{
  "graphics_settings": {
    "category": "Graphics",
    "icon": "monitor",
    "options": [
      {
        "id": "display_mode",
        "name": "Display Mode",
        "type": "dropdown",
        "options": ["Windowed", "Borderless Fullscreen", "Fullscreen"],
        "default": "Borderless Fullscreen",
        "description": "Window display mode"
      },
      {
        "id": "resolution",
        "name": "Resolution",
        "type": "dropdown",
        "options": "dynamic_resolution_list",
        "default": "native",
        "description": "Screen resolution"
      },
      {
        "id": "vsync",
        "name": "V-Sync",
        "type": "toggle",
        "default": true,
        "description": "Synchronize frame rate with display"
      },
      {
        "id": "frame_rate_limit",
        "name": "Frame Rate Limit",
        "type": "dropdown",
        "options": ["30", "60", "120", "144", "Unlimited"],
        "default": "60",
        "visible_if": "vsync == false",
        "description": "Maximum frames per second"
      },
      {
        "id": "quality_preset",
        "name": "Quality Preset",
        "type": "dropdown",
        "options": ["Low", "Medium", "High", "Ultra", "Custom"],
        "default": "High",
        "description": "Overall graphics quality"
      },
      {
        "id": "particle_quality",
        "name": "Particle Effects",
        "type": "dropdown",
        "options": ["Off", "Low", "Medium", "High"],
        "default": "High",
        "visible_if": "quality_preset == Custom",
        "description": "Quality of particle effects"
      },
      {
        "id": "shadow_quality",
        "name": "Shadow Quality",
        "type": "dropdown",
        "options": ["Off", "Low", "Medium", "High"],
        "default": "Medium",
        "visible_if": "quality_preset == Custom",
        "description": "Quality of shadow rendering"
      },
      {
        "id": "post_processing",
        "name": "Post Processing",
        "type": "toggle",
        "default": true,
        "visible_if": "quality_preset == Custom",
        "description": "Enable bloom, vignette, and other effects"
      },
      {
        "id": "anti_aliasing",
        "name": "Anti-Aliasing",
        "type": "dropdown",
        "options": ["Off", "FXAA", "MSAA 2x", "MSAA 4x"],
        "default": "FXAA",
        "visible_if": "quality_preset == Custom",
        "description": "Edge smoothing method"
      },
      {
        "id": "ui_scale",
        "name": "UI Scale",
        "type": "slider",
        "min": 0.75,
        "max": 1.5,
        "step": 0.05,
        "default": 1.0,
        "description": "Scale of user interface elements"
      },
      {
        "id": "show_fps",
        "name": "Show FPS Counter",
        "type": "toggle",
        "default": false,
        "description": "Display frames per second"
      }
    ]
  }
}
```

### Camera Settings

```json
{
  "camera_settings": {
    "category": "Camera",
    "icon": "camera",
    "options": [
      {
        "id": "camera_speed",
        "name": "Camera Pan Speed",
        "type": "slider",
        "min": 0.5,
        "max": 2.0,
        "step": 0.1,
        "default": 1.0,
        "description": "Speed of camera movement"
      },
      {
        "id": "zoom_speed",
        "name": "Zoom Speed",
        "type": "slider",
        "min": 0.5,
        "max": 2.0,
        "step": 0.1,
        "default": 1.0,
        "description": "Speed of camera zoom"
      },
      {
        "id": "edge_scroll",
        "name": "Edge Scrolling",
        "type": "toggle",
        "default": true,
        "description": "Pan camera when cursor is at screen edge"
      },
      {
        "id": "edge_scroll_speed",
        "name": "Edge Scroll Speed",
        "type": "slider",
        "min": 0.5,
        "max": 2.0,
        "step": 0.1,
        "default": 1.0,
        "visible_if": "edge_scroll == true",
        "description": "Speed of edge scrolling"
      },
      {
        "id": "edge_scroll_zone",
        "name": "Edge Scroll Zone",
        "type": "slider",
        "min": 10,
        "max": 50,
        "step": 5,
        "default": 20,
        "unit": "px",
        "visible_if": "edge_scroll == true",
        "description": "Size of edge scroll trigger zone"
      },
      {
        "id": "invert_zoom",
        "name": "Invert Zoom Direction",
        "type": "toggle",
        "default": false,
        "description": "Reverse scroll wheel zoom direction"
      },
      {
        "id": "smooth_camera",
        "name": "Smooth Camera",
        "type": "toggle",
        "default": true,
        "description": "Enable camera movement smoothing"
      },
      {
        "id": "camera_shake",
        "name": "Camera Shake",
        "type": "slider",
        "min": 0,
        "max": 100,
        "step": 10,
        "default": 100,
        "unit": "%",
        "description": "Intensity of camera shake effects"
      },
      {
        "id": "default_zoom",
        "name": "Default Zoom Level",
        "type": "slider",
        "min": 0.5,
        "max": 2.0,
        "step": 0.1,
        "default": 1.0,
        "description": "Starting zoom level for levels"
      }
    ]
  }
}
```

### Controls Settings

```json
{
  "controls_settings": {
    "category": "Controls",
    "icon": "keyboard_mouse",
    "subsections": [
      {
        "name": "Camera Controls",
        "bindings": [
          {"action": "pan_up", "default": "W", "alt": "Up Arrow"},
          {"action": "pan_down", "default": "S", "alt": "Down Arrow"},
          {"action": "pan_left", "default": "A", "alt": "Left Arrow"},
          {"action": "pan_right", "default": "D", "alt": "Right Arrow"},
          {"action": "zoom_in", "default": "Scroll Up", "alt": "="},
          {"action": "zoom_out", "default": "Scroll Down", "alt": "-"},
          {"action": "reset_camera", "default": "Home", "alt": null}
        ]
      },
      {
        "name": "Gameplay Controls",
        "bindings": [
          {"action": "pause", "default": "Escape", "alt": "P"},
          {"action": "start_wave", "default": "Space", "alt": "Enter"},
          {"action": "cancel_word", "default": "Escape", "alt": null},
          {"action": "sell_tower", "default": "Delete", "alt": "Backspace"},
          {"action": "upgrade_tower", "default": "U", "alt": null},
          {"action": "quick_save", "default": "F5", "alt": null},
          {"action": "quick_load", "default": "F9", "alt": null}
        ]
      },
      {
        "name": "UI Controls",
        "bindings": [
          {"action": "toggle_minimap", "default": "M", "alt": null},
          {"action": "toggle_keyboard", "default": "K", "alt": null},
          {"action": "toggle_stats", "default": "Tab", "alt": null},
          {"action": "open_build_menu", "default": "B", "alt": null},
          {"action": "screenshot", "default": "F12", "alt": null}
        ]
      },
      {
        "name": "Quick Actions",
        "bindings": [
          {"action": "select_tower_1", "default": "1", "alt": null},
          {"action": "select_tower_2", "default": "2", "alt": null},
          {"action": "select_tower_3", "default": "3", "alt": null},
          {"action": "select_tower_4", "default": "4", "alt": null},
          {"action": "deselect_all", "default": "Escape", "alt": null}
        ]
      }
    ],
    "options": [
      {
        "id": "show_keybinds",
        "name": "Show Key Bindings in Tooltips",
        "type": "toggle",
        "default": true,
        "description": "Display keyboard shortcuts in UI tooltips"
      }
    ]
  }
}
```

### Accessibility Settings

```json
{
  "accessibility_settings": {
    "category": "Accessibility",
    "icon": "accessibility",
    "options": [
      {
        "id": "colorblind_mode",
        "name": "Colorblind Mode",
        "type": "dropdown",
        "options": ["Off", "Protanopia", "Deuteranopia", "Tritanopia"],
        "default": "Off",
        "description": "Color adjustments for color vision deficiency"
      },
      {
        "id": "high_contrast",
        "name": "High Contrast Mode",
        "type": "toggle",
        "default": false,
        "description": "Increase contrast for better visibility"
      },
      {
        "id": "reduced_motion",
        "name": "Reduce Motion",
        "type": "toggle",
        "default": false,
        "description": "Minimize animations and screen effects"
      },
      {
        "id": "screen_shake_override",
        "name": "Disable Screen Shake",
        "type": "toggle",
        "default": false,
        "description": "Completely disable camera shake"
      },
      {
        "id": "flash_reduction",
        "name": "Reduce Flashing",
        "type": "toggle",
        "default": false,
        "description": "Reduce bright flashing effects"
      },
      {
        "id": "text_size",
        "name": "Text Size",
        "type": "dropdown",
        "options": ["Small", "Medium", "Large", "Extra Large"],
        "default": "Medium",
        "description": "Size of in-game text"
      },
      {
        "id": "dyslexia_font",
        "name": "Dyslexia-Friendly Font",
        "type": "toggle",
        "default": false,
        "description": "Use OpenDyslexic font for better readability"
      },
      {
        "id": "screen_reader",
        "name": "Screen Reader Support",
        "type": "toggle",
        "default": false,
        "description": "Enable compatibility with screen readers"
      },
      {
        "id": "screen_reader_verbosity",
        "name": "Screen Reader Verbosity",
        "type": "dropdown",
        "options": ["Minimal", "Normal", "Detailed"],
        "default": "Normal",
        "visible_if": "screen_reader == true",
        "description": "Amount of information announced"
      },
      {
        "id": "one_handed_mode",
        "name": "One-Handed Mode",
        "type": "dropdown",
        "options": ["Off", "Left Hand Only", "Right Hand Only"],
        "default": "Off",
        "description": "Limit words to single-hand typing"
      },
      {
        "id": "motor_assist",
        "name": "Motor Assist",
        "type": "toggle",
        "default": false,
        "description": "Extended timing windows and input tolerance"
      },
      {
        "id": "hold_instead_of_tap",
        "name": "Hold to Confirm",
        "type": "toggle",
        "default": false,
        "description": "Hold keys instead of tapping for actions"
      },
      {
        "id": "pause_anytime",
        "name": "Pause Anytime",
        "type": "toggle",
        "default": true,
        "description": "Allow pausing even during combat"
      },
      {
        "id": "subtitles",
        "name": "Subtitles",
        "type": "toggle",
        "default": true,
        "description": "Show subtitles for dialogue and important audio"
      },
      {
        "id": "subtitle_background",
        "name": "Subtitle Background",
        "type": "dropdown",
        "options": ["None", "Semi-transparent", "Solid"],
        "default": "Semi-transparent",
        "visible_if": "subtitles == true",
        "description": "Background behind subtitles"
      }
    ]
  }
}
```

### Notification Settings

```json
{
  "notification_settings": {
    "category": "Notifications",
    "icon": "bell",
    "options": [
      {
        "id": "show_damage_numbers",
        "name": "Show Damage Numbers",
        "type": "toggle",
        "default": true,
        "description": "Display floating damage numbers"
      },
      {
        "id": "show_gold_numbers",
        "name": "Show Gold Numbers",
        "type": "toggle",
        "default": true,
        "description": "Display floating gold earned"
      },
      {
        "id": "show_combo_announcements",
        "name": "Combo Announcements",
        "type": "toggle",
        "default": true,
        "description": "Show combo milestone announcements"
      },
      {
        "id": "show_achievement_popups",
        "name": "Achievement Popups",
        "type": "toggle",
        "default": true,
        "description": "Show notifications when achievements unlock"
      },
      {
        "id": "show_item_pickups",
        "name": "Item Pickup Notifications",
        "type": "toggle",
        "default": true,
        "description": "Notify when items are acquired"
      },
      {
        "id": "show_quest_updates",
        "name": "Quest Update Notifications",
        "type": "toggle",
        "default": true,
        "description": "Notify on quest progress"
      },
      {
        "id": "notification_duration",
        "name": "Notification Duration",
        "type": "slider",
        "min": 1,
        "max": 10,
        "step": 0.5,
        "default": 3,
        "unit": "seconds",
        "description": "How long notifications stay on screen"
      }
    ]
  }
}
```

### Data Settings

```json
{
  "data_settings": {
    "category": "Data & Privacy",
    "icon": "shield",
    "options": [
      {
        "id": "auto_save",
        "name": "Auto-Save",
        "type": "toggle",
        "default": true,
        "description": "Automatically save progress"
      },
      {
        "id": "auto_save_interval",
        "name": "Auto-Save Interval",
        "type": "dropdown",
        "options": ["Every Wave", "Every Level", "Every 5 Minutes"],
        "default": "Every Level",
        "visible_if": "auto_save == true",
        "description": "How often to auto-save"
      },
      {
        "id": "save_slot_count",
        "name": "Save Slots Used",
        "type": "info",
        "value": "dynamic",
        "description": "Number of save slots in use"
      },
      {
        "id": "analytics_opt_in",
        "name": "Analytics",
        "type": "toggle",
        "default": false,
        "description": "Share anonymous usage data to improve the game"
      },
      {
        "id": "crash_reports",
        "name": "Crash Reports",
        "type": "toggle",
        "default": true,
        "description": "Send crash reports to help fix bugs"
      }
    ],
    "actions": [
      {
        "id": "export_settings",
        "name": "Export Settings",
        "type": "button",
        "description": "Save settings to a file"
      },
      {
        "id": "import_settings",
        "name": "Import Settings",
        "type": "button",
        "description": "Load settings from a file"
      },
      {
        "id": "reset_settings",
        "name": "Reset to Defaults",
        "type": "button",
        "confirmation": true,
        "description": "Reset all settings to default values"
      },
      {
        "id": "clear_save_data",
        "name": "Clear Save Data",
        "type": "button",
        "confirmation": true,
        "warning": true,
        "description": "Delete all save data (cannot be undone)"
      }
    ]
  }
}
```

---

## Settings UI

### Settings Menu Layout

```json
{
  "settings_ui": {
    "layout": "sidebar_navigation",
    "sidebar": {
      "position": "left",
      "width": 200,
      "shows": "Category list with icons"
    },
    "content_area": {
      "position": "right",
      "scrollable": true,
      "shows": "Selected category options"
    },
    "footer": {
      "buttons": ["Apply", "Cancel", "Reset Category"],
      "shows_unsaved_indicator": true
    }
  }
}
```

### Setting Types UI

```json
{
  "setting_type_ui": {
    "toggle": {
      "style": "switch",
      "animation": "slide",
      "shows_state": "On/Off"
    },
    "slider": {
      "style": "horizontal_bar",
      "shows_value": true,
      "input_field": true,
      "snap_to_steps": true
    },
    "dropdown": {
      "style": "select_box",
      "searchable": false,
      "shows_current": true
    },
    "keybind": {
      "style": "button",
      "click_to_rebind": true,
      "shows_conflicts": true,
      "clear_option": true
    },
    "button": {
      "style": "outlined",
      "confirmation_dialog": "if_destructive"
    }
  }
}
```

### Real-Time Preview

```json
{
  "preview_system": {
    "audio_settings": {
      "preview_sound": true,
      "delay": 0.5
    },
    "graphics_settings": {
      "live_update": true,
      "except": ["resolution", "display_mode"]
    },
    "ui_scale": {
      "live_update": true,
      "preview_indicator": true
    },
    "accessibility": {
      "live_update": true,
      "show_example_text": true
    }
  }
}
```

---

## Settings Persistence

### Save Format

```json
{
  "settings_file": {
    "format": "json",
    "location": "user://settings.json",
    "backup": "user://settings_backup.json",
    "structure": {
      "version": "1.0.0",
      "last_modified": "timestamp",
      "categories": {
        "gameplay": {},
        "typing": {},
        "audio": {},
        "graphics": {},
        "camera": {},
        "controls": {},
        "accessibility": {},
        "notifications": {},
        "data": {}
      }
    }
  }
}
```

### Version Migration

```json
{
  "settings_migration": {
    "on_version_mismatch": "migrate",
    "migration_rules": [
      {
        "from": "0.9.x",
        "to": "1.0.0",
        "changes": [
          {"rename": "old_setting_name", "to": "new_setting_name"},
          {"add": "new_setting", "default": "value"},
          {"remove": "deprecated_setting"}
        ]
      }
    ],
    "backup_before_migration": true
  }
}
```

---

## Quick Settings

### In-Game Quick Access

```json
{
  "quick_settings": {
    "accessible_via": "Escape menu",
    "includes": [
      "Master Volume",
      "Music Volume",
      "SFX Volume",
      "Camera Shake",
      "Show Damage Numbers",
      "Show Keyboard"
    ],
    "link_to_full_settings": true
  }
}
```

---

## Default Profiles

### Preset Configurations

```json
{
  "preset_profiles": {
    "performance": {
      "name": "Performance",
      "description": "Optimized for lower-end systems",
      "settings": {
        "quality_preset": "Low",
        "particle_quality": "Low",
        "post_processing": false,
        "vsync": false,
        "frame_rate_limit": "60"
      }
    },
    "quality": {
      "name": "Quality",
      "description": "Best visual experience",
      "settings": {
        "quality_preset": "Ultra",
        "particle_quality": "High",
        "post_processing": true,
        "anti_aliasing": "MSAA 4x"
      }
    },
    "accessibility": {
      "name": "Accessibility",
      "description": "Optimized for accessibility needs",
      "settings": {
        "reduced_motion": true,
        "high_contrast": true,
        "text_size": "Large",
        "camera_shake": 0,
        "subtitles": true
      }
    },
    "streamer": {
      "name": "Streamer",
      "description": "Good for streaming",
      "settings": {
        "display_mode": "Borderless Fullscreen",
        "vsync": true,
        "show_fps": true,
        "notification_duration": 5
      }
    }
  }
}
```

---

## Implementation Notes

### Godot Implementation

```gdscript
# Settings manager singleton
extends Node

const SETTINGS_PATH = "user://settings.json"
var settings: Dictionary = {}
var defaults: Dictionary = {}

signal setting_changed(category, key, value)

func _ready():
    load_defaults()
    load_settings()

func get_setting(category: String, key: String):
    if settings.has(category) and settings[category].has(key):
        return settings[category][key]
    return defaults.get(category, {}).get(key)

func set_setting(category: String, key: String, value):
    if not settings.has(category):
        settings[category] = {}
    settings[category][key] = value
    emit_signal("setting_changed", category, key, value)
    apply_setting(category, key, value)

func apply_setting(category: String, key: String, value):
    match category + "." + key:
        "audio.master_volume":
            AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))
        "graphics.vsync":
            DisplayServer.window_set_vsync_mode(
                DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
            )
        # ... other settings

func save_settings():
    var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(settings, "  "))

func load_settings():
    if FileAccess.file_exists(SETTINGS_PATH):
        var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
        settings = JSON.parse_string(file.get_as_text())
        apply_all_settings()
```

---

*End of Settings and Options System Document*
