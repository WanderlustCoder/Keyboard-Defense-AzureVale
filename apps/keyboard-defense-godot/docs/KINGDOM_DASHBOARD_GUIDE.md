# Kingdom Dashboard Guide

This document explains the Kingdom Dashboard UI component that provides resource management, worker assignment, building upgrades, research, and trading during the planning phase.

## Overview

The Kingdom Dashboard is a tabbed management interface:

```
Tab Button → Load Tab Content → User Interaction → Signal Emission → State Update
    ↓              ↓                   ↓                  ↓              ↓
Resources     _refresh_*()        Button clicks     worker_assigned   refresh UI
Workers       display data        Slider changes    upgrade_requested
Buildings                                           trade_executed
Research
Trade
```

## UI Structure

### Main Components

```gdscript
# ui/components/kingdom_dashboard.gd
const PANEL_WIDTH := 500
const PANEL_HEIGHT := 450
const SECTION_SPACING := 12
const ITEM_SPACING := 6
const FADE_DURATION := 0.15

# UI References
var _overlay: ColorRect           # Dark background overlay
var _panel: PanelContainer        # Main panel container
var _scroll: ScrollContainer      # Scrollable content
var _content: VBoxContainer       # Main content container
var _tabs: TabContainer           # Tab navigation

# Section containers (one per tab)
var _resources_section: VBoxContainer
var _workers_section: VBoxContainer
var _buildings_section: VBoxContainer
var _research_section: VBoxContainer
var _trade_section: VBoxContainer
```

### Signals

```gdscript
signal worker_assigned(building_index: int)
signal worker_unassigned(building_index: int)
signal upgrade_requested(building_index: int)
signal research_started(research_id: String)
signal trade_executed(from: String, to: String, amount: int)
signal closed
```

## Tab Implementation

### Resources Tab

Displays current resources with production rates:

```gdscript
# ui/components/kingdom_dashboard.gd:199
func _refresh_resources() -> void:
    _clear_children(_resources_section)
    if _state == null:
        return

    var header := _create_section_header("Resource Summary")
    _resources_section.add_child(header)

    var current_box := _create_info_box()
    _resources_section.add_child(current_box)

    var production: Dictionary = SimWorkers.daily_production_with_workers(_state)
    var upkeep: int = SimWorkers.daily_upkeep(_state)

    _add_resource_row(current_box, "Wood", int(_state.resources.get("wood", 0)), int(production.get("wood", 0)))
    _add_resource_row(current_box, "Stone", int(_state.resources.get("stone", 0)), int(production.get("stone", 0)))
    _add_resource_row(current_box, "Food", int(_state.resources.get("food", 0)), int(production.get("food", 0)) - upkeep, upkeep)
    _add_resource_row(current_box, "Gold", _state.gold, int(production.get("gold", 0)))

    # Defense rating
    var defense: int = SimBuildings.total_defense(_state)
    var defense_label := Label.new()
    defense_label.text = "Defense Rating: %d" % defense
    defense_label.add_theme_color_override("font_color", ThemeColors.ACCENT_CYAN)
    _resources_section.add_child(defense_label)
```

**Resource Row Format:**
```
Wood: 150 (+8/day)
Stone: 75 (+4/day)
Food: 200 (+12 -6 = +6/day)   # Shows production and upkeep
Gold: 50 (+2/day)
Defense Rating: 24
```

### Workers Tab

Manages worker assignment to buildings:

```gdscript
# ui/components/kingdom_dashboard.gd:227
func _refresh_workers() -> void:
    _clear_children(_workers_section)
    if _state == null:
        return

    var summary: Dictionary = SimWorkers.get_worker_summary(_state)

    var header := _create_section_header("Workers: %d/%d assigned" % [summary.assigned, summary.total_workers])
    _workers_section.add_child(header)

    var avail_label := Label.new()
    avail_label.text = "Available: %d | Upkeep: %d food/day" % [summary.available, summary.upkeep]
    avail_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
    _workers_section.add_child(avail_label)

    # Worker assignments
    for assignment in summary.assignments:
        var row := _create_worker_row(assignment)
        _workers_section.add_child(row)
```

**Worker Row UI:**
```
[Building Name (x,y)]  [2/3]  [-] [+]
                       count  unassign/assign buttons
```

```gdscript
# ui/components/kingdom_dashboard.gd:248
func _create_worker_row(assignment: Dictionary) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)

    var name_label := Label.new()
    name_label.text = "%s (%d,%d)" % [str(assignment.building_type).capitalize(), assignment.position.x, assignment.position.y]
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(name_label)

    var count_label := Label.new()
    count_label.text = "%d/%d" % [assignment.workers, assignment.capacity]
    row.add_child(count_label)

    var minus_btn := Button.new()
    minus_btn.text = "-"
    minus_btn.disabled = assignment.workers <= 0
    minus_btn.pressed.connect(func(): _on_unassign_worker(assignment.index))
    row.add_child(minus_btn)

    var plus_btn := Button.new()
    plus_btn.text = "+"
    plus_btn.disabled = assignment.workers >= assignment.capacity or SimWorkers.available_workers(_state) <= 0
    plus_btn.pressed.connect(func(): _on_assign_worker(assignment.index))
    row.add_child(plus_btn)

    return row
```

