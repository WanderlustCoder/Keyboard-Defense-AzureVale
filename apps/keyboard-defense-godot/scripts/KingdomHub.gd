extends Control
## Kingdom Hub - Upgrade purchase and management screen.
## Migrated to use DesignSystem and ThemeColors for consistency.

# Tier thresholds based on cost
const TIER_COLORS := {
	"common": Color(0.7, 0.7, 0.75, 1.0),   # Gray
	"uncommon": Color(0.4, 0.8, 0.4, 1.0),  # Green
	"rare": Color(0.3, 0.6, 1.0, 1.0),      # Blue
	"epic": Color(0.7, 0.4, 0.9, 1.0)       # Purple
}
const HOVER_SCALE := 1.02
const HOVER_DURATION := 0.1

var _upgrade_cards: Dictionary = {}  # upgrade_id -> Control
var _card_tweens: Dictionary = {}

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var modifiers_label: Label = $ContentPanel/Scroll/Content/ModifiersLabel
@onready var content_container: VBoxContainer = $ContentPanel/Scroll/Content
@onready var kingdom_list: VBoxContainer = $ContentPanel/Scroll/Content/KingdomList
@onready var unit_list: VBoxContainer = $ContentPanel/Scroll/Content/UnitList
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var icon_cache: Dictionary = {}
var stats_panel: PanelContainer = null

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	_refresh()
	# Play kingdom music
	if audio_manager != null:
		audio_manager.switch_to_kingdom_music()

func _refresh() -> void:
	gold_label.text = "Gold: %d" % progression.gold
	modifiers_label.text = _format_modifiers(progression.get_combat_modifiers())
	_build_stats_panel()
	_build_upgrade_section(kingdom_list, progression.get_kingdom_upgrades())
	_build_upgrade_section(unit_list, progression.get_unit_upgrades())

func _build_stats_panel() -> void:
	# Create or update the stats summary panel
	if stats_panel != null:
		stats_panel.queue_free()
		stats_panel = null

	var mastery: Dictionary = progression.mastery
	var battles_completed: int = progression.completed_nodes.size()

	# Only show if player has some stats
	if battles_completed == 0:
		return

	stats_panel = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = ThemeColors.BG_CARD
	card_style.border_color = ThemeColors.ACCENT_BLUE
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	card_style.set_content_margin_all(12)
	stats_panel.add_theme_stylebox_override("panel", card_style)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	stats_panel.add_child(box)

	var title = Label.new()
	title.text = "📊 Your Mastery"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_BLUE)
	box.add_child(title)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(stats_grid)

	# Best stats
	var best_acc = int(round(float(mastery.get("best_accuracy", 0.0)) * 100.0))
	var best_wpm = int(round(float(mastery.get("best_wpm", 0.0))))
	_add_stat_row(stats_grid, "Best Accuracy:", "%d%%" % best_acc, ThemeColors.SUCCESS)
	_add_stat_row(stats_grid, "Best WPM:", "%d" % best_wpm, ThemeColors.SUCCESS)

	# Last battle stats
	var last_acc = int(round(float(mastery.get("last_accuracy", 0.0)) * 100.0))
	var last_wpm = int(round(float(mastery.get("last_wpm", 0.0))))
	_add_stat_row(stats_grid, "Last Battle:", "%d%% / %d WPM" % [last_acc, last_wpm], ThemeColors.TEXT_DIM)

	# Battles completed
	_add_stat_row(stats_grid, "Battles Won:", "%d" % battles_completed, ThemeColors.TEXT_DIM)

	# Insert after modifiers label (index 0 in content)
	content_container.add_child(stats_panel)
	content_container.move_child(stats_panel, 1)

func _add_stat_row(container: GridContainer, label_text: String, value_text: String, value_color: Color) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	container.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", value_color)
	container.add_child(value)

