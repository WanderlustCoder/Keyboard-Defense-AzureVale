class_name SpellsPanel
extends PanelContainer
## Spells Panel - Shows available spells and cooldowns.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Spell definitions (domain-specific colors)
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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_SM, 450)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SPELLS"
	DesignSystem.style_label(title, "h2", ThemeColors.RARITY_EPIC)
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Type spell name to cast"
	DesignSystem.style_label(subtitle, "caption", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	var bg_color := spell_color.darkened(0.85) if is_unlocked else ThemeColors.BG_CARD_DISABLED

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = bg_color
	panel_style.border_color = spell_color.darkened(0.5) if is_unlocked else ThemeColors.BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel_style.set_content_margin_all(DesignSystem.SPACE_SM)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	container.add_child(vbox)

	# Name and cooldown
	var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = str(spell.get("name", spell_id))
	DesignSystem.style_label(name_label, "body_small", spell_color if is_unlocked else ThemeColors.TEXT_DISABLED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	var status_label := Label.new()
	if not is_unlocked:
		status_label.text = "Lvl %d" % spell.get("unlock_level", 1)
		DesignSystem.style_label(status_label, "caption", ThemeColors.TEXT_DISABLED)
	elif cooldown > 0:
		status_label.text = "%ds" % cooldown
		DesignSystem.style_label(status_label, "caption", ThemeColors.WARNING)
	else:
		status_label.text = "Ready"
		DesignSystem.style_label(status_label, "caption", ThemeColors.SUCCESS)
	header_hbox.add_child(status_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = str(spell.get("description", ""))
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM if is_unlocked else ThemeColors.TEXT_DISABLED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Cooldown info
	var cd_label := Label.new()
	cd_label.text = "Cooldown: %d waves" % spell.get("cooldown", 1)
	DesignSystem.style_label(cd_label, "caption", ThemeColors.TEXT_DIM)
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