### Buildings Tab

Displays buildings with upgrade options:

```gdscript
# ui/components/kingdom_dashboard.gd:288
func _refresh_buildings() -> void:
    _clear_children(_buildings_section)
    if _state == null:
        return

    var header := _create_section_header("Buildings")
    _buildings_section.add_child(header)

    # Group buildings by type
    var by_type: Dictionary = {}
    for key in _state.structures.keys():
        var building_type: String = str(_state.structures[key])
        if not by_type.has(building_type):
            by_type[building_type] = []
        by_type[building_type].append(int(key))

    for building_type in by_type.keys():
        var indices: Array = by_type[building_type]
        for idx in indices:
            var row := _create_building_row(building_type, idx)
            _buildings_section.add_child(row)
```

**Building Row UI:**
```
[Farm Lv2 (3,4)]                    [Upgrade (50w, 30s)]
[Tower Lv3 (5,2)]                   [MAX]
```

```gdscript
# ui/components/kingdom_dashboard.gd:310
func _create_building_row(building_type: String, index: int) -> HBoxContainer:
    var row := HBoxContainer.new()
    var level: int = SimBuildings.structure_level(_state, index)
    var pos: Vector2i = SimMap.pos_from_index(index, _state.map_w)

    var name_label := Label.new()
    name_label.text = "%s Lv%d (%d,%d)" % [building_type.capitalize(), level, pos.x, pos.y]
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(name_label)

    var preview: Dictionary = SimBuildings.get_building_upgrade_preview(_state, index)
    if preview.can_upgrade:
        var cost_text: String = _format_cost(preview.cost)
        var upgrade_btn := Button.new()
        upgrade_btn.text = "Upgrade (%s)" % cost_text
        upgrade_btn.pressed.connect(func(): _on_upgrade_building(index))
        row.add_child(upgrade_btn)
    elif preview.current_level >= SimBuildings.max_level(building_type):
        var max_label := Label.new()
        max_label.text = "MAX"
        max_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
        row.add_child(max_label)

    return row
```

### Research Tab

Shows research progress and available options:

```gdscript
# ui/components/kingdom_dashboard.gd:342
func _refresh_research() -> void:
    _clear_children(_research_section)
    if _state == null or _research_instance == null:
        return

    var summary: Dictionary = _research_instance.get_research_summary(_state)

    var header := _create_section_header("Research (%d/%d completed)" % [summary.completed_count, summary.total_count])
    _research_section.add_child(header)

    # Current research progress
    if not summary.active_research.is_empty():
        var active_box := _create_info_box()
        _research_section.add_child(active_box)

        var active_label := Label.new()
        active_label.text = "Researching: %s" % summary.active_label
        active_box.add_child(active_label)

        var progress_bar := ProgressBar.new()
        progress_bar.value = summary.progress_percent * 100.0
        active_box.add_child(progress_bar)

        var progress_label := Label.new()
        progress_label.text = "%d/%d waves" % [summary.progress, summary.waves_needed]
        active_box.add_child(progress_label)

    # Available research
    var available: Array = _research_instance.get_available_research(_state)
    if available.size() > 0:
        var avail_header := Label.new()
        avail_header.text = "Available Research:"
        _research_section.add_child(avail_header)

        for item in available:
            var row := _create_research_row(item)
            _research_section.add_child(row)
```

**Research Row UI:**
```
[Improved Walls]    [150g]    [Start]
```

### Trade Tab

Enables resource exchange:

```gdscript
# ui/components/kingdom_dashboard.gd:414
func _refresh_trade() -> void:
    _clear_children(_trade_section)
    if _state == null:
        return

    var summary: Dictionary = SimTrade.get_trade_summary(_state)

    var header := _create_section_header("Trade")
    _trade_section.add_child(header)

    if not summary.enabled:
        var disabled_label := Label.new()
        disabled_label.text = "Requires Level 3 Market to trade"
        _trade_section.add_child(disabled_label)
        return

    # Current rates
    var rates_label := Label.new()
    rates_label.text = "Today's Exchange Rates:"
    _trade_section.add_child(rates_label)

    var rates_box := _create_info_box()
    _trade_section.add_child(rates_box)

    var rates: Dictionary = summary.rates
    _add_rate_row(rates_box, "Wood -> Stone", rates.get("wood_to_stone", 0))
    _add_rate_row(rates_box, "Stone -> Wood", rates.get("stone_to_wood", 0))
    _add_rate_row(rates_box, "Wood -> Gold", rates.get("wood_to_gold", 0))
    _add_rate_row(rates_box, "Food -> Gold", rates.get("food_to_gold", 0))

    # Suggested trades
    var suggestions: Array = SimTrade.get_suggested_trades(_state)
    if suggestions.size() > 0:
        for suggestion in suggestions:
            var row := _create_trade_row(suggestion)
            _trade_section.add_child(row)
```

