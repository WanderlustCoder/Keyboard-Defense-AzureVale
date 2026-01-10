# Scene Navigation Guide

Central scene navigation and game flow controller system.

## Overview

The scene navigation system uses `GameController` as a singleton autoload to manage transitions between game screens. Each scene has its own controller script that handles UI, user interaction, and calling GameController for navigation.

## GameController (scripts/GameController.gd)

### Scene Constants

```gdscript
const SCENE_MENU := "res://scenes/MainMenu.tscn"
const SCENE_MAP := "res://scenes/KingdomDefense.tscn"      # Top-down RTS typing game
const SCENE_MAP_LEGACY := "res://scenes/OpenWorld.tscn"   # Open-world version
const SCENE_BATTLE := "res://scenes/Battlefield.tscn"
const SCENE_KINGDOM := "res://scenes/KingdomHub.tscn"
const SCENE_SETTINGS := "res://scenes/SettingsMenu.tscn"
```

### State Variables

```gdscript
# Battle context passed between CampaignMap and Battlefield
var next_battle_node_id: String = ""
var last_battle_summary: Dictionary = {}
```

### Navigation Functions

```gdscript
func go_to_menu() -> void
func go_to_map() -> void
func go_to_battle(node_id: String) -> void
func go_to_kingdom() -> void
func go_to_settings() -> void
```

### Battle Context Flow

```
CampaignMap                    GameController                 Battlefield
    |                               |                              |
    |--- go_to_battle(node_id) ---->|                              |
    |                               |-- next_battle_node_id = id --|
    |                               |-- change_scene_to_file() --->|
    |                               |                              |
    |                               |<-- reads node_id ------------|
    |                               |                              |
    |                               |<-- last_battle_summary = {} -|
    |<-- reads summary -------------|                              |
```

## Scene Flow Diagram

```
                    MainMenu
                       |
                       v
    +---> CampaignMap <---+
    |          |          |
    |          v          |
    |     Battlefield     |
    |          |          |
    |          v          |
    +---- KingdomHub -----+
               |
               v
         SettingsMenu
```

## CampaignMap (scripts/CampaignMap.gd)

The campaign selection screen showing available battle nodes.

### Node References

```gdscript
@onready var map_grid: GridContainer = $MapPanel/ScrollContainer/MapGrid
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var summary_label: Label = $SummaryPanel/Content/SummaryLabel
@onready var modifiers_label: Label = $SummaryPanel/Content/ModifiersLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var kingdom_button: Button = $TopBar/KingdomButton
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")
```

### Core Functions

```gdscript
# Refresh all UI elements
func _refresh() -> void

# Build the node cards grid
func _build_map() -> void

# Create a single node card UI
func _create_node_card(node_id, label, lesson_name, reward_gold, unlocked, completed, requires) -> Control

# Format combat modifiers for display
func _format_modifiers(modifiers: Dictionary) -> String

# Update the last battle summary panel
func _update_summary() -> void
```

### Node Card States

Cards display different styles based on state:

| State | Border Color | Background | Clickable |
|-------|--------------|------------|-----------|
| Completed | ACCENT (green) | BG_CARD | Yes |
| Unlocked | BORDER_HIGHLIGHT | BG_CARD | Yes |
| Locked | BORDER_DISABLED | BG_CARD_DISABLED | No |

### Navigation Callbacks

```gdscript
func _on_node_pressed(node_id: String) -> void:
    game_controller.go_to_battle(node_id)

func _on_back_pressed() -> void:
    game_controller.go_to_menu()

func _on_kingdom_pressed() -> void:
    game_controller.go_to_kingdom()
```

## KingdomHub (scripts/KingdomHub.gd)

The upgrade shop for purchasing permanent bonuses.

### Node References

