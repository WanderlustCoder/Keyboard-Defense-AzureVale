class_name EffectsPanel
extends PanelContainer
## Effects Panel - Shows status effects information organized by category

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")

enum Tab { MOVEMENT, DOT, DEFENSE, SPECIAL }

var _current_tab: Tab = Tab.MOVEMENT

# UI elements
var _close_btn: Button = null
var _tab_container: HBoxContainer = null
var _tab_buttons: Array[Button] = []
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Effect categories
const EFFECT_CATEGORIES: Dictionary = {
	"Movement": {
		"color": Color(0.53, 0.81, 0.92),  # Light blue
		"effects": ["slow", "frozen", "rooted"]
	},
	"Damage Over Time": {
		"color": Color(1.0, 0.5, 0.3),  # Orange-red
		"effects": ["burning", "poisoned", "bleeding", "corrupting"]
	},
	"Defensive Reduction": {
		"color": Color(0.6, 0.6, 0.6),  # Gray
		"effects": ["armor_broken", "exposed", "weakened"]
	},
	"Special": {
		"color": Color(1.0, 0.84, 0.0),  # Gold
		"effects": ["marked", "purifying", "confused"]
	}
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 440)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	style.border_color = ThemeColors.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "STATUS EFFECTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Tab buttons
	_tab_container = HBoxContainer.new()
	_tab_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_tab_container)

	var tab_names: Array[String] = ["Movement", "DoT", "Defense", "Special"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(100, 30)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_container.add_child(btn)
		_tab_buttons.append(btn)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer hint
	var footer := Label.new()
	footer.text = "Towers, skills, and spells can apply these effects to enemies!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)

	_update_tab_buttons()
	_build_effects_list()


func show_effects() -> void:
	_current_tab = Tab.MOVEMENT
	_update_tab_buttons()
	_build_effects_list()
	show()


func _update_tab_buttons() -> void:
	var categories: Array = EFFECT_CATEGORIES.keys()
	for i in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if i < categories.size():
			var cat_data: Dictionary = EFFECT_CATEGORIES.get(categories[i], {})
			var color: Color = cat_data.get("color", Color.WHITE)
			if i == _current_tab:
				btn.add_theme_color_override("font_color", color)
			else:
				btn.remove_theme_color_override("font_color")


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_effects_list() -> void:
	_clear_content()

	var categories: Array = EFFECT_CATEGORIES.keys()
	if _current_tab >= categories.size():
		return

	var category_name: String = categories[_current_tab]
	var cat_data: Dictionary = EFFECT_CATEGORIES.get(category_name, {})
	var color: Color = cat_data.get("color", Color.WHITE)
	var effect_ids: Array = cat_data.get("effects", [])

	# Category header
	var header := Label.new()
	header.text = category_name.to_upper()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", color)
	_content_vbox.add_child(header)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	_content_vbox.add_child(spacer)

	# Effects in category
	for effect_id in effect_ids:
		var widget := _create_effect_widget(effect_id)
		_content_vbox.add_child(widget)


func _create_effect_widget(effect_id: String) -> Control:
	var effect: Dictionary = SimStatusEffects.get_effect(effect_id)
	if effect.is_empty():
		var label := Label.new()
		label.text = "Unknown effect: %s" % effect_id
		return label

	var name: String = str(effect.get("name", effect_id.capitalize()))
	var desc: String = str(effect.get("description", ""))
	var hex_color: String = str(effect.get("color", "#FFFFFF"))
	var effect_color: Color = Color.from_string(hex_color, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = effect_color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Effect name
	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", effect_color)
	vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc_label)

	# Effect details
	var details := _build_effect_details(effect)
	if not details.is_empty():
		var details_label := RichTextLabel.new()
		details_label.bbcode_enabled = true
		details_label.fit_content = true
		details_label.add_theme_font_size_override("normal_font_size", 11)
		details_label.text = details
		vbox.add_child(details_label)

	return container


func _build_effect_details(effect: Dictionary) -> String:
	var lines: Array[String] = []

	# Duration
	var duration: float = 0.0
	if effect.has("duration"):
		duration = float(effect.get("duration", 0))
		lines.append("[color=gray]Duration:[/color] %.1fs" % duration)
	elif effect.has("tiers"):
		var tiers: Array = effect.get("tiers", [])
		if not tiers.is_empty():
			var tier_strs: Array[String] = []
			for tier_data in tiers:
				if typeof(tier_data) == TYPE_DICTIONARY:
					var t: int = int(tier_data.get("tier", 1))
					var d: float = float(tier_data.get("duration", 2.0))
					var slow: int = int(tier_data.get("slow_percent", 0))
					if slow > 0:
						tier_strs.append("T%d: %d%% / %.1fs" % [t, slow, d])
					else:
						tier_strs.append("T%d: %.1fs" % [t, d])
			if not tier_strs.is_empty():
				lines.append("[color=gray]Tiers:[/color] %s" % ", ".join(tier_strs))

	# DoT info
	if effect.has("tick_damage"):
		var tick: int = int(effect.get("tick_damage", 0))
		var interval: float = float(effect.get("tick_interval", 1.0))
		var damage_type: String = str(effect.get("damage_type", ""))
		var max_stacks: int = int(effect.get("max_stacks", 1))

		var dps: float = float(tick) / interval if interval > 0 else 0.0
		lines.append("[color=orange]Damage:[/color] %d %s every %.1fs (%.1f DPS)" % [tick, damage_type, interval, dps])

		if max_stacks > 1:
			lines.append("[color=cyan]Max Stacks:[/color] %d" % max_stacks)
			var max_dps: float = dps * max_stacks
			lines.append("[color=red]Max DPS:[/color] %.1f" % max_dps)

	# Movement effects
	if effect.get("immobilize", false):
		lines.append("[color=cyan]Immobilizes[/color] the target")

	if effect.has("max_slow"):
		lines.append("[color=gray]Max slow:[/color] %d%%" % int(effect.get("max_slow", 80)))

	# Damage modifiers
	if effect.has("damage_vulnerability"):
		var mult: float = float(effect.get("damage_vulnerability", 1.0))
		lines.append("[color=red]+%.0f%% damage taken[/color]" % ((mult - 1.0) * 100))

	if effect.has("damage_taken_increase"):
		var increase: float = float(effect.get("damage_taken_increase", 0))
		lines.append("[color=red]+%.0f%% damage taken[/color]" % (increase * 100))

	if effect.has("damage_dealt_reduction"):
		var reduction: float = float(effect.get("damage_dealt_reduction", 0))
		lines.append("[color=lime]-%.0f%% damage dealt[/color]" % (reduction * 100))

	if effect.has("armor_reduction_percent"):
		var reduction: int = int(effect.get("armor_reduction_percent", 0))
		lines.append("[color=gray]Armor reduced by %d%%[/color]" % reduction)

	# Healing reduction
	if effect.has("healing_reduction"):
		var reduction: float = float(effect.get("healing_reduction", 0))
		lines.append("[color=purple]-%.0f%% healing[/color]" % (reduction * 100))

	# Max HP reduction
	if effect.get("reduces_max_hp", false):
		var reduction: float = float(effect.get("hp_reduction_per_tick", 0.02))
		lines.append("[color=purple]-%.0f%% max HP per tick[/color]" % (reduction * 100))

	# Special behaviors
	if effect.get("movement_refreshes", false):
		lines.append("[color=gray]Refreshes when target moves[/color]")

	if effect.has("immunity_duration"):
		var immunity: float = float(effect.get("immunity_duration", 5.0))
		lines.append("[color=gray]Target immune for %.1fs after[/color]" % immunity)

	if effect.get("can_still_attack", false):
		lines.append("[color=gray]Target can still attack[/color]")

	if effect.has("removed_by"):
		var removed_by: Array = effect.get("removed_by", [])
		if not removed_by.is_empty():
			lines.append("[color=gray]Removed by: %s[/color]" % ", ".join(removed_by))

	# Mark effects
	if effect.get("all_towers_prioritize", false):
		lines.append("[color=yellow]All towers prioritize this target[/color]")

	if effect.has("critical_chance_against"):
		var crit: float = float(effect.get("critical_chance_against", 0))
		lines.append("[color=yellow]+%.0f%% crit chance against[/color]" % (crit * 100))

	# Confused effects
	if effect.has("attack_allies_chance"):
		var chance: float = float(effect.get("attack_allies_chance", 0))
		lines.append("[color=yellow]%.0f%% chance to attack allies[/color]" % (chance * 100))

	return "\n".join(lines)


func _on_tab_pressed(tab_index: int) -> void:
	_current_tab = tab_index as Tab
	_update_tab_buttons()
	_build_effects_list()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