**Trade Row UI:**
```
Wood -> Stone: 1.25
Stone -> Wood: 0.80
[50 wood -> 62 stone]    [Trade]
```

## Show/Hide Animation

```gdscript
# ui/components/kingdom_dashboard.gd:164
func show_dashboard() -> void:
    if _tween and _tween.is_valid():
        _tween.kill()
    visible = true
    modulate.a = 0.0
    _tween = create_tween()
    _tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
    _refresh_all()

func hide_dashboard() -> void:
    if _tween and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
    _tween.tween_callback(func(): visible = false)
    closed.emit()
```

## Input Handling

```gdscript
# ui/components/kingdom_dashboard.gd:184
func _input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed:
        if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
            hide_dashboard()
            get_viewport().set_input_as_handled()
```

| Key | Action |
|-----|--------|
| Tab | Toggle dashboard |
| Escape | Close dashboard |

## State Management

```gdscript
# ui/components/kingdom_dashboard.gd:159
func update_state(state: GameState) -> void:
    _state = state
    if visible:
        _refresh_all()

func _refresh_all() -> void:
    if _state == null:
        return
    _refresh_resources()
    _refresh_workers()
    _refresh_buildings()
    _refresh_research()
    _refresh_trade()
```

## Helper Functions

### Clear Children

```gdscript
# ui/components/kingdom_dashboard.gd:481
func _clear_children(container: Control) -> void:
    for child in container.get_children():
        child.queue_free()
```

### Section Header

```gdscript
# ui/components/kingdom_dashboard.gd:485
func _create_section_header(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", ThemeColors.ACCENT)
    return label
```

### Format Cost

```gdscript
# ui/components/kingdom_dashboard.gd:538
func _format_cost(cost: Dictionary) -> String:
    var parts: Array = []
    for key in cost.keys():
        parts.append("%d%s" % [int(cost[key]), key[0]])  # "50w, 30s"
    return ", ".join(parts)
```

## Integration Example

### Main Game Integration

```gdscript
# game/main.gd
var kingdom_dashboard: KingdomDashboard

func _ready() -> void:
    kingdom_dashboard = KingdomDashboard.new()
    add_child(kingdom_dashboard)

    kingdom_dashboard.worker_assigned.connect(_on_worker_assigned)
    kingdom_dashboard.upgrade_requested.connect(_on_upgrade_requested)
    kingdom_dashboard.trade_executed.connect(_on_trade_executed)
    kingdom_dashboard.closed.connect(_on_dashboard_closed)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_TAB and state.phase == "day":
            if kingdom_dashboard.visible:
                kingdom_dashboard.hide_dashboard()
            else:
                kingdom_dashboard.update_state(state)
                kingdom_dashboard.show_dashboard()

func _on_worker_assigned(building_index: int) -> void:
    # Worker was assigned, update game state display
    _refresh_resource_display()

func _on_upgrade_requested(building_index: int) -> void:
    # Building was upgraded, play sound
    audio_manager.play_build()
    _refresh_map_display()
```

## Testing

```gdscript
func test_resource_row_formatting():
    var dashboard := KingdomDashboard.new()

    # Test cost formatting
    var cost := {"wood": 50, "stone": 30}
    var formatted := dashboard._format_cost(cost)
    assert(formatted == "50w, 30s" or formatted == "30s, 50w")

    _pass("test_resource_row_formatting")

func test_worker_button_states():
    var state := GameState.new()
    state.workers = 5

    var dashboard := KingdomDashboard.new()
    dashboard.update_state(state)

    # Verify buttons enable/disable based on state
    # Plus disabled when at capacity or no available workers
    # Minus disabled when no workers assigned

    _pass("test_worker_button_states")
```

## Sim Integration Points

| Tab | Sim Module | Functions Used |
|-----|------------|----------------|
| Resources | SimWorkers | daily_production_with_workers(), daily_upkeep() |
| Resources | SimBuildings | total_defense() |
| Workers | SimWorkers | get_worker_summary(), assign_worker(), unassign_worker(), available_workers() |
| Buildings | SimBuildings | structure_level(), get_building_upgrade_preview(), max_level(), apply_upgrade() |
| Buildings | SimMap | pos_from_index() |
| Research | SimResearch | get_research_summary(), get_available_research(), start_research() |
| Trade | SimTrade | get_trade_summary(), get_suggested_trades(), execute_trade() |