```gdscript
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var modifiers_label: Label = $ContentPanel/Scroll/Content/ModifiersLabel
@onready var content_container: VBoxContainer = $ContentPanel/Scroll/Content
@onready var kingdom_list: VBoxContainer = $ContentPanel/Scroll/Content/KingdomList
@onready var unit_list: VBoxContainer = $ContentPanel/Scroll/Content/UnitList
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")
```

### State

```gdscript
var icon_cache: Dictionary = {}      # Cached icon textures
var stats_panel: PanelContainer = null
```

### Core Functions

```gdscript
# Refresh all UI
func _refresh() -> void

# Build mastery stats panel
func _build_stats_panel() -> void

# Add a stat row to the grid
func _add_stat_row(container, label_text, value_text, value_color) -> void

# Build upgrade cards in a container
func _build_upgrade_section(container: VBoxContainer, upgrades: Array) -> void

# Format effect preview text
func _format_effect_preview(effects: Dictionary, owned: bool) -> String

# Get effect type tags for badges
func _get_upgrade_tags(effects: Dictionary) -> Array

# Load and cache an icon texture
func _load_icon(path: String) -> Texture2D
```

### Upgrade Effect Types

```gdscript
typing_power              # % bonus to word completion damage
threat_rate_multiplier    # Slows enemy advance rate
mistake_forgiveness       # Reduces penalty for typos
castle_health_bonus       # Extra starting HP
```

### Purchase Flow

```gdscript
func _on_upgrade_pressed(upgrade_id: String) -> void:
    if progression.apply_upgrade(upgrade_id):
        audio_manager.play_upgrade_purchase()
        _refresh()

func _on_back_pressed() -> void:
    game_controller.go_to_map()
```

## BattleStage (scripts/BattleStage.gd)

Visual stage component for battle scenes showing enemy approach.

### Constants

```gdscript
const DEFAULT_STAGE_SIZE := Vector2(800, 360)
const BREACH_RESET := 0.25
const PROJECTILE_SPEED := 520.0
const HIT_FLASH_DURATION := 0.18
const SPRITE_SCALE := 3.0  # Scale 16px sprites to ~48px
```

### Signals

```gdscript
signal castle_damaged
```

### Node References

```gdscript
@onready var castle: Sprite2D = $Castle
@onready var enemy: Sprite2D = $Enemy
@onready var projectile_layer: Control = $ProjectileLayer
@onready var audio_manager = get_node_or_null("/root/AudioManager")
```

### State Variables

```gdscript
var asset_loader: AssetLoader
var hit_effects: HitEffects
var progress: float = 0.0           # 0.0 = far right, 1.0 = at castle
var breach_pending: bool = false
var lane_left_x: float = 0.0
var lane_right_x: float = 0.0
var lane_y: float = 0.0
var projectiles: Array = []
var hit_flash_timer: float = 0.0
var current_enemy_kind: String = "runner"
```

### Progress Management

```gdscript
# Reset to initial state
func reset() -> void

# Set enemy progress (0-100%)
func set_progress_percent(value: float) -> void

# Get current progress percentage
func get_progress_percent() -> float

# Advance progress over time
func advance(delta: float, threat_rate: float) -> void

# Reduce progress (typing success)
func apply_relief(amount_percent: float) -> void

# Increase progress (typing failure)
func apply_penalty(amount_percent: float) -> void

# Check and consume breach state
func consume_breach() -> bool

# Reset progress after breach
func reset_after_breach() -> void
```

### Projectile System

```gdscript
# Spawn a projectile from castle to enemy
func spawn_projectile(power_shot: bool = false) -> void

# Update projectile positions and check collisions
func _update_projectiles(delta: float) -> void

# Remove all projectiles
func _clear_projectiles() -> void
```

### Enemy Display

```gdscript
# Change displayed enemy type
func set_enemy_kind(kind: String) -> void

# Update enemy position based on progress
func _update_enemy_position() -> void

# Flash enemy on hit
func _flash_enemy() -> void

# Spawn visual effects
func _spawn_hit_effect(hit_position: Vector2, is_power_shot: bool) -> void
func spawn_castle_damage_effect() -> void
```