func _format_modifiers(modifiers: Dictionary) -> String:
	var parts: Array = []
	var typing_bonus = int(round((float(modifiers.get("typing_power", 1.0)) - 1.0) * 100.0))
	if typing_bonus != 0:
		parts.append("Typing Power %+d%%" % typing_bonus)
	var threat_bonus = int(round((1.0 - float(modifiers.get("threat_rate_multiplier", 1.0))) * 100.0))
	if threat_bonus != 0:
		parts.append("Threat Slow %+d%%" % threat_bonus)
	var forgiveness = int(round(float(modifiers.get("mistake_forgiveness", 0.0)) * 100.0))
	if forgiveness != 0:
		parts.append("Mistake Forgiveness %+d%%" % forgiveness)
	var castle_bonus = int(modifiers.get("castle_health_bonus", 0))
	if castle_bonus != 0:
		parts.append("Castle +%d" % castle_bonus)
	if parts.is_empty():
		return "Training bonuses: None yet. Upgrade to boost your typing impact."
	return "Training bonuses: " + ", ".join(parts)

func _get_upgrade_tags(effects: Dictionary) -> Array:
	var tags: Array = []
	if float(effects.get("typing_power", 0.0)) != 0.0:
		tags.append(_make_tag("res://assets/icons/typing_power.png", "Typing Power"))
	if float(effects.get("threat_rate_multiplier", 0.0)) != 0.0:
		tags.append(_make_tag("res://assets/icons/threat_slow.png", "Threat Slow"))
	if float(effects.get("mistake_forgiveness", 0.0)) != 0.0:
		tags.append(_make_tag("res://assets/icons/mistake_forgiveness.png", "Mistake Forgiveness"))
	if int(effects.get("castle_health_bonus", 0)) != 0:
		tags.append(_make_tag("res://assets/icons/castle_health.png", "Castle Health"))
	return tags

func _format_effect_preview(effects: Dictionary, owned: bool) -> String:
	# Show the actual impact of the upgrade
	var parts: Array = []
	var typing_power = float(effects.get("typing_power", 0.0))
	if typing_power != 0.0:
		var percent = int(round(typing_power * 100.0))
		parts.append("+%d%% Typing Power" % percent)
	var threat_mult = float(effects.get("threat_rate_multiplier", 0.0))
	if threat_mult != 0.0:
		var percent = int(round((1.0 - threat_mult) * 100.0))
		parts.append("%+d%% Threat Slow" % percent)
	var forgiveness = float(effects.get("mistake_forgiveness", 0.0))
	if forgiveness != 0.0:
		var percent = int(round(forgiveness * 100.0))
		parts.append("+%d%% Mistake Forgiveness" % percent)
	var castle_bonus = int(effects.get("castle_health_bonus", 0))
	if castle_bonus != 0:
		parts.append("+%d Castle Health" % castle_bonus)
	if parts.is_empty():
		return ""
	var prefix = "Effect: " if owned else "Grants: "
	return prefix + ", ".join(parts)

func _make_tag(icon_path: String, tooltip: String) -> Dictionary:
	return {"icon_path": icon_path, "tooltip": tooltip}

func _load_icon(path: String) -> Texture2D:
	if icon_cache.has(path):
		return icon_cache[path]
	var image = Image.new()
	if image.load(path) != OK:
		return null
	var texture = ImageTexture.create_from_image(image)
	icon_cache[path] = texture
	return texture

func _build_tag_badge(tag: Dictionary) -> TextureRect:
	var icon = TextureRect.new()
	var icon_path = str(tag.get("icon_path", ""))
	icon.texture = _load_icon(icon_path)
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.tooltip_text = str(tag.get("tooltip", ""))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _get_tier_from_cost(cost: int) -> String:
	if cost >= 60:
		return "epic"
	elif cost >= 35:
		return "rare"
	elif cost >= 15:
		return "uncommon"
	else:
		return "common"

func _get_tier_label(tier: String) -> String:
	match tier:
		"epic": return "★★★"
		"rare": return "★★"
		"uncommon": return "★"
		_: return ""

