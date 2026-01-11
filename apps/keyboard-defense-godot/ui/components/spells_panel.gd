class_name SpellsPanel
extends PanelContainer
## Spells Panel - Shows available spells and cooldowns

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Spell definitions
const SPELLS: Dictionary = {
	"fireball": {
		"name": "Fireball",
		"description": "Deal 50 damage to target enemy",
		"cooldown": 3,
		"unlock_level": 1,
		"color": Color(1.0, 0.4, 0.2)
	},
	"heal": {
		"name": "Heal",
		"description": "Restore 20 HP to the castle",
		"cooldown": 5,
		"unlock_level": 2,
		"color": Color(0.3, 1.0, 0.4)
	},
	"freeze": {
		"name": "Freeze",
		"description": "Slow all enemies by 50% for 5 seconds",
		"cooldown": 8,
		"unlock_level": 3,
		"color": Color(0.4, 0.7, 1.0)
	},
	"lightning": {
		"name": "Lightning",
		"description": "Chain damage across 3 enemies",
		"cooldown": 6,
		"unlock_level": 5,
		"color": Color(1.0, 1.0, 0.4)
	},
	"meteor": {
		"name": "Meteor",
		"description": "Massive damage in an area",
		"cooldown": 12,
		"unlock_level": 8,
		"color": Color(1.0, 0.5, 0.0)
	},
	"shield": {
		"name": "Shield",
		"description": "Block next 30 damage to castle",
		"cooldown": 10,
		"unlock_level": 4,
		"color": Color(0.7, 0.7, 0.9)
	}
}

# Current state
var _player_level: int = 1
var _cooldowns: Dictionary = {}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(380, 450)

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
	title.text = "SPELLS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.6, 0.4, 0.9))
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
	subtitle.text = "Type spell name to cast"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 8)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)


func show_spells(player_level: int, cooldowns: Dictionary) -> void:
	_player_level = player_level
	_cooldowns = cooldowns
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _build_content() -> void:
	_clear_content()

	for spell_id in SPELLS.keys():
		var spell: Dictionary = SPELLS[spell_id]
		var unlock_level: int = int(spell.get("unlock_level", 1))

		var is_unlocked := _player_level >= unlock_level
		var cooldown_remaining: int = int(_cooldowns.get(spell_id, 0))

		var spell_panel := _create_spell_entry(spell_id, spell, is_unlocked, cooldown_remaining)
		_content_vbox.add_child(spell_panel)


func _create_spell_entry(spell_id: String, spell: Dictionary, is_unlocked: bool, cooldown: int) -> PanelContainer:
	var container := PanelContainer.new()

	var spell_color: Color = spell.get("color", Color.WHITE)
	var bg_color := spell_color.darkened(0.85) if is_unlocked else Color(0.1, 0.1, 0.1)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = bg_color
	panel_style.border_color = spell_color.darkened(0.5) if is_unlocked else Color(0.3, 0.3, 0.3)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	# Name and cooldown
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = str(spell.get("name", spell_id))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", spell_color if is_unlocked else Color(0.5, 0.5, 0.5))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	var status_label := Label.new()
	if not is_unlocked:
		status_label.text = "Lvl %d" % spell.get("unlock_level", 1)
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif cooldown > 0:
		status_label.text = "%ds" % cooldown
		status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	else:
		status_label.text = "Ready"
		status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	status_label.add_theme_font_size_override("font_size", 10)
	header_hbox.add_child(status_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = str(spell.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM if is_unlocked else Color(0.4, 0.4, 0.4))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Cooldown info
	var cd_label := Label.new()
	cd_label.text = "Cooldown: %d waves" % spell.get("cooldown", 1)
	cd_label.add_theme_font_size_override("font_size", 9)
	cd_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(cd_label)

	return container


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