## Integration Examples

### Starting a Battle from CampaignMap

```gdscript
# In CampaignMap
func _on_node_pressed(node_id: String) -> void:
    audio_manager.play_ui_confirm()
    game_controller.go_to_battle(node_id)

# In Battlefield._ready()
var node_id = game_controller.next_battle_node_id
var node_data = progression.get_map_node(node_id)
# Setup battle with node_data...
```

### Returning with Battle Results

```gdscript
# In Battlefield (after battle ends)
game_controller.last_battle_summary = {
    "accuracy": 0.95,
    "wpm": 45.0,
    "gold_awarded": 50,
    "performance_tier": "Good",
    "performance_bonus": 10,
    "node_label": "Training Ground"
}
game_controller.go_to_map()

# In CampaignMap._update_summary()
var summary = progression.get_last_summary()
# Display summary...
```

### Purchasing an Upgrade

```gdscript
# In KingdomHub
func _on_upgrade_pressed(upgrade_id: String) -> void:
    # ProgressionState handles gold deduction and effect application
    if progression.apply_upgrade(upgrade_id):
        audio_manager.play_upgrade_purchase()
        _refresh()  # Rebuild UI to show new state
```

### Battle Stage Progress Loop

```gdscript
# In battle controller _process()
func _process(delta: float) -> void:
    # Advance enemy based on threat rate
    stage.advance(delta, current_threat_rate)

    # Check for breach
    if stage.consume_breach():
        _on_castle_damaged()
        stage.reset_after_breach()
```

## Audio Integration

All scene controllers integrate with AudioManager:

```gdscript
# On scene enter
if audio_manager != null:
    audio_manager.switch_to_kingdom_music()

# On navigation
if audio_manager != null:
    audio_manager.play_ui_confirm()  # Forward navigation
    audio_manager.play_ui_cancel()   # Back navigation
```

## Theme Colors

Scene controllers use `ThemeColors` for consistent styling:

```gdscript
const ThemeColors = preload("res://ui/theme_colors.gd")

# Common colors used
ThemeColors.TEXT           # Normal text
ThemeColors.TEXT_DIM       # Secondary text
ThemeColors.BG_CARD        # Card backgrounds
ThemeColors.BG_CARD_DISABLED
ThemeColors.ACCENT         # Success/completed state
ThemeColors.ACCENT_BLUE    # Information highlights
ThemeColors.BORDER
ThemeColors.BORDER_HIGHLIGHT
ThemeColors.BORDER_DISABLED
ThemeColors.SUCCESS
ThemeColors.WARNING
```

## Adding New Scenes

To add a new scene to the navigation system:

1. Create scene file in `res://scenes/`
2. Add constant in GameController:
```gdscript
const SCENE_NEW := "res://scenes/NewScene.tscn"
```

3. Add navigation function:
```gdscript
func go_to_new_scene() -> void:
    get_tree().change_scene_to_file(SCENE_NEW)
```

4. Create controller script with standard pattern:
```gdscript
extends Control

@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
    # Setup UI
    if audio_manager != null:
        audio_manager.switch_to_appropriate_music()

func _on_back_pressed() -> void:
    if audio_manager != null:
        audio_manager.play_ui_cancel()
    game_controller.go_to_previous_scene()
```

## File Dependencies

- `scripts/GameController.gd` - Autoload singleton for navigation
- `scripts/CampaignMap.gd` - Campaign node selection
- `scripts/KingdomHub.gd` - Upgrade shop
- `scripts/BattleStage.gd` - Battle visual stage component
- `game/progression_state.gd` - ProgressionState autoload for game data
- `game/audio_manager.gd` - AudioManager autoload for sound
- `ui/theme_colors.gd` - Theme color constants
- `game/asset_loader.gd` - Sprite loading
- `game/hit_effects.gd` - Visual effects