func _build_upgrade_section(container: VBoxContainer, upgrades: Array) -> void:
	# Clear old references
	for child in container.get_children():
		child.queue_free()

	for upgrade in upgrades:
		var upgrade_id = str(upgrade.get("id", ""))
		var label = str(upgrade.get("label", ""))
		var cost = int(upgrade.get("cost", 0))
		var owned = progression.is_upgrade_owned(upgrade_id)
		var description = str(upgrade.get("description", ""))
		var effects: Dictionary = upgrade.get("effects", {})
		var tier := _get_tier_from_cost(cost)
		var tier_color: Color = TIER_COLORS.get(tier, TIER_COLORS["common"])

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 100)
		panel.pivot_offset = Vector2(panel.custom_minimum_size.x * 0.5, 50)

		var card_style = StyleBoxFlat.new()
		card_style.bg_color = ThemeColors.BG_CARD
		if owned:
			card_style.border_color = ThemeColors.ACCENT
			card_style.set_border_width_all(3)
		else:
			card_style.border_color = tier_color
			card_style.set_border_width_all(2)
		card_style.set_corner_radius_all(6)
		card_style.set_content_margin_all(12)
		panel.add_theme_stylebox_override("panel", card_style)

		# Add hover effects for purchasable cards
		if not owned and progression.gold >= cost:
			panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			panel.mouse_entered.connect(_on_card_hover_enter.bind(upgrade_id))
			panel.mouse_exited.connect(_on_card_hover_exit.bind(upgrade_id))

		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		panel.add_child(box)

		# Title row with tier badge and owned checkmark
		var title_row = HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 8)
		box.add_child(title_row)

		# Tier badge
		var tier_label_text := _get_tier_label(tier)
		if tier_label_text != "":
			var tier_badge = Label.new()
			tier_badge.text = tier_label_text
			tier_badge.add_theme_font_size_override("font_size", 14)
			tier_badge.add_theme_color_override("font_color", tier_color)
			title_row.add_child(tier_badge)

		# Owned checkmark
		if owned:
			var check_badge = Label.new()
			check_badge.text = "✓"
			check_badge.add_theme_font_size_override("font_size", 16)
			check_badge.add_theme_color_override("font_color", ThemeColors.ACCENT)
			title_row.add_child(check_badge)

		var title = Label.new()
		title.text = "%s (%dg)" % [label, cost]
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", ThemeColors.ACCENT if owned else ThemeColors.TEXT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_child(title)

		_upgrade_cards[upgrade_id] = panel

		var desc = Label.new()
		desc.text = description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		box.add_child(desc)

		# Show effect preview with actual numbers
		var effect_text := _format_effect_preview(effects, owned)
		if effect_text != "":
			var effect_label = Label.new()
			effect_label.text = effect_text
			effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			effect_label.add_theme_font_size_override("font_size", 13)
			effect_label.add_theme_color_override("font_color", ThemeColors.SUCCESS if owned else ThemeColors.ACCENT)
			box.add_child(effect_label)

		var tags = _get_upgrade_tags(effects)
		if not tags.is_empty():
			var tag_row = HBoxContainer.new()
			tag_row.add_theme_constant_override("separation", 8)
			for tag in tags:
				tag_row.add_child(_build_tag_badge(tag))
			box.add_child(tag_row)

		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		if owned:
			button.text = "Owned"
			button.disabled = true
		elif progression.gold < cost:
			button.text = "Need %dg" % cost
			button.disabled = true
		else:
			button.text = "Purchase"
			button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		box.add_child(button)

		container.add_child(panel)

func _on_upgrade_pressed(upgrade_id: String) -> void:
	if progression.apply_upgrade(upgrade_id):
		if audio_manager != null:
			audio_manager.play_upgrade_purchase()
		_refresh()

func _on_back_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	game_controller.go_to_map()

func _on_card_hover_enter(upgrade_id: String) -> void:
	var card = _upgrade_cards.get(upgrade_id)
	if card == null:
		return

	# Kill existing tween
	if _card_tweens.has(upgrade_id):
		var old_tween = _card_tweens[upgrade_id]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_DURATION)
	_card_tweens[upgrade_id] = tween

	if audio_manager != null:
		audio_manager.play_ui_hover()

func _on_card_hover_exit(upgrade_id: String) -> void:
	var card = _upgrade_cards.get(upgrade_id)
	if card == null:
		return

	# Kill existing tween
	if _card_tweens.has(upgrade_id):
		var old_tween = _card_tweens[upgrade_id]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), HOVER_DURATION)
	_card_tweens[upgrade_id] = tween
