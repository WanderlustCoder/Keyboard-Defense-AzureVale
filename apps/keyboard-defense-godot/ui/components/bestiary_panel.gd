class_name BestiaryPanel
extends PanelContainer
## Bestiary Panel - View encountered enemies and their information.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal close_requested

const SimBestiary = preload("res://sim/bestiary.gd")
const SimEnemyTypes = preload("res://sim/enemy_types.gd")
const SimEnemyAbilities = preload("res://sim/enemy_abilities.gd")
const SimBossEncounters = preload("res://sim/boss_encounters.gd")

enum Tab { MINIONS, SOLDIERS, ELITES, CHAMPIONS, BOSSES, ABILITIES, REGIONAL }

var _current_tab: Tab = Tab.MINIONS
var _profile: Dictionary = {}
var _selected_id: String = ""

# UI elements
var _tab_bar: HBoxContainer = null
var _tab_buttons: Array[Button] = []
var _list_container: ItemList = null
var _detail_display: RichTextLabel = null
var _summary_label: Label = null
var _close_btn: Button = null
var _title_label: Label = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG + 100, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "BESTIARY"
	DesignSystem.style_label(_title_label, "h2", ThemeColors.ACCENT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Summary
	_summary_label = Label.new()
	DesignSystem.style_label(_summary_label, "caption", ThemeColors.TEXT_DIM)
	main_vbox.add_child(_summary_label)

	# Tab bar
	_tab_bar = DesignSystem.create_hbox(2)
	main_vbox.add_child(_tab_bar)

	# Create tab buttons with domain-specific tier colors
	var tabs: Array[Dictionary] = [
		{"name": "Minions", "tab": Tab.MINIONS, "color": SimEnemyTypes.TIER_COLORS.get(SimEnemyTypes.Tier.MINION, Color.GRAY)},
		{"name": "Soldiers", "tab": Tab.SOLDIERS, "color": SimEnemyTypes.TIER_COLORS.get(SimEnemyTypes.Tier.SOLDIER, Color.GREEN)},
		{"name": "Elites", "tab": Tab.ELITES, "color": SimEnemyTypes.TIER_COLORS.get(SimEnemyTypes.Tier.ELITE, Color.BLUE)},
		{"name": "Champions", "tab": Tab.CHAMPIONS, "color": SimEnemyTypes.TIER_COLORS.get(SimEnemyTypes.Tier.CHAMPION, Color.PURPLE)},
		{"name": "Bosses", "tab": Tab.BOSSES, "color": SimEnemyTypes.TIER_COLORS.get(SimEnemyTypes.Tier.BOSS, Color.ORANGE)},
		{"name": "Regional", "tab": Tab.REGIONAL, "color": ThemeColors.SUCCESS.darkened(0.2)},
		{"name": "Abilities", "tab": Tab.ABILITIES, "color": ThemeColors.RARITY_EPIC}
	]

	for tab_info in tabs:
		var btn := Button.new()
		btn.text = str(tab_info["name"])
		btn.toggle_mode = true
		DesignSystem.style_label(btn, "caption", ThemeColors.TEXT)
		var tab_val: Tab = tab_info["tab"]
		btn.pressed.connect(_on_tab_selected.bind(tab_val))
		_tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	# Separator
	main_vbox.add_child(DesignSystem.create_separator())

	# Content area - split view
	var content := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	# List
	_list_container = ItemList.new()
	_list_container.custom_minimum_size = Vector2(200, 0)
	_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_container.item_selected.connect(_on_item_selected)
	_style_item_list()
	content.add_child(_list_container)

	# Detail display
	_detail_display = RichTextLabel.new()
	_detail_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_display.bbcode_enabled = true
	_detail_display.scroll_active = true
	content.add_child(_detail_display)

	# Hint
	var hint := Label.new()
	hint.text = "Select an entry to view details. Use LEFT/RIGHT to change tabs. ESC to close."
	DesignSystem.style_label(hint, "caption", ThemeColors.TEXT_DIM)
	main_vbox.add_child(hint)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func _style_item_list() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = ThemeColors.BG_INPUT
	bg_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	_list_container.add_theme_stylebox_override("panel", bg_style)
	_list_container.add_theme_color_override("font_color", ThemeColors.TEXT)
	_list_container.add_theme_color_override("font_selected_color", ThemeColors.TEXT)
	_list_container.add_theme_color_override("guide_color", ThemeColors.BORDER)


func show_bestiary(profile: Dictionary) -> void:
	_profile = profile
	_update_summary()
	_refresh_tab()
	show()


func hide_bestiary() -> void:
	hide()
	close_requested.emit()


func _update_summary() -> void:
	var summary: Dictionary = SimBestiary.get_summary(_profile)
	_summary_label.text = "Discovered: %d/%d enemies | Bosses: %d/%d | Abilities: %d/%d | Completion: %d%%" % [
		int(summary.get("enemies_seen", 0)),
		int(summary.get("enemies_total", 0)),
		int(summary.get("bosses_defeated", 0)),
		int(summary.get("bosses_total", 0)),
		int(summary.get("abilities_seen", 0)),
		int(summary.get("abilities_total", 0)),
		int(summary.get("completion_percent", 0))
	]


func _refresh_tab() -> void:
	_list_container.clear()
	_detail_display.text = ""
	_selected_id = ""

	# Update tab button states
	for i in range(_tab_buttons.size()):
		_tab_buttons[i].button_pressed = (i == int(_current_tab))

	match _current_tab:
		Tab.MINIONS:
			_populate_tier(SimEnemyTypes.Tier.MINION)
		Tab.SOLDIERS:
			_populate_tier(SimEnemyTypes.Tier.SOLDIER)
		Tab.ELITES:
			_populate_tier(SimEnemyTypes.Tier.ELITE)
		Tab.CHAMPIONS:
			_populate_tier(SimEnemyTypes.Tier.CHAMPION)
		Tab.BOSSES:
			_populate_bosses()
		Tab.REGIONAL:
			_populate_regional()
		Tab.ABILITIES:
			_populate_abilities()

	# Select first item if available
	if _list_container.item_count > 0:
		_list_container.select(0)
		_on_item_selected(0)


func _populate_tier(tier: int) -> void:
	var enemy_ids: Array[String] = SimEnemyTypes.get_enemies_by_tier(tier)
	var tier_color: Color = SimBestiary.get_tier_color(tier)

	for enemy_id in enemy_ids:
		var info: Dictionary = SimBestiary.get_enemy_info(enemy_id)
		var encountered: bool = SimBestiary.has_encountered(_profile, enemy_id)
		var name_str: String = str(info.get("name", enemy_id)) if encountered else "???"
		var defeats: int = SimBestiary.get_defeat_count(_profile, enemy_id)
		var glyph: String = str(info.get("glyph", "?"))

		var display: String = "[%s] %s" % [glyph, name_str]
		if encountered and defeats > 0:
			display += " (%d)" % defeats

		var idx: int = _list_container.add_item(display)
		_list_container.set_item_metadata(idx, enemy_id)

		if encountered:
			_list_container.set_item_custom_fg_color(idx, tier_color)
		else:
			_list_container.set_item_custom_fg_color(idx, ThemeColors.TEXT_DISABLED)


func _populate_bosses() -> void:
	var boss_ids: Array[String] = SimBossEncounters.get_all_boss_ids()
	var boss_color: Color = SimBestiary.get_tier_color(SimEnemyTypes.Tier.BOSS)

	for boss_id in boss_ids:
		var info: Dictionary = SimBestiary.get_enemy_info(boss_id)
		var encountered: bool = SimBestiary.has_encountered(_profile, boss_id)
		var name_str: String = str(info.get("name", boss_id)) if encountered else "???"
		var unlock_day: int = SimBossEncounters.get_boss_unlock_day(boss_id)
		var glyph: String = str(info.get("glyph", "B"))

		var display: String = "[%s] Day %d: %s" % [glyph, unlock_day, name_str]

		var idx: int = _list_container.add_item(display)
		_list_container.set_item_metadata(idx, boss_id)

		if encountered:
			_list_container.set_item_custom_fg_color(idx, boss_color)
		else:
			_list_container.set_item_custom_fg_color(idx, ThemeColors.TEXT_DISABLED)


func _populate_regional() -> void:
	# Group by region
	var regions: Array[int] = [
		SimEnemyTypes.Region.EVERGROVE,
		SimEnemyTypes.Region.STONEPASS,
		SimEnemyTypes.Region.MISTFEN,
		SimEnemyTypes.Region.SUNFIELDS
	]

	for region in regions:
		var region_name: String = SimBestiary.get_region_name(region)
		var region_color: Color = SimBestiary.get_region_color(region)
		var regional_ids: Array[String] = SimEnemyTypes.get_regional_enemies_by_region(region)

		# Add region header
		var header_idx: int = _list_container.add_item("-- %s --" % region_name)
		_list_container.set_item_custom_fg_color(header_idx, region_color)
		_list_container.set_item_selectable(header_idx, false)
		_list_container.set_item_metadata(header_idx, "")

		for enemy_id in regional_ids:
			var info: Dictionary = SimBestiary.get_enemy_info(enemy_id)
			var encountered: bool = SimBestiary.has_encountered(_profile, enemy_id)
			var name_str: String = str(info.get("name", enemy_id)) if encountered else "???"
			var glyph: String = str(info.get("glyph", "?"))
			var tier: int = int(info.get("tier", 1))
			var tier_name: String = SimBestiary.get_tier_name(tier)

			var display: String = "  [%s] %s (%s)" % [glyph, name_str, tier_name]

			var idx: int = _list_container.add_item(display)
			_list_container.set_item_metadata(idx, enemy_id)

			if encountered:
				_list_container.set_item_custom_fg_color(idx, region_color.lightened(0.2))
			else:
				_list_container.set_item_custom_fg_color(idx, ThemeColors.TEXT_DISABLED)


func _populate_abilities() -> void:
	# Group abilities by type
	var ability_types: Array[Dictionary] = [
		{"type": SimEnemyAbilities.AbilityType.PASSIVE, "name": "Passive"},
		{"type": SimEnemyAbilities.AbilityType.TRIGGER, "name": "Trigger"},
		{"type": SimEnemyAbilities.AbilityType.COOLDOWN, "name": "Active"},
		{"type": SimEnemyAbilities.AbilityType.DEATH, "name": "On Death"}
	]

	for type_info in ability_types:
		var ability_type: int = int(type_info["type"])
		var type_name: String = str(type_info["name"])
		var ability_ids: Array[String] = SimEnemyAbilities.get_abilities_by_type(ability_type)

		if ability_ids.is_empty():
			continue

		# Add type header
		var header_idx: int = _list_container.add_item("-- %s --" % type_name)
		_list_container.set_item_custom_fg_color(header_idx, ThemeColors.RARITY_EPIC)
		_list_container.set_item_selectable(header_idx, false)
		_list_container.set_item_metadata(header_idx, "")

		for ability_id in ability_ids:
			var info: Dictionary = SimBestiary.get_ability_info(ability_id)
			var encountered: bool = SimBestiary.has_encountered_ability(_profile, ability_id)
			var name_str: String = str(info.get("name", ability_id)) if encountered else "???"

			var display: String = "  %s" % name_str

			var idx: int = _list_container.add_item(display)
			_list_container.set_item_metadata(idx, ability_id)

			if encountered:
				_list_container.set_item_custom_fg_color(idx, ThemeColors.RARITY_EPIC.lightened(0.2))
			else:
				_list_container.set_item_custom_fg_color(idx, ThemeColors.TEXT_DISABLED)


func _on_tab_selected(tab: Tab) -> void:
	_current_tab = tab
	_refresh_tab()


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _list_container.item_count:
		return

	_selected_id = str(_list_container.get_item_metadata(index))
	if _selected_id.is_empty():
		_detail_display.text = ""
		return

	match _current_tab:
		Tab.MINIONS, Tab.SOLDIERS, Tab.ELITES, Tab.CHAMPIONS, Tab.REGIONAL:
			var encountered: bool = SimBestiary.has_encountered(_profile, _selected_id)
			if encountered:
				_detail_display.text = SimBestiary.format_entry(_selected_id, _profile)
			else:
				_detail_display.text = "[i]Not yet encountered.[/i]\n\nDefeat this enemy to learn more about it."
		Tab.BOSSES:
			var encountered: bool = SimBestiary.has_encountered(_profile, _selected_id)
			if encountered:
				_detail_display.text = SimBestiary.format_boss_entry(_selected_id, _profile)
			else:
				var unlock_day: int = SimBossEncounters.get_boss_unlock_day(_selected_id)
				_detail_display.text = "[i]Not yet encountered.[/i]\n\nThis boss appears on Day %d." % unlock_day
		Tab.ABILITIES:
			var encountered: bool = SimBestiary.has_encountered_ability(_profile, _selected_id)
			if encountered:
				_detail_display.text = SimBestiary.format_ability_entry(_selected_id)
				# Show which enemies have this ability
				var enemies_with: Array[String] = SimBestiary.get_enemies_with_ability(_selected_id)
				if not enemies_with.is_empty():
					var names: Array[String] = []
					for enemy_id in enemies_with:
						if SimBestiary.has_encountered(_profile, enemy_id):
							var info: Dictionary = SimBestiary.get_enemy_info(enemy_id)
							names.append(str(info.get("name", enemy_id)))
					if not names.is_empty():
						_detail_display.text += "\n\n[color=gray]Used by:[/color] %s" % ", ".join(names)
			else:
				_detail_display.text = "[i]Not yet encountered.[/i]\n\nFight enemies with this ability to learn more."


func _on_close_pressed() -> void:
	hide_bestiary()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		hide_bestiary()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		# Switch to previous tab
		var new_tab: int = maxi(0, int(_current_tab) - 1)
		_on_tab_selected(new_tab as Tab)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		# Switch to next tab
		var new_tab: int = mini(Tab.ABILITIES, int(_current_tab) + 1)
		_on_tab_selected(new_tab as Tab)
		get_viewport().set_input_as_handled()
