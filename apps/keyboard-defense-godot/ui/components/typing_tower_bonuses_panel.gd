class_name TypingTowerBonusesPanel
extends PanelContainer
## Typing Tower Bonuses Panel - Shows how typing performance affects tower damage

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Tower bonus colors
const TOWER_COLORS: Dictionary = {
	"wordsmith": Color(1.0, 0.6, 0.2),
	"arcane": Color(0.6, 0.4, 0.9),
	"shrine": Color(0.4, 0.9, 0.7),
	"arrow": Color(0.9, 0.8, 0.4),
	"magic": Color(0.5, 0.5, 0.9),
	"frost": Color(0.4, 0.8, 1.0),
	"holy": Color(1.0, 0.95, 0.6),
	"tesla": Color(0.4, 0.9, 0.9),
	"siege": Color(0.8, 0.5, 0.3)
}

# Tower bonus data
const TOWER_BONUSES: Array[Dictionary] = [
	{
		"name": "Wordsmith's Forge",
		"id": "wordsmith",
		"scaling": "WPM + Accuracy",
		"formula": "base * (1 + WPM/100) * accuracy^2",
		"description": "Scales with both typing speed and accuracy. Best tower for fast, accurate typists."
	},
	{
		"name": "Arcane Tower",
		"id": "arcane",
		"scaling": "Accuracy",
		"formula": "1.0 to 1.5x based on accuracy (50-100%)",
		"description": "Linear damage scaling based on accuracy. Rewards precise typing."
	},
	{
		"name": "Letter Spirit Shrine",
		"id": "shrine",
		"scaling": "Unique Letters",
		"formula": "+5% per unique letter (max 130%)",
		"description": "Use variety! Type many different letters to maximize damage."
	},
	{
		"name": "Arrow Tower",
		"id": "arrow",
		"scaling": "Accuracy (Small)",
		"formula": "Up to +20% at perfect accuracy",
		"description": "Small accuracy bonus. Reliable base damage."
	},
	{
		"name": "Magic Tower",
		"id": "magic",
		"scaling": "Accuracy (Moderate)",
		"formula": "Up to +30% at perfect accuracy",
		"description": "Moderate accuracy bonus. Good for consistent typists."
	},
	{
		"name": "Frost Tower",
		"id": "frost",
		"scaling": "Accuracy",
		"formula": "Up to +25% slow effectiveness",
		"description": "Slow effect improves with accuracy."
	},
	{
		"name": "Holy Tower",
		"id": "holy",
		"scaling": "Perfect Streak",
		"formula": "+10% per perfect word (max +50%)",
		"description": "Rewards typing words without errors. Build perfect streaks!"
	},
	{
		"name": "Tesla Tower",
		"id": "tesla",
		"scaling": "Combo",
		"formula": "+2% per combo, extra chains at 10/20/50",
		"description": "Build combos for extra damage and chain lightning targets."
	},
	{
		"name": "Siege Tower",
		"id": "siege",
		"scaling": "Sustained Typing",
		"formula": "Up to +50% based on chars/second",
		"description": "Rewards consistent typing speed over time."
	}
]

# Combo thresholds
const COMBO_INFO: Array[Dictionary] = [
	{"threshold": 3, "multiplier": 1.1, "label": "x1.1"},
	{"threshold": 5, "multiplier": 1.25, "label": "x1.25"},
	{"threshold": 10, "multiplier": 1.5, "label": "x1.5"},
	{"threshold": 20, "multiplier": 2.0, "label": "x2.0"},
	{"threshold": 50, "multiplier": 2.5, "label": "x2.5"}
]

# Letter Shrine modes
const SHRINE_MODES: Array[Dictionary] = [
	{"mode": "Alpha", "condition": "Default", "effect": "Focused single-target damage", "color": Color(0.9, 0.4, 0.4)},
	{"mode": "Epsilon", "condition": "20+ unique letters", "effect": "Chain lightning to multiple targets", "color": Color(0.4, 0.9, 0.9)},
	{"mode": "Omega", "condition": "30+ combo", "effect": "Heals castle on enemy kill", "color": Color(0.4, 0.9, 0.4)}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 580)

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
	title.text = "TYPING TOWER BONUSES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "How your typing performance affects tower damage"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

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

	# Footer
	var footer := Label.new()
	footer.text = "All towers also receive combo damage multipliers"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_typing_tower_bonuses() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Combo system section
	_build_combo_section()

	# Tower bonuses section
	_build_tower_bonuses_section()

	# Letter Shrine modes section
	_build_shrine_modes_section()

	# Tips section
	_build_tips_section()


func _build_combo_section() -> void:
	var section := _create_section_panel("COMBO MULTIPLIERS", Color(1.0, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "All towers receive damage multipliers based on your combo:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	# Combo tiers grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for combo_tier in COMBO_INFO:
		var tier_container := VBoxContainer.new()
		tier_container.add_theme_constant_override("separation", 0)
		grid.add_child(tier_container)

		var threshold_label := Label.new()
		threshold_label.text = "%d+" % int(combo_tier.get("threshold", 0))
		threshold_label.add_theme_font_size_override("font_size", 10)
		threshold_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		threshold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_container.add_child(threshold_label)

		var mult_label := Label.new()
		mult_label.text = str(combo_tier.get("label", ""))
		mult_label.add_theme_font_size_override("font_size", 14)
		mult_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_container.add_child(mult_label)


func _build_tower_bonuses_section() -> void:
	var section := _create_section_panel("TOWER-SPECIFIC BONUSES", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tower_info in TOWER_BONUSES:
		var card := _create_tower_bonus_card(tower_info)
		vbox.add_child(card)


func _create_tower_bonus_card(tower_info: Dictionary) -> Control:
	var tower_id: String = str(tower_info.get("id", ""))
	var tower_name: String = str(tower_info.get("name", ""))
	var scaling: String = str(tower_info.get("scaling", ""))
	var formula: String = str(tower_info.get("formula", ""))
	var description: String = str(tower_info.get("description", ""))

	var color: Color = TOWER_COLORS.get(tower_id, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = tower_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	header.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var scaling_label := Label.new()
	scaling_label.text = scaling
	scaling_label.add_theme_font_size_override("font_size", 10)
	scaling_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	header.add_child(scaling_label)

	# Formula
	var formula_label := Label.new()
	formula_label.text = formula
	formula_label.add_theme_font_size_override("font_size", 10)
	formula_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	main_vbox.add_child(formula_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	return container


func _build_shrine_modes_section() -> void:
	var section := _create_section_panel("LETTER SPIRIT SHRINE MODES", Color(0.4, 0.9, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "The Letter Spirit Shrine changes attack mode based on your typing:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	for mode_info in SHRINE_MODES:
		var row := _create_shrine_mode_row(mode_info)
		vbox.add_child(row)


func _create_shrine_mode_row(mode_info: Dictionary) -> Control:
	var mode_name: String = str(mode_info.get("mode", ""))
	var condition: String = str(mode_info.get("condition", ""))
	var effect: String = str(mode_info.get("effect", ""))
	var color: Color = mode_info.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Mode name
	var mode_label := Label.new()
	mode_label.text = mode_name
	mode_label.add_theme_font_size_override("font_size", 11)
	mode_label.add_theme_color_override("font_color", color)
	mode_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(mode_label)

	# Condition
	var cond_label := Label.new()
	cond_label.text = condition
	cond_label.add_theme_font_size_override("font_size", 10)
	cond_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	cond_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(cond_label)

	# Effect
	var effect_label := Label.new()
	effect_label.text = effect
	effect_label.add_theme_font_size_override("font_size", 10)
	effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(effect_label)

	return hbox


func _build_tips_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.12, 0.15, 0.18, 0.8)
	section_style.border_color = Color(0.3, 0.4, 0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "OPTIMIZATION TIPS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(header)

	var tips: Array[String] = [
		"Build Wordsmith's Forge if you have high WPM and accuracy",
		"Holy Towers excel when you type words without errors",
		"Tesla Towers reward maintaining long combos",
		"Letter Spirit Shrine benefits from typing variety",
		"Siege Towers need sustained typing speed over time"
	]

	for tip in tips:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
